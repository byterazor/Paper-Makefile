# Makefile for generating pdf from latex files
# 	-dependency support
#	-pdf generation of svg files
#   -pdf generation of dot files
#
# Author	: Dominik Meyer <dmeyer@hsu-hh.de>
#	Date  	: 2017-11-22
# License	:	GPLv2
#
SHELL := /bin/bash
DEPDIR := .d
$(shell mkdir -p $(DEPDIR) >/dev/null)
GITDIR = $(shell git rev-parse --show-toplevel)/
export $TEXINPUTS

DEPFLAGS = -M -MP -MF $(DEPDIR)/$*.d


ifneq ("$(wildcard .pdflatex)","")
    LATEXMK=export TEXINPUTS=$(TEXINPUTS);latexmk -use-make -f $(DEPFLAGS) -pdf $(subst .pdf,.tex,$@) 1>>$(subst .pdf,.log,$@) 2>>$(subst .pdf,.log,$@)
else
    LATEXMK=export TEXINPUTS=$(TEXINPUTS);latexmk -use-make -f $(DEPFLAGS) -pdflua $(subst .pdf,.tex,$@) 1>>$(subst .pdf,.log,$@) 2>>$(subst .pdf,.log,$@)
endif

INKSCAPE_EXIST=$(shell which inkscape >/dev/null;echo $$?)

ifeq ($(INKSCAPE_EXIST),0)
	# identify used inkscape version and set command
	INKSCAPE_BASE=$(shell which inkscape)

	INKSCAPE_VERSION=$(shell $(INKSCAPE_BASE) --version 2>/dev/null | cut -d " " -f 2 | cut -d . -f 1)

	ifeq ($(INKSCAPE_VERSION),0)
		INKSCAPE = "echo \"$< --export-pdf=$@\" | DISPLAY= $(INKSCAPE_BASE) -D -y 0 --shell >/dev/null"
	else
		INKSCAPE = "$(INKSCAPE_BASE) --export-type=pdf -o $@ $<"
	endif

endif

.SECONDARY: .latexmkrc
.PHONY: clean watermark IEEE base

%.pdf: %.image.tex
	@echo "**** Generating $@ from tex file $< ****"
	@lualatex -output-directory=`dirname $<` $< >/dev/null
	IN=`echo $< | sed 's/\.tex/\.pdf/'`;OUT=`echo $< | sed 's/\.image\.tex/\.pdf/'`; cp $$IN $$OUT
	@touch $@.dep

%.pdf : %.dot
	@echo "**** Generating $@ from dot file $< ****"
	@dot -Tpdf $< -o $@
	@touch $@.dep

%.svg: %.drawio.svg
	@echo "**** Renaming drawio file $< *****"
	@cp $< $@
	@touch $@.dep

%.svg: %.excalidraw.svg
	@echo "**** Renaming excalidraw file $< *****"
	@cp $< $@
	@touch $@.dep

%.pdf: %.svg
	@echo "**** Generating $@ from svg file $< ****"
	@if [ $(INKSCAPE_EXIST) != "0" ]; then echo "The inkscape tool required for converting svg --> pdf is missing. Please install it"; exit -1; fi
	@if [ "$(INKSCAPE_VERSION)" -eq "0" ]; then echo "$<" --export-pdf=$@ | DISPLAY= $(INKSCAPE_BASE) -D -y 0 --shell >/dev/null; fi
	@if [ "$(INKSCAPE_VERSION)" -eq "1" ]; then $(INKSCAPE_BASE) --export-type=pdf -o $@ $< 1>/dev/null 2>/dev/null; fi
	@touch $@.dep

%.pdf: $(DEPDIR)/%.d
	@echo "**** Generating $@ ****"
	@if [ -e $(subst .pdf,.log,$@) ]; then rm $(subst .pdf,.log,$@); fi
	@$(LATEXMK) || ( if [ -e $@ ]; then rm $@; fi; $(LATEXMK))
	@touch $@
	@echo "**** log file $(subst .pdf, .log,$@)"

$(DEPDIR)/%.d: ;
.PRECIOUS: $(DEPDIR)/%.d

IEEE: IEEEtran.cls

IEEEtran.cls:
	@wget https://www.ieee.org/documents/ieee-latex-conference-template.zip 1>/dev/null 2>/dev/null
	@unzip -j ieee-latex-conference-template.zip IEEEtran/IEEEtran.cls >/dev/null
	@rm ieee-latex-conference-template.zip

base: .gitignore .latexmkrc ${GITDIR}/.git/hooks/post-commit

${GITDIR}/.git/hooks/post-commit ${GITDIR}.git/hooks/post-merge ${GITDIR}.git/hooks/post-checkout: ${MakefileBase}/post-commit
	cp ${MakefileBase}/post-commit ${GITDIR}.git/hooks/
	cp ${MakefileBase}/post-commit ${GITDIR}.git/hooks/post-merge
	cp ${MakefileBase}/post-commit ${GITDIR}.git/hooks/post-checkout
	chmod u+x ${GITDIR}/.git/hooks/*
	${GITDIR}/.git/hooks/post-commit

.gitignore:
	@echo *.pdf >> .gitignore
	@echo *.aux >> .gitignore
	@echo *.bbl >> .gitignore
	@echo *.bcf >> .gitignore
	@echo *.blg >> .gitignore
	@echo *.dvi >> .gitignore
	@echo *.log >> .gitignore
	@echo *.run.xml >> .gitignore
	@echo *.fls >> .gitignore
	@echo *.*latexmk >> .gitignore
	@echo *.files >> .gitignore
	@echo *-blx.bib >> .gitignore
	@echo *.out >> .gitignore
	@echo **/*.dep >> .gitignore
	@echo .d >> .gitignore

.latexmkrc:
	@cp ${MakefileBase}/.latexmkrc . >> $@

watermark.tex:
	cp ${MakefileBase}/watermark.tex $@

watermark: all watermark.tex
	sed -i 's/<email>/$(EMAIL)/g' watermark.tex
	latexmk -pdf watermark.tex
	pdftk paper.pdf stamp watermark.pdf output paper_watermark.pdf
	rm -rf watermark.*

clean:
	@-rm -rf .d
	@-rm -rf *.pdata
	@-rm -rf *.pdf
	@-rm -rf *.bcf
	@-rm -rf *.aux
	@-rm -rf *.bbl
	@-rm -rf *.blg
	@-rm -rf *.dvi
	@-rm -rf *.ps
	@-rm -rf *.log
	@-rm -rf *.run.xml
	@-rm -rf *.fls
	@-rm -rf *.*latexmk
	@-rm -rf *-blx.bib
	@-rm -rf *.out
	@-rm -rf *.toc
	@-rm -rf *.nav
	@-rm -rf *.snm
	@-rm -rf *.vrb
	@-for i in `find . -name '*.dep'`; do  f=`echo $$i | sed 's/.dep//'`; rm $$f; rm $$i; done

include $(wildcard $(patsubst %,$(DEPDIR)/%.d,$(basename $(SRCS))))
