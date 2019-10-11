# Direct State Transfer (DST) Documentation

This repository hosts the design documentation for the [dst-go](https://github.com/direct-state-transfer/dst-go) project, which provides a [Go](https://golang.org/) implementation of the [Perun protocol](https://perun.network/).

## Build

The documentation is written in reStructured text and can be built using [Sphinx](http://www.sphinx-doc.org/en/master/).

To check if python, sphinx and sphinx-rtd-theme are installed, run [setup.sh](https://github.com/direct-state-transfer/dst-doc/setup.sh).  If any of the components are missing, the script will install them.

```bash
# From documentation project root directory

./setup.sh
```

Use make to build the documentation. The files will be available in the build directory. Eg: html output in build/html

```bash
# From documentation project root directory

make html   #To build html
make help   #To see usage info
```

Note : "sphinx-build" and other binaries are installed to `~/.local/bin`. This directory may not be included in the $PATH by default for os using bash 4.3 such as Ubuntu 17.0, Ubuntu 18.04 or Debian Stable (Buster).

In that case, please add `~/.local/bin` to the $PATH variable.

## License

This work is licensed under a [Creative Commons Attribution 4.0 International
License](http://creativecommons.org/licenses/by/4.0/) (CC-BY-4.0).
