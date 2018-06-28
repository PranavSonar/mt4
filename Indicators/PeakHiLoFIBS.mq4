//+------------------------------------------------------------------+
//|                                                PeakHiLo_FIBS.mq4 |
//|                                            Copyright 2017, Radar |
//|                                https://www.SteveHopwoodForex.com |
//|                                                         Based on |
//|                                                    XIT_FIBS.mq4  |
//|                       Copyright © 2011, Jeff West - Forex-XIT  |
//|                                        http://www.forex-xit.com  |
//|                                                             And  |
//|                                                    PeakHiLo.mq4  |
//|                                   Copyright 2016, Steve Hopwood  |
//|                               https://www.SteveHopwoodForex.com  |
//+------------------------------------------------------------------+
#property copyright "Copyright © 2017, Radar, https://www.SteveHopwoodForex.com"
#property link      "https://www.SteveHopwoodForex.com"

#property indicator_chart_window

#define in "PeakHiLo_FIBS" // Indicator Name
#define ins cat(in, cat("_", Symbol(), "_"))

enum tfs          {Current=0,M1=1,M5=5,M15=15,M30=30,H1=60,H4=240,D1=1440,W1=10080,MN=43200};

extern tfs     TimeFrame   =  0;//0 means current chart
extern int     noOfBars    =  1678;
extern color   UpColour    =  Green;
extern color   DownColour  =  Red;

string GetTimeFrameDisplay(int tf)
{

   if (tf == 0)
      tf = Period();
      
   
   if (tf == PERIOD_M1)
      return "M1";
      
   if (tf == PERIOD_M5)
      return "M5";
      
   if (tf == PERIOD_M15)
      return "M15";
      
   if (tf == PERIOD_M30)
      return "M30";
      
   if (tf == PERIOD_H1)
      return "H1";
      
   if (tf == PERIOD_H4)
      return "H4";
      
   if (tf == PERIOD_D1)
      return "D1";
      
   if (tf == PERIOD_W1)
      return "W1";
      
   if (tf == PERIOD_MN1)
      return "Monthly";
      
   return("No recognisable time frame selected");

}//string GetTimeFrameDisplay()

//+------------------------------------------------------------------+
//| Custom indicator initialization function                         |
//+------------------------------------------------------------------+
int init()
  {
//---- indicators
ObjectDelete(cat(ins, GetTimeFrameDisplay(TimeFrame)));
Comment("");
//----
   return(0);
  }
//+------------------------------------------------------------------+
//| Custom indicator deinitialization function                       |
//+------------------------------------------------------------------+
int deinit()
  {
//----
ObjectDelete(cat(ins, GetTimeFrameDisplay(TimeFrame)));
Comment("");
//----
   return(0);
  }
//+------------------------------------------------------------------+
//| Custom indicator iteration function                              |
//+------------------------------------------------------------------+
int start()
{
  //----

   //Rising candle
   int currentPeakHighBar   =  iHighest(Symbol(), TimeFrame, MODE_CLOSE, noOfBars, 1);
   double fibHigh      =  iClose(Symbol(), TimeFrame, currentPeakHighBar);
	 
   //Falling candle
   int currentPeakLowBar =  iLowest(Symbol(), TimeFrame, MODE_CLOSE, noOfBars, 1);
   double fibLow    =  iClose(Symbol(), TimeFrame, currentPeakLowBar);

   datetime highTime = iTime(Symbol(), TimeFrame, currentPeakHighBar);
   datetime lowTime  = iTime(Symbol(), TimeFrame, currentPeakLowBar);
   
   if(lowTime>highTime)
   {
      ObjectDelete(cat(ins, GetTimeFrameDisplay(TimeFrame)));
      ObjectCreate(cat(ins, GetTimeFrameDisplay(TimeFrame)),OBJ_FIBO,0,highTime,fibHigh,lowTime,fibLow);
      color levelColor = UpColour;
   }
   else
   {
      ObjectDelete(cat(ins, GetTimeFrameDisplay(TimeFrame)));
      ObjectCreate(cat(ins, GetTimeFrameDisplay(TimeFrame)),OBJ_FIBO,0,lowTime,fibLow,highTime,fibHigh);
      levelColor = DownColour;
   }
      
      double fiboPrice1=ObjectGet(cat(ins, GetTimeFrameDisplay(TimeFrame)),OBJPROP_PRICE1);
      double fiboPrice2=ObjectGet(cat(ins, GetTimeFrameDisplay(TimeFrame)),OBJPROP_PRICE2);
      
      double fiboPriceDiff = fiboPrice2-fiboPrice1;
      string fiboValue0 = DoubleToStr(fiboPrice2-fiboPriceDiff*0.0,Digits);
      string fiboValue23 = DoubleToStr(fiboPrice2-fiboPriceDiff*0.236,Digits);
      string fiboValue38 = DoubleToStr(fiboPrice2-fiboPriceDiff*0.382,Digits);
      string fiboValue50 = DoubleToStr(fiboPrice2-fiboPriceDiff*0.50,Digits);
      string fiboValue61 = DoubleToStr(fiboPrice2-fiboPriceDiff*0.618,Digits);
      string fiboValue100 = DoubleToStr(fiboPrice2-fiboPriceDiff*1.0,Digits);
    
     ObjectSet(cat(ins, GetTimeFrameDisplay(TimeFrame)),OBJPROP_FIBOLEVELS,6);
     ObjectSet(cat(ins, GetTimeFrameDisplay(TimeFrame)),OBJPROP_FIRSTLEVEL+0,0.0);
     ObjectSet(cat(ins, GetTimeFrameDisplay(TimeFrame)),OBJPROP_FIRSTLEVEL+1,0.236);
     ObjectSet(cat(ins, GetTimeFrameDisplay(TimeFrame)),OBJPROP_FIRSTLEVEL+2,0.382);
     ObjectSet(cat(ins, GetTimeFrameDisplay(TimeFrame)),OBJPROP_FIRSTLEVEL+3,0.50);
     ObjectSet(cat(ins, GetTimeFrameDisplay(TimeFrame)),OBJPROP_FIRSTLEVEL+4,0.618);
     ObjectSet(cat(ins, GetTimeFrameDisplay(TimeFrame)),OBJPROP_FIRSTLEVEL+5,1.0);
     
     
     ObjectSet(cat(ins, GetTimeFrameDisplay(TimeFrame)),OBJPROP_LEVELCOLOR,levelColor);
     ObjectSet(cat(ins, GetTimeFrameDisplay(TimeFrame)),OBJPROP_LEVELWIDTH,1);
     ObjectSet(cat(ins, GetTimeFrameDisplay(TimeFrame)),OBJPROP_LEVELSTYLE,STYLE_DASHDOTDOT);
     ObjectSetFiboDescription( cat(ins, GetTimeFrameDisplay(TimeFrame)), 0,fiboValue0+" --> 0.0%"); 
     ObjectSetFiboDescription( cat(ins, GetTimeFrameDisplay(TimeFrame)), 1,fiboValue23+" --> 23.6%"); 
     ObjectSetFiboDescription( cat(ins, GetTimeFrameDisplay(TimeFrame)), 2,fiboValue38+" --> 38.2%"); 
     ObjectSetFiboDescription( cat(ins, GetTimeFrameDisplay(TimeFrame)), 3,fiboValue50+" --> 50.0%");
     ObjectSetFiboDescription( cat(ins, GetTimeFrameDisplay(TimeFrame)), 4,fiboValue61+" --> 61.8%");
     ObjectSetFiboDescription( cat(ins, GetTimeFrameDisplay(TimeFrame)), 5,fiboValue100+" --> 100.0%");
   
   

//----
   return(0);
}
//+------------------------------------------------------------------+

//======== Lazy Typists' String Concatenation Functions========
string cat(string part1, string part2)
{
   string line = StringConcatenate(part1 + part2);
   return(line);
}

string cat(string part1, string part2, string part3)
{
   string line = StringConcatenate(part1 + part2 + part3);
   return(line);
}

string cat(string part1, string part2, string part3, string part4)
{
   string line = StringConcatenate(part1 + part2 + part3 + part4);
   return(line);
}
//----------------------------------
