import SwiftUI
import LocateViewModel

struct ContentView: View {
    @State private var viewModel = SearchViewModel()

    var body: some View {
        SearchView(model: viewModel)
            .frame(minWidth: 640, minHeight: 480)
    }
}

#Preview {
    ContentView()
}
