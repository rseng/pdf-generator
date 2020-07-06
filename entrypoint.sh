#!/bin/bash

printf "Files in workspace:\n"
ls
ls paper

# Check that the paper markdown file exists
if [ ! -f "${INPUT_PAPER_MARKDOWN}" ]; then
    printf "Input markdown for paper ${INPUT_PAPER_MARKDOWN} not found.\n"
    exit 1
fi

# And the latex template
if [ ! -f "${INPUT_LATEX_TEMPLATE}" ]; then
    printf "LaTex template ${INPUT_LATEX_TEMPLATE} does not exist."
    exit 1
fi

# And the logo
if [ -z "${INPUT_PNG_LOGO}" ]; then

    echo "Cannot find logo, generating randomly!"
    OPENBASES_ICON_URL=$(ob-icons)
    OPENBASES_ICON=/tmp/$(basename ${OPENBASES_ICON_URL})
    wget "${OPENBASES_ICON_URL}" -O ${OPENBASES_ICON}

    # Fall back to openbases logo
    if [ ! -f "${OPENBASES_ICON}" ]; then
        INPUT_PNG_LOGO="/code/paper/openbases-logo.png"
    else
        INPUT_PNG_LOGO="${OPENBASES_ICON}"
    fi
fi

# Make sure it exists
if [ ! -f "${INPUT_PNG_LOGO}" ]; then
    printf "${INPUT_PNG_LOGO} does not exist.\n"
    exit 1
fi

# Make sure that a png file is provided
if [ "${INPUT_PNG_LOGO: -4}" != ".png" ]; then
    printf "${INPUT_PNG_LOGO} is not a png file.\n"
    exit 1
fi

# Alert the user to all their settings

printf "template: ${INPUT_LATEX_TEMPLATE}\n"
printf "  output: ${INPUT_PAPER_OUTFILE}\n"
printf "  bibtex: ${INPUT_BIBTEX}\n"
printf "   paper: ${INPUT_PAPER_MARKDOWN}\n"
printf "    type: ${INPUT_PDF_TYPE}\n"
printf "    logo: ${INPUT_PNG_LOGO}\n"


# Generate ---------------------------------------------------------------------

if [ "${INPUT_PDF_TYPE}" == "minimal" ]; then

    printf "Producing minimal pdf.\n"
    COMMAND="pandoc ${INPUT_PAPER_MARKDOWN} --filter pandoc-citeproc"
    if [ ! -z "${INPUT_BIBTEX}" ]; then
        COMMAND="${COMMAND} --bibliography ${INPUT_BIBTEX}"
    fi
    COMMAND="${COMMAND} -o ${INPUT_PAPER_OUTFILE}"
    printf "${COMMAND}\n"
    $COMMAND

else

    authors=$(ob-paper get ${INPUT_PAPER_MARKDOWN} authors:name)
    title=$(ob-paper get ${INPUT_PAPER_MARKDOWN} title)
    repo=$(ob-paper get ${INPUT_PAPER_MARKDOWN} repo)
    archive_doi=$(ob-paper get ${INPUT_PAPER_MARKDOWN} archive_doi)
    formatted_doi=$(ob-paper get ${INPUT_PAPER_MARKDOWN} formatted_doi)
    paper_url=$(ob-paper get ${INPUT_PAPER_MARKDOWN} paper_url)
    review_issue_url=$(ob-paper get ${INPUT_PAPER_MARKDOWN} review_issue_url)
    
    /usr/bin/pandoc \
        -V paper_title="${title}" \
        -V footnote_paper_title="${title}" \
        -V citation_author="${authors}" \
        -V repository="${repo}" \
        -V archive_doi="${archive_doi}" \
        -V formatted_doi="${formatted_doi}" \
        -V paper_url="http://joss.theoj.org/papers/" \
        -V review_issue_url="https://github.com/openjournals/joss-reviews/issues/${issue}" \
        -V issue="${issue}" \
        -V volume="${vol}" \
        -V year="${year}" \
        -V submitted="${submitted}" \
        -V published="${accepted}" \
        -V page="${issue}" \
        -V graphics="true" \
        -V logo_path="${INPUT_PNG_LOGO}" \
        -V geometry:margin=1in \
        --verbose \
        -o "${INPUT_PAPER_OUTFILE}" \
        --bibliography "${INPUT_BIBTEX}" \
        --pdf-engine=xelatex \
        --filter /usr/bin/pandoc-citeproc "${INPUT_PAPER_MARKDOWN}" \
        --from markdown+autolink_bare_uris \
        --template "${INPUT_LATEX_TEMPLATE}"

fi

printf "Files in workspace:\n"
ls
ls paper

chmod 0777 "${INPUT_PAPER_OUTFILE}"
