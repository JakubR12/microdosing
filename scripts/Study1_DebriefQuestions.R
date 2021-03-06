# Microdosing Experiences
# Vince Polito
# vince.polito@mq.edu.au
# 
# # I learnt R while creating these scripts so I'm sure there are better ways to do some things.
# If you notice any errors or have suggestions for improvements, please get in touch.
# 
# This script relies on csv files in the cleandata subfolder
# This script performs analysis of debrief questions in Study1

pacman::p_load(psych,scales,tidyverse)

post.debrief<-read_csv("cleandata/postdebrief.csv")

#Confidence in doseages reported
# 7-point ordinal scale
# 1= Not at all confident - 7=Completely confident
describe(post.debrief$PostQ_1)
table(post.debrief$PostQ_1)

Meaning1<-scales::rescale(post.debrief[[6]], to=c(1,100), from=c(1,8))
Meaning2<-scales::rescale(post.debrief[[7]], to=c(1,100), from=c(1,6))
Meaning3<-scales::rescale(post.debrief[[8]], to=c(1,100), from=c(-3,3))
post.rescaled<-data.frame(Meaning1,Meaning2,Meaning3)
describe(post.rescaled)


#Test correlation between meaning3 (change in wellbeing) and post qoli score
pre.post<-read.csv("cleandata/longterm.csv")
pre.post<-pre.post[pre.post$Time=="post",]
cor.test(x=pre.post$QOLI_Raw, y=post.rescaled$Meaning3, use = "complete.obs")

