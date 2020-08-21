#!/bin/bash

#SBATCH --ntasks=1
#SBATCH --job-name=dockermappers
#SBATCH --output=/nfs/home/users/afenn/slurm/logs/%x.%j.%a.out
#SBATCH --error=/nfs/home/users/afenn/slurm/logs/%x.%j.%a.err
#SBATCH --mem=1G
#SBATCH --cpus-per-task=1
#SBATCH --array=1-11%1
 #$SLURM_ARRAY_TASK_ID

# Making an array $images with a list of images

image=$(cat /nfs/proj/AS_dockers/images.txt | head -${SLURM_ARRAY_TASK_ID}|tail -1 )
echo $image $USER
docker run -v "/nfs/proj/AS_dockers/:/myvol1" --user $(id -u):$(id -g) --rm $image
