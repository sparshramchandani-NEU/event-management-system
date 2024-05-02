import SwiftUI
import FirebaseStorage

struct AddPage: View {
    @EnvironmentObject var globalData: GlobalData
    @State private var eventName = ""
    @State private var eventDescription = ""
    @State private var eventVenue = ""
    @State private var totalSeats = ""
    @State private var eventDate = Date()
    @State private var eventTime = Date()
    @State private var ticketPrice = ""
    @State private var selectedImage: UIImage?
    @State private var isShowingImagePicker = false
    @State private var isDatePickerVisible = false
    @State private var isTimePickerVisible = false
    @State private var showEventCreatedSuccessPopup = false
    @State private var imageURL = ""
    @State private var showErrorAlert = false
    @State private var errorMessage = ""
    @State private var dateTimeErrorMessage = ""
    
    @State private var userEmail: String?
    @State private var userPassword: String?

    @State private var totalSeatsErrorMessage = ""
    @State private var ticketPriceErrorMessage = ""
    
    let coreDataManager = CoreDataManager.shared

    var body: some View {
        NavigationView {
            ZStack {
                
                Form {
                    Section(header: Text("Event Details")) {
                        TextField("Event Name", text: $eventName)
                        TextField("Event Description", text: $eventDescription)
                        TextField("Event Venue", text: $eventVenue)
                        TextField("Total Seats", text: $totalSeats)
                            .keyboardType(.numberPad)
                            .onChange(of: totalSeats) { newValue in
                                validateTotalSeats()
                            }
                        Text(totalSeatsErrorMessage)
                            .foregroundColor(.red)
                            .font(.caption)
                    }
                    
                    Section(header: Text("Event Date & Time")) {
                        DatePicker("Event Date", selection: $eventDate, displayedComponents: .date)
                            .datePickerStyle(WheelDatePickerStyle())
                            .onChange(of: eventDate) { newValue in
                                validateDateTime()
                            }
                        DatePicker("Event Time", selection: $eventTime, displayedComponents: .hourAndMinute)
                            .datePickerStyle(WheelDatePickerStyle())
                            .onChange(of: eventTime) { newValue in
                                validateDateTime()
                            }
                        Text(dateTimeErrorMessage)
                            .foregroundColor(.red)
                            .font(.caption)
                    }
                    
                    Section(header: Text("Ticket Details")) {
                        TextField("Ticket Price", text: $ticketPrice)
                            .keyboardType(.decimalPad)
                            .onChange(of: ticketPrice) { newValue in
                                validateTicketPrice()
                            }
                        Text(ticketPriceErrorMessage)
                            .foregroundColor(.red)
                            .font(.caption)
                    }
                    
                    Section(header: Text("Event Image")) {
                        Button(action: {
                            self.isShowingImagePicker.toggle()
                        }) {
                            if let image = selectedImage {
                                Image(uiImage: image)
                                    .resizable()
                                    .aspectRatio(contentMode: .fit)
                                    .frame(width: 200, height: 200)
                            } else {
                                Text("Select Image")
                            }
                        }
                        .sheet(isPresented: $isShowingImagePicker) {
                            ImagePicker(selectedImage: self.$selectedImage)
                        }
                    }
                    
                    Section {
                        Button("Add Event") {
                            uploadPhoto()
                        }
                    }
                }
                .navigationBarTitle("Add Event", displayMode: .inline)
                .alert(isPresented: $showErrorAlert) {
                    Alert(title: Text("Error"), message: Text(errorMessage), dismissButton: .default(Text("OK")))
                }
                .alert(isPresented: $showEventCreatedSuccessPopup) {
                    Alert(title: Text("Event Created Successfully"), message: Text(""), dismissButton: .default(Text("OK")))
                }
                .onAppear(){
                    fetchUserCredentials()
                }
            }
        }
    }

    
    func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .none
        return formatter.string(from: date)
    }
    
    func formatTime(_ time: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .none
        formatter.timeStyle = .short
        return formatter.string(from: time)
    }
    
    func uploadPhoto() {
        guard let selectedImage = selectedImage else {
            return
        }
        
        let storageRef = Storage.storage().reference()
        
        guard let imageData = selectedImage.pngData() else {
            return
        }
        
        let fileRef = storageRef.child("images/\(UUID().uuidString).png")
        
        let metadata = StorageMetadata()
        metadata.contentType = "image/png"

        fileRef.putData(imageData, metadata: metadata) { metadata, error in
            if let error = error {
                print("Error uploading image: \(error.localizedDescription)")
                return
            }
            
            fileRef.downloadURL { url, error in
                if let error = error {
                    print("Error getting download URL: \(error.localizedDescription)")
                    return
                }
                
                if let downloadURL = url {
                    imageURL = downloadURL.absoluteString
                    print("Image uploaded successfully. Direct URL: \(imageURL)")
                }
                
                addEvent()
            }
        }
    }
    
    func validateTotalSeats() {
        if let seats = Int(totalSeats), seats > 0 {
            totalSeatsErrorMessage = ""
        } else {
            totalSeatsErrorMessage = "Total seats must be a positive integer."
        }
    }

    func validateTicketPrice() {
        if let price = Float(ticketPrice), price > 0 {
            ticketPriceErrorMessage = ""
        } else {
            ticketPriceErrorMessage = "Ticket price must be a positive number."
        }
    }
    
    private func fetchUserCredentials() {
        coreDataManager.fetchFirstUserCredentials { email, password, _ in
            userEmail = email
            userPassword = password
        }
    }
    
    private func validateDateTime() {
        let currentDate = Date()
        if eventDate < currentDate || (eventDate == currentDate && eventTime <= currentDate) {
            dateTimeErrorMessage = "Event date and time must be ahead of the current date and time."
        } else {
            dateTimeErrorMessage = ""
        }
    }
    
    func addEvent() {
        // Validate the event date and time
        validateDateTime()
        
        // Check if there are any validation errors
        if !dateTimeErrorMessage.isEmpty {
            // Show alert with error message
            showErrorAlert = true
            return
        }
        
        guard let userEmail = userEmail, let userPassword = userPassword else {
            print("User credentials not available")
            return
        }
        
        guard !eventName.isEmpty else {
            errorMessage = "Event name is required."
            showErrorAlert = true
            return
        }
        
        guard !eventDescription.isEmpty else {
            errorMessage = "Event description is required."
            showErrorAlert = true
            return
        }
        
        guard !eventVenue.isEmpty else {
            errorMessage = "Event venue is required."
            showErrorAlert = true
            return
        }
        
        guard let totalSeatsValue = Int32(totalSeats), totalSeatsValue > 0 else {
            errorMessage = "Total seats must be a positive integer."
            showErrorAlert = true
            return
        }
        
        guard let ticketPriceValue = Float(ticketPrice), ticketPriceValue > 0 else {
            errorMessage = "Ticket price must be a positive number."
            showErrorAlert = true
            return
        }
        
        guard selectedImage != nil else {
            errorMessage = "Please select an image."
            showErrorAlert = true
            return
        }
        
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"
        let dateString = dateFormatter.string(from: eventDate)
        dateFormatter.dateFormat = "HH:mm:ss"
        let timeString = dateFormatter.string(from: eventTime)
        let dateTimeString = "\(dateString)T\(timeString).001Z"
        print("Event Date and Time (Formatted): \(dateTimeString)")
        
        guard let url = URL(string: "http://209.38.148.70:3000/events/") else {
            print("Invalid API URL")
            return
        }

        let eventData = EventData(event_name: eventName, event_description: eventDescription, event_venue: eventVenue, total_seats: totalSeatsValue, seats_left: totalSeatsValue, event_date: dateTimeString, ticket_price: ticketPriceValue, thumbnail: imageURL)

        guard let encodedData = try? JSONEncoder().encode(eventData) else {
            print("Failed to encode user data")
            return
        }

        let loginData = "\(userEmail):\(userPassword)".data(using: .utf8)?.base64EncodedString() ?? ""

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("Basic \(loginData)", forHTTPHeaderField: "Authorization")
        request.httpBody = encodedData
        
        URLSession.shared.dataTask(with: request) { data, response, error in
            guard let httpResponse = response as? HTTPURLResponse else {
                print("Invalid response")
                return
            }
            
            if httpResponse.statusCode == 201 {
                print("Event Created Successfully")
                eventName = ""
                eventDescription = ""
                eventVenue = ""
                totalSeats = ""
                eventDate = Date()
                eventTime = Date()
                ticketPrice = ""
                selectedImage = nil
                imageURL = ""
                showEventCreatedSuccessPopup = true
            } else {
                if let data = data, let errorResponse = try? JSONDecoder().decode(ErrorResponse.self, from: data) {
                    errorMessage = errorResponse.error
                } else {
                    errorMessage = "Signup failed with status code: \(httpResponse.statusCode)"
                }
                showErrorAlert = true
            }
        }.resume()
    }
}
