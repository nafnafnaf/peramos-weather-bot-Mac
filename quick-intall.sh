#!/bin/bash

# Quick Install Script - Downloads and runs the main installer
# Users can run this with:
# curl -sSL https://raw.githubusercontent.com/YOUR_USERNAME/peramos-weather-bot/main/quick-install.sh | bash

echo "🚀 Downloading Peramos Weather Bot installer..."

# Download and run the main installation script
curl -sSL https://raw.githubusercontent.com/YOUR_USERNAME/peramos-weather-bot/main/install.sh -o install-peramos-bot.sh
chmod +x install-peramos-bot.sh
./install-peramos-bot.sh

# Clean up
rm install-peramos-bot.sh