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
NUMBER_OF_SAMPLES=$3
LABELS=$4
EXP_DESIGN=$5
COMPARISONS=$6
THRESHOLD=$7
PV=$8

cd $WORKING_DIR/$EXPERIMENT/results

## Creating assemblies.txt file
## Initializing the first line 

echo "Creating asemblies.txt file" >> $WORKING_DIR/$EXPERIMENT/logs_rnaseq.txt

echo $WORKING_DIR/$EXPERIMENT/samples/sample_1/transcripts.gtf > assemblies.txt

## Adding the rest of the paths

i=2
while [ $i -le $NUMBER_OF_SAMPLES  ]
do
   echo $WORKING_DIR/$EXPERIMENT/samples/sample_$i/transcripts.gtf >> assemblies.txt
   ((i++))
done

## Cuffmerge

echo "Cuffmerge" >> $WORKING_DIR/$EXPERIMENT/logs_rnaseq.txt

cuffmerge -g $WORKING_DIR/$EXPERIMENT/annotation/annotation.gtf -s $WORKING_DIR/$EXPERIMENT/genome/genome.fa assemblies.txt


## Split experimental design into an array. Transforming ',' into ''.

echo "Split experimental desing into ARRAY_EXP" >> $WORKING_DIR/$EXPERIMENT/logs_rnaseq.txt

IFS=',' read -ra ARRAY_EXP <<< "$EXP_DESIGN"

NUM_CONDS=${#ARRAY_EXP[@]}

echo "Number of conditions:" $NUM_CONDS >> $WORKING_DIR/$EXPERIMENT/logs_rnaseq.txt

## Initializing 'j' for number of samples and 'l' for check number of replicas 

j=1
l=1

NUM_REP_1=${ARRAY_EXP[0]}

echo "Creating CUFF_PARAM" >> $WORKING_DIR/$EXPERIMENT/logs_rnaseq.txt

CUFF_PARAM="$WORKING_DIR/$EXPERIMENT/samples/sample_$j/accepted_hits.bam"
((j++))
((l++))

while [ $l -le $NUM_REP_1 ]
do
   CUFF_PARAM="$CUFF_PARAM,$WORKING_DIR/$EXPERIMENT/samples/sample_$j/accepted_hits.bam"
   ((j++))
   ((l++))
done

k=1

while [ $k -lt $NUM_CONDS ]
do
   NUM_REP=${ARRAY_EXP[$k]}
   l=1
   CUFF_PARAM="$CUFF_PARAM $WORKING_DIR/$EXPERIMENT/samples/sample_$j/accepted_hits.bam"
   ((j++))
   ((l++))

   while [ $l -le $NUM_REP ]
   do
      
      CUFF_PARAM="$CUFF_PARAM,$WORKING_DIR/$EXPERIMENT/samples/sample_$j/accepted_hits.bam"
      ((l++))
      ((j++))
   done
   ((k++))

done

echo "Final CUFF_PARAM:" $CUFF_PARAM >> $WORKING_DIR/$EXPERIMENT/logs_rnaseq.txt

## Cuffdiff

echo "Cuffdiff" >> $WORKING_DIR/$EXPERIMENT/logs_rnaseq.txt

cuffdiff -o DEGs/ -b $WORKING_DIR/$EXPERIMENT/genome -u merged_asm/merged.gtf -L $LABELS $CUFF_PARAM 

## R analysis

echo "R Analysis" >> $WORKING_DIR/$EXPERIMENT/logs_rnaseq.txt

/usr/lib/R/bin/Rscript $HOME/opt/MARLAU/analysis.R $WORKING_DIR/$EXPERIMENT/results/DEGs $EXPERIMENT $THRESHOLD $LABELS $COMPARISONS $PV

echo "$(tail -n +2 degs.txt)" > degs.txt

## Synchronisation

## Writing information in the blackboard                                                                                                                                        
                                                                                                                                                                                
echo "RNASEQ ANALYSIS DONE" >> $WORKING_DIR/blackboard_MARLAU.txt                                                                                                               
                                                                                                                                                                                
## Reading information from the blackboard                                                                                                                                      
                                                                                                                                                                                
DONE_PIPELINE=$( wc -l $WORKING_DIR/blackboard_MARLAU.txt | awk '{ print $1 }' )                                                                                                
                                                                                                                                                                                
## Checking point of synchronisation point to check whether or not all samples are already done                                                                                 

IFS=',' read -ra ARRAY_EXP <<< "$EXP_DESIGN_CHIP"

NUMBER_CONDITIONS=$((${#ARRAY_EXP[@]}/2))

cd $WORKING_DIR


if [ $DONE_PIPELINE -eq $(($NUMBER_CONDITIONS+1)) ]                                                                                                                                                     
then                                                                                                                                                                            
   
   WORKING_DIR_RNASEQ=$( grep rna_working_dir: sync_file.txt | awk '{print $2}' )
   WORKING_DIR_CHIPSEQ=$( grep chip_working_dir: sync_file.txt | awk '{print $2}' )
   WORKING_DIRECTORY=$( grep working_dir: sync_file.txt | awk '{print $2}' )
   ID_LIST=$( grep ID: sync_file.txt | awk '{print $2}' )

   IFS=',' read -ra ID_ARRAY <<< "$ID_LIST"

   for i in "${ID_ARRAY[@]}"
   do

      /usr/lib/R/bin/Rscript $HOME/opt/MARLAU/intersection.R $WORKING_DIR_RNASEQ $WORKING_DIR_CHIPSEQ $WORKING_DIRECTORY $i

      echo "RNASEQ and CHIPSEQ analysis DONE"
      echo "RNASEQ and CHIPSEQ analysis DONE" >> $WORKING_DIR/logs.txt

   done
                                                                                                          
fi                

echo "MERGE DIFF DONE"
echo "MERGE DIFF DONE" >> $WORKING_DIR/$EXPERIMENT/logs_rnaseq.txt

