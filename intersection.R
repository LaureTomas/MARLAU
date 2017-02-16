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

args <- commandArgs(trailingOnly=TRUE)

directory_targets <- args[1]
directory_degs <- args[2]
directory <- args[3]
id <- args[4]

file.1 <-  paste(id,"_targets.txt", sep = "")
file.2 <- "degs.txt"

directory_targets_real <- paste(directory_targets,id, sep = "")

setwd(directory_targets_real)

genes.1 <- as.vector(read.table(file=file.1,header=FALSE)[[2]])
print(length(unique(genes.1)))
genes.1 <- unique(genes.1)

setwd(directory_degs)

genes.2 <- as.vector(read.table(file=file.2,header=FALSE)[[2]])
print(length(unique(genes.2)))
genes.2 <- unique(genes.2)

genes.1.2 <- intersect(genes.1,genes.2)
genes.1.2 <- unique(genes.1.2)

setwd(directory)

file3.name <- paste("degs_",id,"_targets.txt", sep = "")

write.table(genes.1.2, file3.name)

library(VennDiagram)

label.1.name <- paste(id,"_targets", sep = "")

label.1 <- label.1.name
label.2 <- "degs"

venn.name <- paste("venn",label.1.name,"_degs.png", sep = "")

grid.newpage()
venn <- draw.pairwise.venn(area1 = length(unique(genes.1)),
                   area2 = length(unique(genes.2)),
                   cross.area = length(unique(genes.1.2)),
                   category = c(label.1, label.2), 
                   cat.cex=3, cat.pos=c(-30,20), cat.dist=0.04, cex=2,
                   fill=c("green", "red"),
                   alpha=c(0.4,0.4),
                   lwd=3,fontface="bold",
                   cat.fontface="bold")

png(filename= venn.name, res=72)
venn
dev.off()
