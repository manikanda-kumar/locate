import Foundation
import SQLite3

public struct SQLiteError: Error, Equatable {
    public let message: String
    public let code: Int32
}

public final class DatabaseHandle {
    private var db: OpaquePointer?

    public init(path: String) throws {
        let flags = SQLITE_OPEN_CREATE | SQLITE_OPEN_READWRITE | SQLITE_OPEN_FULLMUTEX
        if sqlite3_open_v2(path, &db, flags, nil) != SQLITE_OK {
            let error = DatabaseHandle.currentError(db)
            sqlite3_close(db)
            throw error
        }
    }

    deinit {
        sqlite3_close(db)
    }

    public func prepare(_ sql: String) throws -> Statement {
        try Statement(db: db, sql: sql)
    }

    public func execute(_ sql: String) throws {
        let statement = try prepare(sql)
        try statement.stepUntilDone()
    }

    private static func currentError(_ db: OpaquePointer?) -> SQLiteError {
        let code = sqlite3_errcode(db)
        let message = sqlite3_errmsg(db).map { String(cString: $0) } ?? "Unknown error"
        return SQLiteError(message: message, code: code)
    }
}

public final class Statement {
    private var stmt: OpaquePointer?
    private weak var db: OpaquePointer?

    public init(db: OpaquePointer?, sql: String) throws {
        self.db = db
        if sqlite3_prepare_v2(db, sql, -1, &stmt, nil) != SQLITE_OK {
            throw Self.currentError(db)
        }
    }

    deinit {
        sqlite3_finalize(stmt)
    }

    public func bindText(_ value: String, at index: Int32) throws {
        try bindText(value, at: index, transient: true)
    }

    public func bindOptionalText(_ value: String?, at index: Int32) throws {
        guard let value else {
            try bindNull(at: index)
            return
        }
        try bindText(value, at: index, transient: true)
    }

    public func bindInt64(_ value: Int64, at index: Int32) throws {
        if sqlite3_bind_int64(stmt, index, sqlite3_int64(value)) != SQLITE_OK {
            throw Self.currentError(db)
        }
    }

    public func bindOptionalInt64(_ value: Int64?, at index: Int32) throws {
        guard let value else {
            try bindNull(at: index)
            return
        }
        try bindInt64(value, at: index)
    }

    public func bindNull(at index: Int32) throws {
        if sqlite3_bind_null(stmt, index) != SQLITE_OK {
            throw Self.currentError(db)
        }
    }

    public func step() throws -> Bool {
        let result = sqlite3_step(stmt)
        switch result {
        case SQLITE_ROW:
            return true
        case SQLITE_DONE:
            return false
        default:
            throw Self.currentError(db)
        }
    }

    public func stepUntilDone() throws {
        while try step() {
        }
    }

    public func reset() throws {
        if sqlite3_reset(stmt) != SQLITE_OK {
            throw Self.currentError(db)
        }
        if sqlite3_clear_bindings(stmt) != SQLITE_OK {
            throw Self.currentError(db)
        }
    }

    public func columnInt64(_ index: Int32) -> Int64 {
        sqlite3_column_int64(stmt, index)
    }

    public func columnBool(_ index: Int32) -> Bool {
        columnInt64(index) != 0
    }

    public func columnText(_ index: Int32) -> String? {
        guard let cString = sqlite3_column_text(stmt, index) else { return nil }
        return String(cString: cString)
    }

    private func bindText(_ value: String, at index: Int32, transient: Bool) throws {
        let destructor: sqlite3_destructor_type = transient ? unsafeBitCast(-1, to: sqlite3_destructor_type.self) : nil
        if sqlite3_bind_text(stmt, index, value, -1, destructor) != SQLITE_OK {
            throw Self.currentError(db)
        }
    }

    private static func currentError(_ db: OpaquePointer?) -> SQLiteError {
        let code = sqlite3_errcode(db)
        let message = sqlite3_errmsg(db).map { String(cString: $0) } ?? "Unknown error"
        return SQLiteError(message: message, code: code)
    }
}
