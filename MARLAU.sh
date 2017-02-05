#! /bin/bash

## Copyright 2016 Manuel Cantero, Maria Roman and Laureano Tomas

## This file is part of MARLAU

## MARLAU is free software: you can redistribute it and/or modify
## it under the terms of the GNU General Public License as published by
## the Free Software Foundation, either version 3 of the License, or
## (at your option) any later version.

## MARLAU is distributed in the hope that it will be useful,
## but WITHOUT ANY WARRANTY; without even the implied warranty of
## MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
## GNU General Public License for more details.

## You should have received a copy of the GNU General Public License
## along with MARLAU.  If not, see <http://www.gnu.org/licenses/>.

if [ $# -eq 0 ]
then
   echo "Usage: MARLAU <working_directory> <experiment> </home/opt/parameter_file_rnaseq.txt> </home/opt/parameter_file_chipseq.txt>"
   echo "Do you want to creat a parameter_file_rnaseq.txt? Type 0 for yes 1 for no"
   read RES_1
   if [ $RES_1 -eq 0 ]
   then
   	echo "Experiment Working Directory:"
      read WORKING_DIR
      echo "Experiment name (rnaseq recommended):"
      read EXPERIMENT
	 	echo "Number of samples:"
	 	read NUMBER_OF_SAMPLES
      echo "Genome URL:"
  	 	read URL_GENOME
	 	echo "Annotation URL:"
	 	read URL_ANNOTATION
	 	echo "Labels:"
	 	read LABELS
	 	echo "Experiment design"
	 	read EXP_DESIGN
	 	echo "Comparisons"
	 	read COMPARISONS
	 	echo "threshold"
	 	read THRESHOLD

	 	echo "working_directory: $WORKING_DIR" > $WORKING_DIR/parameter_file_${EXPERIMENT}_rnaseq.txt
	 	echo "experiment: $EXPERIMENT" >> $WORKING_DIR/parameter_file_${EXPERIMENT}_rnaseq.txt
	 	echo "number of samples: $NUMBER_OF_SAMPLES" >> $WORKING_DIR/parameter_file_${EXPERIMENT}_rnaseq.txt 
	 	echo "url_genome: $URL_GENOME" >> $WORKING_DIR/parameter_file_${EXPERIMENT}_rnaseq.txt 
	 	echo "url_annotation: $URL_ANNOTATION" >> $WORKING_DIR/parameter_file_${EXPERIMENT}_rnaseq.txt  
	 	echo "labels: $LABELS" >> $WORKING_DIR/parameter_file_${EXPERIMENT}_rnaseq.txt 
	 	echo "experimental design: $EXP_DESIGN" >> $WORKING_DIR/parameter_file_${EXPERIMENT}_rnaseq.txt
	 	echo "comparisons: $COMPARISONS" >> $WORKING_DIR/parameter_file_${EXPERIMENT}_rnaseq.txt
	 	echo "threshold: $THRESHOLD" >> $WORKING_DIR/parameter_file_${EXPERIMENT}_rnaseq.txt
 	 	i=1
	 	while [ $i -le $NUMBER_OF_SAMPLES ]
      do
      	echo "Sample $i URL"
        	read URL_SAMPLE
         echo "url_sample_$i: $URL_SAMPLE" >> $WORKING_DIR/parameter_file_${EXPERIMENT}_rnaseq.txt
         ((i++))
      done

		echo "The parameter file has been created."
   else
      exit
   fi 
   echo "Do you want to creat a parameter_file_chipseq.txt? Type 0 for yes 1 for no"
   read RES_2
   if [ $RES_2 -eq 0 ]
      then
         echo "Experiment Working Directory:"
         read WORKING_DIR
         echo "Experiment name (chipseq recommended):"
         read EXPERIMENT
         echo "Experiment design"
	 		read EXP_DESIGN
         echo "Genome URL:"
  	 		read URL_GENOME
	 		echo "Annotation URL:"
	 		read URL_ANNOTATION
	 		echo "Experiment Type:"
	 		read EXPERIMENT_TYPE
	 		echo "threshold"
	 		read THRESHOLD

			echo "working_directory: $WORKING_DIR" > $WORKING_DIR/parameter_file_${EXPERIMENT}_chipseq.txt
	 		echo "experiment: $EXPERIMENT" >> $WORKING_DIR/parameter_file_${EXPERIMENT}_chipseq.txt
			echo "experimental design: $EXP_DESIGN" >> $WORKING_DIR/parameter_file_${EXPERIMENT}_chipseq.txt
	 		echo "url_genome: $URL_GENOME" >> $WORKING_DIR/parameter_file_${EXPERIMENT}_chipseq.txt
	 		echo "url_annotation: $URL_ANNOTATION" >> $WORKING_DIR/parameter_file_${EXPERIMENT}_chipseq.txt
	 		echo "experiment_type: $EXPERIMENT_TYPE" >> $WORKING_DIR/parameter_file_${EXPERIMENT}_chipseq.txt
	 		echo "targets_threshold: $THRESHOLD" >> $WORKING_DIR/parameter_file_${EXPERIMENT}_chipseq.txt

	 		echo "The parameter file has been created."
   else
      exit
   fi 
fi

## Reading parameters

WORKING_DIR=$1
EXPERIMENT=$2
PARAM_FILE_RNASEQ=$3
PARAM_FILE_CHIPSEQ=$4

## Creating working directory

cd $WORKING_DIR

mkdir $EXPERIMENT

cd $EXPERIMENT

echo "working_directory:" $WORKING_DIR > logs.txt
echo "experiment_name:" $EXPERIMENT >> logs.txt

## Parallel processing of RNA-seq and CHIP-seq

qsub -N rnaseq -o log_rnaseq $HOME/opt/MARLAU/BAGPIPE $PARAM_FILE_RNASEQ
qsub -N chipseq -o log_chipseq $HOME/opt/MARLAU/CHIPIPE $PARAM_FILE_CHIPSEQ

echo "MARLAU DONE"
echo "MARLAU DONE" >> logs.txt