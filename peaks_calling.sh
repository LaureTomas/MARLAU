#$ -S /bin/bash
#$ -V
#$ -cwd
#$ -j yes

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

WORKING_DIR=$1
EXPERIMENT=$2
EXPERIMENT_TYPE=$3
THRESHOLD=$4
CHIP_NAME=$5
EXP_DESIGN=$6
INPUT_NAME=$7


## STEP 4. PEAK CALLING ##
##########################

## Accessing the results directory

echo "Peaks calling" >> $WORKING_DIR/$EXPERIMENT/logs_chipseq.txt

## If there is not any input

if [ -z $7 ]
then

## Peak calling

   ID=${CHIP_NAME}
   mkdir $ID
   cd $WORKING_DIR/$EXPERIMENT/results/$ID
   macs2 callpeak -t $WORKING_DIR/$EXPERIMENT/samples/chip/$CHIP_NAME.sam -n $ID --outdir . -f SAM
   echo -n "$ID," >> $WORKING_DIR/sync_file.txt
else

## If there is input
## Peak calling

   ID=${CHIP_NAME}"_"${INPUT_NAME}
   mkdir $ID
   cd $WORKING_DIR/$EXPERIMENT/results/$ID
   macs2 callpeak -t $WORKING_DIR/$EXPERIMENT/samples/chip/$CHIP_NAME.sam -c $WORKING_DIR/$EXPERIMENT/samples/input/$INPUT_NAME.sam -n $ID --outdir . -f SAM
   echo -n "$ID," >> $WORKING_DIR/sync_file.txt
fi

## Running R script model.R generated by the peak calling

Rscript ${ID}_model.r

## STEP 5. PEAK ANNOTATION ##
#############################

## Peak annotator

if [[ $EXPERIMENT_TYPE == "EP" ]]
then
   echo "Peak annotator EP" >> $WORKING_DIR/$EXPERIMENT/logs_chipseq.txt
                                                                                                                                                                     
   less $WORKING_DIR/$EXPERIMENT/results/${ID}_peaks.narrowPeak | awk '{printf("chr%s\t%s\t%s\n"),$1,$2,$3}' > ${ID}_peaks.bed                                                   
   
   java -jar -Xmx4g /home/marlau/opt/PeakAnnotator_Java_1.4/PeakAnnotator.jar -u NDG -p ${ID}_peaks.bed -a $WORKING_DIR/$EXPERIMENT/annotation/annotation.gtf -o . -g all               
   
## Selecting targets genes

   /usr/lib/R/bin/Rscript $HOME/opt/MARLAU/targets_ep.R ${ID} $WORKING_DIR/$EXPERIMENT/results/$ID $THRESHOLD

   echo "$(tail -n +2 ${ID}_targets.txt)" > ${ID}_targets.txt
   

elif [[ $EXPERIMENT_TYPE == "TF" ]]
then
  echo "Peak annotator TF" >> $WORKING_DIR/$EXPERIMENT/logs_chipseq.txt
  
  java -jar -Xmx4g $HOME/opt/PeakAnnotator_Java_1.4/PeakAnnotator.jar -u NDG -p ${ID}_summits.bed -a $WORKING_DIR/$EXPERIMENT/annotation/annotation.gtf -o . -g all

## Selecting targets genes

   /usr/lib/R/bin/Rscript $HOME/opt/MARLAU/targets_tf.R ${ID} $WORKING_DIR/$EXPERIMENT/results/$ID $THRESHOLD

   echo "$(tail -n +2 ${ID}_targets.txt)" > ${ID}_targets.txt
fi

## Synchronisation

## Writing information in the blackboard

echo "$ID CHIP-SEQ ANALYSIS DONE" >> $WORKING_DIR/blackboard_MARLAU.txt

## Reading information from the blackboard

DONE_PIPELINE=$( wc -l $WORKING_DIR/blackboard_MARLAU.txt | awk '{ print $1 }' )

## Checking point of synchronisation point to check whether or not all samples are already done

IFS=',' read -ra ARRAY_EXP <<< "$EXP_DESIGN"

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

## STEP 6. TSS MAPPING ##
#########################

echo "HOMER" >> $WORKING_DIR/$EXPERIMENT/logs_chipseq.txt

## HOMER

findMotifsGenome.pl ${ID}_summits.bed $WORKING_DIR/$EXPERIMENT/genome/genome.fa HOMER_results/primary_motifs -size 50 
findMotifsGenome.pl ${ID}_summits.bed $WORKING_DIR/$EXPERIMENT/genome/genome.fa HOMER_results/secondary_motifs -size 200

echo "PEAKS CALLING DONE"
echo "PEAKS CALLING DONE" >> $WORKING_DIR/$EXPERIMENT/logs_chipseq.txt
