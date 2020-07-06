#!/bin/bash

# Change working directory
if [ ! -z "${INPUT_WORKDIR}" ]; then
    printf "Changing working directory to ${INPUT_WORKDIR}\n"
    cd "${INPUT_WORKDIR}"
fi

printf "Files in workspace:\n"
ls

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

    # Generate list of variables from the mapping file
    mappings=""
    if [ ! -z "${INPUT_MAPPING_FILE}" ]; then
        if [ ! -f ${INPUT_MAPPING_FILE} ]; then
            printf "${INPUT_MAPPING_FILE} is not found\n"
            exit 1
        fi
        while IFS= read -r line; do
            if [ ! -z "${line}" ]; then
                mappingkey=$(cut -d ' ' -f 1 <<< "$line")
                mappingval=$(cut -d ' ' -f 2 <<< "$line")
                value=$(ob-paper get ${INPUT_PAPER_MARKDOWN} ${mappingval})
                echo $value
                mappings="$mappings -V ${mappingkey}=\"${value}\""
            fi
        done < "$INPUT_MAPPING_FILE"
    fi

    # Now add hard coded variables
    if [ ! -z "${INPUT_VARIABLES_FILE}" ]; then
        if [ ! -f ${INPUT_VARIABLES_FILE} ]; then
            printf "${INPUT_VARIABLES_FILE} is not found\n"
            exit 1
        fi
        while IFS= read -r line; do
            if [ ! -z "${line}" ]; then
                key=$( cut -d ' ' -f 1 <<< "$line" )
                val=$( cut -d ' ' -f 2 <<< "$line" )
                if [ ! -z "${val}" ]; then
                    mappings="$mappings -V ${key}=\"${val}\""
                else
                    mappings="$mappings -V ${key}="
                fi
            fi
        done < "$INPUT_VARIABLES_FILE"
    fi

    # Build command programatically
    COMMAND="/usr/bin/pandoc"
    if [ ! -z "${mappings}" ]; then
        COMMAND="${COMMAND} ${mappings}"
    fi

    # Bibliography?
    if [ ! -z "${INPUT_BIBTEX}" ]; then
        COMMAND="${COMMAND} --bibliography ${INPUT_BIBTEX}"
    fi
    COMMAND="${COMMAND} -V graphics=\"true\" -V logo_path=\"${INPUT_PNG_LOGO}\" -V geometry:margin=1in --verbose -o ${INPUT_PAPER_OUTFILE} --pdf-engine=xelatex --filter /usr/bin/pandoc-citeproc ${INPUT_PAPER_MARKDOWN} --from markdown+autolink_bare_uris --template ${INPUT_LATEX_TEMPLATE}"
    printf "$COMMAND\n"
    printf "${COMMAND}" > pandoc_run.sh
    chmod +x pandoc_run.sh
    /bin/bash pandoc_run.sh

fi

if [ ! -f "${INPUT_PAPER_OUTFILE}" ]; then
    printf "There was an issue rendering ${INPUT_PAPER_OUTFILE}\n"
    exit 1
else
    printf "Files in workspace:\n"
    ls
    chmod 0777 "${INPUT_PAPER_OUTFILE}"
fi
