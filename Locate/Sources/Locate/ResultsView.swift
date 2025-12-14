import AppKit
import SwiftUI
import LocateViewModel

struct ResultsView: View {
    let results: [SearchViewModel.SearchResult]
    @Binding var selection: Set<SearchViewModel.SearchResult.ID>
    let model: SearchViewModel

    var body: some View {
        Group {
            if results.isEmpty {
                emptyState
            } else {
                Table(results, selection: $selection) {
                    TableColumn("Name") { result in
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
                    TableColumn("Size") { result in
                        Text(sizeDescription(for: result))
                            .foregroundStyle(.secondary)
                    }
                    TableColumn("Modified") { result in
                        if let date = result.modifiedDate {
                            Text(date, format: .dateTime.year().month().day().hour().minute())
                                .foregroundStyle(.secondary)
                        } else {
                            Text("—")
                                .foregroundStyle(.secondary)
                        }
                    }
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

                        Button("Copy Path") {
                            handleCopyPath()
                        }
                        .keyboardShortcut("c", modifiers: [.command, .shift])
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
              let result = results.first(where: { $0.id == firstID }) else {
            return
        }
        model.openFile(result)
    }

    private func handleRevealInFinder() {
        guard let firstID = selection.first,
              let result = results.first(where: { $0.id == firstID }) else {
            return
        }
        model.revealInFinder(result)
    }

    private func handleCopyPath() {
        guard let firstID = selection.first,
              let result = results.first(where: { $0.id == firstID }) else {
            return
        }
        model.copyPath(result)
    }

    private var emptyState: some View {
        VStack(spacing: 8) {
            Image(systemName: "text.magnifyingglass")
                .font(.largeTitle)
                .foregroundStyle(.secondary)
            Text("Start typing to search your index.")
                .foregroundStyle(.secondary)
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
