# Minimal makefile for Sphinx documentation
#

# You can set these variables from the command line.
SPHINXOPTS    =
SPHINXBUILD   = sphinx-build
SPHINXPROJ    = DST
SOURCEDIR     = source
BUILDDIR      = build
STAGEDIR      = ../perun-doc-stage

SOURCEREPO    = https://github.com/direct-state-transfer/perun-doc
DEPLOYREPO    = https://github.com/direct-state-transfer/direct-state-transfer.github.io

SPHINXHELP    = $(SPHINXBUILD) -M help "$(SOURCEDIR)" "$(BUILDDIR)"
SPHINXTARGETS = $(shell $(SPHINXHELP) | awk 'NR > 2 {print $$1}')

UMLSRC        = $(wildcard source/images/*/*.plantuml)
UMLOBJ        = $(patsubst source/images/%.plantuml,source/_generated/%.png,\
					$(UMLSRC))

LICENSES      = $(addprefix $(STAGEDIR)/, $(wildcard LICENSES/*))

# color definitions for commandline
BLUE = \033[1;34m
NC   = \033[0m$()# No Color

source/_generated/%.png : source/images/%.plantuml
	./tools/plantuml -ppng -o$(subst source,../..,$(@D)) $<

$(STAGEDIR)/LICENSES/%.txt : LICENSES/%.txt
	sed 's;^/build/html;;' "$<" > "$@"

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

stage: clean html   ## to make html target and stage for deployment
	cp -a "$(BUILDDIR)/html" "$(STAGEDIR)"
	cp LICENSE "$(STAGEDIR)"
	mkdir "$(STAGEDIR)/LICENSES"
	$(MAKE) $(LICENSES)

GIT_COMMIT="$(shell git show --format="%H" --no-patch)"

deploy:             ## to deploy staged artefacts to github pages repository
	cd "$(STAGEDIR)" && ! git status -s # fails if we're w/in git repository
	cd "$(STAGEDIR)" \
	&& git init \
	&& git add --all \
	&& git commit -m "HTML build of dst-doc" \
	              -m "Source: $(SOURCEREPO)/tree/$(GIT_COMMIT)" \
	&& git remote add origin $(DEPLOYREPO) \
	&& git push --force origin master

clean:              ## to remove all build artifacts
	rm -rf "$(BUILDDIR)"
	rm -rf "$(STAGEDIR)"
