BINARY_NAME = apple_menu
SWIFT_PRODUCT = AppleMenu

# Source layout is a Swift Package (Package.swift + Sources/AppleMenu/...),
# so build via `swift build` rather than a flat swiftc invocation.
# The SPM product is `AppleMenu`; we copy it to bin/apple_menu so the
# Lua items (which reference bin/apple_menu) keep working.
all: bin/$(BINARY_NAME)

bin/$(BINARY_NAME): | bin
	swift build -c release
	cp .build/release/$(SWIFT_PRODUCT) $@

bin:
	mkdir -p $@

clean:
	rm -rf bin .build

.PHONY: all clean
