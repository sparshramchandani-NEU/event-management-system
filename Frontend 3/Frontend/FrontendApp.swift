import SwiftUI
import CoreData
import FirebaseCore




@main
struct FrontendApp: App {
    let persistenceController = PersistenceController.shared
    @StateObject var globalData = GlobalData()

    var body: some Scene {
        WindowGroup {
            
            // Check if user data exists in Core Data
            let fetchRequest: NSFetchRequest<User> = User.fetchRequest()
            let users = try? persistenceController.container.viewContext.fetch(fetchRequest)
            
            if let existingUsers = users, !existingUsers.isEmpty {
                // User data exists, navigate to ContentView
                ContentView()
                    .environment(\.managedObjectContext, persistenceController.container.viewContext)
                    .environmentObject(globalData)
            } else {
                // No user data found, navigate to LoginView
                LoginView()
                    .environment(\.managedObjectContext, persistenceController.container.viewContext)
                    .environmentObject(globalData)
                    .onAppear {
                        globalData.checkAPIHealth()
                    }
            }
        }
    }
    init(){
        FirebaseApp.configure()
    }
}
