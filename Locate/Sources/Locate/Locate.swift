import SwiftUI
import LocateCore
import LocateViewModel
import AppKit
import Observation

@Observable
@MainActor
final class SharedViewModel {
    let searchModel: SearchViewModel

    init() {
        self.searchModel = SearchViewModel()
    }
}

final class AppDelegate: NSObject, NSApplicationDelegate {
    private var hotkeyManager: HotkeyManager?

    func applicationDidFinishLaunching(_ notification: Notification) {
        NSApp.setActivationPolicy(.regular)
        NSApp.activate(ignoringOtherApps: true)

        // Ensure window is visible and in front
        if let window = NSApp.windows.first {
            window.makeKeyAndOrderFront(nil)
            window.orderFrontRegardless()
        }

        // Register global hotkey (Option + Space)
        Task { @MainActor in
            self.hotkeyManager = HotkeyManager {
                self.activateMainWindow()
            }
            let registered = self.hotkeyManager?.register() ?? false
            if registered {
                print("Global hotkey registered successfully (Option + Space)")
            } else {
                print("Failed to register global hotkey")
            }
        }

        // Listen for window activation requests
        NotificationCenter.default.addObserver(
            forName: .activateMainWindow,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            Task { @MainActor in
                self?.activateMainWindow()
            }
        }
    }

    @MainActor
    private func activateMainWindow() {
        // Activate the app
        NSApp.activate(ignoringOtherApps: true)

        // Find and focus the main window
        for window in NSApp.windows {
            if window.identifier?.rawValue == "Locate-main" || window.title == "Locate" {
                window.makeKeyAndOrderFront(nil)
                window.orderFrontRegardless()

                // Post notification to focus search field
                NotificationCenter.default.post(name: .focusSearchRequested, object: nil)
                return
            }
        }

        // If no main window found, try to open one
        if let window = NSApp.windows.first {
            window.makeKeyAndOrderFront(nil)
            window.orderFrontRegardless()
            NotificationCenter.default.post(name: .focusSearchRequested, object: nil)
        }
    }
}

@main
struct LocateApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    @State private var sharedViewModel = SharedViewModel()

    var body: some Scene {
        WindowGroup("Locate", id: "main") {
            ContentView()
                .environment(sharedViewModel)
        }
        .commands {
            CommandGroup(after: .newItem) {
                Button("Update Index") {
                    NotificationCenter.default.post(name: .updateIndexRequested, object: nil)
                }
                .keyboardShortcut("r", modifiers: .command)
            }
            CommandGroup(replacing: .textEditing) {
                Button("Find") {
                    NotificationCenter.default.post(name: .focusSearchRequested, object: nil)
                }
                .keyboardShortcut("f", modifiers: .command)
            }
        }

        MenuBarExtra("Locate", systemImage: "magnifyingglass") {
            MenuBarSearchView(model: sharedViewModel.searchModel)
                .environment(sharedViewModel)
        }
        .menuBarExtraStyle(.window)

        Settings {
            SettingsView(model: sharedViewModel.searchModel)
                .environment(sharedViewModel)
        }
    }
}

extension Notification.Name {
    static let updateIndexRequested = Notification.Name("updateIndexRequested")
    static let focusSearchRequested = Notification.Name("focusSearchRequested")
    static let activateMainWindow = Notification.Name("activateMainWindow")
}