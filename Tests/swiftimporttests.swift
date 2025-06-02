//
//  swiftimporttests.swift
//  swiftimport
//
//  Created by Cristian Felipe Patiño Rojas on 2/5/25.
//

import XCTest

final class Tests: XCTestCase {
    func test_scanImports_parsesStandaloneSwiftFilesImports() {
        let sut = FileImporter(keyword: "import")
        let code = """
        import a.swift
        import b.swift
        import some_really_long_named_file.swift
        import cascade_b.swift

        let a = B()
        """
        
        let output = sut.scanImports(atContent: code)
        let expectedOutput: Set<String> = ["a.swift", "b.swift", "some_really_long_named_file.swift", "cascade_b.swift"]
        
        XCTAssertEqual(output, expectedOutput)
    }
    
    
    func test_scanImports_parsesNestedSwiftFilesImports() {
        let sut = FileImporter(keyword: "import")
        let code = """
        import nested/a.swift
        import nested/b.swift
        
        enum SomeEnum {}
        """
        
        let output = sut.scanImports(atContent: code)
        let expectedOutput: Set<String> = ["nested/a.swift", "nested/b.swift"]
        
        XCTAssertEqual(output, expectedOutput)
    }
    
    func test_scanImports_parsesFolders() {
        let sut = FileImporter(keyword: "import")
        let code = """
        import nested/
        """
        
        let output = sut.scanImports(atContent: code)
        let expectedOutput: Set<String> = ["nested/"]
        
        XCTAssertEqual(output, expectedOutput)
    }
}

import Foundation
import RegexBuilder

struct FileImporter {
    let keyword: String
    
    private let fm = FileManager.default
    
    enum Error: Swift.Error {
        case unableToReadContentsOfFile(atPath: String)
        case fileDoesntExist(atPath: String)
        case unableToScanDirectory(atPath: String)
    }
    
    func scanImports(ofFile url: URL) throws(Error) -> Set<URL> {
        var required_files = Set<URL>()
        
        func scanDirectory(_ directoryURL: URL) throws(Error) -> [URL] {
            
            let resourceKeys: [URLResourceKey] = [.isDirectoryKey]
            
            guard let enumerator = fm.enumerator(
                at: directoryURL,
                includingPropertiesForKeys: resourceKeys,
                options: [.skipsHiddenFiles]
            ) else {
                throw Error.unableToScanDirectory(atPath: directoryURL.path)
            }
            
            var swiftFiles: [URL] = []
            
            for case let fileURL as URL in enumerator {
                if fileURL.pathExtension == "swift" {
                    swiftFiles.append(fileURL)
                }
            }
            
            return swiftFiles
        }
        
        func scan_file(_ fileURL: URL) throws(Error) {
            
            guard fm.fileExists(atPath: fileURL.path) else {
                throw Error.fileDoesntExist(atPath: fileURL.path)
            }
            
            var isDirectory: ObjCBool = false
            fm.fileExists(atPath: fileURL.path, isDirectory: &isDirectory)
            
            if isDirectory.boolValue {
                let swiftFiles = try scanDirectory(fileURL)
                for swiftFile in swiftFiles {
                    try scan_file(swiftFile)
                }
                return
            }
            
            guard let content = try? String(contentsOfFile: fileURL.path, encoding: .utf8) else {
                throw Error.unableToReadContentsOfFile(atPath: fileURL.path)
            }
            
            guard !required_files.contains(fileURL) else {
                return
            }
            
            required_files.insert(fileURL)
            let directory = fileURL.deletingLastPathComponent()
            
            let imports = scanImports(atContent: content).map {
                directory.appendingPathComponent($0, isDirectory: $0.hasSuffix("/"))
            }
            
            for item in imports {
                try scan_file(item)
            }
        }
        
        try scan_file(url)
        
        return required_files
    }
    
    func scanImports(atContent content: String) -> Set<String> {
        let importPattern = Regex {
            Anchor.startOfLine
            "\(keyword) "
            Capture {
                OneOrMore {
                    ChoiceOf {
                        .word
                        "/"
                        "."
                    }
                }
                ChoiceOf {
                    ".swift"
                    "/"
                }
            }
        }
        
        let matches = content.matches(of: importPattern)
        
        let importedFiles = matches.map { match in
            String(match.output.1)
        }
        
        return Set(importedFiles)
    }
}

// require fileimporter.swift
import Foundation

final class FileImporterTests {
    
    let currentDir = URL(fileURLWithPath: FileManager.default.currentDirectoryPath)
    lazy var testSources = currentDir.appendingPathComponent("tests-sources")
    
    func test_file_parsing() throws(FileImporter.Error) {
        let sut = FileImporter(keyword: "import")
        let fileURL = testSources.appendingPathComponent("b.swift")
        let output = try sut.scanImports(ofFile: fileURL)
            .map { $0.lastPathComponent }
        let expectedOutput = ["a.swift", "b.swift"]
        
        assert(Set(output) == Set(expectedOutput))
    }
    
    func test_cascade_parsing() throws(FileImporter.Error) {
        let sut = FileImporter(keyword: "import")
        let fileURL = testSources.appendingPathComponent("cascade_a.swift")
        let output = try sut.scanImports(ofFile: fileURL)
            .map {$0.lastPathComponent}
        
        let expectedOutput = [
            "cascade_a.swift",
            "cascade_b.swift",
            "cascade_c.swift"
        ]
        
        assert(Set(output) == Set(expectedOutput))
    }
    
    func test_infinite_recursion() throws(FileImporter.Error) {
        
        let sut = FileImporter(keyword: "import")
        let fileURL = testSources.appendingPathComponent("cyclic_a.swift")
        let output = try sut.scanImports(ofFile: fileURL).map {$0.lastPathComponent}
        
        let expectedOutput = [
            "cyclic_a.swift",
            "cyclic_b.swift"
        ]
        
        assert(Set(output) == Set(expectedOutput))
    }
    
    func test_import_file_inside_folder() throws (FileImporter.Error) {
        let sut = FileImporter(keyword: "import")
        let fileURL = testSources.appendingPathComponent("nested_import.swift")
        let output = try sut.scanImports(ofFile: fileURL)
        
        let expectedOutput = [
            "nested_import.swift",
            "nested/a.swift"
        ].map {
            testSources.appendingPathComponent($0)
        }
        
        assert(output == Set(expectedOutput))
    }
    
    func test_import_file_inside_folder_cascade() throws (FileImporter.Error) {
        let sut = FileImporter(keyword: "import")
        let fileURL = testSources.appendingPathComponent("nested_import_b.swift")
        let output = try sut.scanImports(ofFile: fileURL)
        
        
        let expectedOutput = [
            "nested_import_b.swift",
            "nested/a.swift",
            "nested/b.swift"
        ].map {
            testSources.appendingPathComponent($0)
        }
        
        assert(output == Set(expectedOutput))
    }
    
    func test_import_whole_folder() throws(FileImporter.Error) {
        let sut = FileImporter(keyword: "import")
        let fileURL = testSources.appendingPathComponent("import_whole_folder.swift")
        let output = try sut.scanImports(ofFile: fileURL)
        
        let expectedOutput = [
            "import_whole_folder.swift",
            "nested/a.swift",
            "nested/b.swift",
            "nested/nested/a.swift"
        ].map {
            testSources.appendingPathComponent($0)
        }
        
        assert(output == Set(expectedOutput))
    }
    
    func _try(_ function: () throws(FileImporter.Error) -> Void) {
        do {
            try function()
        } catch {
            print(error)
        }
    }
}

func assert(_ condition: Bool, function: String = #function, line: UInt = #line) {
    let emoji = condition ? "✅" : "❌"
    print(line.description ++ emoji.description ++ function)
}

infix operator ++: AdditionPrecedence
func ++(lhs: String, rhs: String) -> String {
    lhs + " " + rhs
}

