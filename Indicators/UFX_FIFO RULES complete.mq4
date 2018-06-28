//+------------------------------------------------------------------+
//|                                                    UFX Rules.mq4 |
//|                                 info@TradeResearchInstitute.com  |
//+------------------------------------------------------------------+
#property copyright "Trade Research Institute"
#property link      "info@traderesearchinstitute.com"  
 


#property indicator_chart_window
 
 
extern int    myChartX   = 0 ;
extern int    myChartY1   = 10 ;
extern int    myChartY2   = 30 ;
extern int    myChartY3   = 50 ;
extern int    myChartY4   = 70 ;
extern int    myChartY5   = 90 ;
extern int    myChartY6   = 110 ;
extern int    myChartY7   = 130 ;
extern int    myChartY8   = 150 ;
extern int    myChartY9   = 170 ;
extern int    myChartY10   = 190 ;
extern int    myChartY11   = 210 ;
extern int    myChartY12   = 230 ;
extern int    myChartY13   = 250 ;
extern int    myChartY14   = 270 ;
extern int    myChartY15   = 290 ;
extern int    myChartY16   = 310 ;
extern int    myChartY17   = 330 ;
extern int    myChartY18   = 350 ;
extern int    myChartY19   = 370 ;
extern int    myChartY20   = 390 ;
extern int    myChartY21   = 410 ;
extern int    myChartY22   = 430 ;
extern int    myChartY23   = 450 ;
extern int    myChartY24   = 470 ;
extern int    myChartY25   = 490 ;
extern int    myChartY26   = 510 ;
extern int    myCorner   = 0;
extern string myFont     = "Arial Black" ;
extern int    myFontSize = 10 ;
extern color  myColor1    = Lime ;
extern color  myColor2    = RoyalBlue ;
extern color  myColor3    = RoyalBlue ;
extern color  myColor4    = RoyalBlue ;
extern color  myColor5    = RoyalBlue ;
extern color  myColor6    = RoyalBlue ;
extern color  myColor7    = RoyalBlue ;
extern color  myColor8    = RoyalBlue ;
extern color  myColor9    = RoyalBlue ;
extern color  myColor10    = RoyalBlue ;
extern color  myColor11    = RoyalBlue ;
extern color  myColor12    = RoyalBlue ;
extern color  myColor13    = RoyalBlue ;
extern color  myColor14    = RoyalBlue ;
extern color  myColor15    = RoyalBlue ;
extern color  myColor16    = RoyalBlue ;
extern color  myColor17    = RoyalBlue ;
extern color  myColor18    = RoyalBlue ;
extern color  myColor19    = RoyalBlue ;
extern color  myColor20    = RoyalBlue ;
extern color  myColor21    = RoyalBlue ;
extern color  myColor22    = RoyalBlue ;
extern color  myColor23    = Lime ;
extern color  myColor24    = Lime ;
extern color  myColor25    = DimGray ;
extern color  myColor26    = DimGray ;

extern string myMessage1  = "WUKAR: WAKE UP KICK ASS REPEAT" ;
extern string myMessage2  = "1. D1 & 1H candle color MUST agree" ;
extern string myMessage3  = "2. Entry ONLY the FIRST 00 level" ;
extern string myMessage4  = "3. Frankfurt open only .400/.500/.600 levels" ;
extern string myMessage5  = "4. London open all levels" ;
extern string myMessage6  = "5. No short @ .100" ;
extern string myMessage7  = "6. No long @ .900" ;
extern string myMessage8  = "7. No trading < 1 hour before RED NEWS" ;
extern string myMessage9  = "8. No trading < 30 min. after RED NEWS" ;
extern string myMessage10  = "9. After 4 losses stop trading for the day" ;
extern string myMessage11  = "10. Higher probabilities @ market opens" ;
extern string myMessage12  = "11. Check ADR" ;
extern string myMessage13  = "12. Distance to RN > 10 pips (See 4 & 5)"  ;
extern string myMessage14  = "13. Stop trading after reaching Daily target" ;
extern string myMessage15  = "14. Stoploss 10 pips" ;
extern string myMessage16  = "15. Take profit 5 pips" ;
extern string myMessage17  = "16. Trailstop 3.5 pips & SL to BE @ 3.5 pips" ;
extern string myMessage18  = "17. Only pending orders" ;
extern string myMessage19  = "18. Trade higher ADR pairs only" ;
extern string myMessage20  = "19. My pairs EJ and GJ" ;
extern string myMessage21  = "20. Only 1 trade per hour per pair" ;
extern string myMessage22  = "21. A mistake is 10 burpees" ;
extern string myMessage23  = "22. GOAL = PROFIT !!!" ;
extern string myMessage24  = "22. Daily Target = 2 %" ;
extern string myMessage25  = "22. PDF: PATIENCE, DISCIPLINE, FOCUS!!" ;
extern string myMessage26  = "22. BCC: BELIEF, CONSISTENCY, CONFIDENCE!!" ;


//+------------------------------------------------------------------+
int init()
  { 
  
  
             
   string tObjName1   = "TRITAG"  ;
   ObjectDelete(tObjName1);  
   ObjectCreate(tObjName1, OBJ_LABEL, 0, 0, 0); 
   ObjectSetText(tObjName1, myMessage1 , myFontSize ,myFont  ,  myColor1 );
   ObjectSet(tObjName1, OBJPROP_CORNER, myCorner);
   ObjectSet(tObjName1, OBJPROP_XDISTANCE, myChartX+2*myFontSize );
   ObjectSet(tObjName1, OBJPROP_YDISTANCE, myChartY1 ); 
   ObjectSet(tObjName1, OBJPROP_BACK,true);  
   
   string tObjName2   = "TRITAG2"  ;
   ObjectDelete(tObjName2);  
   ObjectCreate(tObjName2, OBJ_LABEL, 0, 0, 0); 
   ObjectSetText(tObjName2, myMessage2 , myFontSize ,myFont  ,  myColor2 );
   ObjectSet(tObjName2, OBJPROP_CORNER, myCorner);
   ObjectSet(tObjName2, OBJPROP_XDISTANCE, myChartX+2*myFontSize );
   ObjectSet(tObjName2, OBJPROP_YDISTANCE, myChartY2 ); 
   ObjectSet(tObjName2, OBJPROP_BACK,true);
   
   string tObjName3   = "TRITAG3"  ;
   ObjectDelete(tObjName3);  
   ObjectCreate(tObjName3, OBJ_LABEL, 0, 0, 0); 
   ObjectSetText(tObjName3, myMessage3 , myFontSize ,myFont  ,  myColor3 );
   ObjectSet(tObjName3, OBJPROP_CORNER, myCorner);
   ObjectSet(tObjName3, OBJPROP_XDISTANCE, myChartX+2*myFontSize );
   ObjectSet(tObjName3, OBJPROP_YDISTANCE, myChartY3 ); 
   ObjectSet(tObjName3, OBJPROP_BACK,true); 
   
   string tObjName4   = "TRITAG4"  ;
   ObjectDelete(tObjName4);  
   ObjectCreate(tObjName4, OBJ_LABEL, 0, 0, 0); 
   ObjectSetText(tObjName4, myMessage4 , myFontSize ,myFont  ,  myColor4 );
   ObjectSet(tObjName4, OBJPROP_CORNER, myCorner);
   ObjectSet(tObjName4, OBJPROP_XDISTANCE, myChartX+2*myFontSize );
   ObjectSet(tObjName4, OBJPROP_YDISTANCE, myChartY4 ); 
   ObjectSet(tObjName4, OBJPROP_BACK,true); 
   
   string tObjName5   = "TRITAG5"  ;
   ObjectDelete(tObjName5);  
   ObjectCreate(tObjName5, OBJ_LABEL, 0, 0, 0); 
   ObjectSetText(tObjName5, myMessage5 , myFontSize ,myFont  ,  myColor5 );
   ObjectSet(tObjName5, OBJPROP_CORNER, myCorner);
   ObjectSet(tObjName5, OBJPROP_XDISTANCE, myChartX+2*myFontSize );
   ObjectSet(tObjName5, OBJPROP_YDISTANCE, myChartY5 ); 
   ObjectSet(tObjName5, OBJPROP_BACK,true); 
   
   string tObjName6   = "TRITAG6"  ;
   ObjectDelete(tObjName6);  
   ObjectCreate(tObjName6, OBJ_LABEL, 0, 0, 0); 
   ObjectSetText(tObjName6, myMessage6 , myFontSize ,myFont  ,  myColor6 );
   ObjectSet(tObjName6, OBJPROP_CORNER, myCorner);
   ObjectSet(tObjName6, OBJPROP_XDISTANCE, myChartX+2*myFontSize );
   ObjectSet(tObjName6, OBJPROP_YDISTANCE, myChartY6 ); 
   ObjectSet(tObjName6, OBJPROP_BACK,true); 
   
   string tObjName7   = "TRITAG7"  ;
   ObjectDelete(tObjName7);  
   ObjectCreate(tObjName7, OBJ_LABEL, 0, 0, 0); 
   ObjectSetText(tObjName7, myMessage7 , myFontSize ,myFont  ,  myColor7 );
   ObjectSet(tObjName7, OBJPROP_CORNER, myCorner);
   ObjectSet(tObjName7, OBJPROP_XDISTANCE, myChartX+2*myFontSize );
   ObjectSet(tObjName7, OBJPROP_YDISTANCE, myChartY7 ); 
   ObjectSet(tObjName7, OBJPROP_BACK,true); 
   
   string tObjName8   = "TRITAG8"  ;
   ObjectDelete(tObjName8);  
   ObjectCreate(tObjName8, OBJ_LABEL, 0, 0, 0); 
   ObjectSetText(tObjName8, myMessage8 , myFontSize ,myFont  ,  myColor8 );
   ObjectSet(tObjName8, OBJPROP_CORNER, myCorner);
   ObjectSet(tObjName8, OBJPROP_XDISTANCE, myChartX+2*myFontSize );
   ObjectSet(tObjName8, OBJPROP_YDISTANCE, myChartY8 ); 
   ObjectSet(tObjName8, OBJPROP_BACK,true); 
   
   string tObjName9   = "TRITAG9"  ;
   ObjectDelete(tObjName9);  
   ObjectCreate(tObjName9, OBJ_LABEL, 0, 0, 0); 
   ObjectSetText(tObjName9, myMessage9 , myFontSize ,myFont  ,  myColor9 );
   ObjectSet(tObjName9, OBJPROP_CORNER, myCorner);
   ObjectSet(tObjName9, OBJPROP_XDISTANCE, myChartX+2*myFontSize );
   ObjectSet(tObjName9, OBJPROP_YDISTANCE, myChartY9 ); 
   ObjectSet(tObjName9, OBJPROP_BACK,true); 
   
   string tObjName10   = "TRITAG10"  ;
   ObjectDelete(tObjName10);  
   ObjectCreate(tObjName10, OBJ_LABEL, 0, 0, 0); 
   ObjectSetText(tObjName10, myMessage10 , myFontSize ,myFont  ,  myColor10 );
   ObjectSet(tObjName10, OBJPROP_CORNER, myCorner);
   ObjectSet(tObjName10, OBJPROP_XDISTANCE, myChartX+2*myFontSize );
   ObjectSet(tObjName10, OBJPROP_YDISTANCE, myChartY10 ); 
   ObjectSet(tObjName10, OBJPROP_BACK,true); 
   
   string tObjName11   = "TRITAG11"  ;
   ObjectDelete(tObjName11);  
   ObjectCreate(tObjName11, OBJ_LABEL, 0, 0, 0); 
   ObjectSetText(tObjName11, myMessage11 , myFontSize ,myFont  ,  myColor11 );
   ObjectSet(tObjName11, OBJPROP_CORNER, myCorner);
   ObjectSet(tObjName11, OBJPROP_XDISTANCE, myChartX+2*myFontSize );
   ObjectSet(tObjName11, OBJPROP_YDISTANCE, myChartY11 ); 
   ObjectSet(tObjName11, OBJPROP_BACK,true); 
   
   string tObjName12   = "TRITAG12"  ;
   ObjectDelete(tObjName12);  
   ObjectCreate(tObjName12, OBJ_LABEL, 0, 0, 0); 
   ObjectSetText(tObjName12, myMessage12 , myFontSize ,myFont  ,  myColor12 );
   ObjectSet(tObjName12, OBJPROP_CORNER, myCorner);
   ObjectSet(tObjName12, OBJPROP_XDISTANCE, myChartX+2*myFontSize );
   ObjectSet(tObjName12, OBJPROP_YDISTANCE, myChartY12 ); 
   ObjectSet(tObjName12, OBJPROP_BACK,true); 
   
   string tObjName13   = "TRITAG13"  ;
   ObjectDelete(tObjName13);  
   ObjectCreate(tObjName13, OBJ_LABEL, 0, 0, 0); 
   ObjectSetText(tObjName13, myMessage13 , myFontSize ,myFont  ,  myColor13 );
   ObjectSet(tObjName13, OBJPROP_CORNER, myCorner);
   ObjectSet(tObjName13, OBJPROP_XDISTANCE, myChartX+2*myFontSize );
   ObjectSet(tObjName13, OBJPROP_YDISTANCE, myChartY13 ); 
   ObjectSet(tObjName13, OBJPROP_BACK,true); 
   
   string tObjName14   = "TRITAG14"  ;
   ObjectDelete(tObjName14);  
   ObjectCreate(tObjName14, OBJ_LABEL, 0, 0, 0); 
   ObjectSetText(tObjName14, myMessage14 , myFontSize ,myFont  ,  myColor14 );
   ObjectSet(tObjName14, OBJPROP_CORNER, myCorner);
   ObjectSet(tObjName14, OBJPROP_XDISTANCE, myChartX+2*myFontSize );
   ObjectSet(tObjName14, OBJPROP_YDISTANCE, myChartY14 ); 
   ObjectSet(tObjName14, OBJPROP_BACK,true);
   
   string tObjName15   = "TRITAG15"  ;
   ObjectDelete(tObjName15);  
   ObjectCreate(tObjName15, OBJ_LABEL, 0, 0, 0); 
   ObjectSetText(tObjName15, myMessage15 , myFontSize ,myFont  ,  myColor15 );
   ObjectSet(tObjName15, OBJPROP_CORNER, myCorner);
   ObjectSet(tObjName15, OBJPROP_XDISTANCE, myChartX+2*myFontSize );
   ObjectSet(tObjName15, OBJPROP_YDISTANCE, myChartY15 ); 
   ObjectSet(tObjName15, OBJPROP_BACK,true);
   
   string tObjName16   = "TRITAG16"  ;
   ObjectDelete(tObjName16);  
   ObjectCreate(tObjName16, OBJ_LABEL, 0, 0, 0); 
   ObjectSetText(tObjName16, myMessage16 , myFontSize ,myFont  ,  myColor16 );
   ObjectSet(tObjName16, OBJPROP_CORNER, myCorner);
   ObjectSet(tObjName16, OBJPROP_XDISTANCE, myChartX+2*myFontSize );
   ObjectSet(tObjName16, OBJPROP_YDISTANCE, myChartY16 ); 
   ObjectSet(tObjName16, OBJPROP_BACK,true); 
   
   string tObjName17   = "TRITAG17"  ;
   ObjectDelete(tObjName17);  
   ObjectCreate(tObjName17, OBJ_LABEL, 0, 0, 0); 
   ObjectSetText(tObjName17, myMessage17 , myFontSize ,myFont  ,  myColor17 );
   ObjectSet(tObjName17, OBJPROP_CORNER, myCorner);
   ObjectSet(tObjName17, OBJPROP_XDISTANCE, myChartX+2*myFontSize );
   ObjectSet(tObjName17, OBJPROP_YDISTANCE, myChartY17 ); 
   ObjectSet(tObjName17, OBJPROP_BACK,true); 
   
   string tObjName18   = "TRITAG18"  ;
   ObjectDelete(tObjName18);  
   ObjectCreate(tObjName18, OBJ_LABEL, 0, 0, 0); 
   ObjectSetText(tObjName18, myMessage18 , myFontSize ,myFont  ,  myColor18 );
   ObjectSet(tObjName18, OBJPROP_CORNER, myCorner);
   ObjectSet(tObjName18, OBJPROP_XDISTANCE, myChartX+2*myFontSize );
   ObjectSet(tObjName18, OBJPROP_YDISTANCE, myChartY18 ); 
   ObjectSet(tObjName18, OBJPROP_BACK,true); 
   
   string tObjName19   = "TRITAG19"  ;
   ObjectDelete(tObjName19);  
   ObjectCreate(tObjName19, OBJ_LABEL, 0, 0, 0); 
   ObjectSetText(tObjName19, myMessage19 , myFontSize ,myFont  ,  myColor19 );
   ObjectSet(tObjName19, OBJPROP_CORNER, myCorner);
   ObjectSet(tObjName19, OBJPROP_XDISTANCE, myChartX+2*myFontSize );
   ObjectSet(tObjName19, OBJPROP_YDISTANCE, myChartY19 ); 
   ObjectSet(tObjName19, OBJPROP_BACK,true); 
   
   string tObjName20   = "TRITAG20"  ;
   ObjectDelete(tObjName20);  
   ObjectCreate(tObjName20, OBJ_LABEL, 0, 0, 0); 
   ObjectSetText(tObjName20, myMessage20 , myFontSize ,myFont  ,  myColor20 );
   ObjectSet(tObjName20, OBJPROP_CORNER, myCorner);
   ObjectSet(tObjName20, OBJPROP_XDISTANCE, myChartX+2*myFontSize );
   ObjectSet(tObjName20, OBJPROP_YDISTANCE, myChartY20 ); 
   ObjectSet(tObjName20, OBJPROP_BACK,true); 
   
   string tObjName21   = "TRITAG21"  ;
   ObjectDelete(tObjName21);  
   ObjectCreate(tObjName21, OBJ_LABEL, 0, 0, 0); 
   ObjectSetText(tObjName21, myMessage21 , myFontSize ,myFont  ,  myColor21 );
   ObjectSet(tObjName21, OBJPROP_CORNER, myCorner);
   ObjectSet(tObjName21, OBJPROP_XDISTANCE, myChartX+2*myFontSize );
   ObjectSet(tObjName21, OBJPROP_YDISTANCE, myChartY21 ); 
   ObjectSet(tObjName21, OBJPROP_BACK,true); 
   
   string tObjName22   = "TRITAG22"  ;
   ObjectDelete(tObjName22);  
   ObjectCreate(tObjName22, OBJ_LABEL, 0, 0, 0); 
   ObjectSetText(tObjName22, myMessage22 , myFontSize ,myFont  ,  myColor22 );
   ObjectSet(tObjName22, OBJPROP_CORNER, myCorner);
   ObjectSet(tObjName22, OBJPROP_XDISTANCE, myChartX+2*myFontSize );
   ObjectSet(tObjName22, OBJPROP_YDISTANCE, myChartY22 ); 
   ObjectSet(tObjName22, OBJPROP_BACK,true); 
   
   string tObjName23   = "TRITAG23"  ;
   ObjectDelete(tObjName23);  
   ObjectCreate(tObjName23, OBJ_LABEL, 0, 0, 0); 
   ObjectSetText(tObjName23, myMessage23 , myFontSize ,myFont  ,  myColor23 );
   ObjectSet(tObjName23, OBJPROP_CORNER, myCorner);
   ObjectSet(tObjName23, OBJPROP_XDISTANCE, myChartX+2*myFontSize );
   ObjectSet(tObjName23, OBJPROP_YDISTANCE, myChartY23 ); 
   ObjectSet(tObjName23, OBJPROP_BACK,true); 
   
   string tObjName24   = "TRITAG24"  ;
   ObjectDelete(tObjName24);  
   ObjectCreate(tObjName24, OBJ_LABEL, 0, 0, 0); 
   ObjectSetText(tObjName24, myMessage24 , myFontSize ,myFont  ,  myColor24 );
   ObjectSet(tObjName24, OBJPROP_CORNER, myCorner);
   ObjectSet(tObjName24, OBJPROP_XDISTANCE, myChartX+2*myFontSize );
   ObjectSet(tObjName24, OBJPROP_YDISTANCE, myChartY24 ); 
   ObjectSet(tObjName24, OBJPROP_BACK,true); 
   
   string tObjName25   = "TRITAG25"  ;
   ObjectDelete(tObjName25);  
   ObjectCreate(tObjName25, OBJ_LABEL, 0, 0, 0); 
   ObjectSetText(tObjName25, myMessage25 , myFontSize ,myFont  ,  myColor25 );
   ObjectSet(tObjName25, OBJPROP_CORNER, myCorner);
   ObjectSet(tObjName25, OBJPROP_XDISTANCE, myChartX+2*myFontSize );
   ObjectSet(tObjName25, OBJPROP_YDISTANCE, myChartY25 ); 
   ObjectSet(tObjName25, OBJPROP_BACK,true); 
   
   string tObjName26   = "TRITAG26"  ;
   ObjectDelete(tObjName26);  
   ObjectCreate(tObjName26, OBJ_LABEL, 0, 0, 0); 
   ObjectSetText(tObjName26, myMessage26 , myFontSize ,myFont  ,  myColor26 );
   ObjectSet(tObjName26, OBJPROP_CORNER, myCorner);
   ObjectSet(tObjName26, OBJPROP_XDISTANCE, myChartX+2*myFontSize );
   ObjectSet(tObjName26, OBJPROP_YDISTANCE, myChartY26 ); 
   ObjectSet(tObjName26, OBJPROP_BACK,true); 
   return(0);
  } 
//+------------------------------------------------------------------+
int start()
  {
   
 

   return(0);
  }
 

//+------------------------------------------------------------------+