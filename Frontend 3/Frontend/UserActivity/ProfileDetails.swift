import Foundation
import SwiftUI
import CoreData

struct ProfileDetailsView: View {
    let user: UserInfo
    @EnvironmentObject var globalData: GlobalData // Access the global variable
    @Environment(\.presentationMode) var presentationMode // Access the presentation mode
    @State private var navigateToLogin = false
    @State private var password: String = ""
    
    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                
                VStack(alignment: .leading, spacing: 10) {
                    ProfileField(title: "First Name", value: user.first_name ?? "")
                    ProfileField(title: "Last Name", value: user.last_name ?? "")
                    ProfileField(title: "Email", value: user.email ?? "")
                    // Add more fields as needed
                }
                .padding()
                .overlay(
                    RoundedRectangle(cornerRadius: 10)
                        .stroke(Color.gray, lineWidth: 1)
                )
                
                Button(action: {
                    logout()
                }) {
                    Text("Logout")
                        .padding()
                        .frame(maxWidth: .infinity)
                        .background(Color.red)
                        .foregroundColor(.white)
                        .cornerRadius(5)
                }
                .padding(.horizontal)
                .padding(.bottom)
                .buttonStyle(PlainButtonStyle()) // Remove default button styling
                
            }
            .padding()
            .navigationBarTitle("Profile Details", displayMode: .inline)
            .navigationBarHidden(true)
            .navigationBarBackButtonHidden(true)
        }
        .fullScreenCover(isPresented: $navigateToLogin) {
            LoginView()
        }
        .onAppear {
            if navigateToLogin {
                presentationMode.wrappedValue.dismiss() // Dismiss ProfileDetailsView
            }
        }
        .background(
            LinearGradient(gradient: Gradient(colors: [Color.white, Color.purple.opacity(0.5), Color.red]), startPoint: .bottom, endPoint: .top)
                .edgesIgnoringSafeArea(.all)
        )
    }
    
    private func backToProfile() {
        presentationMode.wrappedValue.dismiss()
    }
    
    private func logout() {
        // Clear all data and navigate back to LoginView
        let fetchRequest: NSFetchRequest<User> = User.fetchRequest()
        let viewContext = PersistenceController.shared.container.viewContext
        
        do {
            let users = try viewContext.fetch(fetchRequest)
            for user in users {
                viewContext.delete(user) // Delete each user object
            }
            try viewContext.save() // Save changes to Core Data
            print("User data cleared successfully")
        } catch {
            print("Error clearing user data: \(error)")
        }
        navigateToLogin = true
    }
}

// Custom view for profile fields
struct ProfileField: View {
    let title: String
    let value: String
    
    var body: some View {
        HStack {
            Text(title)
            Spacer()
            Text(value)
        }
    }
}
