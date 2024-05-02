import SwiftUI
import CoreData
import Foundation

struct ProfilePage: View {
    @StateObject private var viewModel = ProfileViewModel()
    @State private var isProfileVisible = false // Track whether profile details are visible
    @EnvironmentObject var globalData: GlobalData // Access the global variable
    @State private var events: [Event] = []
    
    var body: some View {
        NavigationView {
            VStack {
                Button(action: {
                    isProfileVisible.toggle()
                }) {
                    HStack {
                        Image(systemName: "person.circle.fill")
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .frame(width: 50, height: 50)
                            .foregroundColor(.black)
                        
                        // Display user's first name
                        Text(viewModel.user?.first_name ?? "")
                            .font(.headline)
                            .padding()
                            .foregroundColor(.black)
                        Spacer()
                        Image(systemName: "chevron.right")
                            .foregroundColor(.black)
                            .padding()
                    }
                    .background(Color.white)
                    .cornerRadius(8)
                    .padding()
                    
                }
                .frame(maxWidth: .infinity)
                .padding(.horizontal)
                .background(LinearGradient(gradient: Gradient(colors: [Color.white, Color.purple.opacity(0.5), Color.red]), startPoint: .top, endPoint: .bottom))
                
                if let user = viewModel.user {
                    NavigationLink(
                        destination: ProfileDetailsView(user: user),
                        isActive: $isProfileVisible
                    ) {
                        EmptyView()
                    }
                    .frame(width: 0, height: 0)
                    .hidden()
                } else {
                    Text("Loading Profile...")
                }
                
                NavigationView {
                    VStack {
                        Text("My Hosted Events")
                            .font(.title3)
                            .padding()
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
                    .background(LinearGradient(gradient: Gradient(colors: [Color.white, Color.purple.opacity(0.5), Color.red]), startPoint: .bottom, endPoint: .top))
                }
                
            }
            .navigationBarTitle("Welcome \(viewModel.user?.first_name ?? "")")
            .onAppear {
                viewModel.fetchUserCredentials()
            }
            .background(Color.red)
        }
        
    }
    func fetchEvents() {
        guard let url = URL(string: "\(globalData.api)events/user_events") else {
            return
        }
        
        // Fetch username and password from Core Data
        let fetchRequest: NSFetchRequest<User> = User.fetchRequest()
        let context = PersistenceController.shared.container.viewContext
        
        do {
            let users = try context.fetch(fetchRequest)
            if let user = users.first {
                let username = user.email ?? ""
                let password = user.password ?? ""
                
//                let username = "john.doe@example.com"
//                let password = "abc123"
//
                // Encode username and password for basic authentication
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



class ProfileViewModel: ObservableObject {
    @Published var user: UserInfo?
    private let coreDataManager = CoreDataManager.shared
    
    func fetchUserCredentials() {
        coreDataManager.fetchFirstUserCredentials { email, password, user_id in
            if let userId = user_id, let userEmail = email, let userPassword = password {
                self.fetchUserInfo(userId: userId, userEmail: userEmail, userPassword: userPassword)
            }
        }
    }
    
    private func fetchUserInfo(userId: String, userEmail: String, userPassword: String) {
        guard let url = URL(string: "http://209.38.148.70:3000/users/\(userId)") else {
            return
        }
        
        let loginData = "\(userEmail):\(userPassword)".data(using: .utf8)?.base64EncodedString() ?? ""
        
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("Basic \(loginData)", forHTTPHeaderField: "Authorization")
        
        URLSession.shared.dataTask(with: request) { data, response, error in
            guard let data = data, error == nil else {
                print("Error fetching user data: \(error?.localizedDescription ?? "Unknown error")")
                return
            }
            
            do {
                let decodedData = try JSONDecoder().decode(UserInfo.self, from: data)
                DispatchQueue.main.async {
                    self.user = decodedData
                }
            } catch {
                print("Error decoding user data: \(error.localizedDescription)")
            }
        }.resume()
    }
}


