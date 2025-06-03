// © 2025  Cristian Felipe Patiño Rojas. Created on 3/6/25.

import XCTest
import Collections
@testable import swiftimport

extension FileImporterTests {
    
    func test_parseImports_handlesStandaloneSwiftFilesImports() {
        let sut = makeSUT()
        let code = """
        import a.swift.txt
        import b.swift.txt
        import some_really_long_named_file.swift.txt
        import cascade_b.swift.txt
        
        let a = B()
        """
        
        let output = sut.parseImports(code)
        let expectedOutput = ["a.swift.txt", "b.swift.txt", "some_really_long_named_file.swift.txt", "cascade_b.swift.txt"]
        
        XCTAssertEqual(output, OrderedSet(expectedOutput))
    }
    
    
    func test_parseImports_handlesNestedSwiftFilesImports() {
        let sut = makeSUT()
        let code = """
        import nested/a.swift.txt
        import nested/b.swift.txt
        
        enum SomeEnum {}
        """
        
        let output = sut.parseImports(code)
        let expectedOutput = ["nested/a.swift.txt", "nested/b.swift.txt"]
        
        XCTAssertEqual(output, OrderedSet(expectedOutput))
    }
    
    func test_parseImports_handlesDirectories() {
        let sut = makeSUT()
        let code = """
        import nested/
        """
        
        let output = sut.parseImports(code)
        let expectedOutput = ["nested/"]
        
        XCTAssertEqual(output, OrderedSet(expectedOutput))
    }
}
