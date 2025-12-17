import SwiftUI
import LocateViewModel

struct MenuBarSearchView: View {
    @Bindable var model: SearchViewModel
    @FocusState private var isSearchFocused: Bool
    @Environment(\.openWindow) private var openWindow

    var body: some View {
        VStack(spacing: 0) {
            searchHeader
            Divider()
            resultsList
            Divider()
            footer
        }
        .frame(width: 500, height: 600)
        .onAppear {
            isSearchFocused = true
        }
    }

    private var searchHeader: some View {
        VStack(spacing: 8) {
            HStack(spacing: 8) {
                Image(systemName: "magnifyingglass")
                    .foregroundStyle(.secondary)
                TextField("Quick Search", text: $model.query)
                    .textFieldStyle(.plain)
                    .focused($isSearchFocused)
                    .onSubmit {
                        model.scheduleSearch(immediate: true)
                    }
                if model.isSearching {
                    ProgressView()
                        .controlSize(.small)
                }
                if !model.query.isEmpty {
                    Button {
                        model.clearQuery()
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundStyle(.secondary)
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(12)

            HStack(spacing: 8) {
                Toggle("Regex", isOn: $model.useRegex)
                    .toggleStyle(.switch)
                    .controlSize(.mini)

                Toggle("Match Case", isOn: $model.caseSensitive)
                    .toggleStyle(.switch)
                    .controlSize(.mini)

                Spacer()

                Button("Open Main Window") {
                    NotificationCenter.default.post(name: .activateMainWindow, object: nil)
                }
                .buttonStyle(.link)
                .controlSize(.small)
            }
            .padding(.horizontal, 12)
            .padding(.bottom, 8)

            if let error = model.regexValidationError {
                HStack(spacing: 4) {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .foregroundStyle(.red)
                        .font(.caption2)
                    Text(error)
                        .font(.caption2)
                        .foregroundStyle(.red)
                }
                .padding(.horizontal, 12)
                .padding(.bottom, 8)
            }
        }
        .background(.regularMaterial)
    }

    private var resultsList: some View {
        Group {
            if model.results.isEmpty {
                emptyState
            } else {
                List(model.results, id: \.id, selection: $model.selection) { result in
                    MenuBarResultRow(result: result, model: model)
                }
                .listStyle(.plain)
            }
        }
    }

    private var emptyState: some View {
        VStack(spacing: 12) {
            Image(systemName: model.query.isEmpty ? "magnifyingglass" : "doc.text.magnifyingglass")
                .font(.system(size: 48))
                .foregroundStyle(.tertiary)
            Text(model.query.isEmpty ? "Start typing to search" : "No results found")
                .font(.headline)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private var footer: some View {
        HStack {
            Text("\(model.results.count) results")
                .font(.caption)
                .foregroundStyle(.secondary)
            Spacer()
            if !model.hasIndex {
                Text("No index. Open main window to build index.")
                    .font(.caption)
                    .foregroundStyle(.orange)
            }
        }
        .padding(8)
        .background(.regularMaterial)
    }
}

struct MenuBarResultRow: View {
    let result: SearchViewModel.SearchResult
    let model: SearchViewModel

    var body: some View {
        Button {
            model.openFile(result)
        } label: {
            HStack(spacing: 8) {
                Image(systemName: result.isDirectory ? "folder.fill" : "doc.fill")
                    .foregroundStyle(result.isDirectory ? .blue : .secondary)
                    .font(.body)

                VStack(alignment: .leading, spacing: 2) {
                    Text(result.name)
                        .font(.body)
                        .lineLimit(1)
                    Text(result.parentPath)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                }

                Spacer()

                if let size = result.size {
                    Text(Formatting.byteCountFormatter.string(fromByteCount: size))
                        .font(.caption)
                        .foregroundStyle(.tertiary)
                }
            }
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .contextMenu {
            Button("Open") {
                model.openFile(result)
            }
            Button("Reveal in Finder") {
                model.revealInFinder(result)
            }
            Button("Copy Path") {
                model.copyPath(result)
            }
        }
    }
}
