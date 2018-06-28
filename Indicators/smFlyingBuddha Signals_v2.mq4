//+------------------------------------------------------------------+
//|                                    smFlyingBuddha Signals_v2.mq4 |
//+------------------------------------------------------------------+
#property copyright "Copyright © 2010.08.20 SwingMan"
#property link      ""

/*--------------------------------------------------------------------
2010.08.20 - v1
           - v2 MA drawing fixed 
--------------------------------------------------------------------*/
#property indicator_chart_window

#property indicator_buffers 4
#property indicator_color1 Blue
#property indicator_color2 Red
#property indicator_color3 DodgerBlue
#property indicator_color4 DeepPink

#property indicator_width1 2
#property indicator_width2 2
#property indicator_width3 0
#property indicator_width4 0

string sIndicatorName = "SwingMan FlyingBuddha Signals";

//---- input parameters 
//+------------------------------------------------------------------+
extern bool Draw_SellSignals = true;
extern bool Draw_BuySignals = true;
extern bool Enable_Alerts = false;
extern bool Enable_EMails = false;
extern string ____MovingAverages="";
extern int Fast_Period  = 5;
extern int Fast_AvgMode = MODE_EMA;
extern int Fast_Price   = PRICE_CLOSE;
extern int Slow_Period  = 10;
extern int Slow_AvgMode = MODE_EMA;
extern int Slow_Price   = PRICE_CLOSE;
extern int MaxBars = 2000;
extern double factorWindow=0.03;
//+------------------------------------------------------------------+

//---- buffers 
double EMAfast[],EMAslow[];
double signalUP[],signalDN[];
//---- buffers temp
double tempSignals[];

//---- variables
datetime thisTime,oldTime;
bool newBar;
double windHeight,offset,oldOffset;

//+------------------------------------------------------------------+
//| Custom indicator initialization function                         |
//+------------------------------------------------------------------+
int init()
{
   IndicatorShortName(sIndicatorName);
   //Comment(sIndicatorName);
   
   IndicatorBuffers(5);
   //-- moving averages
   SetIndexBuffer(0, EMAfast); SetIndexStyle(0,DRAW_LINE);
   SetIndexBuffer(1, EMAslow); SetIndexStyle(1,DRAW_LINE);
   //-- signals
   int arrowUP=233;
   int arrowDN=234;
   SetIndexBuffer(2, signalUP); SetIndexStyle(2,DRAW_ARROW); SetIndexArrow(2,arrowUP);
   SetIndexBuffer(3, signalDN); SetIndexStyle(3,DRAW_ARROW); SetIndexArrow(3,arrowDN);
   
   SetIndexEmptyValue(2,EMPTY_VALUE);
   SetIndexEmptyValue(3,EMPTY_VALUE);
   //-- temp   
   SetIndexBuffer(4, tempSignals);
   
   //-- labels
   SetIndexLabel(0,"FB avg "+Fast_Period);     
   SetIndexLabel(1,"FB avg "+Slow_Period);   
   SetIndexLabel(2,"FB entry UP");     
   SetIndexLabel(3,"FB entry DOWN");   
   
   IndicatorDigits(Digits);
   
   return(0);
}

//+------------------------------------------------------------------+
//| Custom indicator deinitialization function                       |
//+------------------------------------------------------------------+
int deinit()
{
   Comment("");
   return(0);
}

//####################################################################
//+------------------------------------------------------------------+
//| Custom indicator iteration function                              |
//+------------------------------------------------------------------+
int start()
{   
   int i,limit;
   int counted_bars=IndicatorCounted();
   if(counted_bars<0) return(-1);
   if(counted_bars>0) counted_bars--;
   limit=Bars-counted_bars;  
   if (limit>MaxBars) limit=MaxBars;

   windHeight = WindowPriceMax() - WindowPriceMin();
   offset = windHeight*factorWindow;

   //-- adjust offsets  
   if (offset!=oldOffset)
   {
      oldOffset=offset;
      for (i=MaxBars; i>=0; i--)
      {
         if (signalDN[i]!=EMPTY_VALUE)
            signalDN[i]=High[i]+offset;
         if (signalUP[i]!=EMPTY_VALUE)
            signalUP[i]=Low[i]-offset;
      }
   }

   
               //*********************************      
               //    SIGNALS                     *
               //*********************************
   for(i=limit; i>=0; i--)
   {
      int i1=i+1; 
      EMAfast[i] =iMA(Symbol(),Period(),Fast_Period,0,Fast_AvgMode,Fast_Price,i);
      EMAslow[i] =iMA(Symbol(),Period(),Slow_Period,0,Slow_AvgMode,Slow_Price,i);
      double dHigh = iHigh(Symbol(),Period(),i1);
      double dLow  = iLow(Symbol(),Period(),i1);
      
      signalUP[i1] = EMPTY_VALUE;
      signalDN[i1] = EMPTY_VALUE;
      
      //-- short signal
      if (Draw_SellSignals && dLow>MathMax(EMAfast[i1],EMAslow[i1]))
         signalDN[i1]=High[i1]+offset;
         
      //-- long signal
      if (Draw_BuySignals && dHigh<MathMin(EMAfast[i1],EMAslow[i1]))
         signalUP[i1]=Low[i]-offset;
   }

               //*********************************      
               //    ALERTS                      *
               //*********************************   
   //-- check new bar --------------------------------------------
   thisTime=Time[0];
   if (thisTime!=oldTime)
   {
      oldTime=thisTime; 
      newBar=true;
   }
   else newBar=false;
   
   string sAlert, sMail, sCandleTime;
   string subject="Flying Buddha signal";
   if (newBar)
   {
      sCandleTime=" Candle="+TimeToStr(Time[1]);
      //-- short alert
      if (signalDN[1]!=EMPTY_VALUE)
      {
         sAlert=Symbol()+" ("+Get_sPeriod(Period())+") SELL signal  [Flying Buddha]"+sCandleTime;
         sMail =sAlert + "  Time: " + TimeToStr(TimeCurrent());
         if (Enable_Alerts) Alert(sAlert);
         if (Enable_EMails) SendMail(subject, sMail);
      }
      else 
      
      //-- long alert
      if (signalUP[1]!=EMPTY_VALUE)
      {
         sAlert=Symbol()+" ("+Get_sPeriod(Period())+") BUY signal  [Flying Buddha]"+sCandleTime;
         sMail =sAlert + "  Time: " + TimeToStr(TimeCurrent());
         if (Enable_Alerts) Alert(sAlert);
         if (Enable_EMails) SendMail(subject, sMail);
      }
   }
   return(0);
}//start
//+------------------------------------------------------------------+


//+------------------------------------------------------------------+
//    Get sPeriod
//+------------------------------------------------------------------+
string Get_sPeriod(int timeframe)
{
   if (timeframe == PERIOD_M1) return("M1");
   if (timeframe == PERIOD_M5) return("M5");
   if (timeframe == PERIOD_M15) return("M15");
   if (timeframe == PERIOD_M30) return("M30");
   if (timeframe == PERIOD_H1) return("H1");
   if (timeframe == PERIOD_H4) return("H4");
   if (timeframe == PERIOD_D1) return("D1");
   if (timeframe == PERIOD_W1) return("W1");
   if (timeframe == PERIOD_MN1) return("MN1");
}