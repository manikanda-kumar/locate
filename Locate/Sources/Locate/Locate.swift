import SwiftUI
import LocateCore
import AppKit

final class AppDelegate: NSObject, NSApplicationDelegate {
    func applicationDidFinishLaunching(_ notification: Notification) {
        NSApp.setActivationPolicy(.regular)
        NSApp.activate(ignoringOtherApps: true)

        // Ensure window is visible and in front
        if let window = NSApp.windows.first {
            window.makeKeyAndOrderFront(nil)
            window.orderFrontRegardless()
        }
    }
}

@main
struct LocateApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate

    var body: some Scene {
        WindowGroup("Locate") {
            ContentView()
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
    }
}

extension Notification.Name {
    static let updateIndexRequested = Notification.Name("updateIndexRequested")
    static let focusSearchRequested = Notification.Name("focusSearchRequested")
}