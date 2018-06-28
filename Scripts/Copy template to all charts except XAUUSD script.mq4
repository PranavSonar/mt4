//+------------------------------------------------------------------+
//|                                  Copy template to all charts.mq4 |
//|                                    Copyright 2014, Steve Hopwood |
//|                                  http://www.StephenHopwood.co.uk |
//+------------------------------------------------------------------+
#property copyright "Copyright 2014, Steve Hopwood"
#property link      "http://www.StephenHopwood.co.uk"
#property version   "1.00"
#property strict
//+------------------------------------------------------------------+
//| Script program start function                                    |
//+------------------------------------------------------------------+
void OnStart()
{
//---
   string FileName = "temp_template"; //file name to save current template
   long CurrentChart = ChartID();//get current chart ID
   ChartSaveTemplate(0, FileName);//save current template
   //iterate through all charts
   long Chart = ChartFirst();
   while (Chart >= 0){
     if ((Chart != CurrentChart) && (ChartSymbol(Chart) != "XAUUSD")) //do not apply to curent chart and xauusd
       ChartApplyTemplate(Chart, FileName); //apply saved template
       Chart = ChartNext(Chart); //get next chart
   }   
}
//+------------------------------------------------------------------+
