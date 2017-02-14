# MARLAU
Program to analyse CHIP-seq and RNA-seq data


INSTALATION:

To install MARLAu follow these steps:

1. Download the zip file MARLAU.zip to a directory of your choice. The opt directory is recommended.

2. Unzip the file:
        unzip MARLAU.zip
3. Edit your .bashrc file to add the MARLAU path to PATH.
        Open a terminal Ctrl+Alt+T
        cd
        vim .bashrc or nano .bashrc or gedit .bashrc
        add to the end of the filethe MARLAU path
        PATH=$PATH:MARLAU_PATH

PROGRAMS REQUIRED:

- Bowtie 2 version 2.2.6
- TopHat v2.1.0
- FastQC v0.11.2
- cufflinks v2.2.1
- merge_cuff_asms v1.0.0 
- cuffdiff v2.2.1
- R scripting front-end version 3.2.1 (2015-06-18)
- R version 3.2.1 (2015-06-18) -- "World-Famous Astronaut"
- bowtie version 1.1.2 
- samtools version 0.1.18
- macs2 2.1.0.20151222
- PeakAnnotator 1.4
- homer v4.8.3
- R package "cummeRbund"
