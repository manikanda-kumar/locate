import AppKit
import SwiftUI
import LocateViewModel

struct ResultsView: View {
    let results: [SearchViewModel.SearchResult]
    @Binding var selection: Set<SearchViewModel.SearchResult.ID>
    let model: SearchViewModel
    @State private var sortOrder = [KeyPathComparator(\SearchViewModel.SearchResult.name)]

    private var sortedResults: [SearchViewModel.SearchResult] {
        results.sorted(using: sortOrder)
    }

    var body: some View {
        Group {
            if results.isEmpty {
                emptyState
            } else {
                VStack(spacing: 0) {
                    Table(sortedResults, selection: $selection, sortOrder: $sortOrder) {
                        TableColumn("Name", value: \.name) { result in
                            HStack(spacing: 8) {
                                FileIconView(url: result.url, isDirectory: result.isDirectory)
                                VStack(alignment: .leading, spacing: 2) {
                                    Text(result.name)
                                        .lineLimit(1)
                                    Text(result.parentPath)
                                        .lineLimit(1)
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                }
                            }
                            .padding(.vertical, 4)
                        }
                        .width(min: 200, ideal: 350, max: 600)

                        TableColumn("Kind", value: \.kind) { result in
                            Text(result.kind)
                                .foregroundStyle(.secondary)
                        }
                        .width(min: 80, ideal: 100, max: 150)

                        TableColumn("Size") { result in
                            Text(sizeDescription(for: result))
                                .foregroundStyle(.secondary)
                        }
                        .width(min: 60, ideal: 80, max: 120)

                        TableColumn("Modified") { result in
                            if let date = result.modifiedDate {
                                Text(date, format: .dateTime.year().month().day().hour().minute())
                                    .foregroundStyle(.secondary)
                            } else {
                                Text("—")
                                    .foregroundStyle(.secondary)
                            }
                        }
                        .width(min: 120, ideal: 150, max: 200)

                        TableColumn("Created") { result in
                            if let date = result.createdDate {
                                Text(date, format: .dateTime.year().month().day().hour().minute())
                                    .foregroundStyle(.secondary)
                            } else {
                                Text("—")
                                    .foregroundStyle(.secondary)
                            }
                        }
                        .width(min: 120, ideal: 150, max: 200)

                        TableColumn("Path", value: \.path) { result in
                            Text(result.path)
                                .lineLimit(1)
                                .font(.caption)
                                .foregroundStyle(.tertiary)
                        }
                        .width(min: 150, ideal: 250, max: 500)
                    }
                    .tableStyle(.inset(alternatesRowBackgrounds: true))
                    .onTapGesture(count: 2) {
                        handleOpenFile()
                    }
                    .contextMenu {
                        if !selection.isEmpty {
                            Button("Open") {
                                handleOpenFile()
                            }
                            .keyboardShortcut(.return)

                            Button("Reveal in Finder") {
                                handleRevealInFinder()
                            }
                            .keyboardShortcut("r", modifiers: [.command, .shift])

                            Button("Copy Path") {
                                handleCopyPath()
                            }
                            .keyboardShortcut("c", modifiers: [.command, .shift])
                        }
                    }

                    if selection.count > 1 {
                        HStack {
                            Text("\(selection.count) items selected")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                            Spacer()
                        }
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(.bar)
                    }
                }
            }
        }
        .onKeyPress(.return) {
            handleOpenFile()
            return .handled
        }
    }

    private func handleOpenFile() {
        guard let firstID = selection.first,
              let result = sortedResults.first(where: { $0.id == firstID }) else {
            return
        }
        model.openFile(result)
    }

    private func handleRevealInFinder() {
        guard let firstID = selection.first,
              let result = sortedResults.first(where: { $0.id == firstID }) else {
            return
        }
        model.revealInFinder(result)
    }

    private func handleCopyPath() {
        guard let firstID = selection.first,
              let result = sortedResults.first(where: { $0.id == firstID }) else {
            return
        }
        model.copyPath(result)
    }

    private var emptyState: some View {
        VStack(spacing: 12) {
            Image(systemName: "text.magnifyingglass")
                .font(.largeTitle)
                .foregroundStyle(.secondary)
            Text("Start typing to search your index")
                .font(.headline)
                .foregroundStyle(.secondary)
            VStack(spacing: 4) {
                Text("Tips:")
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundStyle(.tertiary)
                Text("• Use filters to narrow results")
                    .font(.caption)
                    .foregroundStyle(.tertiary)
                Text("• Press ⌘R to rebuild the index")
                    .font(.caption)
                    .foregroundStyle(.tertiary)
                Text("• Toggle Regex for pattern matching")
                    .font(.caption)
                    .foregroundStyle(.tertiary)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private func sizeDescription(for result: SearchViewModel.SearchResult) -> String {
        guard let size = result.size, !result.isDirectory else {
            return "—"
        }
        return Formatting.byteCountFormatter.string(fromByteCount: size)
    }
}

private struct FileIconView: View {
    let url: URL
    let isDirectory: Bool

    var body: some View {
        FileIconProvider.icon(for: url, isDirectory: isDirectory)
            .resizable()
            .frame(width: 20, height: 20)
            .clipShape(.rect(cornerRadius: 4))
    }
}

@MainActor
private enum FileIconProvider {
    private static let cache = NSCache<NSURL, NSImage>()

    static func icon(for url: URL, isDirectory: Bool) -> Image {
        if let cached = cache.object(forKey: url as NSURL) {
            return Image(nsImage: cached)
        }
        let icon = NSWorkspace.shared.icon(forFile: url.path(percentEncoded: false))
        icon.size = NSSize(width: 20, height: 20)
        cache.setObject(icon, forKey: url as NSURL)
        return Image(nsImage: icon)
    }
}
