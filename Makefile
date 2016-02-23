PROJECT_DIR=$(shell pwd)

BUILD_NUMBER=1

# Version of packages that will be compiled by this meta-package
PYTHON_VERSION=3.4.4
PYTHON_VER= $(basename $(PYTHON_VERSION))

OPENSSL_VERSION_NUMBER=1.0.2
OPENSSL_REVISION=f
OPENSSL_VERSION=$(OPENSSL_VERSION_NUMBER)$(OPENSSL_REVISION)

BZIP2_VERSION=1.0.6

XZ_VERSION=5.2.2

# OS/X build commands and flags
SDK_ROOT=$(shell xcrun --show-sdk-path)
CC=$(shell xcrun -find clang) --sysroot=$(OSX_SDK_ROOT)

# Working directories

OPENSSL_DIR=build/openssl-$(OPENSSL_VERSION)
BZIP2_DIR=build/bzip2-$(BZIP2_VERSION)
XZ_DIR=build/xz-$(XZ_VERSION)
PYTHON_DIR=build/Python-$(PYTHON_VERSION)

OPENSSL_FRAMEWORK=build/OpenSSL.framework
BZIP2_LIB=build/bzip2/lib/libbz2.a
XZ_LIB=build/xz/lib/liblzma.a

all: OSX

# Clean all builds
clean:
	rm -rf build dist

# Full clean - includes all downloaded products
distclean: clean
	rm -rf downloads

downloads: downloads/openssl-$(OPENSSL_VERSION).tgz downloads/bzip2-$(BZIP2_VERSION).tgz downloads/xz-$(XZ_VERSION).tgz downloads/Python-$(PYTHON_VERSION).tgz

###########################################################################
# OpenSSL
# These build instructions adapted from the scripts developed by
# Felix Shchulze (@x2on) https://github.com/x2on/OpenSSL-for-iPhone
###########################################################################

# Clean the OpenSSL project
clean-OpenSSL:
	rm -rf build/*/openssl-$(OPENSSL_VERSION)-* \
		build/*/libssl.a build/*/libcrypto.a \
		build/*/OpenSSL.framework

# Download original OpenSSL source code archive.
downloads/openssl-$(OPENSSL_VERSION).tgz:
	mkdir -p downloads
	-if [ ! -e downloads/openssl-$(OPENSSL_VERSION).tgz ]; then curl --fail -L http://openssl.org/source/openssl-$(OPENSSL_VERSION).tar.gz -o downloads/openssl-$(OPENSSL_VERSION).tgz; fi
	if [ ! -e downloads/openssl-$(OPENSSL_VERSION).tgz ]; then curl --fail -L http://openssl.org/source/old/$(OPENSSL_VERSION_NUMBER)/openssl-$(OPENSSL_VERSION).tar.gz -o downloads/openssl-$(OPENSSL_VERSION).tgz; fi


# Unpack OpenSSL
$(OPENSSL_DIR)/Makefile: downloads/openssl-$(OPENSSL_VERSION).tgz
	# Unpack sources
	mkdir -p $(OPENSSL_DIR)
	tar zxf downloads/openssl-$(OPENSSL_VERSION).tgz --strip-components 1 -C $(OPENSSL_DIR)
	# Configure the build
	cd $(OPENSSL_DIR) && \
		CC="$(CC)" ./Configure darwin64-x86_64-cc --openssldir=$(PROJECT_DIR)/$(OPENSSL_DIR)

# Build OpenSSL
$(OPENSSL_DIR)/libssl.a $(OPENSSL_DIR)/libcrypto.a: $(OPENSSL_DIR)/Makefile
	# Make the build
	cd $(OPENSSL_DIR) && \
		CC="$(CC)" make all

# Build OpenSSL.framework
$(OPENSSL_FRAMEWORK): $(OPENSSL_DIR)/libssl.a $(OPENSSL_DIR)/libcrypto.a
	# Create framework directory structure
	mkdir -p $(OPENSSL_FRAMEWORK)/Versions/$(OPENSSL_VERSION)

	# Copy the headers (use the version from the simulator because reasons)
	cp -f -r $(OPENSSL_DIR)/include $(OPENSSL_FRAMEWORK)/Versions/$(OPENSSL_VERSION)/Headers

	# Create the fat library
	xcrun libtool -no_warning_for_no_symbols -static \
		-o $(OPENSSL_FRAMEWORK)/Versions/$(OPENSSL_VERSION)/OpenSSL $^

	# Create symlinks
	ln -fs $(OPENSSL_VERSION) $(OPENSSL_FRAMEWORK)/Versions/Current
	ln -fs Versions/Current/Headers $(OPENSSL_FRAMEWORK)
	ln -fs Versions/Current/OpenSSL $(OPENSSL_FRAMEWORK)

###########################################################################
# BZip2
###########################################################################

# Clean the bzip2 project
clean-bzip2:
	rm -rf build/*/bzip2-$(BZIP2_VERSION)-* \
		build/*/bzip2

# Download original OpenSSL source code archive.
downloads/bzip2-$(BZIP2_VERSION).tgz:
	mkdir -p downloads
	if [ ! -e downloads/bzip2-$(BZIP2_VERSION).tgz ]; then curl --fail -L http://www.bzip.org/$(BZIP2_VERSION)/bzip2-$(BZIP2_VERSION).tar.gz -o downloads/bzip2-$(BZIP2_VERSION).tgz; fi

# Unpack BZip2
$(BZIP2_DIR)/Makefile: downloads/bzip2-$(BZIP2_VERSION).tgz
	# Unpack sources
	mkdir -p $(BZIP2_DIR)
	tar zxf downloads/bzip2-$(BZIP2_VERSION).tgz --strip-components 1 -C $(BZIP2_DIR)
	# Patch sources to use correct install directory
	sed -ie 's#PREFIX=/usr/local#PREFIX=$(PROJECT_DIR)/build/bzip2#' $(BZIP2_DIR)/Makefile

# Build BZip2
build/bzip2/lib/libbz2.a: $(BZIP2_DIR)/Makefile
	cd $(BZIP2_DIR) && make install

###########################################################################
# XZ (LZMA)
###########################################################################

# Clean the XZ project
clean-xz:
	rm -rf build/*/xz-$(XZ_VERSION)-* \
		build/*/xz

# Download original OpenSSL source code archive.
downloads/xz-$(XZ_VERSION).tgz:
	mkdir -p downloads
	if [ ! -e downloads/xz-$(XZ_VERSION).tgz ]; then curl --fail -L http://tukaani.org/xz/xz-$(XZ_VERSION).tar.gz -o downloads/xz-$(XZ_VERSION).tgz; fi

# Unpack XZ
$(XZ_DIR)/Makefile: downloads/xz-$(XZ_VERSION).tgz
	# Unpack sources
	mkdir -p $(XZ_DIR)
	tar zxf downloads/xz-$(XZ_VERSION).tgz --strip-components 1 -C $(XZ_DIR)
	# Configure the build
	cd $(XZ_DIR) && \
		./configure --disable-shared --enable-static --prefix=$(PROJECT_DIR)/build/xz

# Build XZ
build/xz/lib/liblzma.a: $(XZ_DIR)/Makefile
	cd $(XZ_DIR) && make && make install

###########################################################################
# Python
###########################################################################

# Clean the Python project
clean-Python:
	rm -rf build/Python-$(PYTHON_VERSION)-host build/*/Python-$(PYTHON_VERSION)-* \
		build/*/libpython$(PYTHON_VER).a build/*/pyconfig-*.h \
		build/*/Python.framework

# Download original Python source code archive.
downloads/Python-$(PYTHON_VERSION).tgz:
	mkdir -p downloads
	if [ ! -e downloads/Python-$(PYTHON_VERSION).tgz ]; then curl -L https://www.python.org/ftp/python/$(PYTHON_VERSION)/Python-$(PYTHON_VERSION).tgz > downloads/Python-$(PYTHON_VERSION).tgz; fi

# Unpack Python
$(PYTHON_DIR)/Makefile: downloads/Python-$(PYTHON_VERSION).tgz
	# Unpack target Python
	mkdir -p $(PYTHON_DIR)
	tar zxf downloads/Python-$(PYTHON_VERSION).tgz --strip-components 1 -C $(PYTHON_DIR)
	# Apply target Python patches
	cp -f $(PROJECT_DIR)/patch/Python/Setup.embedded $(PYTHON_DIR)/Modules/Setup.embedded
	# Configure target Python
	cd $(PYTHON_DIR) && ./configure --without-ensurepip --prefix=$(PROJECT_DIR)/build/python

# Build Python
$(PROJECT_DIR)/build/python/bin/python: build/OpenSSL.framework build/bzip2/lib/libbz2.a build/xz/lib/liblzma.a $(PYTHON_DIR)/Makefile
	# Build target Python
	cd $(PYTHON_DIR) && make all install


###########################################################################
# Packaging
###########################################################################

dist/Python-$(PYTHON_VERSION)-OSX-support.b$(BUILD_NUMBER).tar.gz: $(PROJECT_DIR)/build/python/bin/python
	mkdir -p dist
	tar zcvf $@ -C build python

OSX: dist/Python-$(PYTHON_VERSION)-OSX-support.b$(BUILD_NUMBER).tar.gz
