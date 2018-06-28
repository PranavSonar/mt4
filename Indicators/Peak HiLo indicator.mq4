//+------------------------------------------------------------------+
//|                                                    Peak HiLo.mq4 |
//|                                    Copyright 2016, Steve Hopwood |
//|                                https://www.SteveHopwoodForex.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2016, Steve Hopwood"
#property link      "https://www.SteveHopwoodForex.com"
#property version   "1.00"
#property strict
#property indicator_chart_window

#define        millions 10000000

//Trading direction
#define        longdirection "Long"
#define        shortdirection "Short"

//Allow the user to specify the number of bars on the chart
extern int     NoOfBarsOnChart=1682;
//Thans to Radar for this
extern string  ztxt1             =  "Set Zoom Level...";
extern string  ztxt2             =  "0 = Sky-High...";
extern string  ztxt3             =  "5 = Ground-Level";
extern int     Zoom_Level        =  0;


extern string  hitf="---- Highest time frame ----";
extern bool    UseHighestTimeFrame=true;
extern ENUM_TIMEFRAMES HighestTimeFrame=PERIOD_W1;
extern color   HighestTimeFrameLineColour=Magenta;
extern int     HighestTimeFrameLineSize=3;
//////////////////////////////////////////////////////////
double         highestPeakHigh=0, highestPeakLow=0;//PH and PL
int            highestPeakHighBar=0, highestPeakLowBar=0;//How far back the hilo were found
string         highestPeakHighLineName="phl_Highest time frame peak high";//Name for the line
string         highestPeakLowLineName="phl_Highest time frame peak low";//Name for the line
//////////////////////////////////////////////////////////

extern string  htf="---- High time frame ----";
extern bool    UseHighTimeFrame=true;
extern ENUM_TIMEFRAMES HighTimeFrame=PERIOD_D1;
extern color   HighTimeFrameLineColour=Blue;
extern int     HighTimeFrameLineSize=2;
//////////////////////////////////////////////////////////
double         highPeakHigh=0, highPeakLow=0;//PH and PL
int            highPeakHighBar=0, highPeakLowBar=0;//How far back the hilo were found
string         highPeakHighLineName="phl_High time frame peak high";//Name for the line
string         highPeakLowLineName="phl_High time frame peak low";//Name for the line
//////////////////////////////////////////////////////////

extern string  mtf="---- Medium time frame ----";
extern bool    UseMediumTimeFrame=true;
extern ENUM_TIMEFRAMES MediumTimeFrame=PERIOD_H4;
extern color   MediumTimeFrameLineColour=Turquoise;
extern int     MediumTimeFrameLineSize=1;
//////////////////////////////////////////////////////////
double         mediumPeakHigh=0, mediumPeakLow=0;//PH and PL
int            mediumPeakHighBar=0, mediumPeakLowBar=0;//How far back the hilo were found
string         mediumPeakHighLineName="phl_Medium time frame peak high";//Name for the line
string         mediumPeakLowLineName="phl_Medium time frame peak low";//Name for the line
//////////////////////////////////////////////////////////

extern string  ttf="---- Trading time frame ----";
extern ENUM_TIMEFRAMES TradingTimeFrame=PERIOD_H1;
extern color   TradingTimeFrameLineColour=Yellow;
extern int     TradingTimeFrameLineSize=0;
extern bool    ShowTradingArea=true;
extern bool    ShowCloseProximityArea=true;
//The size of the close proximity area as a percentage of the trading area
extern double  PercentOfTradingAreaForProximity=50;
//////////////////////////////////////////////////////////
double         tradingPeakHigh=0, tradingPeakLow=0;//PH and PL
int            tradingPeakHighBar=0, tradingPeakLowBar=0;//How far back the hilo were found
string         tradingPeakHighLineName="phl_Trading time frame peak high";//Name for the line
string         tradingPeakLowLineName="phl_Trading time frame peak low";//Name for the line
//These inputs are for displaying the top trading area
double         phTradeLine=0, plTradeLine=0;
string         phTradeLineName="phl_Peak high trading line", plTradeLineName="phl_Peak Low Trading LIne";
string         phProximityTradeLineName="phl_Peak high close proximity line", plProximityTradeLineName="phl_Peak Low close proximity LIne";
double         TradingZoneProximity=0;
//////////////////////////////////////////////////////////

extern string  sep1="================================================================";
extern string  six="---- Sixths ----";
extern int     ChartDivisor=6;

extern string  sep2="================================================================";
//Code provided by lifesys. Thanks again Paul.
extern string  lab="---- Labels ----";
extern int     DisplayX          = 1600;
extern int     DisplayY          = 100;
extern int     fontSise          = 14;
extern string  fontName          = "Arial";
extern color   BuyColour=Green;
extern color   SellColour=Red; 
// adjustment to reform lines for different font size
extern double  spacingtweek      = 0.6; 
//////////////////////////////////////////////////////////
string         highestTimeFrameLabelName="phl_Highest time frame label", highTimeFrameLabelName="phl_High time frame label";
string         mediumTimeFrameLabelName="phl_Medium time frame label", tradingTimeFrameLabelName="phl_Trading time frame label";
string         highestTimeFrameLabelDirection="phl_Highest time frame label direction", highTimeFrameLabelDirection="phl_High time frame label direction";
string         mediumTimeFrameLabelDirection="phl_Medium time frame label direction", tradingTimeFrameLabelDirection="phl_Trading time frame label direction";
int            DisplayCount=1;
//////////////////////////////////////////////////////////

//Calculating the factor needed to turn pip values into their correct points value to accommodate different Digit size.
//Thanks to Tommaso for coding the function.
double         factor;//For pips/points stuff.

//////////////////////////////////////////////////////////
//The maximum number of bars that can be displayed on the widest possible chart
int            per=0;
   //////////////////////////////////////////////////////////


//+------------------------------------------------------------------+
//| Custom indicator initialization function                         |
//+------------------------------------------------------------------+
int OnInit()
{

   int ofset = 0;
   string tfDisplay = "";
   string text = longdirection;
   factor = GetPipFactor(Symbol());
   
   
   
   //Zoom the chart out as soon as possible
   //Idiot check. Guess how I know it is necessary?
   if (NoOfBarsOnChart == 0)
      NoOfBarsOnChart = 1680;
   int scale = ChartScaleGet();
   if (scale != Zoom_Level)
   {
      ChartScaleSet(Zoom_Level);
      //A quick time frame change to force accurate display
      per = ChartPeriod(0);
      int nextPer = GetNextPeriod(per);
      ChartSetSymbolPeriod(0, Symbol(), nextPer);//Change time frame
      ChartSetSymbolPeriod(0, Symbol(), per);//reset time frame      
   }//if (scale != Zoom_Level)
      
   //Adjust the right side margin
   double mar = ChartShiftSizeGet(0);
   if (!CloseEnough(mar, 10))
      ChartShiftSizeSet(10, 0);
     
   
   
   //Create the labels
   if (UseHighestTimeFrame)
   {
      if (ObjectFind(highestTimeFrameLabelName) < 0)
      {
         ObjectCreate(highestTimeFrameLabelName, OBJ_LABEL, 0, 0, 0); 
         ObjectSet(highestTimeFrameLabelName, OBJPROP_CORNER, 0);
         //ObjectSet(highestTimeFrameLabelName, OBJPROP_XDISTANCE, DisplayX + ofset); 
         ObjectSet(highestTimeFrameLabelName, OBJPROP_XDISTANCE, DisplayX); 
         ObjectSet(highestTimeFrameLabelName, OBJPROP_YDISTANCE, DisplayY+DisplayCount*(fontSise+4)); 
         ObjectSet(highestTimeFrameLabelName, OBJPROP_BACK, false);
         tfDisplay = GetTimeFrameDisplay(HighestTimeFrame);
         ObjectSetText(highestTimeFrameLabelName, tfDisplay, fontSise, fontName, HighestTimeFrameLineColour);
      }//if (ObjectFind(highestTimeFrameLabelName) < 0)
      
      
      if (ObjectFind(highestTimeFrameLabelDirection) < 0)
      {
         ObjectCreate(highestTimeFrameLabelDirection, OBJ_LABEL, 0, 0, 0); 
         ObjectSet(highestTimeFrameLabelDirection, OBJPROP_CORNER, 0);
         //ObjectSet(highestTimeFrameLabelDirection, OBJPROP_XDISTANCE, DisplayX + ofset); 
         ObjectSet(highestTimeFrameLabelDirection, OBJPROP_XDISTANCE, DisplayX + 50); 
         ObjectSet(highestTimeFrameLabelDirection, OBJPROP_YDISTANCE, DisplayY+DisplayCount*(fontSise+4)); 
         ObjectSet(highestTimeFrameLabelDirection, OBJPROP_BACK, false);
         ObjectSetText(highestTimeFrameLabelDirection, text, fontSise, fontName, BuyColour);
      }//if (ObjectFind(highestTimeFrameLabelDirection) < 0)
      
      DisplayCount++;     
      
   }//if (UseHighestTimeFrame)
   
   if (UseHighTimeFrame)
   {
      if (ObjectFind(highTimeFrameLabelName) < 0)
      {
         ObjectCreate(highTimeFrameLabelName, OBJ_LABEL, 0, 0, 0); 
         ObjectSet(highTimeFrameLabelName, OBJPROP_CORNER, 0);
         //ObjectSet(highTimeFrameLabelName, OBJPROP_XDISTANCE, DisplayX + ofset); 
         ObjectSet(highTimeFrameLabelName, OBJPROP_XDISTANCE, DisplayX); 
         ObjectSet(highTimeFrameLabelName, OBJPROP_YDISTANCE, DisplayY+DisplayCount*(fontSise+10)); 
         ObjectSet(highTimeFrameLabelName, OBJPROP_BACK, false);
         tfDisplay = GetTimeFrameDisplay(HighTimeFrame);
         ObjectSetText(highTimeFrameLabelName, tfDisplay, fontSise, fontName, HighTimeFrameLineColour);
      }//if (ObjectFind(highTimeFrameLabelName) < 0)
      
      
      if (ObjectFind(highTimeFrameLabelDirection) < 0)
      {
         ObjectCreate(highTimeFrameLabelDirection, OBJ_LABEL, 0, 0, 0); 
         ObjectSet(highTimeFrameLabelDirection, OBJPROP_CORNER, 0);
         //ObjectSet(highTimeFrameLabelDirection, OBJPROP_XDISTANCE, DisplayX + ofset); 
         ObjectSet(highTimeFrameLabelDirection, OBJPROP_XDISTANCE, DisplayX + 50); 
         ObjectSet(highTimeFrameLabelDirection, OBJPROP_YDISTANCE, DisplayY+DisplayCount*(fontSise+10)); 
         ObjectSet(highTimeFrameLabelDirection, OBJPROP_BACK, false);
         ObjectSetText(highTimeFrameLabelDirection, text, fontSise, fontName, BuyColour);
      }//if (ObjectFind(highestTimeFrameLabelDirection) < 0)
      
      DisplayCount++;     
      
   }//if (UseHighTimeFrame)
   
   if (UseMediumTimeFrame)
   {
      if (ObjectFind(mediumTimeFrameLabelName) < 0)
      {
         ObjectCreate(mediumTimeFrameLabelName, OBJ_LABEL, 0, 0, 0); 
         ObjectSet(mediumTimeFrameLabelName, OBJPROP_CORNER, 0);
         //ObjectSet(mediumTimeFrameLabelName, OBJPROP_XDISTANCE, DisplayX + ofset); 
         ObjectSet(mediumTimeFrameLabelName, OBJPROP_XDISTANCE, DisplayX); 
         ObjectSet(mediumTimeFrameLabelName, OBJPROP_YDISTANCE, DisplayY+DisplayCount*(fontSise+10)); 
         ObjectSet(mediumTimeFrameLabelName, OBJPROP_BACK, false);
         tfDisplay = GetTimeFrameDisplay(MediumTimeFrame);
         ObjectSetText(mediumTimeFrameLabelName, tfDisplay, fontSise, fontName, MediumTimeFrameLineColour);
      }//if (ObjectFind(mediumTimeFrameLabelName) < 0)
      
      
      if (ObjectFind(mediumTimeFrameLabelDirection) < 0)
      {
         ObjectCreate(mediumTimeFrameLabelDirection, OBJ_LABEL, 0, 0, 0); 
         ObjectSet(mediumTimeFrameLabelDirection, OBJPROP_CORNER, 0);
         //ObjectSet(mediumTimeFrameLabelDirection, OBJPROP_XDISTANCE, DisplayX + ofset); 
         ObjectSet(mediumTimeFrameLabelDirection, OBJPROP_XDISTANCE, DisplayX + 50); 
         ObjectSet(mediumTimeFrameLabelDirection, OBJPROP_YDISTANCE, DisplayY+DisplayCount*(fontSise+10)); 
         ObjectSet(mediumTimeFrameLabelDirection, OBJPROP_BACK, false);
         ObjectSetText(mediumTimeFrameLabelDirection, text, fontSise, fontName, BuyColour);
      }//if (ObjectFind(mediumestTimeFrameLabelDirection) < 0)
      
      DisplayCount++;     
      
   }//if (UseHighTimeFrame)
   
   if (ObjectFind(tradingTimeFrameLabelName) < 0)
   {
      ObjectCreate(tradingTimeFrameLabelName, OBJ_LABEL, 0, 0, 0); 
      ObjectSet(tradingTimeFrameLabelName, OBJPROP_CORNER, 0);
      //ObjectSet(tradingTimeFrameLabelName, OBJPROP_XDISTANCE, DisplayX + ofset); 
      ObjectSet(tradingTimeFrameLabelName, OBJPROP_XDISTANCE, DisplayX); 
      ObjectSet(tradingTimeFrameLabelName, OBJPROP_YDISTANCE, DisplayY+DisplayCount*(fontSise+10)); 
      ObjectSet(tradingTimeFrameLabelName, OBJPROP_BACK, false);
      tfDisplay = GetTimeFrameDisplay(TradingTimeFrame);
      ObjectSetText(tradingTimeFrameLabelName, tfDisplay, fontSise, fontName, TradingTimeFrameLineColour);
   }//if (ObjectFind(tradingTimeFrameLabelName) < 0)
   
   
   if (ObjectFind(tradingTimeFrameLabelDirection) < 0)
   {
      ObjectCreate(tradingTimeFrameLabelDirection, OBJ_LABEL, 0, 0, 0); 
      ObjectSet(tradingTimeFrameLabelDirection, OBJPROP_CORNER, 0);
      //ObjectSet(tradingTimeFrameLabelDirection, OBJPROP_XDISTANCE, DisplayX + ofset); 
      ObjectSet(tradingTimeFrameLabelDirection, OBJPROP_XDISTANCE, DisplayX + 50); 
      ObjectSet(tradingTimeFrameLabelDirection, OBJPROP_YDISTANCE, DisplayY+DisplayCount*(fontSise+10)); 
      ObjectSet(tradingTimeFrameLabelDirection, OBJPROP_BACK, false);
      ObjectSetText(tradingTimeFrameLabelDirection, text, fontSise, fontName, BuyColour);
   }//if (ObjectFind(tradingestTimeFrameLabelDirection) < 0)
   
   
   
   return(INIT_SUCCEEDED);
}//int OnInit()


void OnDeinit(const int reason)
{

   removeAllObjects();

}//void OnDeinit(const int reason)

void removeAllObjects()
{
   for(int i = ObjectsTotal() - 1; i >= 0; i--)
   if (StringFind(ObjectName(i),"phl_",0) > -1) 
      ObjectDelete(ObjectName(i));
      
      
}//End void removeAllObjects()
//   ************************* added for OBJ_LABEL

int GetPipFactor(string Xsymbol)
{
   //Code from Tommaso's APTM
   
   static const string factor1000[]={"SEK","TRY","ZAR","MXN"};
   static const string factor100[]         = {"JPY","XAG","SILVER","BRENT","WTI"};
   static const string factor10[]          = {"XAU","GOLD","SP500","US500Cash","US500","Bund"};
   static const string factor1[]           = {"UK100","WS30","DAX30","NAS100","CAC40","FRA40","GER30","ITA40","EUSTX50","JPN225","US30Cash","US30"};
   int j = 0;
   
   int xFactor=10000;       // correct xFactor for most pairs
   if(MarketInfo(Xsymbol,MODE_DIGITS)<=1) xFactor=1;
   else if(MarketInfo(Xsymbol,MODE_DIGITS)==2) xFactor=10;
   else if(MarketInfo(Xsymbol,MODE_DIGITS)==3) xFactor=100;
   else if(MarketInfo(Xsymbol,MODE_DIGITS)==4) xFactor=1000;
   else if(MarketInfo(Xsymbol,MODE_DIGITS)==5) xFactor=10000;
   else if(MarketInfo(Xsymbol,MODE_DIGITS)==6) xFactor=100000;
   else if(MarketInfo(Xsymbol,MODE_DIGITS)==7) xFactor=1000000;
   for(j=0; j<ArraySize(factor1000); j++)
   {
      if(StringFind(Xsymbol,factor1000[j])!=-1) xFactor=1000;
   }
   for(j=0; j<ArraySize(factor100); j++)
   {
      if(StringFind(Xsymbol,factor100[j])!=-1) xFactor=100;
   }
   for(j=0; j<ArraySize(factor10); j++)
   {
      if(StringFind(Xsymbol,factor10[j])!=-1) xFactor=10;
   }
   for(j=0; j<ArraySize(factor1); j++)
   {
      if(StringFind(Xsymbol,factor1[j])!=-1) xFactor=1;
   }

   return (xFactor);
}//End int GetPipFactor(string Xsymbol)


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

bool CloseEnough(double num1, double num2)
{
   /*
   This function addresses the problem of the way in which mql4 compares doubles. It often messes up the 8th
   decimal point.
   For example, if A = 1.5 and B = 1.5, then these numbers are clearly equal. Unseen by the coder, mql4 may
   actually be giving B the value of 1.50000001, and so the variable are not equal, even though they are.
   This nice little quirk explains some of the problems I have endured in the past when comparing doubles. This
   is common to a lot of program languages, so watch out for it if you program elsewhere.
   Gary (garyfritz) offered this solution, so our thanks to him.
   */
   
   if (num1 == 0 && num2 == 0) return(true); //0==0
   if (MathAbs(num1 - num2) / (MathAbs(num1) + MathAbs(num2)) < 0.00000001) return(true);
   
   //Doubles are unequal
   return(false);

}//End bool CloseEnough(double num1, double num2)

void DrawTrendLine(string name,datetime time1,double val1,datetime time2,double val2,color col,int width,int style,bool ray)
{
   //Plots a trendline with the given parameters

   ObjectDelete(name);

   ObjectCreate(name,OBJ_TREND,0,time1,val1,time2,val2);
   ObjectSet(name,OBJPROP_COLOR,col);
   ObjectSet(name,OBJPROP_WIDTH,width);
   ObjectSet(name,OBJPROP_STYLE,style);
   ObjectSet(name,OBJPROP_RAY,ray);

}//End void DrawLine()


int ChartVisibleBars(const long chart_ID=0) 
{ 
//--- prepare the variable to get the property value 
   long result=-1; 
//--- reset the error value 
   ResetLastError(); 
//--- receive the property value 
   if(!ChartGetInteger(chart_ID,CHART_VISIBLE_BARS,0,result)) 
   { 
      //--- display the error message in Experts journal 
      Print(__FUNCTION__+", Error Code = ",GetLastError()); 
   } 
//--- return the value of the chart property 
   return((int)result); 
}//int ChartVisibleBars(const long chart_ID=0) 

//+------------------------------------------------------------------+ 
//| Get chart scale (from 0 to 5).                                   | 
//+------------------------------------------------------------------+ 
int ChartScaleGet(const long chart_ID=0) 
{ 
//--- prepare the variable to get the property value 
   long result=-1; 
//--- reset the error value 
   ResetLastError(); 
//--- receive the property value 
   if(!ChartGetInteger(chart_ID,CHART_SCALE,0,result)) 
   { 
      //--- display the error message in Experts journal 
      Print(__FUNCTION__+", Error Code = ",GetLastError()); 
   } 
//--- return the value of the chart property 
   return((int)result); 
}//int ChartScaleGet(const long chart_ID=0) 
 

//+------------------------------------------------------------------+ 
//| Set chart scale (from 0 to 5).                                   | 
//+------------------------------------------------------------------+ 
bool ChartScaleSet(const long value,const long chart_ID=0) 
{ 
//--- reset the error value 
   ResetLastError(); 
//--- set property value 
   if(!ChartSetInteger(chart_ID,CHART_SCALE,0,value)) 
   { 
      //--- display the error message in Experts journal 
      Print(__FUNCTION__+", Error Code = ",GetLastError()); 
      return(false); 
   } 
//--- successful execution 
   return(true); 
}//bool ChartScaleSet(const long value,const long chart_ID=0) 


int GetNextPeriod(int currentPeriod)
{
   
   if (currentPeriod == PERIOD_M1)
   {
      return(PERIOD_M5);
   }//if (currentPeriod == PERIOD_M1)
   
   if (currentPeriod == PERIOD_M5)
   {
      return(PERIOD_M15);
   }//if (currentPeriod == PERIOD_M5)
   
   if (currentPeriod == PERIOD_M15)
   {
      return(PERIOD_M30);
   }//if (currentPeriod == PERIOD_M15)
   
   if (currentPeriod == PERIOD_M30)
   {
      return(PERIOD_H1);
   }//if (currentPeriod == PERIOD_M30)
   
   if (currentPeriod == PERIOD_H1)
   {
      return(PERIOD_H4);
   }//if (currentPeriod == PERIOD_H1)
   
   if (currentPeriod == PERIOD_H4)
   {
      return(PERIOD_D1);
   }//if (currentPeriod == PERIOD_H1)
   
   if (currentPeriod == PERIOD_D1)
   {
      return(PERIOD_W1);
   }//if (currentPeriod == PERIOD_D1)
   
   if (currentPeriod == PERIOD_W1)
   {
      return(PERIOD_MN1);
   }//if (currentPeriod == PERIOD_W1)
   
   if (currentPeriod == PERIOD_MN1)
   {
      return(PERIOD_H4);
   }//if (currentPeriod == PERIOD_MN1)
   
   
   
   return(Period());

}//End int GetNextPeriod(int currentPeriod)

//+---------------------------------------------------------------------------+ 
//| The function receives shift size of the zero bar from the right border    | 
//| of the chart in percentage values (from 10% up to 50%).                   | 
//+---------------------------------------------------------------------------+ 
double ChartShiftSizeGet(const long chart_ID=0) 
{ 
//--- prepare the variable to get the result 
   double result=EMPTY_VALUE; 
//--- reset the error value 
   ResetLastError(); 
//--- receive the property value 
   if(!ChartGetDouble(chart_ID,CHART_SHIFT_SIZE,0,result)) 
   { 
      //--- display the error message in Experts journal 
      Print(__FUNCTION__+", Error Code = ",GetLastError()); 
   } 
//--- return the value of the chart property 
   return(result); 
}//End double ChartShiftSizeGet(const long chart_ID=0) 

//+--------------------------------------------------------------------------------------+ 
//| The function sets the shift size of the zero bar from the right                      | 
//| border of the chart in percentage values (from 10% up to 50%). To enable the shift   | 
//| mode, CHART_SHIFT property value should be set to                                    | 
//| true.                                                                                | 
//+--------------------------------------------------------------------------------------+ 
bool ChartShiftSizeSet(const double value,const long chart_ID=0) 
{ 
//--- reset the error value 
   ResetLastError(); 
//--- set property value 
   if(!ChartSetDouble(chart_ID,CHART_SHIFT_SIZE,value)) 
   { 
      //--- display the error message in Experts journal 
      Print(__FUNCTION__+", Error Code = ",GetLastError()); 
      return(false); 
   } 
//--- successful execution 
   return(true); 
}//End bool ChartShiftSizeSet(const double value,const long chart_ID=0) 


void DrawPeaks(int tf, string hiname, string loname, color col, int size, string labelName)
{

   double currentPeakHigh=0, currentPeakLow=0;//PH and PL
   int    currentPeakHighBar=0, currentPeakLowBar=0;//How far back the hilo were found
   string text = "";
   color colour = BuyColour;

   //Iterate back through the bars to get the chart hilo
   currentPeakHigh = 0;
   currentPeakLow = 1000000;
   currentPeakHighBar = 0;
   currentPeakLowBar = 0;
   
   
   currentPeakHighBar = iHighest(Symbol(), tf, MODE_CLOSE, NoOfBarsOnChart, 1);
   currentPeakLowBar = iLowest(Symbol(), tf, MODE_CLOSE, NoOfBarsOnChart, 1);
   currentPeakHigh = iClose(Symbol(), tf, currentPeakHighBar);
   currentPeakLow = iClose(Symbol(), tf, currentPeakLowBar);
   
   //Calculate the distance between ph and pl and divide that by the divisor
   double tradingLineDistance = (currentPeakHigh - currentPeakLow) / ChartDivisor;
   //Now the close proximity line
   double proximityLineDistance = tradingLineDistance * (PercentOfTradingAreaForProximity / 100);
   
   //Draw the lines
   DrawTrendLine(hiname, iTime(Symbol(), tf, currentPeakHighBar), currentPeakHigh, iTime(Symbol(), tf, 0), currentPeakHigh, col, size, STYLE_SOLID, false);
   //Adapt the labels
   text = longdirection;
   colour = BuyColour;
   if (currentPeakHighBar < currentPeakLowBar)
   {
      text = shortdirection;
      colour = SellColour;
   }//if (currentPeakHighBar < currentPeakLowBar)
   ObjectSetText(labelName, text, fontSise, fontName, colour);
   
   double price = 0;
   
   if (hiname == tradingPeakHighLineName)
   {
      price = currentPeakHigh - tradingLineDistance;
      if (ShowTradingArea)    
         DrawTrendLine(phTradeLineName, iTime(Symbol(), tf, currentPeakHighBar), price, Time[0], price, col, size, STYLE_DASH, false);
         
      price-= proximityLineDistance;
      if (ShowCloseProximityArea)
         DrawTrendLine(phProximityTradeLineName, iTime(Symbol(), tf, currentPeakHighBar), price, Time[0], price, col, size, STYLE_DOT, false);
         
   }//if (hiname == tradingPeakHighLineName)
   
   DrawTrendLine(loname, iTime(Symbol(), tf, currentPeakLowBar), currentPeakLow, Time[0], currentPeakLow, col, size, STYLE_SOLID, false);
   if (loname == tradingPeakLowLineName)
   {
      price = currentPeakLow + tradingLineDistance;
      if (ShowTradingArea)    
         DrawTrendLine(plTradeLineName,iTime(Symbol(), tf, currentPeakLowBar), price, iTime(Symbol(), tf, 0), price, col, size, STYLE_DASH, false);

      price+= proximityLineDistance;
      if (ShowCloseProximityArea)
         DrawTrendLine(plProximityTradeLineName,iTime(Symbol(), tf, currentPeakLowBar), price, iTime(Symbol(), tf, 0), price, col, size, STYLE_DOT, false);
     
   }//if (loname == tradingPeakLowLineName)
   

}//void DrawPeaks(int tf)



//+------------------------------------------------------------------+
//| Custom indicator iteration function                              |
//+------------------------------------------------------------------+
int OnCalculate(const int rates_total,
                const int prev_calculated,
                const datetime &time[],
                const double &open[],
                const double &high[],
                const double &low[],
                const double &close[],
                const long &tick_volume[],
                const long &volume[],
                const int &spread[])
{
//---

   
   
   //Draw the trading time frame
   static datetime oldTradingTimeFrameBarTime = 0;
   if (oldTradingTimeFrameBarTime != iTime(Symbol(), TradingTimeFrame, 0))
   {
      oldTradingTimeFrameBarTime = iTime(Symbol(), TradingTimeFrame, 0);
      DrawPeaks(TradingTimeFrame, tradingPeakHighLineName, tradingPeakLowLineName, TradingTimeFrameLineColour, TradingTimeFrameLineSize, tradingTimeFrameLabelDirection);
   }//if (oldTradingTimeFrameBarTime != iTime(Symbol(), TradingTimeFrame, 0))
      
   //Draw the medium time frame
   if (UseMediumTimeFrame)
   {
      static datetime oldMediumTimeFrameBarTime = 0;
      if (oldMediumTimeFrameBarTime != iTime(Symbol(), MediumTimeFrame, 0))
      {
         oldMediumTimeFrameBarTime = iTime(Symbol(), MediumTimeFrame, 0);
         DrawPeaks(MediumTimeFrame, mediumPeakHighLineName, mediumPeakLowLineName, MediumTimeFrameLineColour, MediumTimeFrameLineSize, mediumTimeFrameLabelDirection);
      }//if (oldMediumTimeFrameBarTime != iTime(Symbol(), MediumTimeFrame, 0))
   }//if (UseMediumTimeFrame)
      
   //Draw the high time frame
   if (UseHighTimeFrame)
   {
      static datetime oldHighTimeFrameBarTime = 0;
      if (oldHighTimeFrameBarTime != iTime(Symbol(), HighTimeFrame, 0))
      {
         oldHighTimeFrameBarTime = iTime(Symbol(), HighTimeFrame, 0);
         DrawPeaks(HighTimeFrame, highPeakHighLineName, highPeakLowLineName, HighTimeFrameLineColour, HighTimeFrameLineSize, highTimeFrameLabelDirection);
      }//if (oldHighTimeFrameBarTime != iTime(Symbol(), HighTimeFrame, 0))
   }//if (UseHighTimeFrame)
      
   //Draw the highest time frame
   if (UseHighestTimeFrame)
   {
      static datetime oldHighestTimeFrameBarTime = 0;
      if (oldHighestTimeFrameBarTime != iTime(Symbol(), HighestTimeFrame, 0))
      {
         oldHighestTimeFrameBarTime = iTime(Symbol(), HighestTimeFrame, 0);
         DrawPeaks(HighestTimeFrame, highestPeakHighLineName, highestPeakLowLineName, HighestTimeFrameLineColour, HighestTimeFrameLineSize, highestTimeFrameLabelDirection);
      }//if (oldHighestTimeFrameBarTime != iTime(Symbol(), HighestTimeFrame, 0))
   }//if (UseHighestTimeFrame)
   
   
   
   //Reset the chart time frame
   //if (Period() != TradingTimeFrame)
     // ChartSetSymbolPeriod(0, Symbol(), TradingTimeFrame);
   
//--- return value of prev_calculated for next call
   return(rates_total);
}
//+------------------------------------------------------------------+
