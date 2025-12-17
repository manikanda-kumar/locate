import Foundation
import Carbon
import AppKit

final class HotkeyManager: @unchecked Sendable {
    private var eventHandler: EventHandlerRef?
    private var hotKeyRef: EventHotKeyRef?
    private let hotKeyID = EventHotKeyID(signature: FourCharCode(fromString: "LSRC"), id: 1)
    private let onActivate: @Sendable @MainActor () -> Void

    init(onActivate: @escaping @Sendable @MainActor () -> Void) {
        self.onActivate = onActivate
    }

    func register() -> Bool {
        // Option + Space
        let keyCode: UInt32 = 49 // Space key
        let modifiers: UInt32 = UInt32(optionKey)

        var eventType = EventTypeSpec(eventClass: OSType(kEventClassKeyboard), eventKind: OSType(kEventHotKeyPressed))

        let handler: EventHandlerUPP = { (_, event, userData) -> OSStatus in
            guard let userData = userData else { return OSStatus(eventNotHandledErr) }
            let manager = Unmanaged<HotkeyManager>.fromOpaque(userData).takeUnretainedValue()
            let callback = manager.onActivate
            Task { @MainActor in
                callback()
            }
            return noErr
        }

        let status = InstallEventHandler(
            GetApplicationEventTarget(),
            handler,
            1,
            &eventType,
            Unmanaged.passUnretained(self).toOpaque(),
            &eventHandler
        )

        guard status == noErr else {
            print("Failed to install event handler: \(status)")
            return false
        }

        var hotKey: EventHotKeyRef?
        let registerStatus = RegisterEventHotKey(
            keyCode,
            modifiers,
            hotKeyID,
            GetApplicationEventTarget(),
            0,
            &hotKey
        )

        guard registerStatus == noErr, let hotKey = hotKey else {
            print("Failed to register hotkey: \(registerStatus)")
            return false
        }

        self.hotKeyRef = hotKey
        return true
    }

    func unregister() {
        if let hotKeyRef = hotKeyRef {
            UnregisterEventHotKey(hotKeyRef)
            self.hotKeyRef = nil
        }
        if let eventHandler = eventHandler {
            RemoveEventHandler(eventHandler)
            self.eventHandler = nil
        }
    }

    deinit {
        unregister()
    }
}

private extension FourCharCode {
    init(fromString string: String) {
        var code: FourCharCode = 0
        for char in string.utf8.prefix(4) {
            code = (code << 8) | FourCharCode(char)
        }
        self = code
    }
}
