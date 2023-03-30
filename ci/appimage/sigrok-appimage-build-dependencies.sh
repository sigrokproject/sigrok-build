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
PKG_CONFIG_PATH=$P ./configure $C $L
make $PARALLEL $V
make install $V
cd ..

# libsigrokdecode
$GIT_CLONE $LIBSIGROKDECODE_REPO libsigrokdecode
cd libsigrokdecode
./autogen.sh
PKG_CONFIG_PATH=$P ./configure $C $L
make $PARALLEL $V
make install $V
cd ..

# sigrok-firmware
$GIT_CLONE $SIGROK_FIRMWARE_REPO sigrok-firmware
cd sigrok-firmware
./autogen.sh
# Nothing gets cross-compiled here, we just need 'make install' basically.
PKG_CONFIG_PATH=$P ./configure --prefix="$INSTALL_DIR"
make install $V
cd ..

# sigrok-firmware-fx2lafw
$GIT_CLONE $SIGROK_FIRMWARE_FX2LAFW_REPO sigrok-firmware-fx2lafw
cd sigrok-firmware-fx2lafw
./autogen.sh
# We're building the fx2lafw firmware on the host, no need to cross-compile.
PKG_CONFIG_PATH=$P ./configure --prefix="$INSTALL_DIR"
make $PARALLEL $V
make install $V
cd ..

# sigrok-dumps
$GIT_CLONE $SIGROK_DUMPS_REPO sigrok-dumps
cd sigrok-dumps
make install PREFIX="$INSTALL_DIR" $V
cd ..

