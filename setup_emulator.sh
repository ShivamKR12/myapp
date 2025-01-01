#!/bin/bash

# Step 1: Update system packages
echo "Updating system packages..."
sudo apt-get update -y

# Step 2: Install required packages
echo "Installing required packages..."
sudo apt-get install -y libasyncns0 libvorbisenc2 libxkbfile1 libflac8 libpulse0 libsndfile1 openjdk-11-jdk unzip wget

# Step 3: Check if Android SDK exists, if not, download it
ANDROID_HOME="/home/codespace/android-sdk"
if [ ! -d "$ANDROID_HOME" ]; then
    echo "Android SDK not found, downloading..."
    wget https://dl.google.com/android/repository/commandlinetools-linux-7302050_latest.zip -O android_sdk.zip
    unzip -q android_sdk.zip -d /home/codespace/
    mv /home/codespace/cmdline-tools /home/codespace/android-sdk
    rm android_sdk.zip
    echo "Android SDK downloaded and extracted to $ANDROID_HOME"
fi

# Step 4: Set environment variables
echo "Setting environment variables..."
export ANDROID_SDK_ROOT=$ANDROID_HOME
export ANDROID_HOME=$ANDROID_HOME

# Step 5: Accept Android SDK licenses
echo "Accepting Android SDK licenses..."
yes | $ANDROID_HOME/cmdline-tools/latest/bin/sdkmanager --licenses

# Step 6: Install missing SDK components (platform-tools, platforms, system-images)
echo "Installing necessary SDK packages..."
$ANDROID_HOME/cmdline-tools/latest/bin/sdkmanager "platform-tools" "platforms;android-33" "system-images;android-33;google_apis;x86_64"

# Step 7: Check if AVD already exists, and if so, delete it
echo "Checking if AVD exists..."
AVD_NAME="myEmulator"
$ANDROID_HOME/cmdline-tools/latest/bin/avdmanager list avd | grep -q "$AVD_NAME"
if [ $? -eq 0 ]; then
    echo "AVD '$AVD_NAME' already exists. Deleting..."
    $ANDROID_HOME/cmdline-tools/latest/bin/avdmanager delete avd --name "$AVD_NAME"
fi

# Step 8: Create AVD
echo "Creating AVD..."
$ANDROID_HOME/cmdline-tools/latest/bin/avdmanager create avd --name "$AVD_NAME" --package "system-images;android-33;google_apis;x86_64" --force

# Step 9: Start the emulator
echo "Starting the emulator..."
$ANDROID_HOME/emulator/emulator -avd "$AVD_NAME" -no-snapshot -gpu host

echo "Android Emulator setup is complete!"
