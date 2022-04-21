# You can set these variables from the command line.
SPHINXOPTS    = -W --keep-going
SPHINXBUILD   = sphinx-build
SPHINXPROJ    = perun-doc
SOURCEDIR     = source
BUILDDIR      = build
# Note: $(STAGEDIR) needs to be added to .gitignore
STAGEDIR      = public
REMOTENAME    = origin
BRANCH        = gh-pages
# if DEPLOYVERSION=new: commit as new version to $(BRANCH)
DEPLOYVERSION = overwrite_previous

ifneq ($(DEPLOYVERSION),new)
	_COMMITFLAG    = --amend
else
	_COMMITFLAG    =
endif

_GIT_STATUS_RETURN=$(shell git status 2>&1 1> /dev/null; echo $$?)
ifeq ($(_GIT_STATUS_RETURN),0)     # if in git repository
	_REMOTEURL="$(shell git remote get-url $(REMOTENAME))"
	_GIT_STATUS="$(shell git status -s)"
	ifeq ($(_GIT_STATUS),"")       # if working tree clean
		_GIT_COMMIT="$(shell git show --format="%H" --no-patch)"
	endif
endif

SPHINXHELP    = $(SPHINXBUILD) -M help "$(SOURCEDIR)" "$(BUILDDIR)"
SPHINXTARGETS = $(shell $(SPHINXHELP) | awk 'NR > 2 {print $$1}')

UMLSRC        = $(wildcard source/images/*/*.plantuml)
UMLOBJ        = $(patsubst source/images/%.plantuml,source/_generated/%.svg,\
					$(UMLSRC))

LICENSES      = $(addprefix $(STAGEDIR)/, $(wildcard LICENSES/*))


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
	GIT_COMMIT=$(_GIT_COMMIT) $(SPHINXBUILD) -M $@ "$(SOURCEDIR)" "$(BUILDDIR)" $(SPHINXOPTS) $(O)

# add dependency to html target, which is one of the sphinx targets
html: images

images: $(UMLOBJ)   ## to make svg files out of PlantUML diagrams

init: clean
	echo "Check out branch $(BRANCH) into folder $(STAGEDIR)"
	@git worktree add -B $(BRANCH) $(STAGEDIR) $(REMOTENAME)/$(BRANCH)
	echo "Remove existing files"
	@rm -rf $(STAGEDIR)/*

stage: init html    ## to make html target and stage for deployment
	cp -a "$(BUILDDIR)/html/." "$(STAGEDIR)"
	cp LICENSE "$(STAGEDIR)"
	mkdir "$(STAGEDIR)/LICENSES"
	$(MAKE) $(LICENSES)

check:
	@if [ -z $(_REMOTEURL) ]; then \
		echo "Unknown remote '$(REMOTENAME)'. Check local repository."; \
		exit 1; \
	fi
	@if [ -n $(_GIT_STATUS) ]; then \
		echo "Working tree not clean. Commit or discard pending changes."; \
		exit 1; \
	fi

deploy: check stage ## to deploy staged artefacts to github pages repository
	echo "Update branch $(BRANCH)"
	cd "$(STAGEDIR)" \
	&& git add --all \
	&& git commit $(_COMMITFLAG) \
	              -m "HTML build of $(SPHINXPROJ) with 'make deploy'" \
	              -m "Source: $(_REMOTEURL)/tree/$(_GIT_COMMIT)" \
	&& git push --force $(REMOTENAME) $(BRANCH)

clean:              ## to remove all build artifacts
	rm -rf "$(BUILDDIR)"
	rm -rf "$(STAGEDIR)"
	git worktree prune
	rm -rf .git/worktrees/$(STAGEDIR)/
