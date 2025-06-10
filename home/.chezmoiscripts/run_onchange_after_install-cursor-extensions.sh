#!/bin/bash

# Install Cursor extensions from the extensions list
# This script runs once when chezmoi apply is executed

EXTENSIONS_FILE="$HOME/.config/Code/User/extensions-list.txt"

# Check if Cursor is installed
if ! command -v cursor >/dev/null 2>&1; then
    echo "Cursor is not installed or not in PATH. Skipping extension installation."
    exit 0
fi

# Check if extensions file exists
if [ ! -f "$EXTENSIONS_FILE" ]; then
    echo "Extensions file not found at $EXTENSIONS_FILE"
    exit 1
fi

echo "Installing Cursor extensions..."

# Read extensions file and install each extension
while IFS= read -r line; do
    # Skip empty lines and comments
    if [[ -z "$line" || "$line" =~ ^#.*$ ]]; then
        continue
    fi
    
    echo "Installing extension: $line"
    cursor --install-extension "$line" --force
done < "$EXTENSIONS_FILE"

echo "Cursor extensions installation completed!" 