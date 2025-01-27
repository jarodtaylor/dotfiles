#!/usr/bin/env bash

# Toggle microphone mute state
osascript -e 'set inputVolume to input volume of (get volume settings)
if inputVolume = 0 then
    set volume input volume 100
else
    set volume input volume 0
end if'

# Force update of the mic item
$PLUGIN_DIR/mic.sh