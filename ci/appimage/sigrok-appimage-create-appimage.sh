#!/bin/sh
##
## This file is part of the sigrok-util project.
##
## Copyright (C) 2023 Frank Stettner <frank-stettner@gmx.net>
##
## This program is free software; you can redistribute it and/or modify
## it under the terms of the GNU General Public License as published by
## the Free Software Foundation; either version 2 of the License, or
## (at your option) any later version.
##
## This program is distributed in the hope that it will be useful,
## but WITHOUT ANY WARRANTY; without even the implied warranty of
## MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
## GNU General Public License for more details.
##
## You should have received a copy of the GNU General Public License
## along with this program; if not, see <http://www.gnu.org/licenses/>.
##

set -e

# Generate AppRun.sh scrip
cat > "$INSTALL_DIR"/AppRun.sh << EOF
#! /bin/bash

export PYTHONHOME="\$APPDIR"/usr/share/pyshared
export PYTHONPATH="\$APPDIR"/usr/share/pyshared
export SIGROK_FIRMWARE_PATH="\$SIGROK_FIRMWARE_PATH":"\$APPDIR"/usr/share/sigrok-firmware
export SIGROKDECODE_PATH="\$SIGROKDECODE_PATH":"\$APPDIR"/usr/share/libsigrokdecode/decoders

exec "\$APPDIR"/usr/bin/$ARTIFACT_BIN_NAME "\$@"
EOF
chmod +x "$INSTALL_DIR"/AppRun.sh

# Copy decoders stuff
cp -r "$INSTALL_DIR"/share/libsigrokdecode "$APP_DIR"/usr/share

# Copy sigrok-firmware
cp -r "$INSTALL_DIR"/share/sigrok-firmware "$APP_DIR"/usr/share

# Copy extra Python files
mkdir -p "$APP_DIR"/usr/share/pyshared
cp -r /usr/lib/python3.6/* "$APP_DIR"/usr/share/pyshared

# AppImage build dir
mkdir -p appimage-build
cd appimage-build

# Environment variables
export LD_LIBRARY_PATH="$LD_LIBRARY_PATH":"$INSTALL_DIR"/lib

# Fetch linuxdeploy
wget -c https://github.com/linuxdeploy/linuxdeploy/releases/download/continuous/linuxdeploy-$ARCH.AppImage
chmod +x linuxdeploy-$ARCH.AppImage

PLUGINS=""
if [ "$ARTIFACT_BIN_NAME" = "pulseview" ]; then
    # Fetch qt plugin
    wget -c https://github.com/linuxdeploy/linuxdeploy-plugin-qt/releases/download/continuous/linuxdeploy-plugin-qt-$ARCH.AppImage
    chmod +x linuxdeploy-plugin-qt-$ARCH.AppImage
    PLUGINS="--plugin qt"
fi

export OUTPUT="$ARTIFACT_TITLE-$ARTIFACT_VERSION-$TARGET.AppImage"
./linuxdeploy-$ARCH.AppImage --appdir "$APP_DIR" --output appimage $PLUGINS --custom-apprun "$INSTALL_DIR"/AppRun.sh

