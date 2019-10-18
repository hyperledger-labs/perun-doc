# Minimal makefile for Sphinx documentation
#

# You can set these variables from the command line.
SPHINXOPTS    =
SPHINXBUILD   = sphinx-build
SPHINXPROJ    = DST
SOURCEDIR     = source
BUILDDIR      = build

SPHINXHELP    = $(SPHINXBUILD) -M help "$(SOURCEDIR)" "$(BUILDDIR)"
SPHINXTARGETS = $(shell $(SPHINXHELP) | awk 'NR > 2 {print $$1}')

UMLSRC        = $(wildcard source/images/*/*.plantuml)
UMLOBJ        = $(patsubst source/images/%.plantuml,source/_generated/%.png,\
					$(UMLSRC))

# color definitions for commandline
BLUE = \033[1;34m
NC   = \033[0m$()# No Color

source/_generated/%.png : source/images/%.plantuml
	./tools/plantuml -ppng -o$(subst source,../..,$(@D)) $<

source/_generated/%.png : source/images/%.svg
	@echo Recipe missing how to build $@

# Put it first so that "make" without argument is like "make help".
help:               ## to display this help text
	@$(SPHINXHELP) $(SPHINXOPTS) $(O)
	@grep -E '^[[:alnum:]_-]+:.*?## .*$$' $(MAKEFILE_LIST) \
		| awk 'BEGIN {FS = ":.*?## "}; \
			   NR==1 {printf "----\n"}; \
			   {printf "  $(BLUE)%-11s$(NC) %s\n", $$1, $$2}'

.PHONY: help Makefile

# $(O) is meant as a shortcut for $(SPHINXOPTS).
$(SPHINXTARGETS): Makefile
	@$(SPHINXBUILD) -M $@ "$(SOURCEDIR)" "$(BUILDDIR)" $(SPHINXOPTS) $(O)

# add dependency to html target, which is one of the sphinx targets
html: images

images: $(UMLOBJ)   ## to make png files out of PlantUML diagrams

clean:              ## to remove all build artifacts
	rm -rf $(BUILDDIR)
