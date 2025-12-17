import SwiftUI
import LocateViewModel

struct OnboardingView: View {
    @Bindable var model: SearchViewModel
    @State private var settings = AppSettings.shared
    @State private var currentStep: OnboardingStep = .welcome
    @State private var hasAddedFolders = false

    enum OnboardingStep {
        case welcome
        case selectFolders
        case indexing
        case complete
    }

    var body: some View {
        VStack(spacing: 0) {
            switch currentStep {
            case .welcome:
                WelcomeStep(onContinue: {
                    currentStep = .selectFolders
                })
            case .selectFolders:
                SelectFoldersStep(
                    settings: settings,
                    hasAddedFolders: $hasAddedFolders,
                    onContinue: {
                        currentStep = .indexing
                        Task {
                            await model.rebuildIndexForAllFolders()
                            currentStep = .complete
                        }
                    },
                    onSkip: {
                        settings.hasCompletedOnboarding = true
                    }
                )
            case .indexing:
                IndexingStep(model: model)
            case .complete:
                CompleteStep(onFinish: {
                    settings.hasCompletedOnboarding = true
                })
            }
        }
        .frame(width: 600, height: 500)
    }
}

struct WelcomeStep: View {
    let onContinue: () -> Void

    var body: some View {
        VStack(spacing: 24) {
            Spacer()

            Image(systemName: "magnifyingglass.circle.fill")
                .font(.system(size: 80))
                .foregroundStyle(.blue)

            Text("Welcome to Locate")
                .font(.system(size: 36, weight: .bold))

            Text("Find files on your Mac instantly")
                .font(.title3)
                .foregroundStyle(.secondary)

            VStack(alignment: .leading, spacing: 16) {
                FeatureRow(icon: "bolt.fill", title: "Lightning Fast", description: "Full-text search powered by SQLite FTS5")
                FeatureRow(icon: "slider.horizontal.3", title: "Advanced Filters", description: "Filter by type, size, date, and use regex")
                FeatureRow(icon: "moon.fill", title: "Always Available", description: "Global hotkey (⌥Space) to search anytime")
            }
            .padding(.vertical, 24)

            Button("Get Started") {
                onContinue()
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.large)

            Spacer()
        }
        .padding(40)
    }
}

struct FeatureRow: View {
    let icon: String
    let title: String
    let description: String

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundStyle(.blue)
                .frame(width: 30)

            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.headline)
                Text(description)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
        }
    }
}

struct SelectFoldersStep: View {
    let settings: AppSettings
    @Binding var hasAddedFolders: Bool
    let onContinue: () -> Void
    let onSkip: () -> Void
    @State private var selectedPaths: Set<String> = []

    var body: some View {
        VStack(spacing: 24) {
            VStack(spacing: 12) {
                Image(systemName: "folder.fill.badge.plus")
                    .font(.system(size: 60))
                    .foregroundStyle(.blue)

                Text("Select Folders to Index")
                    .font(.title)
                    .fontWeight(.bold)

                Text("Choose which folders you'd like to search")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
            .padding(.top, 40)

            if settings.indexedFolders.isEmpty {
                VStack(spacing: 16) {
                    Text("No folders selected yet")
                        .font(.title3)
                        .foregroundStyle(.secondary)
                        .padding(.top, 20)

                    Text("Click 'Add Folder' to get started. We recommend starting with your Documents or Downloads folder.")
                        .font(.subheadline)
                        .foregroundStyle(.tertiary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 40)
                }
                .frame(maxHeight: .infinity)
            } else {
                List(settings.indexedFolders, id: \.self, selection: $selectedPaths) { path in
                    HStack {
                        Image(systemName: "folder.fill")
                            .foregroundStyle(.blue)
                        Text(path.replacingOccurrences(of: NSHomeDirectory(), with: "~"))
                        Spacer()
                    }
                    .tag(path)
                }
                .listStyle(.inset)
                .frame(maxHeight: .infinity)
            }

            HStack(spacing: 12) {
                Button("Add Folder") {
                    addFolder()
                }
                .buttonStyle(.bordered)

                if !settings.indexedFolders.isEmpty {
                    Button("Remove") {
                        settings.removeIndexedFolders(selectedPaths)
                        selectedPaths.removeAll()
                    }
                    .buttonStyle(.bordered)
                    .disabled(selectedPaths.isEmpty)
                }

                Spacer()

                Button("Skip for Now") {
                    onSkip()
                }
                .buttonStyle(.bordered)

                Button("Build Index") {
                    onContinue()
                }
                .buttonStyle(.borderedProminent)
                .disabled(settings.indexedFolders.isEmpty)
            }
            .padding(.bottom, 24)
        }
        .padding(.horizontal, 40)
    }

    private func addFolder() {
        let panel = NSOpenPanel()
        panel.canChooseFiles = false
        panel.canChooseDirectories = true
        panel.allowsMultipleSelection = true
        panel.prompt = "Select Folders"
        panel.message = "Choose folders to include in your search index"

        if panel.runModal() == .OK {
            for url in panel.urls {
                settings.addIndexedFolder(url.path(percentEncoded: false))
                hasAddedFolders = true
            }
        }
    }
}

struct IndexingStep: View {
    @Bindable var model: SearchViewModel

    var body: some View {
        VStack(spacing: 32) {
            Spacer()

            ProgressView()
                .controlSize(.extraLarge)

            VStack(spacing: 12) {
                Text("Building Index")
                    .font(.title)
                    .fontWeight(.bold)

                if let progress = model.indexingProgress {
                    Text(progress)
                        .font(.body)
                        .foregroundStyle(.secondary)
                } else {
                    Text("This may take a few minutes…")
                        .font(.body)
                        .foregroundStyle(.secondary)
                }
            }

            Spacer()
        }
        .padding(40)
    }
}

struct CompleteStep: View {
    let onFinish: () -> Void

    var body: some View {
        VStack(spacing: 24) {
            Spacer()

            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 80))
                .foregroundStyle(.green)

            Text("You're All Set!")
                .font(.system(size: 36, weight: .bold))

            Text("Your files have been indexed and are ready to search")
                .font(.title3)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)

            VStack(alignment: .leading, spacing: 16) {
                TipRow(icon: "command", title: "Press ⌥Space anytime to search")
                TipRow(icon: "gearshape.fill", title: "Customize settings in Preferences")
                TipRow(icon: "arrow.triangle.2.circlepath", title: "Index rebuilds automatically")
            }
            .padding(.vertical, 24)

            Button("Start Searching") {
                onFinish()
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.large)

            Spacer()
        }
        .padding(40)
    }
}

struct TipRow: View {
    let icon: String
    let title: String

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundStyle(.blue)
                .frame(width: 30)

            Text(title)
                .font(.body)
        }
    }
}
