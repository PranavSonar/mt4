//+------------------------------------------------------------------+
//|                                                  Experiments.mq4 |
//|                        Copyright 2016, MetaQuotes Software Corp. |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2016, MetaQuotes Software Corp."
#property link      "https://www.mql5.com"
#property version   "1.00"
#property strict

#define million 1000000
datetime ExpiryDate = D'2015.01.01 00:00';//1st Jan 2015
bool RemoveExpert = true;


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
}

//+---------------------------------------------------------------------------------+ 
//| The function receives the value of the chart minimum in the main window or a    | 
//| subwindow.                                                                      | 
//+---------------------------------------------------------------------------------+ 
double ChartPriceMin(const long chart_ID=0,const int sub_window=0) 
{ 
//--- prepare the variable to get the result 
   double result=EMPTY_VALUE; 
//--- reset the error value 
   ResetLastError(); 
//--- receive the property value 
   if(!ChartGetDouble(chart_ID,CHART_PRICE_MIN,sub_window,result)) 
     { 
      //--- display the error message in Experts journal 
      Print(__FUNCTION__+", Error Code = ",GetLastError()); 
     } 
//--- return the value of the chart property 
   return(result); 
}
  
//+--------------------------------------------------------------------------------+ 
//| The function receives the value of the chart maximum in the main window or a   | 
//| subwindow.                                                                     | 
//+--------------------------------------------------------------------------------+ 
double ChartPriceMax(const long chart_ID=0,const int sub_window=0) 
  { 
//--- prepare the variable to get the result 
   double result=EMPTY_VALUE; 
//--- reset the error value 
   ResetLastError(); 
//--- receive the property value 
   if(!ChartGetDouble(chart_ID,CHART_PRICE_MAX,sub_window,result)) 
     { 
      //--- display the error message in Experts journal 
      Print(__FUNCTION__+", Error Code = ",GetLastError()); 
     } 
//--- return the value of the chart property 
   return(result); 
  }  

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
  }
  
  //+----------------------------------------------------------------------------+ 
//| The function receives the number of the first visible bar on the chart.    | 
//| Indexing is performed like in time series, last bars have smaller indices. | 
//+----------------------------------------------------------------------------+ 
int ChartFirstVisibleBar(const long chart_ID=0) 
  { 
//--- prepare the variable to get the property value 
   long result=-1; 
//--- reset the error value 
   ResetLastError(); 
//--- receive the property value 
   if(!ChartGetInteger(chart_ID,CHART_WINDOW_YDISTANCE,0,result)) 
     { 
      //--- display the error message in Experts journal 
      Print(__FUNCTION__+", Error Code = ",GetLastError()); 
     } 
//--- return the value of the chart property 
   return((int)result); 
  }

//+------------------------------------------------------------------+ 
//| The function receives the chart width in bars.                   | 
//+------------------------------------------------------------------+ 
int ChartWidthInBars(const long chart_ID=0) 
  { 
//--- prepare the variable to get the property value 
   long result=-1; 
//--- reset the error value 
   ResetLastError(); 
//--- receive the property value 
   if(!ChartGetInteger(chart_ID,CHART_WIDTH_IN_BARS,0,result)) 
     { 
      //--- display the error message in Experts journal 
      Print(__FUNCTION__+", Error Code = ",GetLastError()); 
     } 
//--- return the value of the chart property 
   return((int)result); 
  }  
//+------------------------------------------------------------------+
//| Script program start function                                    |
//+------------------------------------------------------------------+
void OnStart()
{
   
   Alert(Symbol(), "  ", ChartVisibleBars());
}     
//+------------------------------------------------------------------+
