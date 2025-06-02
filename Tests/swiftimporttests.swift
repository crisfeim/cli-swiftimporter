//
//  swiftimporttests.swift.txt
//  swiftimport
//
//  Created by Cristian Felipe Patiño Rojas on 2/5/25.
//

import XCTest

final class Tests: XCTestCase {
    
    lazy var testSources = Bundle.module.testFilesDirectory
    
    func test_scanImports_parsesStandaloneSwiftFilesImports() {
        let sut = FileImporter(keyword: "import", extension: "swift.txt")
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
        let sut = FileImporter(keyword: "import", extension: "swift.txt")
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
        let sut = FileImporter(keyword: "import", extension: "swift.txt")
        let code = """
        import nested/
        """
        
        let output = sut.scanImports(atContent: code)
        let expectedOutput: Set<String> = ["nested/"]
        
        XCTAssertEqual(output, expectedOutput)
    }
    
    func test_file_parsing() throws(FileImporter.Error) {
        let sut = FileImporter(keyword: "import", extension: "swift.txt")
        let fileURL = testSources.appendingPathComponent("b.swift.txt")
        let output = try sut.scanImports(ofFile: fileURL)
            .map { $0.lastPathComponent }
        let expectedOutput = ["a.swift.txt", "b.swift.txt"]
        
        XCTAssertEqual(Set(output), Set(expectedOutput))
    }
    
    func test_cascade_parsing() throws(FileImporter.Error) {
        let sut = FileImporter(keyword: "import", extension: "swift.txt")
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
        
        let sut = FileImporter(keyword: "import", extension: "swift.txt")
        let fileURL = testSources.appendingPathComponent("cyclic_a.swift.txt")
        let output = try sut.scanImports(ofFile: fileURL).map {$0.lastPathComponent}
        
        let expectedOutput = [
            "cyclic_a.swift.txt",
            "cyclic_b.swift.txt"
        ]
        
        XCTAssertEqual(Set(output), Set(expectedOutput))
    }
    
    func test_import_file_inside_folder() throws (FileImporter.Error) {
        let sut = FileImporter(keyword: "import", extension: "swift.txt")
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
        let sut = FileImporter(keyword: "import", extension: "swift.txt")
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
        let sut = FileImporter(keyword: "import", extension: "swift.txt")
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


private extension Bundle {
    var resourcesDirectory: URL {
        bundleURL.appendingPathComponent("Contents/Resources")
    }
    
    var testFilesDirectory: URL {
        resourcesDirectory.appendingPathComponent("files")
    }
}

import Foundation
import RegexBuilder

struct FileImporter {
    let keyword: String
    let `extension`: String
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
                if fileURL.lastPathComponent.hasSuffix(`extension`) {
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
                    ".swift.txt"
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

