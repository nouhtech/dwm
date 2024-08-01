#!/bin/bash

echo "Choose an option:"
echo "1. Start SDDM"
echo "2. Start dwm directly with startx"

read -p "Enter your choice (1 or 2): " choice

case $choice in
    1)
        # Install SDDM and its default display manager
        echo "Installing SDDM and its default display manager..."
        sudo pacman -S --needed --noconfirm sddm sddm-kcm

        # Enable and start SDDM service
        echo "Enabling and starting SDDM service..."
        sudo systemctl enable sddm.service
        sudo systemctl start sddm.service

        echo "SDDM has been installed and activated."
        ;;
    2)
        echo "Starting dwm with startx..."
        startx ~/.config/chadwm/scripts/run.sh
        ;;
    *)
        echo "Invalid choice. Exiting..."
        ;;
esac
