# Swift import

CLI tool for resolving `import` statements in Swift scripts — enabling file and folder-level inclusion for improved scripting.

### Desired behaviour

```
/b.swift
    func b() {print("b") }

/folder
    |- c.swift
    |- d.swift
    
/a.swift
    import b.swift
    import /folder
    
    b() // prints "b"
    c() // prints "c"
    d() // prints "d"
```

### Use cases

- Quick empowered explorations and playgrounds
- Small projects without Xcode
- Expanding Swift scripting abilities

### System Flow

- System.resolveDependencies(SwiftFileURL) -> SwiftTemporalFileURL
	-> System.readFile(SwiftFileURL) -> SwiftFile
	-> System.parseImportsRecursively(SwiftFile) -> Imports
	-> System.concatenateImports(Imports) -> SwiftFile  
		
### Supported features

- [ ] `import file.swift` (1 level, no recursiion)
- [ ] `import file.swift` (n levels, recursive)
- [ ] `import /folder` (1 level)
- [ ] `import /folder` (n levels, recursive)

### Usage

```
tmp="/tmp/swiftimport-$(date +%s)"
swiftimport file.swift > "$tmp.swift"
swiftc "$tmp.swift" -o "$tmp"
```

### Installation

For now, clone repo and build binary.

