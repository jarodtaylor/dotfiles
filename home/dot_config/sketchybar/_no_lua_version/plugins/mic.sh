#!/usr/bin/env bash

source "$CONFIG_DIR/colors.sh"

# Get input volume and mute status
INPUT_VOLUME=$(osascript -e 'input volume of (get volume settings)')
INPUT_MUTED=$(osascript -e 'input muted of (get volume settings)')

if [ "$INPUT_MUTED" = "true" ] || [ "$INPUT_VOLUME" = "0" ]; then
    ICON="󰍭" # Muted mic icon
else
    ICON="󰍬" # Unmuted mic icon
fi

sketchybar --set $NAME label="$ICON"