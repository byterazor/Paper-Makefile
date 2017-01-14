## Description

The Paper Makefile is a Makefile for generating a paper.pdf from a latex source. It manages
most of the dependencies like generating pdf images from SVG, reducing the size of JPG or PNG
and generating svg images from dot files.

*Directory organization*

In the directory the Makefile is located it clones the repositories for Images, Acronyms and Bibliography. They are
named exactly like that. Furthermore, it clones the Paper-Makefile
repository and the style-check repository from github.

An initial paper.tex file is generated and committed to the papers
git repository. You can rename it or generate a new one.

*Important*

It is best to divide your paper in several tex files, e.g. for each chapter a single file. Put these files in a subdirectory, otherwise the Makefile will treat each TEX file as one paper.

## Motivation

The Makefile was created during my early days in scientific research. I needed an easy way to create and manage papers.
I did not want to recreate everything from scratch for every
new idea.

I started to manage all my images, acronyms and bibliography in
individual git repositories and each of my papers is a git repository of its own.

## Installation

1. create a new directory for holding your paper (mkdir <dirname>)
2. Download the example Makefile from the Paper Makefile repository
3. Edit the Makefile and adapt the repository locations to your needs.
3. run ```make init ```
4. rename paper.tex to your liking and start writing


## Usage

make target | description
------------ | -------------
init | initialize the directory for use with the Paper Makefile
help | display all available targets
all  | create PDFs from all TEX files in the directory. This is the default target.
update | update all git repositories
check | use the style-check.rb script to check all used TEX files for styles
add-ieee | download IEEEtran style and add the cls file
remove-ieee | remove the IEEEtran style
clean | clean up all generated files
dist-clean | do a clean and remove all repositories
< name >.tex | create a TEX file for a new paper

## Contributors

If you extend the Makefile to your needs please send me a pull request, so i can advance this Makefile.

## License

The Paper Makefile is licensed under GPLv2.
