import SwiftUI
import Observation

struct SearchView: View {
    @Bindable var model: SearchViewModel
    @FocusState private var isSearchFocused: Bool

    var body: some View {
        VStack(spacing: 0) {
            searchBar
            filterRow
            Divider()
            ResultsView(results: model.results, selection: $model.selection)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            Divider()
            statusBar
        }
        .padding()
        .task {
            await model.load()
        }
        .onChange(of: model.query, initial: false) { _, _ in
            model.scheduleSearch()
        }
        .onChange(of: model.fileType, initial: false) { _, _ in
            model.scheduleSearch(immediate: true)
        }
        .onChange(of: model.sizePreset, initial: false) { _, _ in
            model.scheduleSearch(immediate: true)
        }
        .onChange(of: model.datePreset, initial: false) { _, _ in
            model.scheduleSearch(immediate: true)
        }
    }

    private var searchBar: some View {
        HStack(spacing: 8) {
            Image(systemName: "magnifyingglass")
                .foregroundStyle(.secondary)
            TextField("Search files and folders", text: $model.query, prompt: Text("Search files and folders"))
                .textFieldStyle(.plain)
                .disableAutocorrection(true)
                .focused($isSearchFocused)
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
        .background {
            RoundedRectangle(cornerRadius: 10, style: .continuous)
                .fill(.thinMaterial)
                .shadow(color: .black.opacity(0.04), radius: 4)
        }
        .clipShape(.rect(cornerRadius: 10))
    }

    private var filterRow: some View {
        HStack(spacing: 12) {
            Picker("Type", selection: $model.fileType) {
                ForEach(SearchViewModel.FileTypeFilter.allCases) { filter in
                    Text(filter.title).tag(filter)
                }
            }
            .pickerStyle(.menu)

            Picker("Size", selection: $model.sizePreset) {
                ForEach(SearchViewModel.SizePreset.allCases) { preset in
                    Text(preset.title).tag(preset)
                }
            }
            .pickerStyle(.menu)

            Picker("Modified", selection: $model.datePreset) {
                ForEach(SearchViewModel.DatePreset.allCases) { preset in
                    Text(preset.title).tag(preset)
                }
            }
            .pickerStyle(.menu)

            Spacer()
        }
        .padding(.vertical, 12)
    }

    private var statusBar: some View {
        HStack {
            Text(model.statusDescription)
                .font(.footnote)
                .foregroundStyle(.secondary)
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
}
