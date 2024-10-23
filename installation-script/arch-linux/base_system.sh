#!/bin/bash

echo "Running base system install"

echo "Checking CPU"

install_intel_microcode (){
	echo "Intel CPU detected"
	echo "Installing intel-ucode"
	sudo pacman -Syu intel-ucode
	echo "Intel microcode installed."
}

install_amd_microcode (){
	echo "AMD CPU detected"
	echo "Installing amd-ucode"
	sudo pacman -Syu amd-ucode
	echo "AMD microcode installed."
}

cpu_info=$(lscpu)

if echo "$cpu_info" | grep -q "Intel"; then
    install_intel_microcode
elif echo "$cpu_info" | grep -q "AMD"; then
    install_amd_microcode
else
    echo "Unsupported CPU type or unable to detect CPU."
    exit 1
fi


