Python OS/X Support
===================

WARNING: This project is DEPRECATED
-----------------------------------

**It has been replaced by the multi-platform `Python-Apple-support<https://github.com/pybee/Python-Apple-support>`__ package**

This is a meta-package for building a version of Python that can be embedded
into an OS/X app.

It works by downloading, patching, and building OpenSSL and Python.

This repository branch builds a packaged version of **Python 3.4.2**.
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

.. _downloaded: https://github.com/pybee/Python-OSX-support/releases/download/3.4.2-b3/Python-3.4.2-OSX-support.b3.tar.gz
