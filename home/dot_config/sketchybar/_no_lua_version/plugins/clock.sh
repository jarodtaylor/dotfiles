#!/usr/bin/env bash

source "$CONFIG_DIR/colors.sh"

# Format: "Mon Jan 15 | 3:04 PM EST"
DATETIME=$(date "+%a %b %d | %I:%M %p %Z")

sketchybar --set $NAME label="$DATETIME"