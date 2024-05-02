import SwiftUI
import Foundation
import CoreData
import QRCode

// Define the Booking struct

struct BookingRowView: View {
    let booking: Booking
    
    var body: some View {
        HStack(alignment: .top) {
            // QR code or image on the left
            QRCodeViewUI(
                content: booking.transaction_id,
                foregroundColor: CGColor(srgbRed: 0, green: 0, blue: 0, alpha: 1.0),
                backgroundColor: CGColor(srgbRed: 1, green: 1, blue: 1, alpha: 1.0),
                pixelStyle: QRCode.PixelShape.RoundedPath(cornerRadiusFraction: 0.7, hasInnerCorners: true),
                eyeStyle: QRCode.EyeShape.RoundedRect()
            )
            .frame(width: 100, height: 100) // Adjust size as needed
            
            // Other details on the right
            VStack(alignment: .leading) {
                Text("\(booking.event_name)").foregroundColor(.gray)
                Text("\(booking.number_of_tickets) Tickets").foregroundColor(.gray)
                // Add other details here
            }
        }
        .padding()
        .background(Color.black)
        .frame(width: 350, height:150)
    }
}



struct MyBookingsPage: View {
    @EnvironmentObject var globalData: GlobalData // Access the global variable
    @State private var bookings: [Booking] = []
    let coreDataManager = CoreDataManager.shared
    @State private var userEmail: String?
    @State private var userPassword: String?
    
    var body: some View {
        NavigationView {
            VStack {
                
                ScrollView {
                    VStack(spacing: 10) {
                        ForEach(bookings, id: \.transaction_id) { booking in
                            BookingRowView(booking: booking)
                                .background(Color.black)
                                .cornerRadius(5)
                                .padding()
                        }
                    }
                }
                .padding(.horizontal)
            }
            .onAppear {
                fetchBookings()
            }
            .navigationBarTitle("My Bookings", displayMode: .inline)
            .background(LinearGradient(gradient: Gradient(colors: [Color.white, Color.purple.opacity(0.5), Color.red]), startPoint: .bottom, endPoint: .top))
        }
    }
    
    func fetchBookings() {
        guard let url = URL(string: "\(globalData.api)transactions/user_transactions/") else {
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
                        let decodedData = try JSONDecoder().decode([Booking].self, from: data)
                        DispatchQueue.main.async {
                            self.bookings = decodedData.sorted { $0.transaction_created > $1.transaction_created }
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
