#!/bin/bash

# URL of the Android Studio installer
ANDROID_STUDIO_URL="https://redirector.gvt1.com/edgedl/android/studio/install/2024.2.1.12/android-studio-2024.2.1.12-windows.exe"

# Download directory
DOWNLOAD_DIR="$HOME/Downloads"

# Create the download directory if it doesn't exist
mkdir -p "$DOWNLOAD_DIR"

# Download the Android Studio installer
echo "Downloading Android Studio installer..."
wget -O "$DOWNLOAD_DIR/android-studio-2024.2.1.12-windows.exe" "$ANDROID_STUDIO_URL"

# Install prerequisite packages
echo "Installing prerequisite packages for Android Studio..."
sudo apt-get update
sudo apt-get install -y libc6:amd64 libstdc++6:amd64 lib32z1 libbz2-1.0:amd64

echo "Download and installation of prerequisite packages completed."