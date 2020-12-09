#!/bin/bash 

#Read gtf file and test if its available
#Parameter: Full path to gtf file

test_gtf(){
	if [[ ! -f $1 ]]
	then 
		echo File not found. Check the path for the ${gtf} gtf file.
		exit 1
	else
		echo found gtf file, moving on...
	fi
}


#Read fasta file and test if its available
#Parameter: Full path to fasta file

test_fasta(){
        if [[ ! -f $1 ]]
        then
                echo File not found. Check the path for the ${fasta} fasta file.
                exit 1
        else
                echo found fasta file, moving on...
        fi
}




#test if BAM file is available and has index file with it
#Parameter: Full path to BAM-file
test_bam(){
	if [[ ! -f $1  ]]
	then
		echo File not found. Check path for the $bamfile file: is it in ${bamdir}?
		exit 1
	else
		echo found bam file, moving on...
		if [[  ! -f ${1}.bai  ]]
		then
			echo File not found. Did not find index file for ${1}. Check if it has the same name as ${1} and is in ${bamdir}.
		else
			echo found bam index, moving on...
		fi
	fi
}


#take all BAM & BAM-index files from bamfolder(or case-/controlfolder) and store paths in the new bamlist contained in the tool-output folder
#Parameter1: folder to check for bam files; 
#Parameter2: optional output filename (standard is bamlist)
readbamfiles(){
	find ${1:-$bamdir} -maxdepth 1 -name "*.bam" -nowarn -not -empty >> $outdir/${2:-bamlist}
	chmod  777 $outdir/${2:-bamlist}
}

#just as readbamfiles, but for SAM-files
#parameter1: optional different bamdirectory
readsamfiles(){
	#touch $wd/$output/${tool:-unspecific}-output/samlist
	find ${1:-$bamdir} -maxdepth 1 -name "*.sam" -nowarn -not -empty >> $outdir/samlist
	chmod  777 $outdir/samlist
}


indexbam(){
	if [ ! -s ${1}.bai ] ; then 
		samtools index $1  -@ 4
	fi
}

#sort bams if unsorted
sortnindexbam(){
	if [[ ! "$(samtools view -H $1 | grep SO: | cut -f 3 | cut -d ":" -f2)" == "coordinate" ]]; then
		#local bamname=$(basename -s .bam $1)
			samtools sort $1 -o $1 && \
			indexbam $1
	fi
}


#Function: Check if bam exists in sam folder or bam folder, if not, build a bam from sam in parameter, sort and index it.
#Parameter1: Full file path to sam file
#Parameter2: directory on which this function is used ($bamdir or $casebam or $controlbam); default is $bamdir
makebamfromsam(){
	local sampath=$(dirname $1)
	local samfileprefix=$(basename -s .sam $1)

		if [[ ! -e ${sampath}/${samfileprefix}.bam ]] 
			then
				if [[ ! -e ${2:-$bamdir}/${samfileprefix}.bam ]]
					then
					{
#Make a Bam file
						echo making bam of $1, in ${2:-$bamdir}/$samfileprefix.bam.  This may take a while..
							samtools view -bS $1 > ${2:-$bamdir}/${samfileprefix}.bam
#Sort bam file
						echo sorting and indexing bam file $samfileprefix.bam
							sortnindexbam "${2:-$bamdir}/$samfileprefix.bam"
					}
				else 
					echo bam file for $1 exists in ${2:-$bamdir}
						sortnindexbam "${2:-$bamdir}/$samfileprefix.bam"				
				fi
		else
			echo bam file for $1 exists in $sampath
				#if [[ ! -e ${2:-$bamdir}/${samfileprefix}.bam ]] ; then
				#	mv $1 "${2:-$bamdir}" 
				#		echo "moved $1 to :" ${2:-$bamdir}
				#		sortnindexbam "${2:-$bamdir}/${samfileprefix}.bam"
				#fi
		fi
} 

#function to handle sam files in either bamdir (for as_tools) or case/control-bamdir (for ds_tools)
#parameter: 0 to use for as_tools; 1 to use in ds_tools
handlesamfiles(){
	#clear samlist file first
	rm -f $outdir/samlist
	if [[ $1 = 0 ]]
	then
		echo "Looking for SAM files in $bamdir and converting them to BAM-files..."
		readsamfiles $bamdir
		#make bam file out of all samfiles in samlist
		for filename in $(cat $outdir/samlist)
		do
		        makebamfromsam $filename $bamdir
		done  		

	else
		echo "Looking for SAM files in $casebam and $controlbam and converting them to BAM-files..."
		readsamfiles $casebam
		#make bam file out of all samfiles in samlist
                for filename in $(cat $outdir/samlist)
                do
                        makebamfromsam $filename $casebam
                done
		echo "-------------------"
		#clear samlist again
		rm -f $outdir/samlist
		readsamfiles $controlbam
                #make bam file out of all samfiles in samlist
                for filename in $(cat $outdir/samlist)
                do
                        makebamfromsam $filename $controlbam
                done
		
	fi

}


	
# read fastq files in fastqfolder and save paths ins fastqlist file
readfastqs(){
        find ${1:-$fastqdir} -maxdepth 1 -name "*.fastq" -nowarn > $outdir/fastqlist
        chmod  777 $outdir/fastqlist
}


#make the output directory: $output/$tool-output
#Parameter: the tools name
mk_outdir(){
	mkdir -p $outdir
	chmod -R 777 $outdir
}


#make the output folder for the specific sample (BAM-file) and return the folder path
#Parameter: BAM filename of sample
mk_sample_out(){
	tmp="${1##*/}"	#get basename of file
        sample_out="${tmp%%.*}"	#remove all file extensions after first . 
        mkdir -p $outdir/$sample_out-output
	chmod -R 777 $outdir/$sample_out-output

	echo $outdir/$sample_out-output
}


build_STAR_index(){
	mkdir -p $star_index
	STAR --runMode genomeGenerate --genomeDir $star_index --genomeFastaFiles $fasta --sjdbGTFfile $gtf --runThreadN $ncores --outFileNamePrefix $star_index/Star_mapped_ --sjdbOverhang 100
	wait
	echo "Built STAR index and saved into $star_index ..."
}

check_star_index(){
	echo "Looking for STAR index in $star_index ..."
	if [ ! -d $star_index ]; then
		echo "Did not find index, building it now into $star_index ..."
		build_STAR_index
	else
		echo "Found STAR index, moving on ..."
	fi
}


#cleaning up
cleaner(){
	rm -f $outdir/bamlist
	rm -f $outdir/samlist
	rm -f $outdir/fastqlist
	rm -rf $outdir/tmp
	echo script is done
	#exit
}






###### functions used for tools which can also do differential splicing analysis

#combine files of case & control folders into one tmp/case_control folder and return the path
#Parameter: 1: path of casefolder 2: path of controlfolder
combine_case_control(){
	mkdir -p $outdir/case_control
	chmod -R 777 $outdir/case_control

	cp -R $1/. $outdir/case_control
	cp -R $2/. $outdir/case_control

	echo $outdir/case_control
}


cleaner_diff(){
	rm -rf $outdir/case_control
	rm -f $outdir/bamlist
       	echo script is done.
	exit
}
