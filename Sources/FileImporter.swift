// © 2025  Cristian Felipe Patiño Rojas. Created on 2/6/25.


import Foundation
import RegexBuilder
import Collections

final class FileImporter {
    private let keyword: String
    private let ext: String
    private let fileHandler: FileHandler
    
    private var importedFilesByVisitOrder = OrderedSet<URL>()
    private var orderedFilesForConcatenation: OrderedSet<URL> {
        OrderedSet(importedFilesByVisitOrder.reversed())
    }
    
    init(keyword: String, ext: String, fileHandler: FileHandler = FileManager.default) {
        self.keyword = keyword
        self.ext = ext
        self.fileHandler = fileHandler
    }
    
    struct FileNotFoundError: Error {}
    
    func scanImports(_ fileURL: URL) throws -> OrderedSet<URL> {
        importedFilesByVisitOrder.removeAll()
        try scanFile(fileURL)
        return orderedFilesForConcatenation
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

private extension FileImporter {
    
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
        guard fileHasNotBeenAlreadyParsed(data.url) else { return }
        importedFilesByVisitOrder.append(data.url)
        
        try parseImports(data.content)
            .map { data.parentDir.appendingPathComponent($0, isDirectory: $0.hasSuffix("/")) }
            .forEach { try scanFile($0) }
    }
    
    func fileHasNotBeenAlreadyParsed(_ url: URL) -> Bool {
        !importedFilesByVisitOrder.contains(url)
    }
}
