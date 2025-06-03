// © 2025  Cristian Felipe Patiño Rojas. Created on 2/6/25.

import XCTest
@testable import swiftimport

class CLITests: XCTestCase {
    
    let sourcesFolder = Bundle.module.testFilesDirectory.appendingPathComponent("integrationTests")
    
    func testCLIOutput() throws {
        let input = sourcesFolder.appendingPathComponent("a.swift.txt")
    }
    
}
