import SwiftUI
import LocateCore

struct ContentView: View {
    var body: some View {
        VStack {
            Text("Hello, World!")
            Text(CoreVersion.description())
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .frame(minWidth: 400, minHeight: 300)
    }
}

#Preview {
    ContentView()
}