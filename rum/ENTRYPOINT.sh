#!/bin/bash

### Needed Functions

#Unpaired mapping command
#...tag outputs with this flag to name it per fastqfile 	"${line##*/}"
#...address for all gtf files are 				$(find /myvol1/ -name "*.gtf")
second_attempt() {
echo "paired mapping failed for ${line}. Try unpaired mapping."
crac -i /myvol1/index/${tool}-index/crac-index -k 22 -r ${line}?.fastq -o /myvol1/"$tool"-output/${line##*/}crac.sam --detailed-sam --nb-threads 64 
}

build_index() {
#Build Genome index
# find gtf and da files with these  $(find /myvol1/ -name "*.fa")  $(find /myvol1/ -name "*.gtf")
mkdir -p /myvol1/index/${tool}-index
echo "compute index"
crac-index index /myvol1/index/${tool}-index/crac-index $(ls /myvol1/Homo_sapiens.GRCh38.dna.primary_assembly.fa)
chmod -R 777 /myvol1/index/${tool}-index/
}

#cleaning up
cleaner() {
rm /myvol1/"$tool"-fastqlist
echo "script is done";exit;
}

#START here: Make a list of fastq files ############################################################################
tool=rum
find /myvol1/ -name "*fastq" -nowarn -maxdepth 1| sed s/.fastq// | sed 's/.$//' | sort | uniq >/myvol1/"$tool"-fastqlist
chmod 777 /myvol1/"$tool"-fastqlist

#test filepaths for fasta and indexing
if ! test -f "/myvol1/Homo_sapiens.GRCh38.dna.primary_assembly.fa"; 
	then echo "check the path for the Homo_sapiens.GRCh* fasta files: is it under <mounted folder>/Homo_sapiens.GRCh*.fa?";
	cleaner;
	exit; fi
if ! test -d "/myvol1/index/${tool}-index"; then build_index; fi

#make output directories
mkdir -p /myvol1/"$tool"-output/
chmod -R 777 /myvol1/"$tool"-output/


echo "compute $tool mapping..."



#Iterate list with paired end map command first
while read -r line; do

#First attempt: Paired end mapping
#...tag outputs with this flag to name it per fastqfile         "${line##*/}"
#...address for all gtf files are                               $(find /myvol1/ -name "*.gtf")

#clean folder in case previous run left junk because of errors
rum_runner clean -o /myvol1/"$tool"-output/

#initialize
rum_runner init         \
    --output /myvol1/"$tool"-output/    \
    --name   "$tool"   \
    --index  /myvol1/index/${tool}-index/ \
    --chunks 64          \
    ${line}1.fastq ${line}2.fastq

#preprocessing
rum_runner resume      \
    --output /myvol1/"$tool"-output/    \
    --preprocess

#chunks
rum_runner resume      \
    --output /myvol1/"$tool"-output/ \
    --child            \
    --chunk $chunk
	
#postprocessing
rum_runner resume      \
    --output /myvol1/"$tool"-output/ \
    --postprocess

#If paired end mapping fails, run unpaired mapping.
trap 'second_attempt $line' ERR
done </myvol1/"$tool"-fastqlist

#make output accessible
chmod -R 777 /myvol1/"$tool"-output/

#wait for all processes to end
wait
cleaner
