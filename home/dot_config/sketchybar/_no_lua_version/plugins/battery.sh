#!/usr/bin/env bash

source "$CONFIG_DIR/colors.sh"

# Get battery percentage
PERCENTAGE=$(pmset -g batt | grep -Eo "\d+%" | cut -d% -f1)

# Get charging status
CHARGING=$(pmset -g batt | grep "AC Power")

if [[ $CHARGING != "" ]]; then
  ICON="🔌"
else
  ICON="🔋"
fi

# Format the output
sketchybar --set $NAME label="$ICON $PERCENTAGE%"