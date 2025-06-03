// © 2025  Cristian Felipe Patiño Rojas. Created on 2/6/25.

import Foundation

extension Bundle {
    var resourcesDirectory: URL {
        bundleURL.appendingPathComponent("Contents/Resources")
    }
    
    var testFilesDirectory: URL {
        resourcesDirectory.appendingPathComponent("files")
    }
}


