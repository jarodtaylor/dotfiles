#!/usr/bin/env bash

# Toggle mute state
osascript -e 'set volume output muted (not output muted of (get volume settings))'

# Force update of the volume item
$PLUGIN_DIR/volume.sh