Python OS/X Support
===================

This is a meta-package for building a version of Python that can be embedded
into an OS/X app.

It works by downloading, patching, and building OpenSSL and Python.

This repository branch builds a packaged version of **Python 3.5.1**.
Other Python versions are available by cloning other branches of the main
repository.

Quickstart
----------

Pre-built versions of the frameworks can be downloaded_, and added to
your OS/X project.

Alternatively, to build the frameworks on your own, download/clone this
repository, and then in the root directory, and run:

    $ make

This should:

1. Download the original source packages
2. Patch them as required for OS/X compatibility
3. Build the packages.

The build products will be in the `build` directory.

.. _downloaded: https://github.com/pybee/Python-OSX-support/releases/download/3.5.1-b1/Python-3.5.1-OSX-support.b1.tar.gz
