// © 2025  Cristian Felipe Patiño Rojas. Created on 2/6/25.


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
