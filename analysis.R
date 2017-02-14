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

directory <- args[1] 
id <- args[2] 
th <- as.numeric(args[3]) 
labels <- args[4]
comparisons <- args[5]
pv <- as.numeric(args[6])

comparisons <- unlist(lapply(strsplit(comparisons, ","), as.numeric))
labels <- unlist(lapply(strsplit(labels, ","), as.character))

setwd(directory)

library(cummeRbund)

file <- paste(id,".db", sep = "")
readCufflinks(dbFile=file)
data <- readCufflinks(dbFile="rna_seq.db")

## Extracting data about genes and differential expression

data.genes <- genes(data)
gene.annotation <- annotation(data.genes)
gene.fpkm <- fpkm(data.genes) 
gene.diff<- diffData(data.genes)

## Creating a vector with the name of the genes associated to its XLOC identifier

gene.names <- gene.annotation[["gene_short_name"]]
gene.ids <- gene.annotation[["gene_id"]]
names(gene.names) <- gene.ids
names(gene.ids) <- gene.names

## Dispersion plots

disp.genes <- dispersionPlot(data.genes)

png(filename="dispersion_plot.png", res=72)
disp.genes
dev.off()

## Density plot

dens.genes <- csDensity(data.genes)

png(filename="density_plot.png", res=72)
dens.genes
dev.off()

## Box plot

boxplot.mean <- csBoxplot(data.genes)

png(filename="boxplot_mean.png", res=72)
boxplot.mean
dev.off()

boxplot.rep <- csBoxplot(data.genes,resplicates=TRUE)
png(filename="boxplot_replicates.png",res=72)
boxplot.rep
dev.off()

## Treatment/mutation effect 

scatterplot <- csScatterMatrix(data.genes)

png(filename="scatterplot.png",res=72)
scatterplot
dev.off()

## Comparisons

if (th != 0 && pv == 0)
{

  th.log <- log2(th)

  degs <- vector(mode = "character")

  for (i in seq(from = 1, to = length(comparisons)-1, by = 2))
  {
    scatter.name <- paste("scatter_",labels[comparisons[i+1]],"_",labels[comparisons[i]],".png", sep = "")
    scatter.comparison <- csScatter(data.genes,labels[comparisons[i+1]],labels[comparisons[i]])
    scatter.comparison
    ggsave(filename = scatter.name)
  
    volcano.name <- paste("volcano_",labels[comparisons[i+1]],"_",labels[comparisons[i]],".png", sep = "")
    volcano.comparison <- csVolcano(data.genes,labels[comparisons[i+1]],labels[comparisons[i]])
    volcano.comparison
    ggsave(filename = volcano.name)
  
    activated.data.frame <- subset(gene.diff,(sample_1 == labels[comparisons[i]] & sample_2 == labels[comparisons[i+1]] & log2_fold_change > th.log & status == "OK"))
    activated.XLOC <- activated.data.frame[["gene_id"]]
    activated.genes <- gene.names[activated.XLOC]
    names(activated.genes) <- NULL
    activated.file <- paste("activated_genes_",labels[comparisons[i+1]],"_",labels[comparisons[i]],".txt",sep = "")
    write(activated.genes,file=activated.file)
  
    repressed.data.frame <- subset(gene.diff,(sample_1 == labels[comparisons[i]] & sample_2 == labels[comparisons[i+1]] & log2_fold_change < -th.log & status == "OK"))
    repressed.XLOC <- repressed.data.frame[["gene_id"]]
    repressed.genes <- gene.names[repressed.XLOC]
    names(repressed.genes) <- NULL
    repressed.file <- paste("repressed_genes_",labels[comparisons[i+1]],"_",labels[comparisons[i]],".txt",sep = "")
    write(repressed.genes,file=repressed.file)
  
    degs <- c(degs, activated.genes, repressed.genes)
  }

  total.degs <- degs[degs != ""]
  sort(total.degs)
  unique(total.degs) 

  write.table(x = total.degs, file = "degs.txt")

}

else if (th == 0 && pv != 0)
{
  th.log <- log2(th)

  degs <- vector(mode = "character")

  for (i in seq(from = 1, to = length(comparisons)-1, by = 2))
  {

    scatter.name <- paste("scatter_",labels[comparisons[i+1]],"_",labels[comparisons[i]],".png", sep = "")
    scatter.comparison <- csScatter(data.genes,labels[comparisons[i+1]],labels[comparisons[i]])
    scatter.comparison
    ggsave(filename = scatter.name)
  
    volcano.name <- paste("volcano_",labels[comparisons[i+1]],"_",labels[comparisons[i]],".png", sep = "")
    volcano.comparison <- csVolcano(data.genes,labels[comparisons[i+1]],labels[comparisons[i]])
    volcano.comparison
    ggsave(filename = volcano.name)
  
    activated.data.frame <- subset(gene.diff,(sample_1 == labels[comparisons[i]] & sample_2 == labels[comparisons[i+1]] & log2_fold_change > 0 & q_value < pv & status == "OK"))
    activated.XLOC <- activated.data.frame[["gene_id"]]
    activated.genes <- gene.names[activated.XLOC]
    names(activated.genes) <- NULL
    activated.file <- paste("activated_genes_",labels[comparisons[i+1]],"_",labels[comparisons[i]],".txt",sep = "")
    write(activated.genes,file=activated.file)
  
    repressed.data.frame <- subset(gene.diff,(sample_1 == labels[comparisons[i]] & sample_2 == labels[comparisons[i+1]] & log2_fold_change < 0 & q_value < pv & status == "OK"))
    repressed.XLOC <- repressed.data.frame[["gene_id"]]
    repressed.genes <- gene.names[repressed.XLOC]
    names(repressed.genes) <- NULL
    repressed.file <- paste("repressed_genes_",labels[comparisons[i+1]],"_",labels[comparisons[i]],".txt",sep = "")
    write(repressed.genes,file=repressed.file)
  
    degs <- c(degs, activated.genes, repressed.genes)
  }

  total.degs <- degs[degs != ""]
  sort(total.degs)
  unique(total.degs) 

  write.table(x = total.degs, file = "degs.txt")

}

else if (th != 0 && pv != 0)
{
  th.log <- log2(2)
pv <- 0.05

  degs <- vector(mode = "character")

  for (i in seq(from = 1, to = length(comparisons)-1, by = 2))
  {

    scatter.name <- paste("scatter_",labels[comparisons[i+1]],"_",labels[comparisons[i]],".png", sep = "")
    scatter.comparison <- csScatter(data.genes,"col","abc")
    scatter.comparison
    ggsave(filename = "scatter_col_abc.png")
  
    volcano.name <- paste("volcano_",labels[comparisons[i+1]],"_",labels[comparisons[i]],".png", sep = "")
    volcano.comparison <- csVolcano(data.genes,"col","abc")
    help("csVolcano")
    volcano.comparison
    ggsave(filename = "volcano_col_abc.png")
  
    activated.data.frame <- subset(gene.diff,(sample_1 == "abc" & sample_2 == "col" & log2_fold_change > th.log & q_value < pv & status == "OK"))
    activated.XLOC <- activated.data.frame[["gene_id"]]
    activated.genes <- gene.names[activated.XLOC]
    names(activated.genes) <- NULL
    activated.file <- paste("activated_genes_",labels[comparisons[i+1]],"_",labels[comparisons[i]],".txt",sep = "")
    write(activated.genes,file="activated_genes_col_abc_txt")
  
    repressed.data.frame <- subset(gene.diff,(sample_1 == "abc" & sample_2 == "col" & log2_fold_change < th.log & q_value < pv & status == "OK"))
    repressed.XLOC <- repressed.data.frame[["gene_id"]]
    repressed.genes <- gene.names[repressed.XLOC]
    names(repressed.genes) <- NULL
    repressed.file <- paste("repressed_genes_",labels[comparisons[i+1]],"_",labels[comparisons[i]],".txt",sep = "")
    write(repressed.genes,file="repressed_genes_col_abc.txt")
  
    degs <- c(degs, activated.genes, repressed.genes)
  }

  total.degs <- degs[degs != ""]
  sort(total.degs)
  unique(total.degs) 

  write.table(x = total.degs, file = "degs.txt")

}
