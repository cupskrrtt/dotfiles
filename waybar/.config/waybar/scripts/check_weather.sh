#!/bin/bash

echo "{ \"text\": $(curl -s 'wttr.in/Bekasi?format="%c%C"')}"
