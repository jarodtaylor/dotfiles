#!/usr/bin/env bash

source "$CONFIG_DIR/colors.sh"

if [ "$SENDER" = "front_app_switched" ] && [ ! -z "$INFO" ]; then
  # You can customize how the app name is displayed here
  APP_NAME="$INFO"
  
  sketchybar --set "$NAME" \
    label="$APP_NAME" \
    label.color="$FRONT_APP_LABEL_COLOR"
fi
