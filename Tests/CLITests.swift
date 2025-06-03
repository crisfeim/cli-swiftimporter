// © 2025  Cristian Felipe Patiño Rojas. Created on 3/6/25.

import XCTest
@testable import swiftimport

class CLITests: XCTestCase {
    
    func test() throws {
        let srcFolder = Bundle.module.testFilesDirectory.appendingPathComponent("integrationTests")
        let entryPointFileURL = srcFolder.appendingPathComponent("a.swift.txt")
        let sut = try CLI.parse([
            "--input", entryPointFileURL.path,
            "--ext", "swift.txt"
        ])
        
        let result = try sut.execute()
        
        let expectedResult = """
        c file
        
        // import nested/c.swift.txt
        b file
        
        // import b.swift.txt
        a file
        
        """
        
        XCTAssertEqual(result, expectedResult)
    }
}
