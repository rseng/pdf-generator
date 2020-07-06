FROM ubuntu:18.04
# docker build -t rseng/pdf-generator .

LABEL maintainer "@vsoch"
ENV DEBIAN_FRONTEND noninteractive

RUN apt update && \
    apt install --yes --no-install-recommends \
       git \
       biber \
       build-essential \
       lmodern \
       pandoc \
       pandoc-citeproc \
       texlive-xetex \
       texlive \
       texlive-latex-extra \
       texlive-bibtex-extra \
       texlive-fonts-recommended \
       tree \
       python3 \
       python3-pip \
       python3-setuptools \
       wget && \
    wget -O /tmp/pandoc.deb https://github.com/jgm/pandoc/releases/download/2.1.1/pandoc-2.1.1-1-amd64.deb && \
    dpkg -i /tmp/pandoc.deb && \
    mkdir -p /data /code  && \
    pip3 install openbases

ADD . /code
RUN chmod u+x /code/entrypoint.sh
WORKDIR /github/workspace

ENTRYPOINT ["/bin/bash", "/code/entrypoint.sh"]
