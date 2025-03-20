FROM debian:stable-slim
LABEL author="KhraD"

# Noninteractive
RUN dpkg-reconfigure debconf --frontend=noninteractive

RUN apt-get update && apt-get install -y --no-install-recommends\
    ca-certificates \
    git \
    git-lfs \
    python3 \
    python3-openssl \
    curl \
    gpg \
    adb \
    wine64 \
    osslsigncode \
    build-essential \
    scons \
    pkg-config \
    libx11-dev \
    libxcursor-dev \
    libxinerama-dev \
    libgl1-mesa-dev \
    libglu1-mesa-dev \
    libasound2-dev \
    libpulse-dev \
    libudev-dev \
    libxi-dev \
    libxrandr-dev \
    libwayland-dev \
    yasm \
    clang \
    && rm -rf /var/lib/apt/lists/*

#java
ENV JAVA_HOME=/opt/java/openjdk
COPY --from=eclipse-temurin:17-noble $JAVA_HOME $JAVA_HOME
ENV PATH="${JAVA_HOME}/bin:${PATH}"

#.net
ENV DOTNET_ROOT=/usr/share/dotnet
COPY --from=mcr.microsoft.com/dotnet/sdk:9.0-noble $DOTNET_ROOT $DOTNET_ROOT
ENV PATH="${DOTNET_ROOT}:${PATH}"

#butler
RUN mkdir -p /opt/butler/bin \
    && cd /opt/butler/bin \
    && curl -sL https://broth.itch.ovh/butler/linux-amd64/LATEST/archive/default | jar -x \
    && chmod +x butler
ENV PATH="/opt/butler/bin:${PATH}"    

#godot
ARG GODOT_VERSION="4.4"
ARG GODOT_TEST_ARGS=""

ENV GODOT_BASE_PULL_URI="https://github.com/godotengine/godot/releases/download"

RUN mkdir -p /opt/godot/base/gradle/build \
    && mkdir -p /opt/godot/mono/gradle/build \
    && ln -sf /opt/godot/base/gradle /opt/godot/gradle  \
    && mkdir -p /root/.local/share/godot/export_templates/${GODOT_VERSION}.stable \
    && mkdir -p /root/.local/share/godot/export_templates/${GODOT_VERSION}.stable.mono \
    && cd /opt/godot/base \
    && curl -sL ${GODOT_BASE_PULL_URI}/${GODOT_VERSION}-stable/Godot_v${GODOT_VERSION}-stable_linux.x86_64.zip | jar -x \
    && curl -sL ${GODOT_BASE_PULL_URI}/${GODOT_VERSION}-stable/Godot_v${GODOT_VERSION}-stable_export_templates.tpz | jar -x \
    && cp ./templates/android_source.zip /opt/godot/base/gradle/build \
	&& cd /opt/godot/base/gradle \
	&& echo "${GODOT_VERSION}.stable" > .build_version \
	&& cd build \
    && jar -xf android_source.zip \
    && rm android_source.zip \
    && chmod +x gradlew \
    && cd /opt/godot/mono \
    && curl -sL ${GODOT_BASE_PULL_URI}/${GODOT_VERSION}-stable/Godot_v${GODOT_VERSION}-stable_mono_linux_x86_64.zip | jar -x \
    && curl -sL ${GODOT_BASE_PULL_URI}/${GODOT_VERSION}-stable/Godot_v${GODOT_VERSION}-stable_mono_export_templates.tpz | jar -x \
    && cp ./templates/android_source.zip /opt/godot/mono/gradle/build \
    && cd /opt/godot/mono/gradle \
    && echo "${GODOT_VERSION}.stable.mono" > .build_version \
    && cd build \
    && jar -xf android_source.zip \
    && rm android_source.zip \
    && chmod +x gradlew \
    && mv /opt/godot/base/templates/* /root/.local/share/godot/export_templates/${GODOT_VERSION}.stable \
    && mv /opt/godot/mono/templates/* /root/.local/share/godot/export_templates/${GODOT_VERSION}.stable.mono \
    && cp -r /opt/godot/mono/Godot_v${GODOT_VERSION}-stable_mono_linux_x86_64/GodotSharp /usr/local/bin/GodotSharp \
    && update-alternatives --install /usr/local/bin/godot godot /opt/godot/base/Godot_v${GODOT_VERSION}-stable_linux.x86_64 10 \
    && update-alternatives --install /usr/local/bin/godot godot /opt/godot/mono/Godot_v${GODOT_VERSION}-stable_mono_linux_x86_64/Godot_v${GODOT_VERSION}-stable_mono_linux.x86_64 9 \
    && chmod +x /opt/godot/base/Godot_v${GODOT_VERSION}-stable_linux.x86_64 \
    && chmod +x /opt/godot/mono/Godot_v${GODOT_VERSION}-stable_mono_linux_x86_64/Godot_v${GODOT_VERSION}-stable_mono_linux.x86_64

# Download and set up Android SDK to export to Android.
ENV ANDROID_SDK_ROOT="/usr/lib/android-sdk"
ENV ANDROID_HOME="/usr/lib/android-sdk"

RUN mkdir -p /tmp/cmdline-tools \
    && cd /tmp/cmdline-tools \
    && curl -sL https://dl.google.com/android/repository/commandlinetools-linux-11076708_latest.zip | jar -x \
    && mv /tmp/cmdline-tools/cmdline-tools /tmp/cmdline-tools/latest \
    && mv /tmp/cmdline-tools/ $ANDROID_SDK_ROOT/ \
    && chmod +x $ANDROID_SDK_ROOT/cmdline-tools/latest/bin/*

ENV PATH="${ANDROID_SDK_ROOT}/cmdline-tools/latest/bin:${PATH}"

# Android Args
ARG ANDROID_CMAKE_VERSION="3.10.2.4988404"
ARG ANDROID_NDK_VERSION="23.2.8568313"
ARG ANDROID_BUILD_TOOLS_VERSION="34.0.0"
ARG ANDROID_PLATFORM_VERSION="34"

RUN yes | sdkmanager --licenses \
    && sdkmanager "platform-tools" "build-tools;$ANDROID_BUILD_TOOLS_VERSION" "platforms;android-$ANDROID_PLATFORM_VERSION" "cmdline-tools;latest" "cmake;$ANDROID_CMAKE_VERSION" "ndk;$ANDROID_NDK_VERSION" --sdk_root=$ANDROID_SDK_ROOT \
    && rm -r ${ANDROID_SDK_ROOT}/cmdline-tools/latest \
    && rm -r ${ANDROID_SDK_ROOT}/platform-tools \
    && mv ${ANDROID_SDK_ROOT}/cmdline-tools/latest-2 ${ANDROID_SDK_ROOT}/cmdline-tools/latest \
    && mv ${ANDROID_SDK_ROOT}/platform-tools-2 ${ANDROID_SDK_ROOT}/platform-tools \
    && sdkmanager --update    

# Add Android keystore and settings.
RUN keytool -keyalg RSA -genkeypair -alias androiddebugkey -keypass android -keystore debug.keystore -storepass android -dname "CN=Android Debug,O=Android,C=US" -validity 9999 \
    && mv debug.keystore /root/debug.keystore

RUN godot -v -e --quit --headless ${GODOT_TEST_ARGS}

RUN curl -sL -o /opt/rcedit/rcedit.exe --create-dirs https://github.com/electron/rcedit/releases/download/v2.0.0/rcedit-x64.exe \
    && chmod +x /opt/rcedit/rcedit.exe \
    && echo 'export/windows/rcedit = "/opt/rcedit/rcedit.exe"' >> ~/.config/godot/editor_settings-${GODOT_VERSION}.tres \
    && echo 'export/windows/wine = "/usr/lib/wine/wine64"' >> ~/.config/godot/editor_settings-${GODOT_VERSION}.tres \
    && echo 'export/android/java_sdk_path = "'${JAVA_HOME}'"' >> ~/.config/godot/editor_settings-${GODOT_VERSION}.tres \
    && echo 'export/android/android_sdk_path = "/usr/lib/android-sdk"' >> ~/.config/godot/editor_settings-${GODOT_VERSION}.tres \
    && echo 'export/android/debug_keystore = "/root/debug.keystore"' >> ~/.config/godot/editor_settings-${GODOT_VERSION}.tres \
    && echo 'export/android/debug_keystore_user = "androiddebugkey"' >> ~/.config/godot/editor_settings-${GODOT_VERSION}.tres \
    && echo 'export/android/debug_keystore_pass = "android"' >> ~/.config/godot/editor_settings-${GODOT_VERSION}.tres \
    && echo 'export/android/force_system_user = false' >> ~/.config/godot/editor_settings-${GODOT_VERSION}.tres \
    && echo 'export/android/timestamping_authority_url = ""' >> ~/.config/godot/editor_settings-${GODOT_VERSION}.tres \
    && echo 'export/android/shutdown_adb_on_exit = true' >> ~/.config/godot/editor_settings-${GODOT_VERSION}.tres
    
# LLVM Toolchain
RUN curl -sL -o /opt/llvm-mingw/llvm-mingw.tar.xz --create-dirs $(curl -s "https://api.github.com/repos/mstorsjo/llvm-mingw/releases/latest" | grep -E "browser_download_url(.)*ucrt-ubuntu(.)*x86_64" | cut -d '"' -f 4) \
    && cd /opt/llvm-mingw \
    && tar -xf /opt/llvm-mingw/* \
    && ln -sF $(ls | grep -v tar) current

RUN mkdir -p /var/opt/proj

WORKDIR /var/opt/proj
