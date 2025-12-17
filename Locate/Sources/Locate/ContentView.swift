import SwiftUI
import LocateViewModel

struct ContentView: View {
    @Environment(SharedViewModel.self) private var sharedViewModel
    @State private var settings = AppSettings.shared

    var body: some View {
        Group {
            if settings.hasCompletedOnboarding {
                SearchView(model: sharedViewModel.searchModel)
                    .frame(minWidth: 640, minHeight: 480)
            } else {
                OnboardingView(model: sharedViewModel.searchModel)
                    .frame(width: 600, height: 500)
            }
        }
    }
}

#Preview {
    ContentView()
}
