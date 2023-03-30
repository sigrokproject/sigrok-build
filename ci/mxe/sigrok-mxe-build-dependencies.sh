#!/bin/sh
##
## This file is part of the sigrok-util project.
##
## Copyright (C) 2013-2018 Uwe Hermann <uwe@hermann-uwe.de>
## Copyright (C) 2018-2023 Frank Stettner <frank-stettner@gmx.net>
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

mkdir -p "$INSTALL_DIR"

BUILD_DIR=./build
mkdir -p $BUILD_DIR
cd $BUILD_DIR

# Cross-compiling Python is highly non-trivial, so we avoid it for now.
# The Python32.tar.gz file below is a repackaged tarball of the official
# Python 3.4.4 MSI installer for Windows:
#   - https://www.python.org/ftp/python/3.4.4/python-3.4.4.msi
#   - https://www.python.org/ftp/python/3.4.4/python-3.4.4.amd64.msi
# The MSI file has been installed on a Windows box and then c:\Python34\libs
# and c:\Python34\include have been stored in the Python34_*.tar.gz tarball.
cp ../contrib-mxe/Python34_$TARGET.tar.gz "$INSTALL_DIR"/Python34.tar.gz
tar xzf "$INSTALL_DIR"/Python34.tar.gz -C "$INSTALL_DIR"

# Fix for bug #1195.
if [ "$TARGET" = "x86_64" ]; then
	patch -p1 "$INSTALL_DIR"/Python34/include/pyconfig.h < ../contrib-mxe/pyconfig.patch
fi

# Create a dummy python3.pc file so that pkg-config finds Python 3.
mkdir -p "$INSTALL_DIR"/lib/pkgconfig
cat > "$INSTALL_DIR"/lib/pkgconfig/python3.pc <<EOF
prefix=$INSTALL_DIR
exec_prefix=\${prefix}
libdir=\${exec_prefix}/Python34/libs
includedir=\${prefix}/Python34/include
Name: Python
Description: Python library
Version: 3.4.4
Libs: -L\${libdir} -lpython34
Cflags: -I\${includedir}
EOF

# The python34.dll and python34.zip files will be shipped in the NSIS
# Windows installers (required for PulseView/SmuView Python scripts to work).
# The file python34.dll (NOT the same as python3.dll) is copied from an
# installed Python 3.4.4 (see above) from c:\Windows\system32\python34.dll.
# The file python34.zip contains all files from the 'DLLs', 'Lib', and 'libs'
# subdirectories from an installed Python on Windows (c:\python34), i.e. some
# libraries and all Python stdlib modules.
cp ../contrib-mxe/python34_$TARGET.dll "$INSTALL_DIR"/python34.dll
cp ../contrib-mxe/python34_$TARGET.zip "$INSTALL_DIR"/python34.zip

# In order to link against Python we need libpython34.a.
# The upstream Python 32bit installer ships this, the x86_64 installer
# doesn't. Thus, we generate the file manually here.
if [ "$TARGET" = "x86_64" ]; then
	cp "$INSTALL_DIR"/python34.dll .
	"$MXE_DIR"/usr/$TARGET-w64-mingw32.static.posix/bin/gendef python34.dll
	"$MXE_DIR"/usr/bin/$TARGET-w64-mingw32.static.posix-dlltool \
		--dllname python34.dll --def python34.def \
		--output-lib libpython34.a
	mv -f libpython34.a "$INSTALL_DIR"/Python34/libs
	rm -f python34.dll
fi

# We need to include the *.pyd files from python34.zip into the installers,
# otherwise importing certain modules (e.g. ctypes) won't work (bug #1409).
unzip -q "$INSTALL_DIR"/python34.zip *.pyd -d "$INSTALL_DIR"

# libserialport
$GIT_CLONE $LIBSERIALPORT_REPO libserialport
cd libserialport
./autogen.sh
./configure $C $L
make $PARALLEL $V
make install $V
cd ..

# libsigrok
$GIT_CLONE -b ${LIBSIGROK_BRANCH:-master} $LIBSIGROK_REPO libsigrok
cd libsigrok
./autogen.sh
./configure $C $L
make $PARALLEL $V
make install $V
cd ..

# libsigrokdecode
$GIT_CLONE $LIBSIGROKDECODE_REPO libsigrokdecode
cd libsigrokdecode
./autogen.sh
./configure $C $L
make $PARALLEL $V
make install $V
cd ..

# sigrok-firmware
$GIT_CLONE $SIGROK_FIRMWARE_REPO sigrok-firmware
cd sigrok-firmware
./autogen.sh
# Nothing gets cross-compiled here, we just need 'make install' basically.
./configure --prefix="$INSTALL_DIR"
make install $V
cd ..

# sigrok-firmware-fx2lafw
$GIT_CLONE $SIGROK_FIRMWARE_FX2LAFW_REPO sigrok-firmware-fx2lafw
cd sigrok-firmware-fx2lafw
./autogen.sh
# We're building the fx2lafw firmware on the host, no need to cross-compile.
./configure --prefix="$INSTALL_DIR"
make $PARALLEL $V
make install $V
cd ..

# sigrok-dumps
$GIT_CLONE $SIGROK_DUMPS_REPO sigrok-dumps
cd sigrok-dumps
make install PREFIX="$INSTALL_DIR" $V
cd ..

