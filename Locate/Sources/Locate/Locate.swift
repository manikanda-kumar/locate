import SwiftUI

@main
struct LocateApp: App {
    var body: some Scene {
        WindowGroup("Locate") {
            ContentView()
        }
    }
}

struct ContentView: View {
    var body: some View {
        Text("Hello, World!")
            .frame(minWidth: 400, minHeight: 300)
    }
}

#Preview {
    ContentView()
}
