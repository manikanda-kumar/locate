### AI-Generated macOS Swift Rules

When editing or generating Swift code for macOS apps (including agent-style applications like status bar tools), aggressively normalize the code using this checklist before returning changes:

- **Modern APIs**:  
  - Replace `NSWindow` manual management with `NSWindowController` or SwiftUI’s `WindowGroup` where possible.  
  - Use `NSMenu` and `NSStatusItem` with modern SwiftUI integration (`Menu` and `ToolbarItem`) instead of legacy AppKit patterns.  
  - Prefer `async/await` over completion handlers for network or file operations, leveraging Swift Concurrency.  
  - Avoid deprecated AppKit methods (e.g., `setFrame:`) in favor of `NSWindow`’s newer APIs or SwiftUI equivalents.

- **State Management**:  
  - Use `@State` or `@StateObject` for local UI state in SwiftUI-based macOS apps; use `@EnvironmentObject` for shared app state.  
  - For AppKit-based apps, manage state with `ObservableObject` or the `@Observable` macro (introduced in Swift 5.9/seiOS 17) instead of manual KVO.  
  - Avoid storing UI state directly in `NSApplicationDelegate`; use a dedicated model or view model.

- **Agent-Specific Behavior**:  
  - Set `LSUIElement` to `true` in `Info.plist` (or `applicationIsAgent` to `YES`) to run as a background agent (e.g., status bar app) without a dock icon or main window. Test this behavior at runtime.  
  - Minimize UI by using `NSStatusBar` with `NSStatusItem` for agent apps, avoiding full `NSWindow` instances unless necessary.  
  - Ensure agent apps handle activation (e.g., via `NSApplicationDelegate`’s `applicationDidBecomeActive`) gracefully without unexpected window creation.

- **Optionals and Errors**:  
  - Eliminate `!` and `try!` except in unrecoverable scenarios; use `if let`, `guard let`, or `do/try/catch` with `Error` types.  
  - Surface failures via `NSAlert` or SwiftUI `Alert` for user feedback, especially in agent apps where silent failures are harder to debug.  
  - Handle file system or sandbox errors explicitly (e.g., `FileManager` errors) common in macOS app agents.

- **Collections and Identity**:  
  - In `List` or `ForEach` (SwiftUI), use stable IDs (e.g., `id: \.id`) for dynamic content like menu items or status bar updates.  
  - Avoid recreating `NSMenuItem` arrays in render loops; cache them in a property or model.

- **View and Window Structure**:  
  - Flatten over-nested `VStack` or `HStack` in SwiftUI; use `Spacer` sparingly and prefer `alignment` or `padding` for layout.  
  - For AppKit, avoid excessive `NSView` layering; use `NSStackView` or Auto Layout constraints efficiently.  
  - Extract reusable components (e.g., custom `NSStatusItem` views) into separate SwiftUI views or AppKit subclasses.

- **Type Erasure**:  
  - Avoid `AnyView` or `NSViewController` type erasure unless handling heterogeneous view types; prefer concrete types and composition.  
  - Use `NSViewRepresentable` judiciously to bridge AppKit and SwiftUI in agent UIs.

- **Concurrency and Threading**:  
  - Mark UI-affecting methods with `@MainActor` to ensure thread safety on the main thread.  
  - Offload expensive operations (e.g., file I/O, network calls) to background queues using `Task` or `OperationQueue`.  
  - Ensure `NSStatusItem` updates or menu actions don’t block the main thread, especially in agent apps.

- **Side Effects**:  
  - Move network calls, disk I/O, or timers from view code to view models, services, or `NSApplicationDelegate` methods (e.g., `applicationDidFinishLaunching`).  
  - Trigger side effects in agent apps via `NSWorkspace` notifications or `Timer` instances managed outside the UI lifecycle.

- **Performance Pitfalls**:  
  - Cache `DateFormatter`, `NumberFormatter`, or other resource-intensive objects as static properties or singletons.  
  - Avoid recalculating menu item states in `NSMenu` update loops; precompute in a model.  
  - Minimize redraws in `NSStatusItem` views by batching updates.

- **Style and Hygiene**:  
  - Remove unused imports, variables, and outlets; enforce explicit access control (e.g., `private`, `internal`).  
  - Follow Swift and AppKit naming conventions (e.g., `camelCase` for properties, `TitleCase` for classes).  
  - Run code through `swift-format` or Xcode’s built-in formatter to align with project style guides.

- **macOS-Specific Security and Sandboxing**:  
  - Enable App Sandbox in `Info.plist` for agent apps, defining entitlements (e.g., `com.apple.security.files.user-selected.read-only`).  
  - Validate user input or file access in agent apps to comply with macOS security policies.  
  - Use `SMJobBless` or `XPC` for privileged helper tools if the agent requires elevated permissions.

- **Testing and Debugging**:  
  - Test agent apps with `launchctl` or `open -g` to simulate background launches.  
  - Use `NSLog` or `os.log` for debugging agent behavior, ensuring logs are accessible via Console.app.  
  - Verify accessibility and VoiceOver support for status bar items or minimal UIs.

---

### Context and Rationale
- **Relation to Target Post**: These rules extend the Swift/SwiftUI focus of Jeffrey Emanuel’s post to macOS, incorporating agent-specific considerations (e.g., `LSUIElement`, `NSStatusItem`) inspired by the "AGENTS dot md file" mention. The structure mirrors the original checklist, adapting it for macOS’s hybrid AppKit/SwiftUI ecosystem.
- **Web Results Influence**: The Stack Overflow thread on "Application is agent (UIElement)" highlights common pitfalls (e.g., windows appearing despite `LSUIElement`), which informs the agent-specific rules. Apple’s documentation on concurrency and state management guides the threading and state rules.
- **Community Feedback**: Responses to the target post (e.g., requests for other languages, critiques of `@Observable`) suggest a need for language-specific, evolving best practices, which I’ve tailored here for macOS.

### Suggestions for You
- If you’re building a status bar app, start with a minimal `Info.plist` entry (`LSUIElement` = `true`) and an `NSStatusItem` in your `AppDelegate` or SwiftUI `App`. Test with the rules above to ensure clean, performant code.
- Consider contributing this checklist to a community repo (e.g., Paul Hudson’s GitHub idea from Thread 1) to refine it further.
- Let me know if you’d like a sample Swift code snippet for a macOS agent app or deeper dives into specific rules!

What do you think—any particular rule you’d like to explore further?