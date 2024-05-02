import SwiftUI

struct EventDetailPage: View {
    @EnvironmentObject var globalData: GlobalData // Access the global variable
        let event: Event
        @State private var thumbnailImage: UIImage? // State variable to hold the thumbnail image
        @State private var numberOfTickets = 1 // State variable for the number of tickets
        @State private var isBookingConfirmed = false // State variable to track booking confirmation
        @State private var errorMessage = "" // State variable for error message
        
        // Inject CoreDataManager instance
        let coreDataManager = CoreDataManager.shared
        
        // User credentials
        @State private var userEmail: String?
        @State private var userPassword: String?
        
        var totalPrice: Double {
            return event.ticket_price * Double(numberOfTickets)
        }
        
        var body: some View {
            ScrollView {
                VStack {
                    if let thumbnailImage = thumbnailImage {
                        Image(uiImage: thumbnailImage)
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .frame(maxWidth: .infinity)
                            .cornerRadius(8)
                            .padding(.bottom)
                    } else {
                        RoundedRectangle(cornerRadius: 8)
                            .fill(Color.gray)
                            .frame(height: 200)
                            .padding(.bottom)
                    }
                    
                    Text(event.event_name)
                        .font(.title)
                        .padding(.bottom)
                    
                    VStack(alignment: .leading, spacing: 10) {
                        Text(event.event_description)
                            .font(.body)
                        
                        Text("📍\(event.event_venue)")
                            .font(.body)
                        
                        Text(formatDate(event.event_date))
                            .font(.body)
                        
                        Text("💰\(String(format: "%.2f", event.ticket_price))")
                            .font(.subheadline)
                            .foregroundColor(.green)
                            .bold()
                        
                        Text("Seats Left:")
                            .font(.headline)
                        Text("\(event.seats_left)")
                            .font(.body)
                        
                        Stepper(value: $numberOfTickets, in: 1...10) {
                            Text("Number of Tickets: \(numberOfTickets)")
                        }
                        .padding(.bottom)
                    }
                    .padding(.horizontal)
                    
                    Button(action: {
                        if event.seats_left <= 0 {
                            errorMessage = "No seats left"
                        } else if numberOfTickets > event.seats_left {
                            errorMessage = "Not enough seats left"
                        } else {
                            isBookingConfirmed = true
                        }
                    }) {
                        Text("Book Tickets")
                            .padding()
                            .foregroundColor(.white)
                    }
                    .padding()
                    .buttonStyle(SquareButtonStyle())
                    .alert(isPresented: $isBookingConfirmed) {
                        Alert(
                            title: Text("Confirm Booking"),
                            message: Text("Number of Tickets: \(numberOfTickets)\nTotal Price: $\(totalPrice)"),
                            primaryButton: .default(Text("OK")) {
                                // Send POST request for booking
                                confirmBooking()
                            },
                            secondaryButton: .cancel()
                        )
                    }
                    
                    if !errorMessage.isEmpty {
                        Text(errorMessage)
                            .foregroundColor(.red)
                            .padding()
                    }
                }
                .onAppear {
                    // Fetch user credentials from Core Data
                    fetchUserCredentials()
                    
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
            }
            .padding(.horizontal)
        }
        
        private func fetchUserCredentials() {
            // Fetch user credentials from Core Data
            coreDataManager.fetchFirstUserCredentials { email, password, _ in
                userEmail = email
                userPassword = password
            }
        }
    
    private func confirmBooking() {
        guard let userEmail = userEmail, let userPassword = userPassword else {
            print("User credentials not available")
            return
        }
        
        guard let url = URL(string: "\(globalData.api)transactions/\(event.event_id)") else {
            print("Invalid API URL")
            return
        }
        
        let bookingData = ["number_of_tickets": numberOfTickets]
        
        guard let jsonData = try? JSONSerialization.data(withJSONObject: bookingData) else {
            print("Failed to encode booking data")
            return
        }
        
        let loginData = "\(userEmail):\(userPassword)".data(using: .utf8)?.base64EncodedString() ?? ""
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("Basic \(loginData)", forHTTPHeaderField: "Authorization")
        request.httpBody = jsonData
        
        URLSession.shared.dataTask(with: request) { data, response, error in
            guard let httpResponse = response as? HTTPURLResponse else {
                print("Invalid response")
                return
            }
            
            if httpResponse.statusCode == 201 {
                print("Booking confirmed successfully")
            } else {
                print("Error booking tickets")
            }
        }.resume()
    }
}
