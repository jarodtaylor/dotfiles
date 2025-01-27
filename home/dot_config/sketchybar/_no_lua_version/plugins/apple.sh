#!/usr/bin/env bash

source "$CONFIG_DIR/colors.sh"

# Get the current Apple menu item
APPLE_MENU=$(osascript -e 'tell application "System Events" to return name of menu bar item 1 of menu bar 1')

sketchybar --set $NAME label="$APPLE_MENU" 