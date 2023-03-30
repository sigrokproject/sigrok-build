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

export PARALLEL="-j$(nproc)"

export P="$INSTALL_DIR/lib/pkgconfig"
export C="$C --prefix=$INSTALL_DIR"
export L="$L"
#export V="V=1 VERBOSE=1"

