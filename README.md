# PDF Generator

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
| workdir | if not the root of the repository, change to this directory first | no | unset |
| variables_file | a file with lines of hard coded key=values to add | no | unset | 
| mapping_file | a file with lines of key=value mappings to use | no | unset | 
| paper_dir | If you want to render an entire folder of markdowns (recursive) set this variable | no | unset |
| output_dir | Only used when paper_dir is defined, write output papers to this directory. | no | unset |

**Important** if you set an output directory, the output files will be named based on the 
markdown basename. You should ensure uniqueness of names, even between directories.

### Quick Example

If you want to render from a latex template, you might add a step that looks like this:

```yaml
 # See https://github.com/rseng/pdf-generator for release
 - name: Generate Full PDF Template      
   uses: rseng/pdf-generator@master
   with:        

     # The latex template to use (defaults to one here)
     latex_template: templates/latex.template.joss

     # The markdown file to render,path is relative to repository
     # make sure that images are also relative to the root in the file
     paper_markdown: paper/paper.md

     # The paper pdf to save
     paper_outfile: paper.pdf

     # Bibliography file, if existing
     bibtex: paper/paper.bib

     # A path to a png logo file
     png_logo: paper/sorse.png

     # One of "minimal" or "pdf" for the template with image, etc.
     pdf_type: pdf

     # A variables file to use
     variables_file: templates/joss-variables.txt
 
     # A mapping file to use
     mapping_file: templates/joss-mapping.txt
```

or if you want to generate a [minimal](paper/minimal.pdf) version you might
do:

```yaml
 - name: Generate Minimal PDF
 
   # Important! Update to release https://github.com/rseng/rse-action/releases
   uses: ./
   with:        

     # The markdown file to render,path is relative to repository
     paper_markdown: paper/paper.md

     # The paper pdf to save
     paper_outfile: minimal.pdf

     # Bibliography file, if existing
     bibtex: paper/paper.bib

     # One of "minimal" or "pdf" for the template with image, etc.
     pdf_type: minimal
```

See the [examples](examples) folder for a full recipe.


### Variables

For the mapping file, this would mean that if you have a variable in your markown `title`
that should be rendered to `paper_title`, you would have a line like this:

```
paper_title title
```
> paper_title in the template is rendered from title in the markdown"

And of course if they were the same (both title) you could leave this out.
If you wanted to render a list of "authors" from a subfield in your markdown (e.g.,
authors is a list and each has a name) you might do this:

```
authors authors:name
```

This is different from a variable file where you would put "hard coded values"

```
title This is the title of my paper
```

Take a look at the variables and mapping example files in the [templates](templates) folder,
and examples for GitHub actions in the [examples](examples) folder.

## Templates

If you use the `pdf_type` "pdf" instead of "minimal" you will render your markdown
using a template. The templates available are in [templates](templates) and each template
can render a particular set of variables (e.g., authors, title, dois). There are two
ways you can add variables to your templates:

 1. **In the front end matter of the markdown**. Let's say the template has a `$doi$` somewhere. If you define the variable `doi` in your front end matter, it will be rendered. This is the suggested approach to take for most templates.
 2. **In a variables.txt file**. If you want to define variables on the fly, you can generate a custom file with a pair of variables on each line. For example, take a look at the [templates/variables-joss.txt](templates/variables-joss.txt) file. Definition on the command line takes preference over in the front end matter, and if you want to use this file with a template, you should define the `variables_file` parameter for the action.


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
export INPUT_LATEX_TEMPLATE=templates/latex.template.joss
export INPUT_PAPER_OUTFILE=paper/minimal.pdf
export INPUT_BIBTEX=paper/paper.bib
export INPUT_PDF_TYPE=minimal
export INPUT_PNG_LOGO=paper/documents-icon.png
export INPUT_VARIABLES_FILE=templates/joss-variables.txt
export INPUT_MAPPING_FILE=templates/joss-mapping.txt
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
