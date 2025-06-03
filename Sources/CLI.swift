// © 2025  Cristian Felipe Patiño Rojas. Created on 3/6/25.

import ArgumentParser
import Foundation

@main
struct CLI: ParsableCommand {
    @Option(name: .shortAndLong, help: "Input entry point swift file") var input: String
    @Option(name: .shortAndLong, help: "The extension of the file") var ext: String = "swift"
    mutating func run() throws {
       print(try execute())
    }
    
    func execute() throws -> String {
        return try FileImporter(keyword: "import", ext: ext).makeExecutable(from: input)
    }
}
