//+------------------------------------------------------------------+
//|                                               ChandelierExit.mq4 |
//|                                                       MQLService |
//|                                           scripts@mqlservice.com |
//+------------------------------------------------------------------+
//mod2008fxtsd
#property copyright "MQLService"
#property link      "scripts@mqlservice.com"

#property indicator_chart_window
#property indicator_buffers 2
#property indicator_color1 Orange
#property indicator_color2 Magenta
//#property indicator_color3 Blue
//#property indicator_color4 Red


//---- input parameters
extern int       Range=22;
extern int       Shift=0;
extern int       ATRPeriod=9;
extern double    ATRMultipl=3;
//---- buffers
double ExtMapBuffer1[];
double ExtMapBuffer2[];
double ExtMapBuffer3[];
double ExtMapBuffer4[];
double direction[];
double ATRvalue;
//+------------------------------------------------------------------+
//| Custom indicator initialization function                         |
//+------------------------------------------------------------------+
int init()
  {
//---- indicators

   IndicatorBuffers(5);

   SetIndexStyle(0,DRAW_LINE);
   SetIndexBuffer(0,ExtMapBuffer3);
   SetIndexEmptyValue(2,0.0);
   
   SetIndexStyle(1,DRAW_LINE);
   SetIndexBuffer(1,ExtMapBuffer4);
   SetIndexEmptyValue(3,0.0);
   
   SetIndexBuffer(2,ExtMapBuffer1);
   SetIndexBuffer(3,ExtMapBuffer2);
   SetIndexBuffer(4,direction);


   //SetIndexStyle(2,DRAW_LINE);
   //SetIndexStyle(3,DRAW_LINE);
   //SetIndexEmptyValue(2,0.0);
   //SetIndexEmptyValue(3,0.0);

   string shortnme;
   shortnme = "("+Range+",ATR("+ATRPeriod+","+DoubleToStr(ATRMultipl,2)+") ";
   
   IndicatorShortName("Chandelier "+shortnme);  
   SetIndexLabel(0, "Chandlr "+shortnme);
   SetIndexLabel(1, "Chandlr "+shortnme);


//----
   return(0);
  }
//+------------------------------------------------------------------+
//| Custor indicator deinitialization function                       |
//+------------------------------------------------------------------+
int deinit()
  {
//---- 
   
   return(0);
  }

//+------------------------------------------------------------------+
//| Custom indicator iteration function                              |
//+------------------------------------------------------------------+

int start()
{
   int limit, counted_bars=IndicatorCounted();
   if(counted_bars<0) return(-1);
   if(counted_bars>0) counted_bars--;

   limit=Bars-counted_bars;

   for(int i=limit; i>=0; i--)
   {
         ExtMapBuffer1[i]= EMPTY_VALUE;   ExtMapBuffer2[i]= EMPTY_VALUE;

         ATRvalue=iATR(NULL,0,ATRPeriod,i+Shift)*ATRMultipl;
         ExtMapBuffer1[i]=High[Highest(NULL,0,MODE_HIGH,Range,i+Shift)] -ATRvalue;
         ExtMapBuffer2[i]=Low[Lowest(NULL,0,MODE_LOW,Range,i+Shift)]    +ATRvalue;
         
         ExtMapBuffer3[i]= EMPTY_VALUE;   ExtMapBuffer4[i]= EMPTY_VALUE;


   direction[i] =direction[i+1];
            
         
             if(Close[i]>ExtMapBuffer2[i+1])direction[i]=  1;
             if(Close[i]<ExtMapBuffer1[i+1])direction[i]= -1;

   if (direction[i]>0)
            {
             if      (  ExtMapBuffer1[i]< ExtMapBuffer1[i+1])
             
                                          ExtMapBuffer1[i]=ExtMapBuffer1[i+1];
                                          ExtMapBuffer3[i]=ExtMapBuffer1[i];
                                          ExtMapBuffer4[i]=EMPTY_VALUE;   
             }                 

   if (direction[i]<0)
            {                    
             if      (  ExtMapBuffer2[i]>ExtMapBuffer2[i+1])
             
                                          ExtMapBuffer2[i]=ExtMapBuffer2[i+1];
                                          ExtMapBuffer4[i]=ExtMapBuffer2[i];  
                                          ExtMapBuffer3[i]=EMPTY_VALUE; 
                                 
            }  

   }
   return(0);
}
//+------------------------------------------------------------------+