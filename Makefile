# Minimal makefile for Sphinx documentation
#

# You can set these variables from the command line.
SPHINXOPTS    =
SPHINXBUILD   = sphinx-build
SPHINXPROJ    = perun-doc
SOURCEDIR     = source
BUILDDIR      = build
# Note: $(STAGEDIR) needs to be added to .gitignore
STAGEDIR      = public
# if DEPLOYVERSION=new: commit as new version to gh-pages
DEPLOYVERSION = overwrite_previous

REMOTENAME    = origin
#REMOTEURL     = https://github.com/hyperledger-labs/perun-doc

SPHINXHELP    = $(SPHINXBUILD) -M help "$(SOURCEDIR)" "$(BUILDDIR)"
SPHINXTARGETS = $(shell $(SPHINXHELP) | awk 'NR > 2 {print $$1}')

UMLSRC        = $(wildcard source/images/*/*.plantuml)
UMLOBJ        = $(patsubst source/images/%.plantuml,source/_generated/%.svg,\
					$(UMLSRC))

LICENSES      = $(addprefix $(STAGEDIR)/, $(wildcard LICENSES/*))

ifneq ($(DEPLOYVERSION),new)
COMMITFLAG    = --amend
else
COMMITFLAG    =
endif

# color definitions for commandline
BLUE = \033[1;34m
NC   = \033[0m$()# No Color

source/_generated/%.svg : source/images/%.plantuml
	./tools/plantuml -tsvg -o$(subst source,../..,$(@D)) $<

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

images: $(UMLOBJ)   ## to make svg files out of PlantUML diagrams

init: clean
	echo "Check out branch gh-pages into folder $(STAGEDIR)"
	@git worktree add -B gh-pages $(STAGEDIR) $(REMOTENAME)/gh-pages
	echo "Remove existing files"
	@rm -rf $(STAGEDIR)/*

stage: init html    ## to make html target and stage for deployment
	cp -a "$(BUILDDIR)/html/." "$(STAGEDIR)"
	cp LICENSE "$(STAGEDIR)"
	mkdir "$(STAGEDIR)/LICENSES"
	$(MAKE) $(LICENSES)

REMOTEURL="$(shell git remote get-url $(REMOTENAME))"

check:
	@if [ -z $(REMOTEURL) ]; then \
		echo "Unknown remote '$(REMOTENAME)'. Check local repository."; \
		exit 1; \
	fi
	@if [ -n "$(shell git status -s)" ]; then \
		echo "Working tree not clean. Commit or discard pending changes."; \
		exit 1; \
	fi

GIT_COMMIT="$(shell git show --format="%H" --no-patch)"

deploy: check stage ## to deploy staged artefacts to github pages repository
	echo "Update branch gh-pages"
	cd "$(STAGEDIR)" \
	&& git add --all \
	&& git commit $(COMMITFLAG) \
	              -m "HTML build of $(SPHINXPROJ) with 'make deploy'" \
	              -m "Source: $(REMOTEURL)/tree/$(GIT_COMMIT)" \
	&& git push --force $(REMOTENAME) gh-pages

clean:              ## to remove all build artifacts
	rm -rf "$(BUILDDIR)"
	rm -rf "$(STAGEDIR)"
	git worktree prune
	rm -rf .git/worktrees/$(STAGEDIR)/
