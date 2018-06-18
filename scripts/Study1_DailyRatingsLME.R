# Microdosing Experiences
# Vince Polito
# vince.polito@mq.edu.au
# 
# This script relies on csv files in the cleandata subfolder
# This script performs LME analyses for all daily ratings in Study1

if (!require("pacman")) install.packages("pacman")
library(pacman)
p_load(psych,lsmeans,nlme,ggpubr,ggthemes,tidyverse)
p_load_gh("vince-p/vtools")

dailydata<-read_csv("cleandata/dailydata.csv") #Load daily summary data
dailydata<-dailydata[!dailydata$id %in% read_csv("cleandata/hidose.csv")$id,] ## RUN THIS LINE TO EXCLUDE HIGH DOSE DAILY REPORTS


dailydata$type[dailydata$type=="dayother"]<-"Baseline"
dailydata$type[dailydata$type=="day0"]<-"DoseDay"
dailydata$type[dailydata$type=="day1"]<-"Day+1"
dailydata$type[dailydata$type=="day2"]<-"Day+2"

dailydata$type <- factor(dailydata$type, levels=c("Baseline","DoseDay", "Day+1", "Day+2"))
dailydata<-dailydata %>% select(id, type,order(colnames(.))) # sort columns alphabetically

# ## WORKING FOR GENERATING A LME FOR A SINGLE RATING ===================
# model.lme <- lme(d~type,random=~1|id,data=dailydata,method="ML",na.action = na.omit) #basic model without corrections
# summary(model.lme)
# model.lsm = lsmeans(model.lme, "type") # generates an lsmobj with the appropriate means for each condition
# z<-(cont.lsm<-contrast(model.lsm, "trt.vs.ctrl1", adjust="holm")) #trtvsctrl1 compares all other values to first value (Baseline).
# plot(model.lsm, horiz=F)
# tt<-summary(model.lme)


makeplot<-function(data,graphtitle){
  c<-"steelblue"
  ggplot(data=data, aes(x=type, y=lsmean)) +
    geom_line(group=1,color=c,linetype='dashed',size=1.5) + 
    geom_errorbar(aes(ymin = lower.CL, ymax = upper.CL), width = 0.2, alpha=.6, size=1.2, color=c) +
    geom_point(aes(y = lsmean), size = 3, shape = 22, color=c, fill=c) + # darkred / pink
    ylim(2.8, 4) +
    annotate("text", x = 2, y = 3.9, label = "*",colour = "red", size = 14) + #comparison bars would be better
    labs(x = NULL, y = "Rating",
         title = graphtitle) +
    theme(axis.text.x = element_text(face="bold",  size=18),
          axis.title.y =element_text(face="plain",  size=16),
          axis.text.y = element_text(face="plain",  size=18),
          plot.title = element_text(hjust = 0.5, size=22),
          plot.margin=unit(c(1,0,2,0), "lines")) +
    theme_hc()
   
}

# Test plot with this code:
 # model.lme <- lme(Connected~type,random=~1|id,data=dailydata,method="ML",na.action = na.omit) #basic model without correctio
 # m<-makeplot(as.data.frame(summary(lsmeans(model.lme, ~type))),"test")
 # m


# Loop through all variables ===================

names(dailydata)[3:9]<-c("Connected", "Contemplative","Creative","Focused","Happy","Productive","Well")

describeBy(dailydata[3:9],dailydata$type) # Descriptives for each type

varlist=names(dailydata)[3:9] #define what vars to use
daily.modelsummary<-lapply(varlist, function(x) { 
  # generate the  uncorrected model
  dailymodel = lme(eval(substitute(i ~ type, list(i = as.name(x)))),
                   random = ~1 | id, data = dailydata,method="ML",na.action = na.omit)
  
  # this line fixes the label for the lme object. See note in loop below
  dailymodel$call$fixed<-eval(substitute(i ~ type, list(i = as.name(x)))) 
  
  # generate a summary object to feed into table
  temp.summary<-summary(dailymodel)
  
  # generate a least squares means object (for contrast totals I think)
  temp.lsm = lsmeans(dailymodel, "type")
  
  # generate the actual contrasts
  temp.contrasts<-summary(contrast(temp.lsm, "trt.vs.ctrl1", adjust="holm")) #trtvsctrl1 compares all other values to first value (Baseline).
  
  # make a dataframe with the model summary statistics
  data.frame(Measure=x,Intercept=as.numeric(temp.summary$tTable["(Intercept)",c("Value")]),
             Day0_b=as.numeric(temp.summary$tTable["typeDoseDay",c("Value")]),
             t=as.numeric(temp.summary$tTable["typeDoseDay",c("t-value")]),
             p=pv(temp.contrasts[1,6]), #this is lazy notation... referring to the first comparison. 6th col is p value
             Day1_b=as.numeric(temp.summary$tTable["typeDay+1",c("Value")]),
             T=as.numeric(temp.summary$tTable["typeDay+1",c("t-value")]),
             p=pv(temp.contrasts[2,6]),
             Day2_b=as.numeric(temp.summary$tTable["typeDay+2",c("Value")]),
             T=as.numeric(temp.summary$tTable["typeDay+2",c("t-value")]),
             p=pv(temp.contrasts[3,6])
             )
})
round_df(do.call(rbind,daily.modelsummary)) # this line converts output from loop above to a useable dataframe. 


# this is a second loop to generate data for plots
daily.plots<-lapply(varlist, function(x) { 
  # GENERATE THE BASIC UNCORRECTED MODEL
  #code from: https://stackoverflow.com/questions/26357429/how-to-use-substitute-to-loop-lme-functions-from-nlme-package
  dailymodel = lme(eval(substitute(i ~ type, list(i = as.name(x)))),
                   random = ~1 | id, data = dailydata,method="ML",na.action = na.omit)
  
  # This  next line necessary for lsmeans to work. From the alternate method (which also works) at https://stackoverflow.com/questions/26357429/how-to-use-substitute-to-loop-lme-functions-from-nlme-package
  dailymodel$call$fixed<-eval(substitute(i ~ type, list(i = as.name(x)))) 
  
  # GENERATE THE CORRECTED MODEL
  model.lsm = lsmeans(dailymodel, "type")
  
  # CREATE PLOTS
  tmp<-as.data.frame(summary(lsmeans(dailymodel, ~type)))
  makeplot(data=tmp,graphtitle=x)
})

#arrange in panels: http://www.sthda.com/english/articles/24-ggpubr-publication-ready-plots/81-ggplot2-easy-way-to-mix-multiple-graphs-on-the-same-page/
# *** is there a better way to do this subsetting?
ggarrange(daily.plots[[1]], daily.plots[[2]], daily.plots[[3]], daily.plots[[4]], daily.plots[[5]], daily.plots[[6]], daily.plots[[7]], 
          #labels = c("A", "B"),
          ncol = 2, nrow = 4)
