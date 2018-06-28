//+------------------------------------------------------------------+
//|                                                  FractalsMod.mq4 |
//|                                                    Manel Sanchon |
//+------------------------------------------------------------------+
#property copyright "Manel Sanchon"
#property link      ""

#property indicator_chart_window
#property indicator_buffers 2
#property indicator_color1 ForestGreen
#property indicator_width1 1
#property indicator_color2 FireBrick
#property indicator_width2 1
//---- input parameters
extern int leftbars      = 2;
extern int rightbars     = 2;
extern int shift         = 0;

//---- buffers
double ExtUpperBuffer[];
double ExtLowerBuffer[];
//+------------------------------------------------------------------+
//| Custom indicator initialization function                         |
//+------------------------------------------------------------------+
int init()
  {
//---- indicator buffers mapping  
   SetIndexBuffer(0,ExtUpperBuffer);
   SetIndexBuffer(1,ExtLowerBuffer);
//---- drawing settings
   SetIndexStyle(0,DRAW_ARROW);
   SetIndexArrow(0,167);
   SetIndexStyle(1,DRAW_ARROW);
   SetIndexArrow(1,167);
//----
   SetIndexEmptyValue(0,0.0);
   SetIndexEmptyValue(1,0.0);
//---- name for DataWindow
   SetIndexLabel(0,"Fractal Up");
   SetIndexLabel(1,"Fractal Down");
//---- initialization done   
   return(0);
  }
//+------------------------------------------------------------------+
//| Custor indicator deinitialization function                       |
//+------------------------------------------------------------------+
int deinit()
  {
   ObjectDelete(0,"Fractal Up");
   ObjectDelete(1,"Fractal Down");
   return(0);
  }
//+------------------------------------------------------------------+
//| Custom indicator iteration function                              |
//+------------------------------------------------------------------+
int start()
  {
   double Higher,Lower;
   int   countup=0;
   int   countdown=0;

   int counted_bars=IndicatorCounted();
   if(counted_bars < 0)  return(-1);
   if(counted_bars>0) counted_bars--;
   int CalculateBars=Bars-counted_bars;
   if(counted_bars==0) CalculateBars-=1+leftbars;

   for(int Count=CalculateBars; Count>=0; Count--)
     {
      for(int j=1;j<=leftbars;j++)
        {
         if(Count+j<CalculateBars)
           {
            if(High[Count]>High[Count+j]) countup=countup+1;
            if(Low[Count]<Low[Count+j]) countdown=countdown+1;
           }
        }
      for(j=1;j<=rightbars;j++)
        {
         if(Count-j>=0)
           {
            if(High[Count]>High[Count-j]) countup=countup+1;
            if(Low[Count]<Low[Count-j]) countdown=countdown+1;
           }
        }
      if(countup==leftbars+rightbars) Higher=High[Count];
      else Higher = ExtUpperBuffer[Count-shift+1];
      if(countdown==leftbars+rightbars) Lower = Low[Count];
      else Lower=ExtLowerBuffer[Count-shift+1];
      ExtUpperBuffer[Count-shift] = Higher;
      ExtLowerBuffer[Count-shift] = Lower;
      countup=0;
      countdown=0;
      //if(shift==0)
      //  {
      //   Comment("FractalMod("+leftbars+","+rightbars+";"+shift+")","\n Up="+Higher+";Down="+Lower);
      //  }
     }
//----
   return(0);
  }
//+------------------------------------------------------------------+