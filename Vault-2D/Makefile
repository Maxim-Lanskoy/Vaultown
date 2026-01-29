# Vault-2D - SwiftGodot Build Configuration
# Builds the Swift GDExtension library for Godot 4

SWIFT_BUILD_FLAGS = --configuration release
LIBRARY_NAME = libVault-2D.dylib
SWIFTGODOT_NAME = libSwiftGodot.dylib
OUTPUT_DIR = Godot/bin

.PHONY: all build debug release clean install fix-rpath

all: release install

# Debug build
debug:
	swift build --configuration debug
	@mkdir -p $(OUTPUT_DIR)
	cp .build/debug/$(LIBRARY_NAME) $(OUTPUT_DIR)/
	cp .build/debug/$(SWIFTGODOT_NAME) $(OUTPUT_DIR)/
	$(MAKE) fix-rpath

# Release build
release:
	swift build $(SWIFT_BUILD_FLAGS)
	@mkdir -p $(OUTPUT_DIR)
	cp .build/release/$(LIBRARY_NAME) $(OUTPUT_DIR)/
	cp .build/release/$(SWIFTGODOT_NAME) $(OUTPUT_DIR)/
	$(MAKE) fix-rpath

# Fix library rpath to find SwiftGodot in same directory
fix-rpath:
	@install_name_tool -change @rpath/$(SWIFTGODOT_NAME) @loader_path/$(SWIFTGODOT_NAME) $(OUTPUT_DIR)/$(LIBRARY_NAME) 2>/dev/null || true
	@echo "Fixed rpath for $(LIBRARY_NAME)"

# Install the library to Godot project
install:
	@echo "Libraries installed to $(OUTPUT_DIR)/"
	@ls -la $(OUTPUT_DIR)/*.dylib

# Clean build artifacts
clean:
	swift package clean
	rm -rf .build
	rm -f $(OUTPUT_DIR)/$(LIBRARY_NAME)
	rm -f $(OUTPUT_DIR)/$(SWIFTGODOT_NAME)

# Run Godot editor with the project
run:
	open -a Godot Godot/project.godot

# Show help
help:
	@echo "Vault-2D SwiftGodot Build System"
	@echo ""
	@echo "Usage: make [target]"
	@echo ""
	@echo "Targets:"
	@echo "  all       - Build release and install (default)"
	@echo "  debug     - Build debug configuration"
	@echo "  release   - Build release configuration"
	@echo "  fix-rpath - Fix library paths for Godot"
	@echo "  install   - Copy libraries to Godot/bin/"
	@echo "  clean     - Remove build artifacts"
	@echo "  run       - Open Godot editor with project"
	@echo "  help      - Show this help message"
