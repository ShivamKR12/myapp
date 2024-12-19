#!/bin/bash

# Update the system
echo "Updating system packages..."
sudo apt update -y

# Install necessary dependencies
echo "Installing required packages..."
sudo apt install -y \
  libpulse0 \
  libxkbfile1 \
  libasyncns0 \
  libflac8 \
  libsndfile1 \
  libvorbisenc2

# Set up Android SDK path if it's not already set
export ANDROID_HOME="/usr/local/android-sdk"
export PATH="$ANDROID_HOME/tools:$ANDROID_HOME/tools/bin:$ANDROID_HOME/platform-tools:$ANDROID_HOME/emulator:$PATH"

# Accept Android SDK licenses
echo "Accepting Android SDK licenses..."
yes | sdkmanager --licenses

# Install emulator and system images if not installed
echo "Installing emulator and system images..."
sdkmanager "system-images;android-33;google_apis;x86_64"
sdkmanager "emulator"

# Create an Android Virtual Device (AVD) if not already created
echo "Creating AVD..."
echo "no" | avdmanager create avd -n myEmulator -k "system-images;android-33;google_apis;x86_64" --device "pixel"

# Run the Android Emulator
echo "Starting the emulator..."
emulator -avd myEmulator
