import Testing
@testable import LocateCore

@Test func sqliteSelectOne() {
    #expect(SQLiteVerification.runSelectOne() == true)
}

@Test func sqliteVersionAndFTS5() {
    let (version, hasFTS5) = SQLiteVerification.verify()
    #expect(!version.isEmpty)
    #expect(hasFTS5 == true, "FTS5 should be available on macOS")
}