#!/usr/bin/env bash

source "$CONFIG_DIR/colors.sh"

# Get volume and mute status
VOLUME=$(osascript -e 'output volume of (get volume settings)')
MUTED=$(osascript -e 'output muted of (get volume settings)')

if [ "$MUTED" = "true" ] || [ "$VOLUME" = "0" ]; then
    ICON="󰝟" # Muted
elif [ "$VOLUME" -gt 66 ]; then
    ICON="󰕾" # High volume
elif [ "$VOLUME" -gt 33 ]; then
    ICON="󰖀" # Medium volume
else
    ICON="󰕿" # Low volume
fi

# Only show volume number if not muted
if [ "$MUTED" = "true" ]; then
    LABEL="$ICON"
else
    LABEL="$ICON ${VOLUME}%"
fi

sketchybar --set $NAME label="$LABEL"