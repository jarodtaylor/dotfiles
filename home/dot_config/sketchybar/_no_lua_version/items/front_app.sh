#!/usr/bin/env bash

sketchybar --add item front_app_spacer_left left \
  --set front_app_spacer_left \
  background.drawing=off

sketchybar --add item front_app left \
  --subscribe front_app front_app_switched \
  --set front_app \
  background.drawing=on \
  background.color="$FRONT_APP_BG" \
  label.color="$FRONT_APP_TEXT" \
  background.corner_radius=12 \
  label.padding_left=5 \
  label.padding_right=5 \
  script="$PLUGIN_DIR/front_app.sh"

sketchybar --add item front_app_spacer_right left \
  --set front_app_spacer_right \
  background.drawing=off

sketchybar --add bracket front_app_bracket front_app_spacer_left front_app front_app_spacer_right \
  --set front_app_bracket \
  background.border_color="$GREEN"
