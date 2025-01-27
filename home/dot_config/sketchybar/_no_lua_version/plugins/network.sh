#!/usr/bin/env bash

source "$CONFIG_DIR/colors.sh"

# Function to get WiFi signal strength (0-100)
get_wifi_strength() {
    /System/Library/PrivateFrameworks/Apple80211.framework/Versions/Current/Resources/airport -I | grep "CtlRSSI" | awk '{print $(NF)}' | awk '{strength=($1+100)*100/70; print int(strength)}'
}

# Check for ethernet connection first
if [[ -n $(ifconfig en1 2>/dev/null | grep "status: active") ]]; then
    ICON="" # Ethernet icon
    LABEL="Ethernet"
else
    # Check if Wi-Fi is turned on
    WIFI_STATUS=$(networksetup -getairportpower en0 | awk '{ print $4 }')

    if [ "$WIFI_STATUS" = "On" ]; then
        # Get Wi-Fi information
        WIFI_NAME=$(networksetup -getairportnetwork en0 | cut -c 24-)
        if [ "$WIFI_NAME" = "" ]; then
            ICON="󰖪" # Disconnected WiFi icon
            LABEL="Disconnected"
        else
            # Get signal strength and set appropriate icon
            STRENGTH=$(get_wifi_strength)
            if [ $STRENGTH -gt 70 ]; then
                ICON="󰤨" # High signal
            elif [ $STRENGTH -gt 30 ]; then
                ICON="󰤥" # Medium signal
            else
                ICON="󰤯" # Low signal
            fi
            LABEL="$WIFI_NAME"
        fi
    else
        ICON="󰖪" # Disconnected WiFi icon
        LABEL="Disabled"
    fi
fi

sketchybar --set $NAME label="$ICON $LABEL"