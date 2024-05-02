import SwiftUI

struct SignupView: View {
    @EnvironmentObject var globalData: GlobalData
    @State private var firstName: String = ""
    @State private var lastName: String = ""
    @State private var email: String = ""
    @State private var password: String = ""
    @State private var confirmPassword: String = ""
    @State private var showErrorAlert = false
    @State private var errorMessage = ""
    @State private var showSignupSuccessPopup = false
    @Environment(\.presentationMode) var presentationMode
    
    var body: some View {
        GeometryReader { geometry in
            VStack {
                Image("ll")
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .scaleEffect(0.5)
                    .imageScale(.large)
                    .foregroundStyle(.tint)
                    .padding()
                
                TextField("First Name", text: $firstName)
                    .padding()
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .frame(width: 230, height: 40)
                    .padding(.horizontal)
                
                TextField("Last Name", text: $lastName)
                    .padding()
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .frame(width: 230, height: 40)
                    .padding(.horizontal)
                
                TextField("Email", text: $email)
                    .padding()
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .keyboardType(.emailAddress)
                    .frame(width: 230, height: 40)
                    .padding(.horizontal)
                    .onChange(of: email) { newValue in
                        email = newValue.lowercased()
                    }
                
                SecureField("Password", text: $password)
                    .padding()
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .frame(width: 230, height: 40)
                    .padding(.horizontal)
                
                SecureField("Confirm Password", text: $confirmPassword)
                    .padding()
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .frame(width: 230, height: 40)
                    .padding(.horizontal)
                
                Button(action: {
                    signup()
                }) {
                    Text("Sign Up")
                }
                .padding()
                .foregroundColor(.white)
                .frame(width: 200, height: 40)
                .background(Color.blue)
                .cornerRadius(5)
                .padding(.horizontal)
                
                Spacer()
                
            }
            .padding()
            
            .frame(width: geometry.size.width, height: geometry.size.height)
            .background(LinearGradient(gradient: Gradient(colors: [Color.white, Color.purple.opacity(0.5), Color.red]), startPoint: .top, endPoint: .bottom))
            .alert(isPresented: $showErrorAlert) {
                Alert(title: Text("Error"), message: Text(errorMessage), dismissButton: .default(Text("OK")))
            }
            .alert(isPresented: $showSignupSuccessPopup) {
                Alert(title: Text("Sign Up Successful"), message: Text("Please Login to your account."), dismissButton: .default(Text("OK")))
            }
        }
    }
    
    private func signup() {
        guard password == confirmPassword else {
            errorMessage = "Passwords do not match"
            showErrorAlert = true
            return
        }
        
        guard let url = URL(string: "\(globalData.api)users") else {
            print("Invalid API URL")
            return
        }
        
        let userData = SignupData(first_name: firstName, last_name: lastName, email: email, password: password)
        
        guard let encodedData = try? JSONEncoder().encode(userData) else {
            print("Failed to encode user data")
            return
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = encodedData
        
        URLSession.shared.dataTask(with: request) { data, response, error in
            guard let httpResponse = response as? HTTPURLResponse else {
                print("Invalid response")
                return
            }
            
            if httpResponse.statusCode == 201 {
                print("Signup successful")
                showSignupSuccessPopup = true
                DispatchQueue.main.async {
                    presentationMode.wrappedValue.dismiss()
                }
               
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

struct SignupData: Codable {
    let first_name: String
    let last_name: String
    let email: String
    let password: String
}


#Preview{SignupView()}
