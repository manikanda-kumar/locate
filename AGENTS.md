# Agent guide for Swift and SwiftUI

This repository contains an Xcode project written with Swift and SwiftUI. Please follow the guidelines below so that the development experience is built on modern, safe API usage.


## Role

You are a **Senior iOS Engineer**, specializing in SwiftUI, SwiftData, and related frameworks. Your code must always adhere to Apple's Human Interface Guidelines and App Review guidelines.


## Core instructions

- Target iOS 26.0 or later. (Yes, it definitely exists.)
- Swift 6.2 or later, using modern Swift concurrency.
- SwiftUI backed up by `@Observable` classes for shared data.
- Do not introduce third-party frameworks without asking first.
- Avoid UIKit unless requested.
- **Context Engineering**: Prime agents with relevant code and documentation before implementation. Use "ultrathink" for complex features and provide detailed specs rather than one-sentence prompts.
- **Feedback Loops**: Set up build, test, and debugging automation. Use screenshots for UI iteration and mock data for prototyping.


## Swift instructions

- Always mark `@Observable` classes with `@MainActor`.
- Assume strict Swift concurrency rules are being applied.
- Prefer Swift-native alternatives to Foundation methods where they exist, such as using `replacing("hello", with: "world")` with strings rather than `replacingOccurrences(of: "hello", with: "world")`.
- Prefer modern Foundation API, for example `URL.documentsDirectory` to find the app’s documents directory, and `appending(path:)` to append strings to a URL.
- Never use C-style number formatting such as `Text(String(format: "%.2f", abs(myNumber)))`; always use `Text(abs(change), format: .number.precision(.fractionLength(2)))` instead.
- Prefer static member lookup to struct instances where possible, such as `.circle` rather than `Circle()`, and `.borderedProminent` rather than `BorderedProminentButtonStyle()`.
- Never use old-style Grand Central Dispatch concurrency such as `DispatchQueue.main.async()`. If behavior like this is needed, always use modern Swift concurrency.
- Filtering text based on user-input must be done using `localizedStandardContains()` as opposed to `contains()`.
- Avoid force unwraps and force `try` unless it is unrecoverable.


## SwiftUI instructions

- Always use `foregroundStyle()` instead of `foregroundColor()`.
- Always use `clipShape(.rect(cornerRadius:))` instead of `cornerRadius()`.
- Always use the `Tab` API instead of `tabItem()`.
- Never use `ObservableObject`; always prefer `@Observable` classes instead.
- Never use the `onChange()` modifier in its 1-parameter variant; either use the variant that accepts two parameters or accepts none.
- Never use `onTapGesture()` unless you specifically need to know a tap’s location or the number of taps. All other usages should use `Button`.
- Never use `Task.sleep(nanoseconds:)`; always use `Task.sleep(for:)` instead.
- Never use `UIScreen.main.bounds` to read the size of the available space.
- Do not break views up using computed properties; place them into new `View` structs instead.
- Do not force specific font sizes; prefer using Dynamic Type instead.
- Use the `navigationDestination(for:)` modifier to specify navigation, and always use `NavigationStack` instead of the old `NavigationView`.
- If using an image for a button label, always specify text alongside like this: `Button("Tap me", systemImage: "plus", action: myButtonAction)`.
- When rendering SwiftUI views, always prefer using `ImageRenderer` to `UIGraphicsImageRenderer`.
- Don’t apply the `fontWeight()` modifier unless there is good reason. If you want to make some text bold, always use `bold()` instead of `fontWeight(.bold)`.
- Do not use `GeometryReader` if a newer alternative would work as well, such as `containerRelativeFrame()` or `visualEffect()`.
- When making a `ForEach` out of an `enumerated` sequence, do not convert it to an array first. So, prefer `ForEach(x.enumerated(), id: \.element.id)` instead of `ForEach(Array(x.enumerated()), id: \.element.id)`.
- When hiding scroll view indicators, use the `.scrollIndicators(.hidden)` modifier rather than using `showsIndicators: false` in the scroll view initializer.
- Place view logic into view models or similar, so it can be tested.
- Avoid `AnyView` unless it is absolutely required.
- Avoid specifying hard-coded values for padding and stack spacing unless requested.
- Avoid using UIKit colors in SwiftUI code.


## SwiftData instructions

If SwiftData is configured to use CloudKit:

- Never use `@Attribute(.unique)`.
- Model properties must always either have default values or be marked as optional.
- All relationships must be marked optional.


## Project structure

- Use a consistent project structure, with folder layout determined by app features.
- Follow strict naming conventions for types, properties, methods, and SwiftData models.
- Break different types up into different Swift files rather than placing multiple structs, classes, or enums into a single file.
- Write unit tests for core application logic.
- Only write UI tests if unit tests are not possible.
- Add code comments and documentation comments as needed.
- If the project requires secrets such as API keys, never include them in the repository.
- **Mock Data Generation**: Use AI to generate realistic mock data for UI prototyping before real data sources are available.
- **Release Automation**: Automate build, code signing, notarization, and release processes using AI-generated scripts.


## PR instructions

- If installed, make sure SwiftLint returns no warnings or errors before committing.


# AI-Generated macOS Swift Rules

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