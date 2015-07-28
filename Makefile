PROJECTDIR=$(shell pwd)

BUILD_NUMBER=1

# Version of packages that will be compiled by this meta-package
PYTHON_VERSION=3.4.2

OPENSSL_VERSION_NUMBER=1.0.2
OPENSSL_REVISION=d
OPENSSL_VERSION=$(OPENSSL_VERSION_NUMBER)$(OPENSSL_REVISION)

# OS/X build commands and flags
OSX_SDK_ROOT=$(shell xcrun --show-sdk-path)
OSX_CC=$(shell xcrun -find clang) --sysroot=$(OSX_SDK_ROOT)


all: Python-$(PYTHON_VERSION)-OSX-support.b$(BUILD_NUMBER).tar.gz

# Clean all builds
clean:
	rm -rf build dist Python-$(PYTHON_VERSION)-OSX-support.b$(BUILD_NUMBER).tar.gz

# Full clean - includes all downloaded products
distclean: clean
	rm -rf downloads

Python-$(PYTHON_VERSION)-OSX-support.b$(BUILD_NUMBER).tar.gz: dist/python/bin/python$(basename $(PYTHON_VERSION))m
	cd dist && tar zcvf ../Python-$(PYTHON_VERSION)-OSX-support.b$(BUILD_NUMBER).tar.gz python

###########################################################################
# Working directories
###########################################################################

downloads:
	mkdir -p downloads

build:
	mkdir -p build

dist:
	mkdir -p dist

# Clean the OpenSSL project
clean-OpenSSL:
	rm -rf build/openssl-$(OPENSSL_VERSION)
	rm -rf build/OpenSSL
	rm -rf dist/OpenSSL.framework

# Download original OpenSSL source code archive.
downloads/openssl-$(OPENSSL_VERSION).tgz: downloads
	-if [ ! -e downloads/openssl-$(OPENSSL_VERSION).tgz ]; then curl --fail -L http://openssl.org/source/openssl-$(OPENSSL_VERSION).tar.gz -o downloads/openssl-$(OPENSSL_VERSION).tgz; fi
	if [ ! -e downloads/openssl-$(OPENSSL_VERSION).tgz ]; then curl --fail -L http://openssl.org/source/old/$(OPENSSL_VERSION_NUMBER)/openssl-$(OPENSSL_VERSION).tar.gz -o downloads/openssl-$(OPENSSL_VERSION).tgz; fi

build/OpenSSL/lib/libssl.a: build downloads/openssl-$(OPENSSL_VERSION).tgz
	# Unpack sources
	cd build && tar zxf ../downloads/openssl-$(OPENSSL_VERSION).tgz
	mkdir -p build/OpenSSL
	# Configure the build
	cd build/openssl-$(OPENSSL_VERSION) && \
		CC="$(OSX_CC)" ./Configure darwin64-x86_64-cc --openssldir=$(PROJECTDIR)/build/OpenSSL
	# Make the build
	cd build/openssl-$(OPENSSL_VERSION) && CC="$(OSX_CC)" make all
	# Install the build
	cd build/openssl-$(OPENSSL_VERSION) && make install

###########################################################################
# Python
###########################################################################

# Clean the Python project
clean-Python:
	rm -rf build/Python-$(PYTHON_VERSION)
	rm -rf build/python
	rm -rf dist/Python.framework

# Download original Python source code archive.
downloads/Python-$(PYTHON_VERSION).tgz: downloads
	curl -L https://www.python.org/ftp/python/$(PYTHON_VERSION)/Python-$(PYTHON_VERSION).tgz > downloads/Python-$(PYTHON_VERSION).tgz

# build/Python-$(PYTHON_VERSION)/Python.framework: build dist/OpenSSL.framework downloads/Python-$(PYTHON_VERSION).tgz
dist/python/bin/python$(basename $(PYTHON_VERSION))m: build downloads/Python-$(PYTHON_VERSION).tgz build/OpenSSL/lib/libssl.a
	# Unpack sources
	cd build && tar zxf ../downloads/Python-$(PYTHON_VERSION).tgz
	mkdir -p build/python
	# Apply patches
	cd build/Python-$(PYTHON_VERSION) && cp ../../patch/Python/Setup.embedded Modules/Setup.embedded
	# Configure the build
	cd build/Python-$(PYTHON_VERSION) && ./configure --prefix=$(PROJECTDIR)/dist/python --without-ensurepip
	# Make the build
	cd build/Python-$(PYTHON_VERSION) && make
	# Install the build
	cd build/Python-$(PYTHON_VERSION) && make install
	# Prune out things that aren't needed
	cd dist/python && rm -rf share include
	cd dist/python/bin && rm -rf 2to3* idle* pydoc* python*-config pyvenv* python*m
	cd dist/python/lib && rm -rf libpython$(basename $(PYTHON_VERSION)).a pkgconfig
	cd dist/python/lib/python$(basename $(PYTHON_VERSION)); \
		rm -rf *test* bsddb curses ensurepip hotshot idlelib tkinter turtledemo wsgiref \
			config-$(basename $(PYTHON_VERSION))m ctypes/test distutils/tests site-packages sqlite3/test
	# Make sure python always works as an executable name
	cd dist/python/bin && ln -si python$(basename $(PYTHON_VERSION)) python
