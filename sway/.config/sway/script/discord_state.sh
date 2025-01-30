#!/bin/bash

if pgrep "Discord" > /dev/null; then
  echo '{"text": "", "class": "discord-running"}'
else 
  echo '{"text": "", "class": "discord-not-running"}'
fi
