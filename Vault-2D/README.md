# Vault-2D - SwiftGodot Game Client

Mobile game client for Vaultown using SwiftGodot (Swift bindings for Godot 4).

## Prerequisites

1. **Godot v4.5.1+** - Download from [godotengine.org](https://godotengine.org/download) or install with `brew`
2. **Swift 6.2+** - Included with Xcode 16+ on macOS
3. **Xcode Command Line Tools** - `xcode-select --install`

## Project Structure

```
Vault-2D/
├── Package.swift           # Swift package manifest
├── Makefile               # Build automation
├── Sources/Vault-2D/     # Swift source code
│   ├── Vault-2D.swift    # GDExtension entry point
│   ├── Scenes/           # Game scenes (GameMain, GameWorld)
│   └── UI/               # UI components
└── Godot/                 # Godot project
    ├── project.godot     # Godot project config
    ├── bin/              # Built Swift library
    │   └── Vault-2D.gdextension
    └── scenes/           # Godot scene files
```

## Building

### Quick Start

```bash
cd Vault-2D

# Build and install
make

# Open in Godot
make run
```

### Manual Build

```bash
# Build release
swift build -c release

# Copy library to Godot project
cp .build/release/libVault-2D.dylib Godot/bin/
```

## How It Works

1. **SwiftGodot** compiles Swift code into a dynamic library (.dylib)
2. **GDExtension** configuration tells Godot where to find the library
3. Godot loads the library and registers Swift classes as native nodes
4. Swift classes (GameMain, GameWorld, etc.) become available in Godot

## Shared GameLogic

This package depends on the shared `GameLogic` package which provides:

- TODO 1
- TODO 2
- TODO 3
- TODO 4

Both the Telegram bot and SwiftGodot versions use the same game logic.

## Development

### Adding New Swift Classes

1. Create the class in `Sources/Vault-2D/`
2. Add `@Godot` macro and inherit from Godot node type
3. Register in `Vault-2D.swift` `#initSwiftExtension`
4. Rebuild with `make`

### Debugging

```bash
# Build debug version
make debug

# Check for Swift errors
swift build 2>&1 | head -50
```

## Troubleshooting

### "Library not found"
- Ensure `.dylib` is in `Godot/bin/`
- Check `Vault-2D.gdextension` paths

### "Symbol not found"
- Rebuild Swift package: `make clean && make`
- Check Swift version compatibility

### Godot crashes on load
- Check Godot console for errors
- Verify SwiftGodot version matches Godot version
