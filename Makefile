-include .deps
SHELL=/bin/bash
INIT_TEX+=paper.tex
MAIN_TEX+=$(shell find -maxdepth 1 -name '*.tex' -exec basename '{}' \;)
TEXFILES+=$(MAIN_TEX)
TEXFILES+=$(foreach f,$(MAIN_TEX),$(shell for i in `cat $f | grep -v "%" | grep "\\\\input{" | sed 's/.*\\\input{//' | sed 's/}.*//'`; do echo "$$i.tex "; done))
TARGETS+=$(foreach f,$(MAIN_TEX), $(subst .tex,.pdf,$f))
REPOS+=Paper-Makefile Images Acronyms Bibliography style-check


.PHONY: all update init clean check init-git add-ieee remove-ieee

all: init $(TARGETS)

init: $(INIT_TEX) IEEEtran.cls .latexmkrc .gitignore $(REPOS) .git

.git:
	@echo "Initializing Paper Directory"
	@echo "	creating git repository"
	@git init
	@echo "	creating initial commit"
	@git add .latexmkrc .gitignore Makefile *.tex *.cls
	@git commit -m "ADD initial commit of paper directory"

update: init $(REPOS)
	@$(foreach r, $(REPOS), cd $r; git pull;cd ..;)

check: .style-check.d
	@$(foreach f, $(TEXFILES), style-check/style-check.rb $f;)

add-ieee: IEEEtran.cls

IEEEtran.cls:
	@wget https://www.ieee.org/documents/IEEEtran.zip 1>/dev/null 2>/dev/null
	@unzip -j IEEEtran.zip IEEEtran/IEEEtran.cls >/dev/null
	@rm IEEEtran.zip

remove-ieee:
	@if [ -e IEEEtran.cls ]; then rm IEEEtran.cls; fi

%.pdf: $(MAIN_TEX) $(TEXFILES) $(IMAGES) $(BIB) $(ACRONYMS)
	latexmk	-r .latexmkrc -pdf $(subst .pdf,.tex,$@)

%.tex:
	@cp Paper-Makefile/template.tex $(INIT_TEX)

Images:
	@git clone ssh://tiweb.hsu-hh.de:9222/home/repos/Paper-Shared/Images

Acronyms:
	@git clone ssh://tiweb.hsu-hh.de:9222/home/repos/Paper-Shared/Acronyms

Bibliography:
	@git clone ssh://tiweb.hsu-hh.de:9222/home/repos/Paper-Shared/Bibliography

.style-check.d: style-check
	@ln -s style-check/rules .style-check.d

style-check:
	@git clone https://github.com/byterazor/style-check.git

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
	@echo .style-check.d >> .gitignore

.latexmkrc:
	@echo '$$pdflatex' "= 'pdflatex -interaction=nonstopmode';" >> $@

.deps: $(TEXFILES)
	@if [ -e .deps ]; then rm .deps; fi
	@$(foreach f,$(TEXFILES), for i in `cat $f | grep includegraphics | sed 's/.*\\\includegraphics\[*.*\]*{//' | sed 's/\\\only.*{//' | sed 's/}//g' | sed 's/;//'`;do echo IMAGES+=$$i >>.deps; done;)
	@echo -n "BIB+=" >> .deps
	@$(foreach f,$(MAIN_TEX), cat $f | grep "\\\\bibliography" | sed 's/\\bibliography{//' | sed 's/}//g' | sed 's/,/ /g'| sed 's/}//g' | sed 's/,/ /g' >>.deps;)
	@echo >> .deps
	@echo -n "ACRONYMS+=" >> .deps
	@$(foreach f,$(MAIN_TEX), cat $f | grep "\\\\loadglsentries" | sed 's/\\loadglsentries{//' | sed 's/}/.tex/g' | sed 's/,/ /g'| sed 's/}//g' >>.deps;)
	@echo >> .deps

clean:
	@(rm .deps .files *.pdf *.bcf *.aux *.bbl *.blg *.dvi *.ps *.log *.run.xml *.fls *.*latexmk *-blx.bib; echo "") 1>/dev/null 2>/dev/null

dist-clean: clean
	-@rm $(REPOS) -rf
