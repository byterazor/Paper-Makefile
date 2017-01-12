-include .files
-include .deps

MAIN_TEX+=$(shell find -maxdepth 1 -name '*.tex' -exec basename '{}' \;)
TARGETS+=$(foreach f,$(MAIN_TEX), $(subst .tex,.pdf,$f))
REPOS+=Images Acronyms Bibliography


.PHONY: all update init clean

all: init $(TARGETS)

init: .latexmkrc .gitignore $(REPOS)

update: init $(REPOS)
	@$(foreach r, $(REPOS), cd $r; git pull;cd ..;)

%.pdf: $(MAIN_TEX) $(TEXFILES) $(IMAGES) $(BIB) $(ACRONYMS)
	latexmk	-r .latexmkrc -pdf $(subst .pdf,.tex,$@)

Images:
	@git clone ssh://tiweb.hsu-hh.de:9222/home/repos/Paper-Shared/Images

Acronyms:
	@git clone ssh://tiweb.hsu-hh.de:9222/home/repos/Paper-Shared/Acronyms

Bibliography:
	@git clone ssh://tiweb.hsu-hh.de:9222/home/repos/Paper-Shared/Bibliography

Images/%_hd.jpg: Images/%.jpg Images
		@echo **** Reducing Size of $@ ****
		convert $< -resize 1920 $@

Images/%_md.jpg: Images/%.jpg Images
	@echo **** Reducing Size of $@ ****
	convert $< -resize 1024 $@

Images/%_lo.jpg: Images/%.jpg Images
		@echo **** Reducing Size of $@ ****
		convert $< -resize 480 $@

Images/%_hd.png: Images/%.png Images
		@echo **** Reducing Size of $@ ****
		convert $< -resize 1920 $@

Images/%_md.png: Images/%.png Images
	@echo **** Reducing Size of $@ ****
	convert $< -resize 1024 $@

Images/%_lo.png: Images/%.png Images
		@echo **** Reducing Size of $@ ****
		convert $< -resize 480 $@

Images/%.pdf: Images/%.svg Images
	@echo "**** Generating $@ ****"
	@echo "$< --export-pdf=$@" | DISPLAY= inkscape -D -y 0 --shell

Images/%.svg: Images/%.dot Images
		@echo "**** Generating SVG $@ from dot file $<"
		@dot -Tsvg -o $@ $<

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
	@echo *.deps >> .gitignore
	@echo *.files >> .gitignore
	@echo *-blx.bib >> .gitignore

.latexmkrc:
	@echo '$$pdflatex' "= 'pdflatex -interaction=nonstopmode';" >> $@

.files: $(MAIN_TEX)
	@if [ -e .files ]; then rm .files; fi
	@echo -n "TEXFILES+=" >> .files
	@$(foreach f,$(MAIN_TEX), echo $f >> .files)
	@echo >>.files
	@$(foreach f,$(MAIN_TEX),for i in `cat $f | grep -v "%" | grep "\\\\input{" | sed 's/.*\\\input{//' | sed 's/}.*//'`; do echo TEXFILES+=$$i.tex >>.files; done)
	@echo >> .files

.deps: .files $(TEXFILES) $(MAIN_TEX)
	@if [ -e .deps ]; then rm .deps; fi
	@$(foreach f,$(TEXFILES), for i in `cat $f | grep includegraphics | sed 's/.*\\\includegraphics\[*.*\]*{//' | sed 's/\\\only.*{//' | sed 's/}//g' | sed 's/;//'`;do echo IMAGES+=$$i >>.deps; done;)
	@echo -n "BIB+=" >> .deps
	@$(foreach f,$(MAIN_TEX), cat $f | grep "\\\\bibliography" | sed 's/\\bibliography{//' | sed 's/}//g' | sed 's/,/ /g'| sed 's/}//g' | sed 's/,/ /g' >>.deps;)
	@echo >> .deps
	@echo -n "ACRONYMS+=" >> .deps
	@$(foreach f,$(MAIN_TEX), cat $f | grep "\\\\loadglsentries" | sed 's/\\loadglsentries{//' | sed 's/}/.tex/g' | sed 's/,/ /g'| sed 's/}//g' >>.deps;)
	@echo >> .deps

clean:
	@(rm .deps .files *.pdf *.aux *.bbl *.blg *.dvi *.ps *.log *.run.xml *.fls *.*latexmk *-blx.bib; echo "") 1>/dev/null 2>/dev/null

dist-clean: clean
	-@rm $(REPOS) -rf
