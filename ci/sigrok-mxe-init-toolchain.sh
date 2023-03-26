#!/bin/sh
##
## This file is part of the sigrok-util project.
##
## Copyright (C) 2013-2018 Uwe Hermann <uwe@hermann-uwe.de>
## Copyright (C) 2018-2021 Frank Stettner <frank-stettner@gmx.net>
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

export PARALLEL="-j$(nproc)"

# We need to find tools in the toolchain.
export PATH="$MXE_DIR/usr/bin":"$PATH"

TOOLCHAIN_TRIPLET="$TARGET-w64-mingw32.static.posix"

export CMAKE="$TOOLCHAIN_TRIPLET-cmake"

P="$INSTALL_DIR/lib/pkgconfig"
P2="$MXE_DIR/usr/$TOOLCHAIN_TRIPLET/lib/pkgconfig"
export C="--host=$TOOLCHAIN_TRIPLET --prefix=$INSTALL_DIR CPPFLAGS=-D__printf__=__gnu_printf__"
export L="--disable-shared --enable-static"

if [ "$TARGET" = "i686" ]; then
	export PKG_CONFIG_PATH_i686_w64_mingw32_static_posix="$P:$P2"
else
	export PKG_CONFIG_PATH_x86_64_w64_mingw32_static_posix="$P:$P2"
fi

