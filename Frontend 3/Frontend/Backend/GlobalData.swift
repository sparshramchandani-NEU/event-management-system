import Foundation
import SwiftUI

class GlobalData: ObservableObject {
    @Published var api: String = "http://209.38.148.70:3000/" // Make sure to include the protocol (http://)
    
    func checkAPIHealth() {
        guard let url = URL(string: "\(api)healthz".addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? "") else {
            print("Invalid API URL")
            return
        }
        
        let task = URLSession.shared.dataTask(with: url) { (data, response, error) in
            guard let httpResponse = response as? HTTPURLResponse else {
                print("Invalid response")
                return
            }
            
            if httpResponse.statusCode == 200 {
                print("Server connected successfully")
            } else {
                print("Server connection failed with status code: \(httpResponse.statusCode)")
            }
        }
        
        task.resume()
    }
}
