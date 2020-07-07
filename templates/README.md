# Templates

The templates within each have a set of default variables that you can define
in the markdown to have them show up in the paper. These include the following (if
a mapping isn't mentioned, assume it's the same as the field name):

 - **authors**: mapped from authors:name
 - **tite** 
 - **repo** 
 - **issue**
 - **vol**
 - **year**
 - **archive_doi**
 - **formatted_doi**
 - **paper_url**
 - **review_issue_url**
 - **submitted**
 - **accepted**


## Namespaced Variables

In the case that you want to generate a link to the pdf itself (or some other
GitHub pages rendering) there are also a set of namespaced variables to do that.

  - **pdf_generator_outfile** the full path of the output file, relative to the input directory
  - **pdf_generator_outdir** the full path of the output directory, also relative to the input directory
  - **pdf_generator_basename** the base name of the generated file (event-01.pdf)
  - **pdf_generator_fileprefix** just the name of the file without .pdf.

You can assemble these however you need in your template to generate a custom path. For example,
for a Jekyll collection of events (on GitHub pages) you might define a url and baseurl
in a variables.txt:

```
url https://sorse.github.io
baseurl sorse20
```

and then assemble the variables as follows:

```bash
\href{$url$/$baseurl$/$pdf_generator_outdir$/$pdf_generator_fileprefix$/}
```
