

darken <- function(color, factor=1.4){
  col <- col2rgb(color)
  col <- col/factor
  col <- rgb(t(col), maxColorValue=255)
  col
}


#' @export
plot_hospital<- function(initial_report= 1000,
                           final_report = 10000,
                           distribution= "exponential",
                           young=.24,
                           medium=.6,
                           M=352,
                           L=1781,
                    			t = 60,
                    			chi_C=0.1,
                    			chi_L=.142857,
                    			growth_rate=1,
                					mu_C1 = .1,
                					mu_C2 = .1,
                					mu_C3 = .1,
                					rampslope=1.2,
                					Cinit = .25,
                					Finit = .5,
                					Lfinal=1781,
                					Lramp=c(0,0),
                					Mfinal=352,
                					Mramp=c(0,0),
                          doprotocols=0){
  
      hospital <- hospital_queues(initial_report=initial_report,
                                  final_report = final_report,
                                  distribution= distribution,
                                  young=young,
                                  medium=medium,
                                  M=M,
                                  L=L,
                              		t=t,
                              		chi_C=chi_C,
                              		chi_L=chi_L,
                              		growth_rate=growth_rate,
                      						mu_C1 = mu_C1,
                      						mu_C2 = mu_C2,
                      						mu_C3 = mu_C3,
                      						rampslope=rampslope,
                      						Cinit = Cinit,
                      						Finit = Finit,
                      						Lfinal=Lfinal,
                      						Lramp=Lramp,
                      						Mfinal=Mfinal,
                      						Mramp=Mramp,
                                  doprotocols=doprotocols)

      hospital$totaldead<- hospital$Dead_at_ICU + hospital$Dead_in_ED + hospital$Dead_on_Floor+ hospital$Dead_waiting_for_Floor+ hospital$Dead_waiting_for_ICU+ hospital$Dead_with_mild_symptoms
      hospital$totalWC<- hospital$WC1 + hospital$WC2 + hospital$WC3
      hospital$totalWF<- hospital$WF1 + hospital$WF2 + hospital$WF3
      

      
      hospital_melt<- hospital %>% gather(variable, value, -time);  
      
  
      p1 <-ggplot(hospital,
                  aes(x=time, y=reports))+
        geom_bar(size=1.5, stat="identity")+
      theme_bw(base_size=14) +
        labs(x="Time (Day)", y="Patients")+
        ggtitle("ED visits per day")+
        theme(panel.border = element_blank(), axis.line = element_line(colour = "black"))      
      
     
      
      p2 <-ggplot(hospital_melt,
                  aes(x=time,y=value, color=variable))+
        geom_line(data= hospital_melt[hospital_melt$variable %in% c("Number_seen_at_ED", "totaldead"),],size=1.5)+
        theme_bw(base_size=14) +
        scale_color_manual( name=element_blank(), values=c("black", "red"), labels=c("Number_seen_at_ED"="ED throughput", "totaldead"="Deaths"))+
        labs(x="Time (Day)", y="Patients")+
        ggtitle("Cumulative ED triages and deaths")+
        theme(panel.border = element_blank(), axis.line = element_line(colour = "black"),  legend.position = c(0.25, 0.75), legend.text=element_text(size=11),    legend.title=element_text(size=8),legend.background = element_rect(fill="transparent"))
       
      p3 <-ggplot(hospital_melt,
                  aes(x=time,y=value, fill=variable))+
        geom_area(data= hospital_melt[hospital_melt$variable %in% c("Dead_at_ICU", "Dead_waiting_for_ICU", "Dead_on_Floor", "Dead_waiting_for_Floor", "Dead_with_mild_symptoms", "Dead_in_ED"),],size=1.5)+
        theme_bw(base_size=14)+
        scale_fill_manual( name=element_blank(), values=(c("black", "yellow", "red",  "pink", "grey", "orange")), labels=c("Dead_at_ICU"="In ICU", "Dead_waiting_for_ICU"="Waiting for ICU beds", "Dead_on_Floor"= "On floor", "Dead_waiting_for_Floor"="Waiting for floor beds", "Dead_with_mild_symptoms"="Post discharge from ED", "Dead_in_ED"="In ED"))+
        labs(x="Time (Day)", y="Patients")+
        ggtitle("Cumulative deaths by location")+
        theme(panel.border = element_blank(), axis.line = element_line(colour = "black"), legend.position = c(0.25, 0.65), legend.text=element_text(size=11),    legend.title=element_text(size=8),legend.background = element_rect(fill="transparent")) 
  
      
      p4 <-ggplot(hospital_melt,
                  aes(x=time,y=value, color=variable))+
        geom_line(data= hospital_melt[hospital_melt$variable %in% c("CTotal", "FTotal", "totalWC", "totalWF"),],size=1.5)+
        theme_bw(base_size=14) +
        scale_color_manual( name=element_blank(), values=c("black", "red", "grey", "pink"), labels=c("CTotal"="In ICU", "FTotal"= "On floor", "totalWC" ="Waiting for ICU beds", "totalWF"="Waiting for floor beds"))+
        labs(x="Time (Day)", y="Patients")+
        ggtitle("ICU and floor utilization")+
        theme(panel.border = element_blank(), axis.line = element_line(colour = "black"),  legend.position = c(0.25, 0.75), legend.text=element_text(size=11),    legend.title=element_text(size=8),legend.background = element_rect(fill="transparent"))+
        #geom_hline(yintercept=M, linetype="dashed", color = "black", size=1.5)+
        #geom_hline(yintercept=L, linetype="dashed", color = "red", size=1.5)
        geom_line(data= hospital_melt[hospital_melt$variable == "capacity_L",],size=1.5, linetype="dashed", color = "red")+
        geom_line(data= hospital_melt[hospital_melt$variable == "capacity_M",],size=1.5, linetype="dashed", color = "black")
      ### determine when the hospital exceeds capacity
      
      #ICU queue 
      
      ICUover = (hospital$WC1+hospital$WC2+hospital$WC3>=1)
      
      
      #floor queue
      
      floorover = (hospital$WF1+hospital$WF2+hospital$WF3>=1)
      
      
      if(sum(floorover)>0){
        floorover<- min(which(floorover))
        p4 <- p4 +annotate(geom="label", x=floorover, y=hospital$capacity_L[floorover], label=paste("Day", as.character(floorover)), size=4, color="red")
      }

      if(sum(ICUover)>0){
        ICUover<- min(which(ICUover))
        p4 <- p4 +annotate(geom="label", x=ICUover, y=hospital$capacity_M[ICUover], label=paste("Day", as.character(ICUover)), size=4)
      }
      list(p1, p2, p3, p4, ICUover, floorover)
      

}
