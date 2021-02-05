# Perun Documentation

This repository hosts the documentation for the Hyperledger Labs project
[Perun](https://github.com/hyperledger-labs?q=perun), a
blockchain-agnostic state channels framework.

The documentation is written in
[reStructuredText](https://www.sphinx-doc.org/en/master/usage/restructuredtext/index.html)
or [Markdown](https://www.sphinx-doc.org/en/master/usage/markdown.html)
(of [CommonMark](https://commonmark.org/) flavor) and can be built with
[Sphinx](http://www.sphinx-doc.org/en/master/). The latest generated
HTML documentation is published at
<https://labs.hyperledger.org/perun-doc/>.

## Build

To check if python, sphinx and sphinx-rtd-theme are installed, run
[setup.sh](setup.sh) from the project root directory.  If any of the
components are missing, the script will install them.

```bash
# from project root directory

./setup.sh
```

Note: "sphinx-build" and other binaries are installed to `~/.local/bin`.
Make sure that this directory is included in the `$PATH` environment
variable. By default that may not be the case, e.g. if you're using bash
on Ubuntu 17.0, Ubuntu 18.04, or Debian Stable (Buster).

Use make to build the documentation. During development the most
important make targets are:

```bash
# from project root directory

make help      # to see usage info
make html      # to build html into ./build/html/
make linkcheck # to check all external links for integrity
```

## License

This work is licensed under a [Creative Commons Attribution 4.0 International
License](http://creativecommons.org/licenses/by/4.0/) (CC-BY-4.0).
