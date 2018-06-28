//+------------------------------------------------------------------+
//|                                                     ATR Pips.mq4 |
//|                                                                  |
//|                                                                  |
//+------------------------------------------------------------------+
#property copyright "Joshua Jones"
#property link      "http://www.forexfactory.com"

#property indicator_chart_window
#property indicator_buffers 1

//---- input parameters

extern int periods = 5;
extern double multiplier = 1.0;
extern int xDistance=5;
extern int yDistance=20;
extern int myFontSize  = 15 ;
extern color colorFont = DarkBlue ;
extern string myFont   = "Arial" ;// "BRADDON"
int pipMult = 10000;
double buffer[];

string prefix = "";

//+------------------------------------------------------------------+
//| Custom indicator initialization function                         |
//+------------------------------------------------------------------+
int init()
  {

   if (StringFind(Symbol(),"JPY",0) != -1)
   {
      pipMult = 100;
   }

   if (multiplier != 1.0)
   {
      int percentage = multiplier*100;
      prefix = percentage + "% of ";
   }

   
   SetIndexBuffer(0,buffer);
   SetIndexLabel(0,"ATR (" + periods + ")");
   SetIndexStyle(0,DRAW_NONE);
   IndicatorShortName(prefix + "ATR (" + periods + ")");
   
   if(ObjectFind("label_ATRinPips")==-1)
     ObjectCreate("label_ATRinPips", OBJ_LABEL, 0, 0, 0);

   ObjectSet("label_ATRinPips", OBJPROP_XDISTANCE, xDistance);
   ObjectSet("label_ATRinPips", OBJPROP_YDISTANCE, yDistance);

//----
   return(0);
  }
//+------------------------------------------------------------------+
//| Custor indicator deinitialization function                       |
//+------------------------------------------------------------------+
int deinit()
  {
   if(ObjectFind("label_ATRinPips")!=-1) ObjectDelete("label_ATRinPips");
   return(0);
  }
//+------------------------------------------------------------------+
//| Custom indicator iteration function                              |
//+------------------------------------------------------------------+

int start()
  {
   int limit;  
   int counted_bars=IndicatorCounted(); 
//---- check for possible errors
   if(counted_bars<0) return(-1);
//---- last counted bar will be recounted
   if(counted_bars>0) counted_bars--;
   
   limit=Bars-counted_bars;


      for (int i = 0; i < limit; i++){
         double stopLoss = MathCeil(pipMult * multiplier * (iATR(NULL,0,periods,i)));
         buffer[i] = stopLoss;
      }
      
      
      //Comment(prefix, "ATR (", periods, "): ", buffer[0], " pips");
      string text = prefix+ "ATR ("+ periods+ "): "+ DoubleToStr(buffer[0],0)+" pips";
      ObjectSetText("label_ATRinPips",text, myFontSize , myFont, colorFont);
      
      return(0);
  }
//+------------------------------------------------------------------+