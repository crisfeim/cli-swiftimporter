// © 2025  Cristian Felipe Patiño Rojas. Created on 2/6/25.


import Foundation
import RegexBuilder
import Collections

final class FileImporter {
    private let keyword: String
    private let ext: String
    private let fileHandler: FileHandler
    
    private var importedFiles = OrderedSet<URL>()
    
    init(keyword: String, ext: String, fileHandler: FileHandler = FileManager.default) {
        self.keyword = keyword
        self.ext = ext
        self.fileHandler = fileHandler
    }
    
    struct FileNotFoundError: Error {}
    
    func scanImports(_ fileURL: URL) throws -> OrderedSet<URL> {
        try scanFile(fileURL)
        return importedFiles
    }
    
    func scanFile(_ fileURL: URL) throws {
        switch try fileHandler.getFile(fileURL) {
        case .directory: return try handleDirectory(fileURL)
        case .file(let data): return try handleFile(data)
        case .none: throw FileNotFoundError()
        }
    }
    
    func handleDirectory(_ directoryURL: URL) throws {
        try fileHandler.getFileURLsOnDirectory(directoryURL)
            .filter { $0.lastPathComponent.hasSuffix(ext) }
            .forEach { try scanFile($0) }
    }
    
    func handleFile(_ data: File.Data) throws {
        guard !importedFiles.contains(data.url) else { return }
        importedFiles.append(data.url)
        
        try parseImports(data.content)
            .map { data.parentDir.appendingPathComponent($0, isDirectory: $0.hasSuffix("/")) }
            .forEach { try scanFile($0) }
    }
    
    
    func parseImports(_ content: String) -> OrderedSet<String> {
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
        
        return OrderedSet(content
            .matches(of: importPattern)
            .map { String($0.output.1) })
    }
}
