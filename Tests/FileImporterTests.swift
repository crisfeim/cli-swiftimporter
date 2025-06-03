//
//  Created by Cristian Felipe Patiño Rojas on 2/5/25.

import XCTest
import Collections
@testable import swiftimport

final class FileImporterTests: XCTestCase {
    
    lazy var testSources = Bundle.module.testFilesDirectory
    
    func test_file_parsing() throws {
        let sut = makeSUT()
        let fileURL = testSources.appendingPathComponent("b.swift.txt")
        let output = OrderedSet(try sut.scanImports(fileURL)
            .map { $0.lastPathComponent })
        let expectedOutput = ["a.swift.txt", "b.swift.txt"]
        
        XCTAssertEqual(output, OrderedSet(expectedOutput))
    }
    
    func test_cascade_parsing() throws {
        let sut = makeSUT()
        let fileURL = testSources.appendingPathComponent("cascade_a.swift.txt")
        let output = try sut.scanImports(fileURL)
            .map {$0.lastPathComponent}
        
        let expectedOutput = [
            "cascade_c.swift.txt",
            "cascade_b.swift.txt",
            "cascade_a.swift.txt"
        ]
        
        XCTAssertEqual(OrderedSet(output), OrderedSet(expectedOutput))
    }
    
    func test_infinite_recursion() throws {
        
        let sut = makeSUT()
        let fileURL = testSources.appendingPathComponent("cyclic_a.swift.txt")
        let output = try sut.scanImports(fileURL).map {$0.lastPathComponent}
        
        let expectedOutput = [
            "cyclic_b.swift.txt",
            "cyclic_a.swift.txt",
        ]
        
        XCTAssertEqual(OrderedSet(output), OrderedSet(expectedOutput))
    }
    
    func test_import_file_inside_folder() throws {
        let sut = makeSUT()
        let fileURL = testSources.appendingPathComponent("nested_import.swift.txt")
        let output = try sut.scanImports(fileURL)
        
        let expectedOutput = [
            "nested/a.swift.txt",
            "nested_import.swift.txt",
        ].map {
            testSources.appendingPathComponent($0)
        }
        
        XCTAssertEqual(output,  OrderedSet(expectedOutput))
    }
    
    func test_import_file_inside_folder_cascade() throws {
        let sut = makeSUT()
        let fileURL = testSources.appendingPathComponent("nested_import_b.swift.txt")
        let output = try sut.scanImports(fileURL)
        
        
        let expectedOutput = [
            "nested/a.swift.txt",
            "nested/b.swift.txt",
            "nested_import_b.swift.txt",
        ].map {
            testSources.appendingPathComponent($0)
        }
        
        XCTAssertEqual(output,  OrderedSet(expectedOutput))
    }
    
    func test_import_whole_folder() throws {
        let sut = makeSUT()
        let fileURL = testSources.appendingPathComponent("import_whole_folder.swift.txt")
        let output = try sut.scanImports(fileURL)
        
        let expectedOutput = [
            "nested/nested/a.swift.txt",
            "nested/b.swift.txt",
            "nested/a.swift.txt",
            "import_whole_folder.swift.txt",
        ].map {
            testSources.appendingPathComponent($0)
        }
        
        XCTAssertEqual(output,  OrderedSet(expectedOutput))
    }
}


// MARK: - Helpers
extension FileImporterTests {
    func makeSUT(keyword: String = "import", extension: String = "swift.txt") -> FileImporter {
        FileImporter(keyword: keyword, ext: `extension`)
    }
}
