import SwiftUI

struct LoginView: View {
    @EnvironmentObject var globalData: GlobalData
    @State private var email: String = ""
    @State private var password: String = ""
    @Environment(\.managedObjectContext) private var viewContext
    @State private var errorMessage = ""
    @State private var isSignupActive = false
    @State private var showForgotPasswordAlert = false
    @State private var forgotPasswordResponse: String = ""
    @State private var forgotPasswordResponseTitle: String = ""
    @State private var isLoggedIn = false
    
    var body: some View {
        NavigationView {
            GeometryReader { geometry in
                VStack {
                    
                    Spacer()
                    
                    Image("ll")
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .scaleEffect(0.5)
                        .animation(.easeInOut(duration: 1.0))
                        .imageScale(.large)
                        .foregroundStyle(.tint)
                        .padding()

                    
                    TextField("Email", text: $email)
                        .padding()
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .frame(width: 230, height: 40)
                        .onChange(of: email) { newValue in
                            email = newValue.lowercased()
                        }
                    
                    SecureField("Password", text: $password)
                        .padding()
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .frame(width: 230, height: 40)
                    
                    NavigationLink(destination: ContentView().navigationBarBackButtonHidden(true), isActive: $isLoggedIn) {
                        Button(action: {
                            login()
                        }) {
                            Text("Login")
                        }
                    }
                    .padding()
                    .buttonStyle(SquareButtonStyle())
                    .frame(width: 200, height: 40)
                    .alert(isPresented: $showForgotPasswordAlert) {
                        Alert(title: Text(forgotPasswordResponseTitle), message: Text(forgotPasswordResponse), dismissButton: .default(Text("OK")))
                    }
                    
                    NavigationLink(destination: SignupView(), isActive: $isSignupActive) {
                        Text("Sign Up")
                    }
                    .padding()
                    .foregroundColor(.white)
                    .frame(width: 200, height: 40)
                    .background(Color.blue)
                    .cornerRadius(5)
                    .padding(.horizontal)
                    
                    Button(action: {
                        forgotPassword()
                    }) {
                        Text("Forgot Password?")
                    }
                    .padding()
                    .foregroundColor(.blue)
                    .frame(width: 200, height: 40)
                    .cornerRadius(5)
                    .padding(.horizontal)
                    
                    Spacer()
                    
                    Text("© Evently 2024")
                        .foregroundColor(.white)
                        .padding(.bottom)
                }
                .padding()
                .alert(isPresented: $showForgotPasswordAlert) {
                    Alert(title: Text(forgotPasswordResponseTitle), message: Text(forgotPasswordResponse), dismissButton: .default(Text("OK")))
                }
                .frame(width: geometry.size.width, height: geometry.size.height)
                .background(LinearGradient(gradient: Gradient(colors: [Color.white, Color.purple.opacity(0.5), Color.red]), startPoint: .top, endPoint: .bottom))
            }
        }
        
    }
    
    
    private func login() {
        guard let url = URL(string: "\(globalData.api)users/login") else {
            print("Invalid API URL")
            return
        }
        
        let loginData = "\(email):\(password)".data(using: .utf8)?.base64EncodedString() ?? ""
        
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue("Basic \(loginData)", forHTTPHeaderField: "Authorization")
        
        URLSession.shared.dataTask(with: request) { data, response, error in
            guard let httpResponse = response as? HTTPURLResponse else {
                print("Invalid response")
                return
            }
            
            if httpResponse.statusCode == 200, let data = data {
                do {
                    let decoder = JSONDecoder()
                    let response = try decoder.decode(LoginResponse.self, from: data)
                    saveUserData(email: email, password: password, userId: response.message, role: response.role)
                    isLoggedIn = true
                    print("Login successful")
                } catch {
                    print("Error decoding response: \(error)")
                }
            } else {
                forgotPasswordResponseTitle = "Error"
                forgotPasswordResponse = "Invalid Email or Password."
                showForgotPasswordAlert = true
            }
        }.resume()
    }

    private func saveUserData(email: String, password: String, userId: String, role: String) {
        let newUser = User(context: viewContext)
        newUser.email = email
        newUser.password = password
        newUser.user_id = userId
        newUser.role = role
        
        do {
            try viewContext.save()
            print("User data saved to Core Data")
        } catch {
            print("Error saving user data: \(error)")
        }
    }
    
    private func forgotPassword() {
        guard let url = URL(string: "\(globalData.api)users/forgot-password") else {
            print("Invalid API URL")
            return
        }
        
        let forgotPasswordData = ["email": email]
        
        guard let jsonData = try? JSONSerialization.data(withJSONObject: forgotPasswordData) else {
            print("Failed to encode forgot password data")
            return
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = jsonData
        
        URLSession.shared.dataTask(with: request) { data, response, error in
            guard let httpResponse = response as? HTTPURLResponse else {
                print("Invalid response")
                return
            }
            
            if httpResponse.statusCode == 200, let data = data {
                if let responseString = String(data: data, encoding: .utf8) {
                    forgotPasswordResponseTitle = "New Password sent Successfully, please check your email"
                    showForgotPasswordAlert = true
                }
            } else {
                if let data = data, let errorResponse = try? JSONDecoder().decode(ErrorResponse.self, from: data) {
                    forgotPasswordResponse = errorResponse.error
                } else {
                    forgotPasswordResponseTitle = "Error"
                    forgotPasswordResponse = "Invalid Email."
                }
                showForgotPasswordAlert = true
            }
        }.resume()
    }
}

struct SquareButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .foregroundColor(.white)
            .frame(width: 200, height: 40)
            .background(Color.black)
            .cornerRadius(5)
    }
}

struct LoginResponse: Codable {
    let message: String
    let role: String
}

struct ErrorResponse: Codable {
    let error: String
}

#if DEBUG
struct LoginView_Previews: PreviewProvider {
    static var previews: some View {
        LoginView()
    }
}
#endif
