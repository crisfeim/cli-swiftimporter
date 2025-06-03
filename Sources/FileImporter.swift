// © 2025  Cristian Felipe Patiño Rojas. Created on 2/6/25.


import Foundation
import RegexBuilder
import Collections

final class FileImporter {
    let keyword: String
    let `extension`: String
    private let fm = FileManager.default
    
    private var required_files = OrderedSet<URL>()
    
    init(keyword: String, extension: String) {
        self.keyword = keyword
        self.extension = `extension`
    }
    
    enum Error: Swift.Error {
        case unableToReadContentsOfFile(atPath: String)
        case fileDoesntExist(atPath: String)
        case unableToScanDirectory(atPath: String)
    }
    
    func concatenateImportsFromFile(_ fileURL: URL) throws -> String {
        try scanImports(fileURL).reduce("") {
            let string = try String(contentsOfFile: $1.path, encoding: .utf8)
            return $0 + "\n" + string
        }
    }
    
    func scanImports(_ fileURL: URL) throws -> OrderedSet<URL> {
        try scan_file(fileURL)
        return required_files
    }
    
    func scan_file(_ fileURL: URL) throws {
        
        var isDirectory: ObjCBool = false
        guard fm.fileExists(atPath: fileURL.path, isDirectory: &isDirectory) else {
            throw Error.fileDoesntExist(atPath: fileURL.path)
        }
        
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
        
        required_files.append(fileURL)
        let directory = fileURL.deletingLastPathComponent()
        
        let imports = scanImports(content).map {
            directory.appendingPathComponent($0, isDirectory: $0.hasSuffix("/"))
        }
        
        for item in imports {
            try scan_file(item)
        }
    }
    
    func scanDirectory(_ directoryURL: URL) throws -> [URL] {
        
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
    
    func scanImports(_ content: String) -> OrderedSet<String> {
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
        
        return OrderedSet(importedFiles)
    }
}
