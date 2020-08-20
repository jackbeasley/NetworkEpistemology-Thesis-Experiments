
BASEDIR=$(CURDIR)
SOURCE_DIR=$(BASEDIR)/source
TEX_OUT_DIR=$(BASEDIR)/tex-out
OUTPUT_DIR=$(BASEDIR)
OUTPUT_NAME=thesis.pdf
OUT=${OUTPUT_DIR}/${OUTPUT_NAME}

SOURCE_FILES=$(wildcard $(SOURCE_DIR)/*.md)
TEX_OUT_FILES = $(SOURCE_FILES:${SOURCE_DIR}/%.md=${TEX_OUT_DIR}/%.tex)
BIB_FILE=$(BASEDIR)/references.bib
CSL_FILE=$(BASEDIR)/chicago-note-bibliography.csl
PDF_PREFS_FILE=$(BASEDIR)/pdf-prefs.yaml

.PHONY: all
all: ${TEX_OUT_FILES} ${OUT}

.PHONY: clean
clean:
	rm ${OUT} || true
	rm ${TEX_OUT_FILES} || true

${TEX_OUT_FILES}: ${TEX_OUT_DIR}/%.tex: ${SOURCE_DIR}/%.md
	pandoc --biblatex --filter pandoc-xnos --top-level-division=chapter $< -o $@ 

${OUT}: ${TEX_OUT_FILES} thesis.tex suthesis-2e.sty
	latexmk -bibtex -pdf thesis.tex

#${OUT}: $(SOURCE_FILES)
#	pandoc $(SOURCE_FILES) \
#	-o $(OUTPUT_DIR)/thesis.pdf \
#	--bibliography $(BIB_FILE) \
#	--csl $(CSL_FILE) \
#	-d $(PDF_PREFS_FILE) \
#	-N \
#	--filter pandoc-xnos \
#	--pdf-engine=xelatex \
#	--toc
