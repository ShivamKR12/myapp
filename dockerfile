# Use a base image with Java installed
FROM openjdk:11

# Install necessary packages
RUN apt-get update && \
    apt-get install -y wget unzip lib32stdc++6 lib32z1 qemu-kvm libvirt-daemon-system libvirt-clients bridge-utils && \
    apt-get clean

# Download and install Android SDK
RUN wget https://dl.google.com/android/repository/commandlinetools-linux-7583922_latest.zip -O /tmp/cmdline-tools.zip && \
    mkdir -p /sdk/cmdline-tools && \
    unzip /tmp/cmdline-tools.zip -d /sdk/cmdline-tools && \
    rm /tmp/cmdline-tools.zip

# Set environment variables
ENV ANDROID_HOME=/sdk
ENV PATH=$ANDROID_HOME/cmdline-tools/bin:$PATH
ENV PATH=$ANDROID_HOME/platform-tools:$PATH
ENV PATH=$ANDROID_HOME/emulator:$PATH

# Install Android SDK components
RUN yes | sdkmanager --licenses && \
    sdkmanager "platform-tools" "platforms;android-30" "build-tools;30.0.3" "emulator" "system-images;android-30;google_apis;x86_64"

# Create and start the Android emulator
RUN echo "no" | avdmanager create avd -n test -k "system-images;android-30;google_apis;x86_64" -d "pixel" --force

# Expose necessary ports for emulator
EXPOSE 5554 5555 5556 5557

# Start the emulator
CMD ["emulator", "-avd", "test", "-no-window", "-no-boot-anim", "-gpu", "swiftshader_indirect"]docker 