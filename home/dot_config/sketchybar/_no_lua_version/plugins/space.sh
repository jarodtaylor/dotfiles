#!/usr/bin/env bash

source "$CONFIG_DIR/colors.sh"

if [ "$1" = "$FOCUSED_WORKSPACE" ]; then
  sketchybar --set $NAME \
    background.drawing=on \
    background.color="$ACTIVE_WORKSPACE_BG" \
    label.color="$ACTIVE_WORKSPACE_TEXT"
else
  sketchybar --set $NAME \
    background.drawing=off \
    label.color="$LABEL_COLOR"
fi
