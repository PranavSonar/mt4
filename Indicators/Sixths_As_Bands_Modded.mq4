//+------------------------------------------------------------------+
//|                                                                  |
//|                                                                  |
//|                                                                  |
//+------------------------------------------------------------------+


#property copyright "Copyright © 2016 Bruster400"
#property link      ""
#property strict
#property indicator_chart_window
#property indicator_buffers 8

#property  indicator_color3  Green       //MA
#property  indicator_color4  DeepSkyBlue // Lower band 
#property  indicator_color5  DeepSkyBlue // Upper band 

bool EnableSoundAlert = TRUE;
bool EnableMailAlert = FALSE;

double pip;// Points for 1 pip;
int pipMult;//pip-to-Points multiplier;
int pipMultTab[]={0,0,1,10,1,10,100}; // multiplier to convert pips to Points;

extern int BarCount = 1682; 
extern bool UseCloseForCalc=true;//Use Close price instead of High/Low for sixths calculation
extern int TradeLinePipDistance=5;
extern int TakeProfitPips=30;

double Line_1[];
double Line_2[];
double Line_3[];
double Line_4[];
double Line_5[];
double Line_6[];
double Line_7[];
double Line_8[];


double Signal_Buffer[];

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+

int init() {


pipMult = pipMultTab[Digits];
  pip     = pipMult*Point;
///// define arrow types


//////

  
   // Line 1
   SetIndexStyle(1,DRAW_LINE,STYLE_SOLID,1,clrYellow);
   SetIndexBuffer(1, Line_1);
   SetIndexDrawBegin(1, BarCount);
   SetIndexLabel(1, "Line_1");
   
   // Line 2
   SetIndexStyle(2,DRAW_LINE,STYLE_DOT,1,clrYellow);
   SetIndexBuffer(2, Line_2);
   SetIndexDrawBegin(2, BarCount);
   SetIndexLabel(2, "Line_2");
   
   // Line 3
   SetIndexStyle(3,DRAW_LINE,STYLE_DASH,1,clrNONE);
   SetIndexBuffer(3, Line_3);
   SetIndexDrawBegin(3, BarCount);
   SetIndexLabel(3, "Line_3");
   
   // Line 4
   SetIndexStyle(4,DRAW_LINE,STYLE_DASH,1,clrNONE);
   SetIndexBuffer(4, Line_4);
   SetIndexDrawBegin(4, BarCount);
   SetIndexLabel(4, "Line_4");
   
   // Line 5
   SetIndexStyle(5,DRAW_LINE,STYLE_DASH,1,clrNONE);
   SetIndexBuffer(5, Line_5);
   SetIndexDrawBegin(5, BarCount);
   SetIndexLabel(5, "Line_5");
   
   // Line 6
   SetIndexStyle(6,DRAW_LINE,STYLE_DASH,1,clrNONE);
   SetIndexBuffer(6, Line_6);
   SetIndexDrawBegin(6, BarCount);
   SetIndexLabel(6, "Line_6");
   
   // Line 7
   SetIndexStyle(7,DRAW_LINE,STYLE_DOT,1,clrYellow);
   SetIndexBuffer(7, Line_7);
   SetIndexDrawBegin(7, BarCount);
   SetIndexLabel(7, "Line_7");

   // Line 8
   SetIndexStyle(0,DRAW_LINE,STYLE_SOLID,1,clrYellow);
   SetIndexBuffer(0, Line_8);
   SetIndexDrawBegin(0, BarCount);
   SetIndexLabel(0, "Line_8");

   return (0);
}

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+

int start() {
double high;
double low;

// Main indicator For Loop:  
   if(Bars <= BarCount)
       return(0);
   int BarsCounted = IndicatorCounted();
   if (BarsCounted < 0) return (-1);
   if (BarsCounted > 0) BarsCounted--;
   int ChartBars = Bars - 1;
   if (BarsCounted >= 1) ChartBars = Bars - BarsCounted - 1;
   if (ChartBars < 0) ChartBars = 0;
   for (int i = ChartBars; i >= 0; i--) 
   
   { // start of for loop:
   
   // High Low of range calculations:
   if (UseCloseForCalc)   
   {
      high = Close[iHighest(NULL,0,MODE_CLOSE,BarCount,i)];
      low  = Close[iLowest(NULL,0,MODE_CLOSE,BarCount,i)];
   }
   else
   {
      high = High[iHighest(NULL,0,MODE_HIGH,BarCount,i)];
      low  = Low[iLowest(NULL,0,MODE_LOW,BarCount,i)];
   }
   // Sixth Calculations:  
   
      double value = high-low;      //value top of the chart - value buttom
      double sixth = value/6;
      double seventh = value/7;
      double valueS = value/pip;
      double sixthS = sixth/pip;
      double seventhS = seventh/pip;
      double tradedist = TradeLinePipDistance*pip;
      double tpdist = TakeProfitPips*pip;
      
   // Populate all the buffers
   
      Line_1[i] = low;
      Line_2[i] = low+(1*sixth);
      Line_3[i] = low+(1*sixth)+tradedist;
      Line_4[i] = low+(1*sixth)+tradedist+tpdist;
      Line_5[i] = low+(5*sixth)-tradedist-tpdist;
      Line_6[i] = low+(5*sixth)-tradedist;
      Line_7[i] = low+(5*sixth);
      Line_8[i] = low+(6*sixth);
        
 
      
   } //for (int i = ChartBars; i >= 0; i--)
     

     
   
   return (0);
} //int start()

