#!/usr/bin/env bash

source "$CONFIG_DIR/colors.sh"

sketchybar --add item clock right \
  --set clock \
    update_freq=1 \
    background.drawing=on \
    background.color="$FRONT_APP_BG" \
    label.color="$FRONT_APP_TEXT" \
    background.corner_radius=5 \
    label.padding_left=5 \
    label.padding_right=5 \
    script="$PLUGIN_DIR/clock.sh"