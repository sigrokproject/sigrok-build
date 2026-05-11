FROM ubuntu:24.04
LABEL \
	org.opencontainers.image.title="sigrok AppImage x86_64 Build Image" \
	org.opencontainers.image.description="This image is used to build the sigrok x86_64 AppImage artifacts" \
	org.opencontainers.image.url="https://sigrok.org" \
	org.opencontainers.image.source="https://github.com/sigrokproject/sigrok-build" \
	org.opencontainers.image.licenses="GPL-3.0-or-later" \
	org.opencontainers.image.authors="Soeren Apel <sigrok@apelpie.net>, Frank Stettner <frank-stettner@gmx.net>" \
	maintainer="Soeren Apel <sigrok@apelpie.net>"

ENV DEBIAN_FRONTEND=noninteractive
ENV BASE_DIR=/opt
# AppImage related setting
ENV APPIMAGE_EXTRACT_AND_RUN=1
ENV ARCH=x86_64
# Qt5 settings (system Qt on Ubuntu 24.04)
ENV QT_BASE_DIR=/usr
ENV QTDIR=$QT_BASE_DIR
ENV PATH=$QT_BASE_DIR/lib/qt5/bin:$PATH
ENV LD_LIBRARY_PATH=$QT_BASE_DIR/lib/x86_64-linux-gnu:$LD_LIBRARY_PATH
ENV PKG_CONFIG_PATH=$QT_BASE_DIR/lib/x86_64-linux-gnu/pkgconfig:$PKG_CONFIG_PATH

RUN apt-get update \
	&& apt-get upgrade -y \
	# Install basic stuff
	&& apt-get install -y --no-install-recommends \
		sudo bash apt-utils software-properties-common \
		wget ca-certificates gpg gnupg2 unzip bzip2 lzip sed git cmake \
	# Install build stuff
	&& apt-get install -y --no-install-recommends \
		gcc g++ make autoconf autoconf-archive automake libtool \
		pkg-config check doxygen swig shellcheck sdcc \
		python3-dev \
	# Install libserialport, libsigrok, pulseview and smuview dependencies
	&& apt-get install -y --no-install-recommends \
		libglib2.0-dev libglibmm-2.4-dev libzip-dev libusb-1.0-0-dev \
		libftdi1-dev libhidapi-dev libbluetooth-dev nettle-dev \
		libavahi-client-dev libieee1284-3-dev \
		libboost-dev libboost-system-dev libboost-filesystem-dev libboost-serialization-dev \
	#
	# Update certificates
	&& update-ca-certificates \
	#
	# Install Qt5 (system packages)
	&& apt-get install -y --no-install-recommends \
		qtbase5-dev qtchooser qt5-qmake qtbase5-dev-tools \
		libqt5svg5-dev qttools5-dev qttools5-dev-tools \
		libqt5opengl5-dev mesa-common-dev libgl1-mesa-dev \
	#
	# Install Qwt 6.1.6
	&& cd /opt \
	&& wget https://sourceforge.net/projects/qwt/files/qwt/6.1.6/qwt-6.1.6.tar.bz2 \
	&& tar xf qwt-6.1.6.tar.bz2 \
	&& cd qwt-6.1.6 \
	&& qmake qwt.pro \
	&& make \
	# Change the QWT_INSTALL_PREFIX in qwtconfig.pri to /usr
	&& sed -i 's|^\([[:space:]]*QWT_INSTALL_PREFIX[[:space:]]*=[[:space:]]*\)/usr.*$|\1/usr|g' qwtconfig.pri \
	&& make install \
	# Cleanup
	&& cd .. \
	&& rm qwt-6.1.6.tar.bz2 \
	&& rm -rf qwt-6.1.6 \
	#
	# Cleanup apt
	&& apt-get clean \
	&& rm -rf /var/lib/apt/lists/*
