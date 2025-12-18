import Foundation

public struct Root: Equatable, Sendable {
    public let id: Int64
    public let path: String
    public let volumeName: String?
    public let fileCount: Int64
    public let dirCount: Int64
    public let lastIndexed: Int64?
}

public struct FileRecord: Equatable, Sendable, Hashable {
    public let id: Int64
    public let rootID: Int64
    public let parentID: Int64?
    public let name: String
    public let nameLower: String
    public let path: String
    public let isDirectory: Bool
    public let size: Int64?
    public let fileExtension: String?
    public let modifiedAt: Int64?
    public let createdAt: Int64?
    public let accessedAt: Int64?
    public let attributes: Int64
}

public extension Root {
    init?(from statement: Statement) {
        guard let path = statement.columnText(1) else { return nil }
        self.init(
            id: statement.columnInt64(0),
            path: path,
            volumeName: statement.columnText(2),
            fileCount: statement.columnInt64(3),
            dirCount: statement.columnInt64(4),
            lastIndexed: statement.columnOptionalInt64(5)
        )
    }
}

public extension FileRecord {
    init?(from statement: Statement) {
        guard
            let name = statement.columnText(3),
            let nameLower = statement.columnText(4),
            let path = statement.columnText(5)
        else {
            return nil
        }
        self.init(
            id: statement.columnInt64(0),
            rootID: statement.columnInt64(1),
            parentID: statement.columnOptionalInt64(2),
            name: name,
            nameLower: nameLower,
            path: path,
            isDirectory: statement.columnBool(6),
            size: statement.columnOptionalInt64(7),
            fileExtension: statement.columnText(8),
            modifiedAt: statement.columnOptionalInt64(9),
            createdAt: statement.columnOptionalInt64(10),
            accessedAt: statement.columnOptionalInt64(11),
            attributes: statement.columnInt64(12)
        )
    }
}
