//
//  swiftimporttests.swift.txt
//  swiftimport
//
//  Created by Cristian Felipe Patiño Rojas on 2/5/25.
//

import XCTest
@testable import swiftimport

final class Tests: XCTestCase {
    
    lazy var testSources = Bundle.module.testFilesDirectory
    
    func makeSUT(keyword: String = "import", extension: String = "swift.txt") -> FileImporter {
        FileImporter(keyword: keyword, extension: `extension`)
    }
    
    func test_scanImports_parsesStandaloneSwiftFilesImports() {
        let sut = makeSUT()
        let code = """
        import a.swift.txt
        import b.swift.txt
        import some_really_long_named_file.swift.txt
        import cascade_b.swift.txt

        let a = B()
        """
        
        let output = sut.scanImports(atContent: code)
        let expectedOutput: Set<String> = ["a.swift.txt", "b.swift.txt", "some_really_long_named_file.swift.txt", "cascade_b.swift.txt"]
        
        XCTAssertEqual(output, expectedOutput)
    }
    
    
    func test_scanImports_parsesNestedSwiftFilesImports() {
        let sut = makeSUT()
        let code = """
        import nested/a.swift.txt
        import nested/b.swift.txt
        
        enum SomeEnum {}
        """
        
        let output = sut.scanImports(atContent: code)
        let expectedOutput: Set<String> = ["nested/a.swift.txt", "nested/b.swift.txt"]
        
        XCTAssertEqual(output, expectedOutput)
    }
    
    func test_scanImports_parsesFolders() {
        let sut = makeSUT()
        let code = """
        import nested/
        """
        
        let output = sut.scanImports(atContent: code)
        let expectedOutput: Set<String> = ["nested/"]
        
        XCTAssertEqual(output, expectedOutput)
    }
    
    func test_file_parsing() throws(FileImporter.Error) {
        let sut = makeSUT()
        let fileURL = testSources.appendingPathComponent("b.swift.txt")
        let output = try sut.scanImports(ofFile: fileURL)
            .map { $0.lastPathComponent }
        let expectedOutput = ["a.swift.txt", "b.swift.txt"]
        
        XCTAssertEqual(Set(output), Set(expectedOutput))
    }
    
    func test_cascade_parsing() throws(FileImporter.Error) {
        let sut = makeSUT()
        let fileURL = testSources.appendingPathComponent("cascade_a.swift.txt")
        let output = try sut.scanImports(ofFile: fileURL)
            .map {$0.lastPathComponent}
        
        let expectedOutput = [
            "cascade_a.swift.txt",
            "cascade_b.swift.txt",
            "cascade_c.swift.txt"
        ]
        
        XCTAssertEqual(Set(output), Set(expectedOutput))
    }
    
    func test_infinite_recursion() throws(FileImporter.Error) {
        
        let sut = makeSUT()
        let fileURL = testSources.appendingPathComponent("cyclic_a.swift.txt")
        let output = try sut.scanImports(ofFile: fileURL).map {$0.lastPathComponent}
        
        let expectedOutput = [
            "cyclic_a.swift.txt",
            "cyclic_b.swift.txt"
        ]
        
        XCTAssertEqual(Set(output), Set(expectedOutput))
    }
    
    func test_import_file_inside_folder() throws (FileImporter.Error) {
        let sut = makeSUT()
        let fileURL = testSources.appendingPathComponent("nested_import.swift.txt")
        let output = try sut.scanImports(ofFile: fileURL)
        
        let expectedOutput = [
            "nested_import.swift.txt",
            "nested/a.swift.txt"
        ].map {
            testSources.appendingPathComponent($0)
        }
        
        XCTAssertEqual(output,  Set(expectedOutput))
    }
    
    func test_import_file_inside_folder_cascade() throws (FileImporter.Error) {
        let sut = makeSUT()
        let fileURL = testSources.appendingPathComponent("nested_import_b.swift.txt")
        let output = try sut.scanImports(ofFile: fileURL)
        
        
        let expectedOutput = [
            "nested_import_b.swift.txt",
            "nested/a.swift.txt",
            "nested/b.swift.txt"
        ].map {
            testSources.appendingPathComponent($0)
        }
        
        XCTAssertEqual(output,  Set(expectedOutput))
    }
    
    func test_import_whole_folder() throws(FileImporter.Error) {
        let sut = makeSUT()
        let fileURL = testSources.appendingPathComponent("import_whole_folder.swift.txt")
        let output = try sut.scanImports(ofFile: fileURL)
        
        let expectedOutput = [
            "import_whole_folder.swift.txt",
            "nested/a.swift.txt",
            "nested/b.swift.txt",
            "nested/nested/a.swift.txt"
        ].map {
            testSources.appendingPathComponent($0)
        }
        
        XCTAssertEqual(output,  Set(expectedOutput))
    }
    
}


