import SwiftUI
import LocateViewModel

struct SettingsView: View {
    @Bindable var model: SearchViewModel
    @State private var selectedTab: SettingsTab = .indexedFolders

    enum SettingsTab: String, CaseIterable, Identifiable {
        case indexedFolders = "Indexed Folders"
        case exclusions = "Exclusions"
        case indexing = "Indexing"
        case permissions = "Privacy"

        var id: String { rawValue }

        var icon: String {
            switch self {
            case .indexedFolders:
                return "folder.fill"
            case .exclusions:
                return "eye.slash.fill"
            case .indexing:
                return "arrow.triangle.2.circlepath"
            case .permissions:
                return "lock.shield.fill"
            }
        }
    }

    var body: some View {
        TabView(selection: $selectedTab) {
            IndexedFoldersView(model: model)
                .tabItem {
                    Label(SettingsTab.indexedFolders.rawValue, systemImage: SettingsTab.indexedFolders.icon)
                }
                .tag(SettingsTab.indexedFolders)

            ExclusionsView(model: model)
                .tabItem {
                    Label(SettingsTab.exclusions.rawValue, systemImage: SettingsTab.exclusions.icon)
                }
                .tag(SettingsTab.exclusions)

            IndexingScheduleView(model: model)
                .tabItem {
                    Label(SettingsTab.indexing.rawValue, systemImage: SettingsTab.indexing.icon)
                }
                .tag(SettingsTab.indexing)

            FullDiskAccessGuideView()
                .tabItem {
                    Label(SettingsTab.permissions.rawValue, systemImage: SettingsTab.permissions.icon)
                }
                .tag(SettingsTab.permissions)
        }
        .frame(width: 600, height: 500)
        .padding()
    }
}

struct IndexedFoldersView: View {
    @Bindable var model: SearchViewModel
    @State private var settings = AppSettings.shared
    @State private var selectedPaths: Set<String> = []
    @State private var showRemoveConfirmation = false

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Indexed Folders")
                .font(.title2)
                .fontWeight(.semibold)

            Text("Select folders to include in the search index.")
                .font(.subheadline)
                .foregroundStyle(.secondary)

            if settings.indexedFolders.isEmpty {
                VStack {
                    Spacer()
                    Text("No folders indexed yet")
                        .font(.title3)
                        .foregroundStyle(.secondary)
                    Text("Click 'Add Folder' to get started")
                        .font(.subheadline)
                        .foregroundStyle(.tertiary)
                    Spacer()
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

            HStack {
                Button("Add Folder") {
                    addFolder()
                }
                .buttonStyle(.bordered)

                Button("Remove") {
                    showRemoveConfirmation = true
                }
                .buttonStyle(.bordered)
                .disabled(selectedPaths.isEmpty)

                Spacer()

                if model.isIndexing {
                    ProgressView()
                        .controlSize(.small)
                    Text(model.indexingProgress ?? "Indexing...")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                } else {
                    Button("Rebuild Index Now") {
                        Task {
                            await model.rebuildIndexForAllFolders()
                        }
                    }
                    .buttonStyle(.borderedProminent)
                    .disabled(model.isIndexing || settings.indexedFolders.isEmpty)
                }
            }
        }
        .padding()
        .confirmationDialog(
            "Remove \(selectedPaths.count) folder\(selectedPaths.count == 1 ? "" : "s")?",
            isPresented: $showRemoveConfirmation,
            titleVisibility: .visible
        ) {
            Button("Remove", role: .destructive) {
                settings.removeIndexedFolders(selectedPaths)
                selectedPaths.removeAll()
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("The folder\(selectedPaths.count == 1 ? "" : "s") will be removed from the index. Files will not be deleted.")
        }
    }

    private func addFolder() {
        let panel = NSOpenPanel()
        panel.canChooseFiles = false
        panel.canChooseDirectories = true
        panel.allowsMultipleSelection = false
        panel.prompt = "Select Folder"

        if panel.runModal() == .OK {
            if let url = panel.url {
                settings.addIndexedFolder(url.path(percentEncoded: false))
            }
        }
    }
}

struct ExclusionsView: View {
    @Bindable var model: SearchViewModel
    @State private var settings = AppSettings.shared
    @State private var newPattern = ""
    @State private var selectedPatterns: Set<String> = []

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Exclusion Patterns")
                .font(.title2)
                .fontWeight(.semibold)

            Text("Folders and patterns to exclude from indexing.")
                .font(.subheadline)
                .foregroundStyle(.secondary)

            List(settings.exclusionPatterns, id: \.self, selection: $selectedPatterns) { pattern in
                HStack {
                    Image(systemName: "eye.slash.fill")
                        .foregroundStyle(.orange)
                        .font(.caption)
                    Text(pattern)
                    Spacer()
                }
                .tag(pattern)
            }
            .listStyle(.inset)
            .frame(maxHeight: .infinity)

            HStack {
                TextField("New pattern", text: $newPattern)
                    .textFieldStyle(.roundedBorder)
                    .onSubmit {
                        addPattern()
                    }

                Button("Add") {
                    addPattern()
                }
                .buttonStyle(.bordered)
                .disabled(newPattern.isEmpty)

                Button("Remove") {
                    settings.removeExclusionPatterns(selectedPatterns)
                    selectedPatterns.removeAll()
                }
                .buttonStyle(.bordered)
                .disabled(selectedPatterns.isEmpty)

                Spacer()
            }

            Text("Changes will apply on next index rebuild.")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .padding()
    }

    private func addPattern() {
        guard !newPattern.isEmpty else { return }
        settings.addExclusionPattern(newPattern)
        newPattern = ""
    }
}

struct IndexingScheduleView: View {
    @Bindable var model: SearchViewModel
    @State private var settings = AppSettings.shared

    private let intervalMarks: [Double] = [1, 6, 12, 18, 24]

    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            Text("Indexing Schedule")
                .font(.title2)
                .fontWeight(.semibold)

            VStack(alignment: .leading, spacing: 8) {
                Text("Hidden Files")
                    .font(.headline)

                Toggle("Include hidden files and folders in index", isOn: $settings.indexHiddenFiles)

                Text("Files and folders starting with '.' will be indexed. Requires rebuild to take effect.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Divider()

            VStack(alignment: .leading, spacing: 12) {
                Toggle("Automatically reindex while app is running", isOn: $settings.autoReindex)
                    .onChange(of: settings.autoReindex) { _, _ in
                        model.startAutoReindexIfNeeded()
                    }

                if settings.autoReindex {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Reindex every:")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)

                        VStack(spacing: 4) {
                            Slider(value: $settings.reindexIntervalHours, in: 1...24, step: 1)
                                .frame(maxWidth: 300)
                                .onChange(of: settings.reindexIntervalHours) { _, _ in
                                    model.startAutoReindexIfNeeded()
                                }

                            HStack {
                                ForEach(intervalMarks, id: \.self) { mark in
                                    Text("\(Int(mark))h")
                                        .font(.caption2)
                                        .foregroundStyle(.tertiary)
                                    if mark != intervalMarks.last {
                                        Spacer()
                                    }
                                }
                            }
                            .frame(maxWidth: 300)
                        }

                        Text("\(Int(settings.reindexIntervalHours)) hour\(settings.reindexIntervalHours == 1 ? "" : "s")")
                            .font(.body)
                            .fontWeight(.medium)
                    }
                    .padding(.leading, 20)
                }
            }

            Divider()

            VStack(alignment: .leading, spacing: 8) {
                Text("Index Status")
                    .font(.headline)

                Text(model.statusDescription)
                    .font(.body)
                    .foregroundStyle(.secondary)

                if let progress = model.indexingProgress {
                    HStack {
                        ProgressView()
                            .controlSize(.small)
                        Text(progress)
                            .font(.body)
                    }
                }
            }

            Spacer()
        }
        .padding()
    }
}
