import Foundation
import SwiftUI
import CoreData

struct HomePage: View {
    @State private var events: [Event] = []
    @EnvironmentObject var globalData: GlobalData
    
    var body: some View {
        NavigationView {
            VStack {
                ScrollView {
                    VStack(spacing: 10) {
                        ForEach(events, id: \.event_id) { event in
                            NavigationLink(destination: EventDetailPage(event: event)) {
                                EventCard(event: event)
                                    .cornerRadius(5)
                            }
                        }
                    }
                }
                .padding(.horizontal)
            }
            .onAppear {
                fetchEvents()
            }
            .navigationBarTitle("All Events", displayMode: .inline)
            .background(LinearGradient(gradient: Gradient(colors: [Color.white, Color.purple.opacity(0.5), Color.red]), startPoint: .bottom, endPoint: .top))
            
        }
        
    }
    
    func fetchEvents() {
        guard let url = URL(string: "\(globalData.api)events/") else {
            return
        }
        
        let fetchRequest: NSFetchRequest<User> = User.fetchRequest()
        let context = PersistenceController.shared.container.viewContext
        
        do {
            let users = try context.fetch(fetchRequest)
            if let user = users.first {
                let username = user.email ?? ""
                let password = user.password ?? ""
                let loginString = "\(username):\(password)"
                let loginData = loginString.data(using: .utf8)?.base64EncodedString() ?? ""
                
                var request = URLRequest(url: url)
                request.httpMethod = "GET"
                request.setValue("Basic \(loginData)", forHTTPHeaderField: "Authorization")
                
                URLSession.shared.dataTask(with: request) { data, response, error in
                    guard let data = data else {
                        return
                    }
                    
                    do {
                        let decodedData = try JSONDecoder().decode([Event].self, from: data)
                        DispatchQueue.main.async {
                            self.events = decodedData.sorted { $0.event_created > $1.event_created }
                        }
                    } catch {
                        print("Error decoding JSON: \(error)")
                    }
                }.resume()
            } else {
                print("No user data found in Core Data")
            }
        } catch {
            print("Error fetching user data: \(error)")
        }
    }
}

struct EventCard: View {
    let event: Event
    @State private var thumbnailImage: UIImage?
    
    var body: some View {
        HStack(alignment: .top) {
            if let thumbnail = event.thumbnail, let thumbnailImage = thumbnailImage {
                Image(uiImage: thumbnailImage)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 100, height: 100)
                    .cornerRadius(8)
                    .padding(.vertical, 4)
            } else {
                RoundedRectangle(cornerRadius: 8)
                    .fill(Color.gray)
                    .frame(width: 100, height: 100)
                    .padding(.vertical, 4)
            }
            
            VStack(alignment: .leading) {
                Text(event.event_name)
                    .font(.headline)
                    .foregroundColor(Color.white)
                
                Text("📍\(event.event_venue)")
                    .font(.subheadline)
                    .foregroundColor(.gray)
                
                Text("\(formatDate(event.event_date))          ")
                    .font(.subheadline)
                    .foregroundColor(.gray)
                
                Text("💰\(String(format: "%.2f", event.ticket_price))")
                    .font(.subheadline)
                    .foregroundColor(.green)
                    .bold()
                    
            }
        }
        .padding()
        .onAppear {
            if let thumbnail = event.thumbnail, let url = URL(string: thumbnail) {
                URLSession.shared.dataTask(with: url) { data, response, error in
                    guard let data = data, let image = UIImage(data: data) else {
                        return
                    }
                    DispatchQueue.main.async {
                        thumbnailImage = image
                    }
                }.resume()
            }
        }
        .background(Color.black)
    }
}

func formatDate(_ dateString: String) -> String {
    let dateFormatter = DateFormatter()
    dateFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSSZ"
    
    if let eventDate = dateFormatter.date(from: dateString) {
        let dateFormatterOutput = DateFormatter()
        dateFormatterOutput.dateFormat = "MMMM d, yyyy"
        let formattedDate = dateFormatterOutput.string(from: eventDate)

        let timeFormatterOutput = DateFormatter()
        timeFormatterOutput.dateFormat = "HH:mm"
        let formattedTime = timeFormatterOutput.string(from: eventDate)

        return "🗓️\(formattedDate)  ⏰\(formattedTime)"
    } else {
        return "Invalid date"
    }
}
