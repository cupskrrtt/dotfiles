#!/bin/bash

# Find the correct Firefox instance running Apple Music
player=$(playerctl -l | grep "firefox" | while read line; do
    if playerctl -p "$line" metadata 2>/dev/null | grep -q "music.apple.com"; then
        echo "$line"
        break
    fi
done)

# If no player is found, exit
if [ -z "$player" ]; then
    echo '{"text": "No Music", "tooltip": "Apple Music not detected"}'
    exit 0
fi

# If a command (play, next, prev) is passed, execute it
if [ "$1" ]; then
    playerctl -p "$player" "$1"
    exit 0
fi

# Otherwise, just display the currently playing song
metadata=$(playerctl -p "$player" metadata --format '{"text": "{{title}}", "tooltip": "{{album}} - {{artist}}"}')
echo "$metadata"
