FROM ubuntu:18.04
LABEL \
	org.opencontainers.image.title="sigrok AppImage x86_64 Build Image" \
	org.opencontainers.image.description="This image is used to build the sigrok x86_64 AppImage artefacts" \
	org.opencontainers.image.url="https://sigrok.org" \
	org.opencontainers.image.source="https://github.com/knarfS/sigrok-build" \
	org.opencontainers.image.licenses="GPL-3.0-or-later" \
	org.opencontainers.image.authors="Frank Stettner <frank-stettner@gmx.net>" \
	maintainer="Frank Stettner <frank-stettner@gmx.net>"

ENV DEBIAN_FRONTEND noninteractive
ENV BASE_DIR /opt
# AppImage related setting
ENV APPIMAGE_EXTRACT_AND_RUN 1
ENV ARCH x86_64
# Qt 5.12 settings
ENV QT_BASE_DIR /opt/qt512
ENV QTDIR $QT_BASE_DIR
ENV PATH $QT_BASE_DIR/bin:$PATH
ENV LD_LIBRARY_PATH $QT_BASE_DIR/lib/x86_64-linux-gnu:$QT_BASE_DIR/lib:$LD_LIBRARY_PATH
ENV PKG_CONFIG_PATH $QT_BASE_DIR/lib/pkgconfig:$PKG_CONFIG_PATH

RUN apt-get update \
	&& apt-get upgrade -y \
	# Install basic stuff
	&& apt-get install -y --no-install-recommends \
		sudo bash apt-utils software-properties-common \
		wget ca-certificates gpg gnupg2 unzip bzip2 lzip sed \
	# Install build stuff
	&& apt-get install -y --no-install-recommends \
		gcc g++ make autoconf autoconf-archive automake libtool \
		pkg-config check doxygen swig shellcheck sdcc \
	# Install libserialport, libsigrok, pulseview and smuview dependencies
	&& apt-get install -y --no-install-recommends \
		libglib2.0-dev libglibmm-2.4-dev libzip-dev libusb-1.0-0-dev \
		libftdi1-dev libhidapi-dev libbluetooth-dev libvisa-dev nettle-dev \
		libavahi-client-dev libieee1284-3-dev libboost1.65-dev libboost-system1.65-dev \
		libboost-filesystem1.65-dev libboost-serialization1.65-dev \
	#
	# Update certificates
	&& update-ca-certificates \
	#
	# Install current git
	&& add-apt-repository -y ppa:git-core/ppa \
	&& apt-get update \
	&& apt-get install -y git \
	#
	# Install current cmake
	&& wget -O - https://apt.kitware.com/keys/kitware-archive-latest.asc 2>/dev/null | gpg --dearmor - | sudo tee /usr/share/keyrings/kitware-archive-keyring.gpg > /dev/null \
	&& echo 'deb [signed-by=/usr/share/keyrings/kitware-archive-keyring.gpg] https://apt.kitware.com/ubuntu/ bionic main' | sudo tee /etc/apt/sources.list.d/kitware.list > /dev/null \
	&& apt-get update \
	&& apt-get install -y cmake \
	#
	# Install Qt 5.12 from beineri PPA
	&& sudo add-apt-repository -y ppa:beineri/opt-qt-5.12.10-bionic \
	&& sudo apt-get update \
	&& apt-get install -y --no-install-recommends \
		qt512base qt512svg qt512tools qt512translations \
	#
	# Install Qwt 6.1.6
	&& apt-get install -y mesa-common-dev libgl1-mesa-dev \
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
