setwd("~/PhD/ng_poc/repository/NG-POC-resistance/scripts/")

library(xtable)
library(ggplot2)
library(grid)
library(gridExtra)
library(grDevices)
library(ggthemes)
library(cowplot)
library(tidyr)

source("gg_custom.R")


max.outros <- 1000 # number of parameter sets used in paper


for (popno in c(1,2)){ # population loop
  if(popno == 1){
    seed <- 312774
    pop <- "msm"
    groupcol <- "dodgerblue3"
    figno <- 2
    popname <- "MSM"
  }else{
    seed <- 993734
    pop <- "het" 
    groupcol <- "darkolivegreen3"
    figno <- 3
    popname <- "HMW"
  }
  
  load(paste("../data/outros_", pop, "-", seed, "-", pop, ".data", sep=""))
  
  
  odf <- outros[1:max.outros,]
  
  # get median and IQR for prevalence and incidence
  # prevL, prevH, prevT, incL, incH, incT, theta
  prevM <- apply(odf[,1:3], 2, median)
  prev50low <- apply(odf[,1:3], 2, function(x) quantile(x, 0.25))
  prev50up <- apply(odf[,1:3], 2, function(x) quantile(x, 0.75))
  incM <- median(odf[,6]*odf[,11])
  inc50low <- quantile(odf[,6]*odf[,11], 0.25)
  inc50up <- quantile(odf[,6]*odf[,11], 0.75)
  
  df <- rbind(cbind(prevM, prev50low, prev50up), cbind(incM, inc50low, inc50up))
  df2a <- df[1:3,]*100
  df2b <- df[4,]*100000
  
  df <- rbind(df2a, df2b)
  
  # print latex table with median and IQR
  print(xtable(df))
  
  # Generate figures S2/S3 that show prevalence and incidence in resistance-free equilibrium
  dfn <- as.data.frame(cbind(odf, odf[,4]*odf[,11], odf[,5]*odf[,11], odf[,6]*odf[,11]))
  colnames(dfn) <- c("prevL", "prevH", "prevT", "incL", "incH", "incT", "epsilon", "betaL", "betaH", "D", "f", "visIncL", "visIncH", "visIncT")
  
  # manipulate prevalence records
  dfn2p <- dfn[,1:3] %>%
    gather(group, value, prevL:prevT)
  
  dfn2p$group <- factor(dfn2p$group, levels=c("prevL", "prevH", "prevT"))
  levels(dfn2p$group) <- c(paste("low activity class ", popname, sep=""), paste("high activity class ", popname, sep=""), paste("total ", popname, " population", sep=""))
  
  # plot prevalence
  pp <- ggplot(dfn2p)+
    geom_histogram(aes(x=value*100, y=..density..), fill=groupcol, size=0.2, colour=groupcol, alpha=0.5, boundary=0, bins=31)+
    xlab("prevalence (in %)")+
    custom+
    theme(strip.background=element_rect(size=0, fill="white"),
          plot.margin=margin(12,3,1,1,"pt"))
  pp2 <- pp + facet_wrap( ~ group, ncol=3, scales="free")
  pp2
  
  # manipulate incidence records
  dfn2i <- dfn[,12:14] %>%
    gather(group, value, visIncL:visIncT)
  
  dfn2i$group <- factor(dfn2i$group, levels=c("visIncL", "visIncH", "visIncT"))
  levels(dfn2i$group) <- c(paste("low activity class ", popname, sep=""), paste("high activity class ", popname, sep=""), paste("total ", popname, " population", sep=""))
  
  # plot incidence
  pi <- ggplot(dfn2i)+
    geom_histogram(aes(x=value*100000, y=..density..), fill=groupcol, size=0.2, colour=groupcol, alpha=0.5, boundary=0, bins=31)+
    xlab("incidence of diagnosed and treated infections (per 100 000 persons per year)")+
    custom+
    theme(strip.background=element_rect(size=0, fill="white"),
          plot.margin=margin(12,3,1,1,"pt"))
  pi2 <- pi + facet_wrap( ~ group, ncol=3, scales="free")
  pi2
  
  # arrange prevalence and incidence plots on one common plot
  gprev <- ggplotGrob(pp2)
  ginc <- ggplotGrob(pi2)
  
  g <- rbind(gprev, ginc)
  
  pdf(paste("../figures/FigS",figno,"_tmp.pdf", sep=""), width=lwi, height=lwi*0.5, colormodel="cmyk")
  grid.newpage()
  grid.draw(g)
  dev.off()
  
}