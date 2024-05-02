import SwiftUI
import CoreData

struct ContentView: View {
    var body: some View {
        NavigationView {
            TabView {
                HomePage()
                    .tabItem {
                        Label("Home", systemImage: "house")
                            .background(Color.white)
                    }
                MyBookingsPage()
                    .tabItem {
                        Label("My Bookings", systemImage: "list.bullet")
                            .background(Color.white)
                    }
                AddPage()
                    .tabItem {
                        Label("Add", systemImage: "plus")
                            .background(Color.white)
                    }
                ProfilePage()
                    .tabItem {
                        Label("Profile", systemImage: "person.crop.circle")
                            .background(Color.white)
                    }
            }

        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
