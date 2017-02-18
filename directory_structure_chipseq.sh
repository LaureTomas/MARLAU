#! /bin/bash

## Copyright 2016 Maria Roman and Laureano Tomas   

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

## Reading parameters

WORKING_DIR=$1
EXPERIMENT=$2
URL_GENOME=$3
URL_ANNOTATION=$4

## STEP 1. BUILDING WORKING DIRECTORY #
####################################### 

## Accessing the working directory

cd $WORKING_DIR/$EXPERIMENT/

## Creating the structure

mkdir genome
mkdir annotation
mkdir samples
mkdir results

## Creating subfolders for each sample

cd samples

mkdir input
mkdir chip

## Downloading annotation

echo "Downloading annotation"
echo "Downloading annotation" >> $WORKING_DIR/$EXPERIMENT/logs_chipseq.txt

cd ../annotation
wget -O annotation.gtf.gz $URL_ANNOTATION
gunzip annotation.gtf.gz

## Downloading reference genome

echo "Downloading reference genome"
echo "Downloading reference genome" >> $WORKING_DIR/$EXPERIMENT/logs_chipseq.txt

cd ../genome
wget -O genome.fa.gz $URL_GENOME
gunzip genome.fa.gz

## Building index for reference genome

echo "Building index for reference genome"
echo "Building index for reference genome" >> $WORKING_DIR/$EXPERIMENT/logs_chipseq.txt

bowtie-build genome.fa genome

echo "CHIPSEQ DIRECTORY STRUCTURE DONE"
echo "CHIPSEQ DIRECTORY STRUCTURE DONE" >> $WORKING_DIR/$EXPERIMENT/logs_chipseq.txt
