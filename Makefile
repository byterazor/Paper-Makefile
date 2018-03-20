# Makefile for generating pdf from latex files
# 	-dependency support
#		-pdf generation of svg files
#   -pdf generation of dot files
#
# Author	: Dominik Meyer <dmeyer@hsu-hh.de>
#	Date  	: 2017-11-22
# License	:	GPLv2
#
DEPDIR := .d
$(shell mkdir -p $(DEPDIR) >/dev/null)

export $TEXINPUTS

DEPFLAGS = -M -MP -MF $(DEPDIR)/$*.d

LATEXMK=export TEXINPUTS=$(TEXINPUTS);latexmk -use-make -f $(DEPFLAGS) -pdf $(subst .pdf,.tex,$@) 1>>$(subst .pdf,.log,$@) 2>>$(subst .pdf,.log,$@)

.SECONDARY: .latexmkrc
.PHONY: clean

%.pdf : %.dot
	@echo "**** Generating $@ from dot file $< ****"
	@dot -Tpdf $< -o $@
	@touch $@.dep

%.pdf: %.svg
	@echo "**** Generating $@ from svg file $< ****"
	@echo "$< --export-pdf=$@" | DISPLAY= inkscape -D -y 0 --shell >/dev/null
	@touch $@.dep

%.pdf: $(DEPDIR)/%.d
	@echo "**** Generating $@ ****"
	@if [ -e $(subst .pdf,.log,$@) ]; then rm $(subst .pdf,.log,$@); fi
	@$(LATEXMK) || ( if [ -e $@ ]; then rm $@; fi; $(LATEXMK))
	@touch $@
	@echo "**** log file $(subst .pdf, .log,$@)"

$(DEPDIR)/%.d: ;
.PRECIOUS: $(DEPDIR)/%.d

watermark.tex:
	cp Paper-Makefile/watermark.tex $@

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
	@-for i in `find -name '*.dep'`; do  f=`echo $$i | sed 's/.dep//'`; rm $$f; rm $$i; done

include $(wildcard $(patsubst %,$(DEPDIR)/%.d,$(basename $(SRCS))))
