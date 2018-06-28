//+------------------------------------------------------------------+
//|                                                       SIXTHS.mq4 |
//|                                                      Magnumfreak |
//|                                                                  |
//+------------------------------------------------------------------+
#property copyright "Magnumfreak"
#property link      ""

#property indicator_chart_window

extern int BarCount = 120; //4 weeks of H4 bars = 4*5*24/4 = 120 bars

double pip;// Points for 1 pip;
int pipMult;//pip-to-Points multiplier;
int pipMultTab[]={0,0,1,10,1,10,100}; // multiplier to convert pips to Points;

string prefix = "Indi-Sixth";

//+------------------------------------------------------------------+
//| Custom indicator initialization function                         |
//+------------------------------------------------------------------+
int init()
  {
  pipMult = pipMultTab[Digits];
  pip     = pipMult*Point;
//---- indicators
   int shift = MathMax(WindowFirstVisibleBar()-WindowBarsPerChart()*0.8,0);
   DrawSixthsLines(BarCount, shift);
//----
   return(0);
  }
//+------------------------------------------------------------------+
//| Custom indicator deinitialization function                       |
//+------------------------------------------------------------------+
int deinit()
  {
//----
   DeleteSixthsLines();
   Comment("");
//----
   return(0);
  }

//+------------------------------------------------------------------+
//| Custom indicator iteration function                              |
//+------------------------------------------------------------------+
int start()
  {
   int bars_count = WindowBarsPerChart();
   if (BarCount==0) BarCount = WindowBarsPerChart();

   int shift = MathMax(WindowFirstVisibleBar()-WindowBarsPerChart()*0.8,0);
   DrawSixthsLines(BarCount, shift);
   
   
   return(0);
  }


    //+------------------------------------------------------------------+
   
    //+------------------------------------------------------------------+
 void DrawSixthsLines(int BarCount, int shift)
    {
      double high = High[iHighest(NULL,0,MODE_HIGH,BarCount,shift)];
      double low  = Low[iLowest(NULL,0,MODE_LOW,BarCount,shift)];
   
      double value = high-low;      //value top of the chart - value buttom
      double sixth = value/6;
      double seventh = value/7;
      double valueS = value/pip;
      double sixthS = sixth/pip;
      double seventhS = seventh/pip;
   
      DeleteSixthsLines();
      color SixthsColor[] = {Blue,Gold,Green,White,Green,Gold,Blue};
      for (int i=0;i<=6;i++) {
        ObjectCreate(prefix+i,OBJ_TREND,0,Time[shift],low+i*sixth,Time[shift+BarCount],low+i*sixth);
        ObjectSet(prefix+i,OBJPROP_COLOR,SixthsColor[i]);
        ObjectSet(prefix+i,OBJPROP_STYLE,STYLE_SOLID);
        ObjectSet(prefix+i,OBJPROP_WIDTH,2);
        ObjectSet(prefix+i,OBJPROP_RAY,false);
      //draw dashed lines as "future continuation" of Sixth Lines
        ObjectCreate(prefix+"Future"+i,OBJ_TREND,0,Time[shift],low+i*sixth,Time[shift]+BarCount/4*Period()*60,low+i*sixth);
        ObjectSet(prefix+"Future"+i,OBJPROP_COLOR,SixthsColor[i]);
        ObjectSet(prefix+"Future"+i,OBJPROP_STYLE,STYLE_DASH);
        ObjectSet(prefix+"Future"+i,OBJPROP_RAY,false);
      }
      // draw a vertical line at the anchor point of the SixthLines
      ObjectCreate(prefix+"AnchorTime",OBJ_VLINE,0,Time[shift],0);
      ObjectSet(prefix+"AnchorTime",OBJPROP_COLOR,Gold);
      ObjectSet(prefix+"AnchorTime",OBJPROP_STYLE,STYLE_DOT);
      
       Comment("Top to bottom = ", (valueS), " pips", "\n" ,"Distance between lines = ", (sixthS), " pips" , 
           "\n" ,"TAKE PROFIT DISTANCE = ", (seventhS), " pips");

    }

    void DeleteSixthsLines()
    {
      for (int i=0;i<=6;i++) {
        ObjectDelete(prefix+i);
        ObjectDelete(prefix+"Future"+i);
      }
      ObjectDelete(prefix+"AnchorTime");
    }
    
/*
    //+------------------------------------------------------------------+
    void DrawSixthsFibs(int BarCount, int shift)
    //+------------------------------------------------------------------+
    {
      double high = High[iHighest(NULL,0,MODE_HIGH,BarCount,shift)];
      double low  = Low[iLowest(NULL,0,MODE_LOW,BarCount,shift)];
   
      double value = high-low;      //value top of the chart - value buttom
      double sixth = value/6;

      // draw "fib" lines for entry+stop+TP levels:
      ObjectDelete(prefix);
      ObjectCreate(prefix,OBJ_FIBO,0,Time[shift+BarCount],low+1*sixth,Time[shift],low+0*sixth);
      ObjectSet(prefix,OBJPROP_RAY,false);
      ObjectSet(prefix,OBJPROP_LEVELCOLOR,Gold); 
      ObjectSet(prefix,OBJPROP_FIBOLEVELS,7);
      ObjectSet(prefix,OBJPROP_LEVELSTYLE,STYLE_DASH);
      for (int i=0;i<=6;i++) {
        ObjectSet(prefix,OBJPROP_FIRSTLEVEL+i,i);
        ObjectSetFiboDescription(prefix,i,"%$");
      }
    }
*/
    
//+------------------------------------------------------------------+