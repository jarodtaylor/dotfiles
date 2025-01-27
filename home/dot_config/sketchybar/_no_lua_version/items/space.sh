#!/usr/bin/env bash

sketchybar --add event aerospace_workspace_change

# Add monitor indicator first
sketchybar --add item monitor.5 left \
  --set monitor.5 \
  label="󰍹 5" \
  background.height=24 \
  width=32 \
  background.corner_radius=12 \
  label.font="$FONT:Bold:12.0" \
  label.y_offset=0 \
  click_script="aerospace workspace 5" \
  script="$CONFIG_DIR/plugins/space.sh 5"

# Add separator
sketchybar --add item space.separator left \
  --set space.separator \
  label="|" \
  label.font="$FONT:Bold:12.0" \
  label.color="$OVERLAY0" \
  padding_left=2 \
  padding_right=2

# Add other workspaces
for sid in $(aerospace list-workspaces --all); do
  # Skip monitor space 5
  if [ "$sid" != "5" ]; then
    sketchybar --add item space.$sid left \
      --subscribe space.$sid aerospace_workspace_change \
      --set space.$sid \
      label="$sid" \
      background.height=24 \
      width=24 \
      background.corner_radius=12 \
      label.font="$FONT:Bold:12.0" \
      label.y_offset=0 \
      click_script="aerospace workspace $sid" \
      script="$CONFIG_DIR/plugins/space.sh $sid"
  fi
done
