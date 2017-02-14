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


## Reading parameters

WORKING_DIR=$1
EXPERIMENT=$2
URL=$3
SAMPLE_TYPE=$4
SAMPLE_NAME=$5
EXP_DESIGN=$6
EXPERIMENT_TYPE=$7
THRESHOLD=$8


echo "working_directory:" $WORKING_DIR >> $WORKING_DIR/$EXPERIMENT/logs_chipseq.txt
echo "experiment:" $EXPERIMENT >> $WORKING_DIR/$EXPERIMENT/logs_chipseq.txt
echo "url:" $URL >> $WORKING_DIR/$EXPERIMENT/logs_chipseq.txt
echo "sample_type:" $SAMPLE_TYPE >> $WORKING_DIR/$EXPERIMENT/logs_chipseq.txt
echo "sample_name:" $SAMPLE_NAME >> $WORKING_DIR/$EXPERIMENT/logs_chipseq.txt
echo "experimental_design:" $EXP_DESIGN >> $WORKING_DIR/$EXPERIMENT/logs_chipseq.txt
echo "experiment_type:" $EXPERIMENT_TYPE >> $WORKING_DIR/$EXPERIMENT/logs_chipseq.txt
echo "threshold:" $THRESHOLD >> $WORKING_DIR/$EXPERIMENT/logs_chipseq.txt

## Accessing sample directory

echo "Accessing "$SAMPLE_TYPE"_directory"
echo "Accessing "$SAMPLE_TYPE"_directory" >> $WORKING_DIR/$EXPERIMENT/logs_chipseq.txt

cd $WORKING_DIR/$EXPERIMENT/samples/$SAMPLE_TYPE

## Downloading sample file

echo "Downloading "$SAMPLE_NAME
echo "Downloading "$SAMPLE_NAME >> $WORKING_DIR/$EXPERIMENT/logs_chipseq.txt

wget -O ${SAMPLE_NAME}.sra $URL

## Extracting sample file and quality control

fastq-dump --split-files ${SAMPLE_NAME}.sra 
rm ${SAMPLE_NAME}.sra

## STEP 2. QUALITY CONTROL ##
#############################

fastqc ${SAMPLE_NAME}_1.fastq

## Mapping sample to reference genome

echo "Mapping" ${SAMPLE_NAME} "to reference genome"
echo "Mapping" ${SAMPLE_NAME} "to reference genome" >> $WORKING_DIR/$EXPERIMENT/logs_chipseq.txt

## STEP 3. MAPPING ##
#####################

bowtie $WORKING_DIR/$EXPERIMENT/genome/genome -q ${SAMPLE_NAME}_1.fastq -S -v 2 --best --strata -m 1 > ${SAMPLE_NAME}.sam

## Converting .sam into .bam in order to be able to visualize in IGV and creating index

echo "Converting " ${SAMPLE_NAME}".sam into" ${SAMPLE_NAME}".bam"
echo "Converting " ${SAMPLE_NAME}".sam into" ${SAMPLE_NAME}".bam" >> $WORKING_DIR/$EXPERIMENT/logs_chipseq.txt

samtools view -bS ${SAMPLE_NAME}.sam | samtools sort - ${SAMPLE_NAME}.sam.sorted && echo "${SAMPLE_NAME}.sam bam sorted" && samtools index ${SAMPLE_NAME}.sam.sorted.bam

###################################3
## Synchronization point

## Writing sample X is DONE in the blackboard

echo ${SAMPLE_NAME} "DONE" >> $WORKING_DIR/$EXPERIMENT/blackboard_chipseq.txt

## Split Experimental Design into an array

IFS=',' read -ra ARRAY_EXP <<< "$EXP_DESIGN"

## Calculating the number of conditions, i.e., the number of positions in the array divided by 2

NUMBER_CONDITIONS=$((${#ARRAY_EXP[@]}/2))

## Initializing parameters:
##   m: number of condition
##   CHIP: position of ARRAY_EXP containing chip samples
##   INPUT: position of ARRAY_EXP containing input samples
##   n: number associated with each chip
##   o: number associated with each input

m=1
CHIP=0
INPUT=1
n=1
o=1

## While loop to submit each pair of chip/input to peaks calling

while [ $m -le $NUMBER_CONDITIONS ]
do

## Initializing CHIP_NUMBER and INPUT_NUMBER with the number of chips and inputs in this condition

   CHIP_NUMBER=${ARRAY_EXP[$CHIP]}
   INPUT_NUMBER=${ARRAY_EXP[$INPUT]}

## If this condition does not have any input

   if [ $INPUT_NUMBER -eq 0 ]
   then

## Initializing the string CHIP_NAMES with the name of the first chip in this condition
## Update n
## Initializing CHIP_NUMBER_ADAPTOR with n in order to calculate the real number of the chips in this condition

      CHIP_NAMES="chip_"$n
      ((n++))
      CHIP_NUMBER_ADAPTOR=$n

## While n less or equal to CHIP_NUMBER + (n-2)

      while [ $n -le $((${CHIP_NUMBER}+$((${CHIP_NUMBER_ADAPTOR}-2)))) ]
      do

## Adding the rest of the chip's names to the string CHIP_NAMES

         CHIP_NAMES=$CHIP_NAMES,"chip_"$n
         ((n++))
      done

## If the sample name is in the string CHIP_NAME, it means that this sample belongs to this condition

      if [[ $CHIP_NAMES == *${SAMPLE_NAME}* ]]
      then

## Spliting CHIP_NAMES into an array

         IFS=',' read -ra CHIP_NAMES_ARRAY <<< "$CHIP_NAMES"
         CHIP_CHECK=0

## For each element of CHIP_NAMES_ARRAY search in blackboard_samples.txt if the sample is DONE and update the checker

         for p in "${CHIP_NAMES_ARRAY[@]}"
         do
            if grep $p $WORKING_DIR/$EXPERIMENT/blackboard_chipseq.txt
            then
               ((CHIP_CHECK++))
            fi
         done

## If CHIP_CHECK equal to CHIP_NUMBER it means the condition is ready

         if [ $CHIP_CHECK -eq $CHIP_NUMBER ]
         then

## For each element of the array submit to the queue peaks_calling.sh of each chip

            for k in "${CHIP_NAMES_ARRAY[@]}"
            do
               qsub -N peaks_${k} -o log_peaks_${k} $HOME/opt/MARLAU/peaks_calling.sh $WORKING_DIR $EXPERIMENT $EXPERIMENT_TYPE $THRESHOLD ${k} $EXP_DESIGN
            done
         fi
      fi

## if the condition have any input

   else

## Initializing the string CHIP_NAMES with the name of the first chip in this condition
## Update n
## Initializing CHIP_NUMBER_ADAPTOR with n in order to calculate the real number of the chips in this condition

      CHIP_NAMES="chip_"$n
      ((n++))
      CHIP_NUMBER_ADAPTOR=$n

## While n less or equal to CHIP_NUMBER + (n-2)

      while [ $n -le $((${CHIP_NUMBER}+$((${CHIP_NUMBER_ADAPTOR}-2)))) ]
      do
         CHIP_NAMES=$CHIP_NAMES,"chip_"$n
         ((n++))
      done

## Initializing the string INPUT_NAMES with the name of the first input in this condition
## Update o
## Initializing INPUT_NUMBER_ADAPTOR with o in order to calculate the real number of the input in this condition

      INPUT_NAMES="input_"$o
      ((o++))
      INPUT_NUMBER_ADAPTOR=$o

## While o less or equal to INPUT_NUMBER + (o-2)

      while [ $o -le $((${INPUT_NUMBER}+$((${INPUT_NUMBER_ADAPTOR}-2)))) ]
      do
         INPUT_NAMES=$INPUT_NAMES,"input_"$o
         ((o++))
      done

## If the sample name is in the strings CHIP_NAME OR INPUT_NAMES, it means that this sample belongs to this condition

      if [[ $CHIP_NAMES == *${SAMPLE_NAME}* ]] || [[ $INPUT_NAMES == *${SAMPLE_NAME}* ]]
      then

## Spliting CHIP_NAMES into an array

         IFS=',' read -ra CHIP_NAMES_ARRAY <<< "$CHIP_NAMES"
         CHIP_CHECK=0

## For each element of CHIP_NAMES_ARRAY search in blackboard_samples.txt if the sample is DONE and update the checker

         for p in "${CHIP_NAMES_ARRAY[@]}"
         do
            if grep $p $WORKING_DIR/$EXPERIMENT/blackboard_chipseq.txt
            then
               ((CHIP_CHECK++))
            fi
         done

## Spliting INPUT_NAMES into an array

         IFS=',' read -ra INPUT_NAMES_ARRAY <<< "$INPUT_NAMES"
         INPUT_CHECK=0

## For each element of INPUT_NAMES_ARRAY search in blackboard_samples.txt if the sample is DONE and update the checker

         for j in "${INPUT_NAMES_ARRAY[@]}"
         do
            if grep $j $WORKING_DIR/$EXPERIMENT/blackboard_chipseq.txt
            then
               ((INPUT_CHECK++))
            fi
         done

## If CHIP_CHECK equal to CHIP_NUMBER AND INPUT_CHECK equal to INPUT_NUMBER it means the condition is ready

         if [ $CHIP_CHECK -eq $CHIP_NUMBER ] && [ $INPUT_CHECK -eq $INPUT_NUMBER ]
         then

## if the condition has the same number of chips and inputs

            if [ $CHIP_NUMBER -eq $INPUT_NUMBER ]
            then

## For each chip sample submit to the queue peaks_calling.sh of each chip with its input

               for ((k=0;k<${#CHIP_NAMES_ARRAY[@]};++k))
               do
                 qsub -N peaks_${CHIP_NAMES_ARRAY[k]}_${INPUT_NAMES_ARRAY[k]} -o log_peaks_${CHIP_NAMES_ARRAY[k]}_${INPUT_NAMES_ARRAY[k]} $HOME/opt/MARLAU/peaks_calling.sh $WORKING_DIR $EXPERIMENT $EXPERIMENT_TYPE $THRESHOLD ${CHIP_NAMES_ARRAY[k]} $EXP_DESIGN ${INPUT_NAMES_ARRAY[k]}
               done
            fi

## if the condition has only 1 input

            if [ $INPUT_NUMBER -eq 1 ]
            then

## For each chip sample submit to the queue peaks_calling.sh of each chip with the only input

               for k in "${CHIP_NAMES_ARRAY[@]}"
               do
                 qsub -N peaks_${k}_$INPUT_NAMES_ARRAY -o log_peaks_${k}_$INPUT_NAMES_ARRAY $HOME/opt/MARLAU/peaks_calling.sh $WORKING_DIR $EXPERIMENT $EXPERIMENT_TYPE $THRESHOLD ${k} $EXP_DESIGN $INPUT_NAMES_ARRAY 
               done
            fi
         fi
      fi
   fi

## Updating m parameter to pass to the next conditions
## Updating CHIP and INPUT parameters plus 2 in order to pass to the chip and input elements if the next condition in the ARRAY_EXP

   ((m++))
   CHIP=$((${CHIP}+2))
   INPUT=$((${INPUT}+2))
done

echo ${SAMPLE_NAME} "PROCESSING DONE"
echo ${SAMPLE_NAME} "PROCESSING DONE" >> $WORKING_DIR/$EXPERIMENT/logs_chipseq.txt
