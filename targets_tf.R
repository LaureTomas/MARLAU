## Copyright 2016 Manuel Cantero, Maria Roman and Laureano Tomas

## This file is part of MARLAU

## CHIPPIE is free software: you can redistribute it and/or modify
## it under the terms of the GNU General Public License as published by
## the Free Software Foundation, either version 3 of the License, or
## (at your option) any later version.

## MARLAU is distributed in the hope that it will be useful,
## but WITHOUT ANY WARRANTY; without even the implied warranty of
## MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
## GNU General Public License for more details.

## You should have received a copy of the GNU General Public License
## along with MARLAU  If not, see <http://www.gnu.org/licenses/>.

args <- commandArgs(trailingOnly=TRUE)

id <- args[1]
directory <- args[2]
th <- as.numeric(args[3])

setwd(directory)

get.first <- function(elto)
{
  return(strsplit(elto,"\\.")[[1]][1])
}

overlap.file <- paste(id,"_summits.overlap.bed", sep = "")

overlap <- read.table(file = overlap.file, header = TRUE, comment.char="%",fill=TRUE)
overlap.gene <- as.vector(overlap[["OverlapGene"]])

overlap.gene <- sapply(overlap.gene,get.first)
names(overlap.gene) <- NULL
overlap.gene <- unique(overlap.gene)

ndg.file <- paste(id,"_summits.ndg.bed", sep = "")
ndg <- read.table(file = ndg.file, header = TRUE, comment.char="%",fill=TRUE)

fw.genes <- as.vector(ndg[["Downstream_FW_Gene"]])
rv.genes <- as.vector(ndg[["Downstream_REV_Gene"]])

ndg.fw.genes <- as.vector(fw.genes[ndg[["X.Overlaped_Genes"]] == 0 & (ndg[["Distance"]] < ndg[["Distance.1"]]) & (ndg[["Distance"]] < 2000)])
ndg.rv.genes <- as.vector(rv.genes[ndg[["X.Overlaped_Genes"]] == 0 & (ndg[["Distance"]] > ndg[["Distance.1"]]) & (ndg[["Distance.1"]] < 2000)])

ndg.genes <- c(ndg.fw.genes,ndg.rv.genes)
ndg.genes <- sapply(ndg.genes,get.first)
names(ndg.genes) <- NULL
length(ndg.genes)

final.targets <- unique(c(ndg.genes,overlap.gene))

final.table <- paste(id,"_targets.txt", sep = "")
write.table(x = final.targets, file = final.table)
