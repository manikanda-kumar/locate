import SwiftUI
import Observation
import LocateViewModel

struct SearchView: View {
    @Bindable var model: SearchViewModel
    @FocusState private var isSearchFocused: Bool

    var body: some View {
        VStack(spacing: 0) {
            FullDiskAccessBanner()
            searchBar
            filterRow
            Divider()
            ResultsView(results: model.results, selection: $model.selection, model: model)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            Divider()
            statusBar
        }
        .padding()
        .task {
            await model.load()
        }
        .onAppear {
            isSearchFocused = true
        }
        .onReceive(NotificationCenter.default.publisher(for: .focusSearchRequested)) { _ in
            isSearchFocused = true
        }
        .onReceive(NotificationCenter.default.publisher(for: .updateIndexRequested)) { _ in
            Task {
                await model.rebuildIndex()
            }
        }
        .onKeyPress(.escape) {
            NSApp.keyWindow?.close()
            return .handled
        }
    }

    private var searchBar: some View {
        HStack(spacing: 8) {
            ZStack {
                RoundedRectangle(cornerRadius: 10, style: .continuous)
                    .fill(.thinMaterial)
                    .shadow(color: .black.opacity(0.04), radius: 4)

                HStack(spacing: 8) {
                    Image(systemName: "magnifyingglass")
                        .foregroundStyle(.secondary)
                    TextField("Search files and folders", text: $model.query, prompt: Text("Search files and folders"))
                        .textFieldStyle(.plain)
                        .disableAutocorrection(true)
                        .focused($isSearchFocused)
                        .accessibilityIdentifier("SearchField")
                        .onSubmit {
                            model.scheduleSearch(immediate: true)
                        }
                    if model.isSearching {
                        ProgressView()
                            .controlSize(.small)
                    }
                    if !model.query.isEmpty {
                        Button("Clear", systemImage: "xmark.circle.fill") {
                            model.clearQuery()
                        }
                        .buttonStyle(.borderless)
                        .foregroundStyle(.secondary)
                    }
                }
                .padding(.vertical, 10)
                .padding(.horizontal, 12)
            }
            .frame(height: 44)

            Button("Search") {
                model.scheduleSearch(immediate: true)
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.large)
            .disabled(model.query.isEmpty)

            Button(model.isIndexing ? "Indexing…" : "Update Index") {
                Task {
                    await model.rebuildIndex()
                }
            }
            .buttonStyle(.bordered)
            .controlSize(.large)
            .disabled(model.isIndexing)
            .keyboardShortcut("r", modifiers: .command)
        }
    }

    private var filterRow: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 12) {
                Picker("Type", selection: $model.fileType) {
                    ForEach(SearchViewModel.FileTypeFilter.allCases) { filter in
                        Text(filter.title).tag(filter)
                    }
                }
                .pickerStyle(.menu)
                .accessibilityIdentifier("TypeFilter")

                Picker("Size", selection: $model.sizePreset) {
                    ForEach(SearchViewModel.SizePreset.allCases) { preset in
                        Text(preset.title).tag(preset)
                    }
                }
                .pickerStyle(.menu)
                .accessibilityIdentifier("SizeFilter")

                Picker("Modified", selection: $model.datePreset) {
                    ForEach(SearchViewModel.DatePreset.allCases) { preset in
                        Text(preset.title).tag(preset)
                    }
                }
                .pickerStyle(.menu)
                .accessibilityIdentifier("DateFilter")

                Divider()
                    .frame(height: 16)

                Toggle("Regex", isOn: $model.useRegex)
                    .toggleStyle(.switch)
                    .controlSize(.small)
                    .accessibilityIdentifier("RegexToggle")
                    .onChange(of: model.useRegex) { _, _ in
                        model.validateRegex()
                    }
                    .onChange(of: model.query) { _, _ in
                        if model.useRegex {
                            model.validateRegex()
                        }
                    }

                Toggle("Match Case", isOn: $model.caseSensitive)
                    .toggleStyle(.switch)
                    .controlSize(.small)
                    .accessibilityIdentifier("CaseSensitiveToggle")

                Divider()
                    .frame(height: 16)

                HStack(spacing: 4) {
                    Text("Ext:")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    TextField(".swift,.md", text: $model.customExtensions)
                        .textFieldStyle(.roundedBorder)
                        .frame(width: 120)
                        .font(.caption)
                        .accessibilityIdentifier("ExtensionFilter")
                        .onSubmit {
                            model.scheduleSearch(immediate: true)
                        }
                }

                Spacer()
            }

            HStack(spacing: 8) {
                Text("Scope:")
                    .font(.caption)
                    .foregroundStyle(.secondary)

                if model.folderScope.isEmpty {
                    Text("All indexed folders")
                        .font(.caption)
                        .foregroundStyle(.tertiary)
                } else {
                    Text(model.folderScopeDisplayName)
                        .font(.caption)
                        .lineLimit(1)
                        .truncationMode(.middle)
                        .frame(maxWidth: 200)

                    Button {
                        model.clearFolderScope()
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundStyle(.secondary)
                    }
                    .buttonStyle(.borderless)
                    .controlSize(.small)
                }

                Button("Browse...") {
                    selectFolderScope()
                }
                .buttonStyle(.bordered)
                .controlSize(.small)
                .accessibilityIdentifier("FolderScopeBrowse")

                Spacer()
            }

            if let error = model.regexValidationError {
                HStack(spacing: 4) {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .foregroundStyle(.red)
                        .font(.caption)
                    Text(error)
                        .font(.caption)
                        .foregroundStyle(.red)
                }
            }
        }
        .padding(.vertical, 12)
    }

    private var statusBar: some View {
        HStack {
            if let progress = model.indexingProgress {
                HStack(spacing: 8) {
                    ProgressView()
                        .controlSize(.small)
                    Text(progress)
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }
            } else {
                Text(model.statusDescription)
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }
            Spacer()
            if let lastError = model.lastError {
                Text(lastError)
                    .font(.footnote)
                    .foregroundStyle(.red)
            } else {
                Text("\(model.results.count) results")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(.top, 8)
    }

    private func selectFolderScope() {
        let panel = NSOpenPanel()
        panel.canChooseFiles = false
        panel.canChooseDirectories = true
        panel.allowsMultipleSelection = false
        panel.prompt = "Select Folder"
        panel.message = "Choose a folder to limit search scope"

        if panel.runModal() == .OK, let url = panel.url {
            model.folderScope = url.path(percentEncoded: false)
            model.scheduleSearch(immediate: true)
        }
    }
}
