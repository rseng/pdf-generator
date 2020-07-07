#!/bin/bash

set -e

# Change working directory
if [ ! -z "${INPUT_WORKDIR}" ]; then
    printf "Changing working directory to ${INPUT_WORKDIR}\n"
    cd "${INPUT_WORKDIR}"
fi

printf "Files in workspace:\n"
ls

# If both paper markdown and paper_dir are unset, nothing to do
if [ -z "${INPUT_PAPER_MARKDOWN}" ] && [ -z "${INPUT_PAPER_DIR}" ]; then
    printf "Please define either paper_markdown or paper_dir.\n"
    exit 1
fi

# Check that the paper markdown file exists
if [ ! -z "${INPUT_PAPER_MARKDOWN}" ]; then
    if [ ! -f "${INPUT_PAPER_MARKDOWN}" ]; then
        printf "Input markdown for paper ${INPUT_PAPER_MARKDOWN} not found.\n"
        exit 1
    fi
fi

if [ ! -z "${INPUT_PAPER_DIR}" ]; then

    # Make sure input directoy exists
    if [ ! -d "${INPUT_PAPER_DIR}" ]; then
        printf "Input directory ${INPUT_PAPER_DIR} not found.\n"
        exit 1
    fi

    # If output directory defined, it needs to exist too
    if [ ! -z "${INPUT_OUTPUT_DIR}" ]; then
        if [ ! -d "${INPUT_OUTPUT_DIR}" ]; then
            printf "Output directory ${INPUT_OUTPUT_DIR} not found.\n"
            exit 1
        fi
    fi
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

printf "paperdir: ${INPUT_PAPER_DIR}\n"
printf "template: ${INPUT_LATEX_TEMPLATE}\n"
printf " mapping: ${INPUT_MAPPING_FILE}\n"
printf "variable: ${INPUT_VARIABLES_FILE}\n"
printf "  output: ${INPUT_PAPER_OUTFILE}\n"
printf "  bibtex: ${INPUT_BIBTEX}\n"
printf "   paper: ${INPUT_PAPER_MARKDOWN}\n"
printf "    type: ${INPUT_PDF_TYPE}\n"
printf "    logo: ${INPUT_PNG_LOGO}\n"


# Generate ---------------------------------------------------------------------

generate_minimal() {

    INPUT_PAPER_MARKDOWN="${1}"
    INPUT_PAPER_OUTFILE="${2}"
    INPUT_BIBTEX="${3}"
    printf "Producing minimal pdf for ${INPUT_PAPER_MARKDOWN} -> ${INPUT_PAPER_OUTFILE}\n"

    COMMAND="pandoc ${INPUT_PAPER_MARKDOWN} --filter pandoc-citeproc"
    if [ ! -z "${INPUT_BIBTEX}" ]; then
        COMMAND="${COMMAND} --bibliography ${INPUT_BIBTEX}"
    fi
    COMMAND="${COMMAND} -o ${INPUT_PAPER_OUTFILE}"
    printf "${COMMAND}\n"
    $COMMAND

}

generate_mappings() {

    mappings=""
    INPUT_MAPPING_FILE="${1}"
    INPUT_VARIABLES_FILE="${2}"
    OUTPUT_FILE="${3}"
    OUTPUT_MAPPINGS_TO="${4}"

    if [ ! -z "${INPUT_MAPPING_FILE}" ]; then
        if [ ! -f ${INPUT_MAPPING_FILE} ]; then
            printf "${INPUT_MAPPING_FILE} is not found\n"
            exit 1
        fi
        while IFS= read -r line; do
            if [ ! -z "${line}" ]; then
                IFS=' ' read -r mappingkey mappingval <<< "$line"
                value=$(ob-paper get ${INPUT_PAPER_MARKDOWN} ${mappingval})
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
                IFS=' ' read -r key val <<< "$line"
                if [ ! -z "${val}" ]; then
                    mappings="$mappings -V ${key}=\"${val}\""
                else
                    mappings="$mappings -V ${key}="
                fi
            fi
        done < "$INPUT_VARIABLES_FILE"
    fi

    # And finally, write variable defaults for different files
    pdf_generator_outdir=$(dirname "${OUTPUT_FILE}")
    pdf_generator_basename=$(basename "${OUTPUT_FILE}")
    pdf_generator_fileprefix="${pdf_generator_basename%.pdf}"
    mappings="$mappings -V pdf_generator_outfile=\"${OUTPUT_FILE}\""
    mappings="$mappings -V pdf_generator_outdir=\"${pdf_generator_outdir}\""
    mappings="$mappings -V pdf_generator_fileprefix=\"${pdf_generator_fileprefix}\""
    mappings="$mappings -V pdf_generator_basename=\"${pdf_generator_basename}\""
    echo "${mappings}" > "${OUTPUT_MAPPINGS_TO}"
}

function get_outdir {

    INPUT_PAPER_MARKDOWN="${1}"
    INPUT_OUTPUT_DIR="${2}"
    outfile_relative=$(realpath --relative-to="." "${INPUT_PAPER_MARKDOWN}")
    outfile=$(basename ${outfile_relative%.md}).pdf
    if [ ! -z "${INPUT_OUTPUT_DIR}" ]; then
        outfile="${INPUT_OUTPUT_DIR}/${outfile}"
    else
        outdir=$(dirname "${outfile_relative}")
        outfile="${outdir}/${outfile}"
    fi
    echo "${outfile}"
}

# Minimal PDF generation

if [ "${INPUT_PDF_TYPE}" == "minimal" ]; then
    if [ ! -z "${INPUT_PAPER_MARKDOWN}" ]; then
        generate_minimal "${INPUT_PAPER_MARKDOWN}" "${INPUT_PAPER_OUTFILE}" "${INPUT_BIBTEX}"
    else
        for INPUT_PAPER_MARKDOWN in $(find "${INPUT_PAPER_DIR}" -regex '.*/[^/]*.md'); do
            outfile=$(get_outdir "${INPUT_PAPER_MARKDOWN}" "${INPUT_OUTPUT_DIR}")
            # Only run if outfile does not exist
            if [ ! -f "${outfile}" ]; then
                generate_minimal "${INPUT_PAPER_MARKDOWN}" "${outfile}" "${INPUT_BIBTEX}"
            fi
        done
    fi

# PDF with template generation

else

    if [ ! -z "${INPUT_PAPER_MARKDOWN}" ]; then

        # Build command programatically
        mappingfile=$(mktemp /tmp/mappings.XXXXXX)
        generate_mappings "${INPUT_MAPPING_FILE}" "${INPUT_VARIABLES_FILE}" "${outfile}" "${mappingfile}"
        mappings=$(cat "${mappingfile}")
        rm "${mappingfile}"
        COMMAND="/usr/bin/pandoc ${mappings}"

        # Bibliography?
        if [ ! -z "${INPUT_BIBTEX}" ]; then
            COMMAND="${COMMAND} --bibliography ${INPUT_BIBTEX}"
        fi

        COMMAND="${COMMAND} -V graphics=\"true\" -V logo_path=\"${INPUT_PNG_LOGO}\" -V geometry:margin=1in -o ${INPUT_PAPER_OUTFILE} --pdf-engine=xelatex --filter /usr/bin/pandoc-citeproc ${INPUT_PAPER_MARKDOWN} --from markdown+autolink_bare_uris --template ${INPUT_LATEX_TEMPLATE}"

        # Verbose output?
        if [ "${INPUT_VERBOSE}" == "true" ]; then
            COMMAND="${COMMAND} --verbose" 
        fi
        printf "$COMMAND\n"
        printf "${COMMAND}" > pandoc_run.sh
        chmod +x pandoc_run.sh
        /bin/bash pandoc_run.sh

    else
        for INPUT_PAPER_MARKDOWN in $(find "${INPUT_PAPER_DIR}" -regex '.*/[^/]*.md'); do
            outfile=$(get_outdir "${INPUT_PAPER_MARKDOWN}" "${INPUT_OUTPUT_DIR}")

            # Only run if outfile does not exist
            if [ ! -f "${outfile}" ]; then

                COMMAND="/usr/bin/pandoc"
                mappingfile=$(mktemp /tmp/mappings.XXXXXX)
                generate_mappings "${INPUT_MAPPING_FILE}" "${INPUT_VARIABLES_FILE}" "${outfile}" "${mappingfile}"
                mappings=$(cat "${mappingfile}")
                rm "${mappingfile}"

                # Bibliography?
                if [ ! -z "${INPUT_BIBTEX}" ]; then
                    COMMAND="${COMMAND} --bibliography ${INPUT_BIBTEX}"
                fi

                # Verbose?
                if [ "${INPUT_VERBOSE}" == "true" ]; then
                    COMMAND="${COMMAND} --verbose" 
                fi

                COMMAND="${COMMAND} ${mappings} -V graphics=\"true\" -V logo_path=\"${INPUT_PNG_LOGO}\" -V geometry:margin=1in  -o ${outfile} --pdf-engine=xelatex --filter /usr/bin/pandoc-citeproc ${INPUT_PAPER_MARKDOWN} --from markdown+autolink_bare_uris --template ${INPUT_LATEX_TEMPLATE}"
                printf "$COMMAND\n"
                printf "${COMMAND}" > pandoc_run.sh
                chmod +x pandoc_run.sh
                /bin/bash pandoc_run.sh
            fi
        done
    fi
fi

if [ -f "${INPUT_PAPER_OUTFILE}" ]; then
    printf "Files in workspace:\n"
    ls
    chmod 0777 "${INPUT_PAPER_OUTFILE}"
fi
if [ -d "${INPUT_PAPER_DIR}" ]; then
    printf "Files generated:\n"
    ls "${INPUT_PAPER_DIR}"
    chmod -R 0777 "${INPUT_PAPER_DIR}"
fi
