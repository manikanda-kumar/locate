import SwiftUI
import Observation
import LocateViewModel

struct SearchView: View {
    @Bindable var model: SearchViewModel
    @FocusState private var isSearchFocused: Bool
    @State private var showAdvancedFilters = false

    var body: some View {
        VStack(spacing: 0) {
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
                    .onChange(of: model.query) { _, _ in
                        model.scheduleSearch(immediate: false)
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

                Spacer()

                Button {
                    withAnimation(.easeInOut(duration: 0.2)) {
                        showAdvancedFilters.toggle()
                    }
                } label: {
                    HStack(spacing: 4) {
                        Text("Advanced")
                        Image(systemName: showAdvancedFilters ? "chevron.up" : "chevron.down")
                    }
                }
                .buttonStyle(.bordered)
            }

            if showAdvancedFilters {
                VStack(alignment: .leading, spacing: 8) {
                    HStack(spacing: 8) {
                        Text("Extensions:")
                            .foregroundStyle(.secondary)
                            .frame(width: 70, alignment: .leading)
                        TextField(".swift,.md,.txt", text: $model.customExtensions)
                            .textFieldStyle(.roundedBorder)
                            .frame(minWidth: 150, maxWidth: 300)
                            .accessibilityIdentifier("ExtensionFilter")
                            .onSubmit {
                                model.scheduleSearch(immediate: true)
                            }
                            .help(model.customExtensions.isEmpty ? "Enter comma-separated extensions" : model.customExtensions)
                    }

                    HStack(spacing: 8) {
                        Text("Scope:")
                            .foregroundStyle(.secondary)
                            .frame(width: 70, alignment: .leading)

                        if model.folderScope.isEmpty {
                            Text("All indexed folders")
                                .foregroundStyle(.tertiary)
                        } else {
                            Text(model.folderScopeDisplayName)
                                .lineLimit(1)
                                .truncationMode(.middle)
                                .frame(maxWidth: 200)
                                .help(model.folderScope)

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
                }
                .padding(.top, 4)
                .padding(.leading, 4)
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
