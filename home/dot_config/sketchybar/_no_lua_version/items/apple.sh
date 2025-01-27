#!/usr/bin/env bash

source "$CONFIG_DIR/colors.sh"

sketchybar --add item apple left \
  --set apple \
    icon="􀣺" \
    icon.font="SF Pro:Bold:16.0" \
    icon.color="$GREEN" \
    icon.padding_left=5 \
    icon.padding_right=5 \
    icon.drawing=on \
    background.drawing=on \
    background.corner_radius=5 \
    padding_left=5 \
    padding_right=5 \
    label.drawing=off 