FROM ubuntu:base
LABEL description="Image for MAJIQ"
LABEL maintainer="Alexander Dietrich"

#install htslib

WORKDIR /usr/local/lib
RUN wget https://github.com/samtools/htslib/releases/download/1.9/htslib-1.9.tar.bz2 && tar -vxjf htslib-1.9.tar.bz2 && rm -f htslib-1.9.tar.bz2 && cd htslib-1.9 && make && make install

#install python3.8 and update pip
RUN apt-get update -y && apt-get --no-install-recommends --fix-broken install -y software-properties-common
RUN add-apt-repository ppa:deadsnakes/ppa -y -u
RUN apt-get update && apt-get --no-install-recommends --fix-broken install -y python3.8 python3.8-dev python3-pip python3.8-venv
RUN python3.8 -m pip install pip --upgrade
ENV HTSLIB_INCLUDE_DIR="/usr/local/lib/htslib-1.9/"
ENV HTSLIB_LIBRARY_DIR="/usr/local/lib/htslib-1.9/"



#install majiq dependencies
RUN pip3.8 install --no-cache-dir -U wheel setuptools
RUN pip3.8 install --no-cache-dir -U numpy cython pandas
RUN apt-get update -y && apt-get --no-install-recommends --fix-broken install -y git

# Install unification dependencies
RUN pip3.8 install --no-cache-dir -U pandas

#download and install majiq from source
WORKDIR /tmp
RUN git clone https://bitbucket.org/biociphers/majiq_academic.git
WORKDIR /tmp/majiq_academic
RUN pip3.8 install --no-cache-dir .
RUN python3.8 setup.py install
#RUN rm -rf /tmp
WORKDIR /opt

#download and add script to convert GTF file to GFF3 format
RUN wget --no-check-certificate http://majiq.biociphers.org/download/gtf2gff3.pl && wget --no-check-certificate  http://www.sequenceontology.org/resources/gtf2gff3.cfg

ENV PATH=/usr/local/sbin:/usr/local/bin:/usr/local/lib/usr/sbin:/usr/bin:/sbin:/bin:/opt:/usr/local/lib/htslib-1.9

WORKDIR /docker_main
RUN chmod 777 /tmp

COPY [--chown=nobody:nogroup] ./ENTRYPOINT.sh /docker_main/ENTRYPOINT.sh
RUN chmod 777 /docker_main/ENTRYPOINT.sh
ENTRYPOINT ["/docker_main/ENTRYPOINT.sh"]
