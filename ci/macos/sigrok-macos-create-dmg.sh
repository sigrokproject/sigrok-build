#!/bin/sh
##
## This file is part of the sigrok-util project.
##
## Copyright (C) 2017 Uwe Hermann <uwe@hermann-uwe.de>
## Copyright (C) 2021-2023 Frank Stettner <frank-stettner@gmx.net>
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

# NOTE: $TARGET, $BREW_QT_VERSION, $BREW_PYTHON_VERSION, $ARTIFACT_* are defined
#       as environment variables in the github workflow yml

set -e
set -x

# Path to Qt5 binaries
QT_BIN_DIR=$(brew list "$BREW_QT_VERSION" | grep bin | head -n 1 | xargs dirname)
QT_TRANSLATIONS_DIR=$(brew --prefix "$BREW_QT_VERSION")/translations

# Path to Python 3 framework
PYTHON_FRAMEWORK_DIR=$(brew list "$BREW_PYTHON_VERSION" | grep Python.framework/Python | head -n 1 | xargs dirname)
PYTHON_PREFIX_DIR=$(brew --prefix "$BREW_PYTHON_VERSION")

# Get Python version
PYTHON_VERSION=$(python3 -c 'import sys; print(".".join(map(str, sys.version_info[0:2])))')

DMG_BUILD_DIR=./build_dmg
mkdir $DMG_BUILD_DIR
cd $DMG_BUILD_DIR

CONTENTS_DIR="$ARTIFACT_TITLE.app/Contents"
MACOS_DIR="$CONTENTS_DIR/MacOS"
FRAMEWORKS_DIR="$CONTENTS_DIR/Frameworks"
SHARE_DIR="$CONTENTS_DIR/share"
PYTHON_DIR="$FRAMEWORKS_DIR/Python.framework/Versions/$PYTHON_VERSION"

mkdir -p $MACOS_DIR $FRAMEWORKS_DIR $SHARE_DIR

# Copy executable
cp "$INSTALL_DIR"/bin/$ARTIFACT_BIN_NAME $MACOS_DIR
# Copy and cleanup decoders
cp -R "$INSTALL_DIR"/share/libsigrokdecode $SHARE_DIR
rm -rf $SHARE_DIR/libsigrokdecode/decoders/**/__pycache__
rm -rf $SHARE_DIR/libsigrokdecode/decoders/common/**/__pycache__
# Copy firmware
cp -R "$INSTALL_DIR"/share/sigrok-firmware $SHARE_DIR

if [ "$ARTIFACT_BIN_NAME" = "pulseview" ]; then
	# Copy translations ("macdeployqt" won't copy them).
	mkdir -p $CONTENTS_DIR/translations
	cp "$QT_TRANSLATIONS_DIR"/qt_*.qm $CONTENTS_DIR/translations
	cp "$QT_TRANSLATIONS_DIR"/qtbase_*.qm $CONTENTS_DIR/translations

	# Copy some boost libs that "macdeployqt" won't copy.
	# cp $BOOSTLIBDIR/libboost_timer-mt.dylib $FRAMEWORKS_DIR
	# cp $BOOSTLIBDIR/libboost_chrono-mt.dylib $FRAMEWORKS_DIR
	# chmod 644 $FRAMEWORKS_DIR/*boost*
fi

"$QT_BIN_DIR"/macdeployqt $ARTIFACT_TITLE.app

# Copy Python framework and fix it up.
cp -R "$PYTHON_FRAMEWORK_DIR" $FRAMEWORKS_DIR
chmod 644 "$PYTHON_DIR"/lib/libpython*.dylib
rm -rf "$PYTHON_DIR"/Headers
rm -rf "$PYTHON_DIR"/bin
rm -rf "$PYTHON_DIR"/include
rm -rf "$PYTHON_DIR"/share
rm -rf "$PYTHON_DIR"/lib/pkgconfig
rm -rf "$PYTHON_DIR"/lib/python$PYTHON_VERSION/lib2to3
rm -rf "$PYTHON_DIR"/lib/python$PYTHON_VERSION/distutils
rm -rf "$PYTHON_DIR"/lib/python$PYTHON_VERSION/idlelib
rm -rf "$PYTHON_DIR"/lib/python$PYTHON_VERSION/test
rm -rf "$PYTHON_DIR"/lib/python$PYTHON_VERSION/**/test
rm -rf "$PYTHON_DIR"/lib/python$PYTHON_VERSION/tkinter
rm -rf "$PYTHON_DIR"/lib/python$PYTHON_VERSION/turtledemo
rm -rf "$PYTHON_DIR"/lib/python$PYTHON_VERSION/unittest
rm -rf "$PYTHON_DIR"/lib/python$PYTHON_VERSION/__pycache__
rm -rf "$PYTHON_DIR"/lib/python$PYTHON_VERSION/**/__pycache__
rm -rf "$PYTHON_DIR"/lib/python$PYTHON_VERSION/**/**/__pycache__
rm -rf "$PYTHON_DIR"/Resources

# Replace paths
install_name_tool -change \
	"$PYTHON_PREFIX_DIR"/Frameworks/Python.framework/Versions/$PYTHON_VERSION/Python \
	@executable_path/../Frameworks/Python.framework/Versions/$PYTHON_VERSION/Python \
	$FRAMEWORKS_DIR/libsigrokdecode.*.dylib

# Add wrapper for executable (sets PYTHONHOME/SIGROK_FIRMWARE_DIR/SIGROKDECODE_DIR).
mv $MACOS_DIR/$ARTIFACT_BIN_NAME $MACOS_DIR/$ARTIFACT_BIN_NAME.real
cat > $MACOS_DIR/$ARTIFACT_BIN_NAME << EOF
#!/bin/sh

DIR="\$(dirname "\$0")"
cd "\$DIR"
export PYTHONHOME="../Frameworks/Python.framework/Versions/$PYTHON_VERSION"
export SIGROK_FIRMWARE_PATH="\$SIGROK_FIRMWARE_PATH":../share/sigrok-firmware
export SIGROKDECODE_PATH="\$SIGROKDECODE_PATH":../share/libsigrokdecode/decoders
exec ./$ARTIFACT_BIN_NAME.real "\$@"
EOF
chmod 755 $MACOS_DIR/$ARTIFACT_BIN_NAME

xsltproc --stringparam VERSION "${ARTIFACT_VERSION}" -o $CONTENTS_DIR/Info.plist \
	../contrib-macos/Info-${ARTIFACT_BIN_NAME}.xslt ../contrib-macos/Info-${ARTIFACT_BIN_NAME}.plist
cp ../contrib-macos/${ARTIFACT_BIN_NAME}.icns $CONTENTS_DIR/Resources

hdiutil create "${ARTIFACT_TITLE}-${ARTIFACT_VERSION}-${TARGET}.dmg" \
	-volname "$ARTIFACT_TITLE $ARTIFACT_VERSION" \
	-fs HFS+ -srcfolder "$ARTIFACT_TITLE.app"

# Move DMG to parent directory, so it is accessible without knowing $DMG_BUILD_DIR
mv "${ARTIFACT_TITLE}-${ARTIFACT_VERSION}-${TARGET}.dmg" ..

