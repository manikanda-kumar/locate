import SwiftUI
import LocateViewModel

struct ContentView: View {
    @Environment(SharedViewModel.self) private var sharedViewModel

    var body: some View {
        SearchView(model: sharedViewModel.searchModel)
            .frame(minWidth: 640, minHeight: 480)
    }
}

#Preview {
    ContentView()
}
