#!/usr/bin/env bash

VOLUME=$(osascript -e 'output volume of (get volume settings)')

case "$SENDER" in
    "mouse.scrolled.up")
        NEW_VOLUME=$((VOLUME + 5))
        if [ $NEW_VOLUME -gt 100 ]; then
            NEW_VOLUME=100
        fi
        ;;
    "mouse.scrolled.down")
        NEW_VOLUME=$((VOLUME - 5))
        if [ $NEW_VOLUME -lt 0 ]; then
            NEW_VOLUME=0
        fi
        ;;
esac

osascript -e "set volume output volume $NEW_VOLUME"

# Force update of the volume item
$PLUGIN_DIR/volume.sh