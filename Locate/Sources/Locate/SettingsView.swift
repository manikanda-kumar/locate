import SwiftUI
import LocateViewModel

struct SettingsView: View {
    @Bindable var model: SearchViewModel
    @State private var selectedTab: SettingsTab = .indexedFolders

    enum SettingsTab: String, CaseIterable, Identifiable {
        case indexedFolders = "Indexed Folders"
        case exclusions = "Exclusions"
        case indexing = "Indexing"

        var id: String { rawValue }

        var icon: String {
            switch self {
            case .indexedFolders:
                return "folder.fill"
            case .exclusions:
                return "eye.slash.fill"
            case .indexing:
                return "arrow.triangle.2.circlepath"
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
        }
        .frame(width: 600, height: 500)
        .padding()
    }
}

struct IndexedFoldersView: View {
    @Bindable var model: SearchViewModel
    @State private var selectedPaths: Set<String> = []

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Indexed Folders")
                .font(.title2)
                .fontWeight(.semibold)

            Text("Select folders to include in the search index.")
                .font(.subheadline)
                .foregroundStyle(.secondary)

            List(selection: $selectedPaths) {
                Text("~/Documents")
                    .tag("~/Documents")
                Text("~/Downloads")
                    .tag("~/Downloads")
            }
            .listStyle(.inset)
            .frame(maxHeight: .infinity)

            HStack {
                Button("Add Folder") {
                    addFolder()
                }
                .buttonStyle(.bordered)

                Button("Remove") {
                    // Remove selected folders
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
                            await model.rebuildIndex()
                        }
                    }
                    .buttonStyle(.borderedProminent)
                    .disabled(model.isIndexing)
                }
            }
        }
        .padding()
    }

    private func addFolder() {
        let panel = NSOpenPanel()
        panel.canChooseFiles = false
        panel.canChooseDirectories = true
        panel.allowsMultipleSelection = false
        panel.prompt = "Select Folder"

        if panel.runModal() == .OK {
            if let url = panel.url {
                // Add folder to index
                print("Selected folder: \(url.path)")
            }
        }
    }
}

struct ExclusionsView: View {
    @Bindable var model: SearchViewModel
    @State private var newPattern = ""
    @State private var exclusionPatterns: [String] = [
        "Library",
        ".git",
        "node_modules",
        ".Trash"
    ]
    @State private var selectedPatterns: Set<String> = []

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Exclusion Patterns")
                .font(.title2)
                .fontWeight(.semibold)

            Text("Folders and patterns to exclude from indexing.")
                .font(.subheadline)
                .foregroundStyle(.secondary)

            List(exclusionPatterns, id: \.self, selection: $selectedPatterns) { pattern in
                Text(pattern)
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
                    exclusionPatterns.removeAll { selectedPatterns.contains($0) }
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
        exclusionPatterns.append(newPattern)
        newPattern = ""
    }
}

struct IndexingScheduleView: View {
    @Bindable var model: SearchViewModel
    @State private var autoReindex = false
    @State private var reindexInterval: Double = 6.0 // hours

    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            Text("Indexing Schedule")
                .font(.title2)
                .fontWeight(.semibold)

            VStack(alignment: .leading, spacing: 12) {
                Toggle("Automatically reindex while app is running", isOn: $autoReindex)

                if autoReindex {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Reindex every:")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)

                        HStack {
                            Slider(value: $reindexInterval, in: 1...24, step: 1)
                                .frame(maxWidth: 300)

                            Text("\(Int(reindexInterval)) hours")
                                .font(.body)
                                .frame(width: 80, alignment: .leading)
                        }
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
