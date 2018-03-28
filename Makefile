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
.PHONY: clean watermark IEEE base

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

IEEE: IEEEtran.cls

IEEEtran.cls:
	@wget https://www.ieee.org/documents/ieee-latex-conference-template.zip 1>/dev/null 2>/dev/null
	@unzip -j ieee-latex-conference-template.zip IEEEtran/IEEEtran.cls >/dev/null
	@rm ieee-latex-conference-template.zip

base: .gitignore .latexmkrc .git/hooks/post-commit

.git/hooks/post-commit .git/hooks/post-merge .git/hooks/post-checkout: Paper-Makefile/post-commit
	cp Paper-Makefile/post-commit .git/hooks/
	cp Paper-Makefile/post-commit .git/hooks/post-merge
	cp Paper-Makefile/post-commit .git/hooks/post-checkout
	chmod u+x .git/hooks/*
	.git/hooks/post-commit

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
	@echo '$$pdflatex' "= 'pdflatex -interaction=nonstopmode';" >> $@

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
