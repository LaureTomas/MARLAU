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

WORKING_DIR=$1
EXPERIMENT=$2
NUMBER_OF_SAMPLES=$3
URL_GENOME=$4 
URL_ANNOTATION=$5

## Accessing the working directory

cd $WORKING_DIR/$EXPERIMENT/

## Creating the structure

mkdir genome 
mkdir annotation
mkdir samples
mkdir results

## Creating subfolders for each sample

cd samples

i=1

while [ $i -le $NUMBER_OF_SAMPLES ]
do
   mkdir sample_$i 
   ((i++))
done

## Downloading annotation

echo "Downloading annotation"
echo "Downloading annotation" >> $WORKING_DIR/$EXPERIMENT/logs_rnaseq.txt

cd ../annotation
wget -O annotation.gtf.gz $URL_ANNOTATION
gunzip annotation.gtf.gz

sed -i 's/#//g' $WORKING_DIR/$EXPERIMENT/annotation/annotation.gtf

## Downloading reference genome

echo "Downloading reference genome"
echo "Downloading reference genome" >> $WORKING_DIR/$EXPERIMENT/logs_rnaseq.txt

cd ../genome
wget -O genome.fa.gz $URL_GENOME
gunzip genome.fa.gz

## Building index for reference genome

echo "Building index for reference genome"
echo "Building index for reference genome" >> $WORKING_DIR/$EXPERIMENT/logs_rnaseq.txt

bowtie2-build genome.fa genome

echo "RNASEQ DIRECTORY STRUCTURE DONE"
echo "RNASEQ DIRECTORY STRUCTURE DONE" >> $WORKING_DIR/$EXPERIMENT/logs_rnaseq.txt

