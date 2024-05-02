import Foundation
import CoreData

class CoreDataManager {
    static let shared = CoreDataManager() // Singleton instance
    
    private init() {} // Private initializer to prevent external initialization
    
    lazy var persistentContainer: NSPersistentContainer = {
        let container = NSPersistentContainer(name: "Frontend")
        container.loadPersistentStores(completionHandler: { (storeDescription, error) in
            if let error = error as NSError? {
                fatalError("Unresolved error \(error), \(error.userInfo)")
            }
        })
        return container
    }()
    
    func fetchFirstUserCredentials(completion: @escaping (String?, String?, String?) -> Void) {
        let fetchRequest: NSFetchRequest<User> = User.fetchRequest()
        fetchRequest.fetchLimit = 1 // Fetch only the first user
        
        do {
            let users = try persistentContainer.viewContext.fetch(fetchRequest)
            if let user = users.first {
                let email = user.email
                let password = user.password
                let userId = user.user_id
                completion(email, password, userId)
            } else {
                completion(nil, nil, nil)
            }
        } catch {
            print("Error fetching user: \(error)")
            completion(nil, nil, nil)
        }
    }
}
