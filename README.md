# PDF Builder

> Hi friend! :wave:

This is a GitHub action that will make it easy to generate a PDF for your
software! If you are looking for a command line tool, see [openbases/openbases-pdf](https://github.com/openbases/openbases-pdf).
This repository is intended for GitHub action usage, and basic Docker usage.

This repository is **under development**! We have yet to design an easy way to
define (and then export) template substitutions - possibly we will look into
providing a file that includes these substitutions, or some kind of list 
definition.

## GitHub Action Usage

The following variables are defined and can be customized.

| name | description | required | default |
|------|-------------|----------|---------|
| paper_markdown | The path to the paper.md file. | yes | paper/paper.md |
| paper_outfile | The path to the PDF to be generated. | no | paper.pdf |
| bibtex | If needed, an optional bibliography file (prefix .bib) | no | unset |
| png_logo | A png logo file to render in the top left of the paper | no | unset |
| latex_template | the latex template to use. | no | paper/latex.template.joss |
| pdf_type | one of minimal (standard pandoc latex) or pdf (template) | no | minimal |

We will be adding example recipes and testing soon.

## Local Usage

First, build the container.

```bash
$ docker build -t rseng/pdf-generator .
```

Then shell into the container with a bash entrypoint. You probably want to bind the
directory with your paper files (paper, bibliography, logos) to the container.
The GitHub workspace is a good option, since it exists and this is the 
working directory for the action anyway.

```bash
docker run -it --entrypoint bash -v $PWD:/github/workspace rseng/pdf-generator
```

There is also a paper provided at `/code` if you don't have your own handy, and
don't want to create the mount:

```bash
docker run -it --entrypoint bash rseng/pdf-generator
```

Once inside the container, you can check that pandoc exists.

```bash
# which pandoc
/usr/bin/pandoc
```

Normally the entrypoint would look for input parameters to be exported
to define different variables. We can just do that manually instead. These
should be relative to where you are running the script from.

```bash
export INPUT_PAPER_MARKDOWN=paper/paper.md
export INPUT_LATEX_TEMPLATE=paper/latex.template.joss
export INPUT_PAPER_OUTFILE=paper/minimal.pdf
export INPUT_BIBTEX=paper/paper.bib
export INPUT_PDF_TYPE=minimal
export INPUT_PNG_LOGO=paper/documents-icon.png
```

And then run the entrypoint script to generate your paper!

```bash
$ ./code/entrypoint.sh
```

You can also try generating the more complex type:

```bash
export INPUT_PDF_TYPE=pdf
export INPUT_PAPER_OUTFILE=paper/paper.pdf
```

Have a question or need help? Please [open an issue](https://www.github.com/vsoch/pdf-generator/issues)
