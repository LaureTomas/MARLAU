#$ -S /bin/bash
#$ -V
#$ -cwd
#$ -j yes

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

WORKING_DIR=$1
EXPERIMENT=$2
i=$3
URL_SAMPLE=$4
NUMBER_OF_SAMPLES=$5
LABELS=$6
EXP_DESIGN=$7
COMPARISONS=$8
THRESHOLD=$9
PV=$10

## Accessing sample directory

echo "Accessing sample_"$i"_directory"
echo "Accessing sample_"$i"_directory" >> $WORKING_DIR/$EXPERIMENT/logs_rnaseq.txt

cd $WORKING_DIR/$EXPERIMENT/samples/sample_$i

## Downloading sample file

echo "Downloading sample_"$i
echo "Downloading sample_"$i >> $WORKING_DIR/$EXPERIMENT/logs_rnaseq.txt

wget -O sample_$i.sra $URL_SAMPLE

## Extracting sample file and quality control

fastq-dump --split-files sample_$i.sra 
rm sample_$i.sra

if [ -e sample_${i}_2.fastq ]
then
   fastqc sample_${i}_1.fastq
   fastqc sample_${i}_2.fastq

## Mapping sample to reference genome
   echo "Mapping sample_"$i "to reference genome"
   echo "Mapping sample_"$i "to reference genome" >> $WORKING_DIR/$EXPERIMENT/logs_rnaseq.txt
   tophat --no-coverage-search -G $WORKING_DIR/$EXPERIMENT/annotation/annotation.gtf -o $WORKING_DIR/$EXPERIMENT/samples/sample_$i $WORKING_DIR/$EXPERIMENT/genome/genome $WORKING_DIR/$EXPERIMENT/samples/sample_$i/sample_${i}_2.fastq $WORKING_DIR/$EXPERIMENT/samples/sample_$i/sample_${i}_1.fastq
else
   fastqc sample_${i}_1.fastq
   ## Mapping sample to reference genome
   echo "Mapping sample_"$i "to reference genome"
   echo "Mapping sample_"$i "to reference genome" >> $WORKING_DIR/$EXPERIMENT/logs_rnaseq.txt
   tophat --no-coverage-search -G $WORKING_DIR/$EXPERIMENT/annotation/annotation.gtf -o $WORKING_DIR/$EXPERIMENT/samples/sample_$i $WORKING_DIR/$EXPERIMENT/genome/genome $WORKING_DIR/$EXPERIMENT/samples/sample_$i/sample_${i}_1.fastq
fi

## Transcript Assembly

echo "Transcript Assembly sample_"$i
echo "Transcript Assembly sample_"$i >> $WORKING_DIR/$EXPERIMENT/logs_rnaseq.txt

cufflinks -G $WORKING_DIR/$EXPERIMENT/annotation/annotation.gtf accepted_hits.bam

## Synchronisation point using a blackboard

## Writing information to the blackboard

echo "SAMPLE" $i "DONE" >> $WORKING_DIR/$EXPERIMENT/blackboard_rnaseq.txt

## Reading information from the blackboard

DONE_SAMPLES=$( wc -l $WORKING_DIR/$EXPERIMENT/blackboard_rnaseq.txt | awk '{ print $1 }' )

## Checking point of synchronisation point to check whether or not all samples are already done

if [ $DONE_SAMPLES -eq $NUMBER_OF_SAMPLES ]
then
   cd $WORKING_DIR/$EXPERIMENT/results
   qsub -N merge_diff -o merge_diff $HOME/opt/MARLAU/merge_diff.sh $WORKING_DIR $EXPERIMENT $NUMBER_OF_SAMPLES $LABELS $EXP_DESIGN $COMPARISONS $THRESHOLD $PV
fi

echo "SAMPLE" $i "PROCESSING DONE"
echo "SAMPLE" $i "PROCESSING DONE" >> $WORKING_DIR/$EXPERIMENT/logs_rnaseq.txt
