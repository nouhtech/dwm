#!/bin/bash

# Install yay if not already installed
if ! command -v yay &> /dev/null; then
    git clone https://aur.archlinux.org/yay.git /tmp/yay
    cd /tmp/yay
    makepkg -si --noconfirm
    cd -
fi

# Install prerequisites
sudo pacman -Sy --needed dash imlib2 xorg-xsetroot jetbrains-mono-nerd-font-mono

# Install packages using yay
yay -S --noconfirm picom feh acpi rofi

# Clone ChadWM repository
git clone https://github.com/siduck/chadwm --depth 1 ~/.config/chadwm
cd ~/.config/chadwm

# Move eww directory
mv eww ~/.config

# Install ChadWM
cd chadwm
sudo make install

# Set executable permissions for scripts
chmod +x ~/.config/chadwm/scripts/*

# Set up autostart for ChadWM
echo "#!/bin/sh" > ~/.config/chadwm/scripts/run.sh
chmod +x ~/.config/chadwm/scripts/run.sh

# Alias for ChadWM
echo "alias chadwm='startx ~/.config/chadwm/scripts/run.sh'" >> ~/.bashrc

# Create desktop entry for Display Manager
sudo tee /usr/share/xsessions/chadwm.desktop > /dev/null <<EOF
[Desktop Entry]
Name=ChadWM
Comment=dwm made beautiful
Exec=/home/$(whoami)/.config/chadwm/scripts/run.sh
Type=Application
EOF

# Recompile dwm after changes
cd ~/.config/chadwm/chadwm
rm config.h
sudo make install

# Change themes in relevant files
# Make necessary adjustments here

# Copy eww directory to config
cp -r ~/.config/chadwm/eww ~/.config/

# Add eww launch command to autostart
echo "eww open eww" >> ~/.config/chadwm/scripts/run.sh

# Output completion message
echo "ChadWM installation completed successfully."
