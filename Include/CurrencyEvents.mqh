//+-------------------------------------------------------------------------------------------------------+
//|                                                                                    CurrencyEvents.mqh |
//|                                                                                              renexxxx |
//|                                                                      http://www.stevehopwoodforex.com |
//+-------------------------------------------------------------------------------------------------------+
#property copyright "renexxxx"
#property link      "http://www.stevehopwoodforex.com"
#property version   "1.00"
#property strict

#define EVENT_CURRENCY_FLAT                 9001                        // Currency is FLAT
#define EVENT_CURRENCY_WEAK                 9002                        // Currency is WEAK
#define EVENT_CURRENCY_STRONG               9003                        // Currency is STRONG
#define EVENT_CURRENCY_EXHAUSTED            9004                        // Currency Strength/Weakness is EXHAUSTED
#define EVENT_CURRENCY_STRONG_EXHAUSTED     9005                        // Currency Strength is EXHAUSTED
#define EVENT_CURRENCY_WEAK_EXHAUSTED       9006                        // Currency Weakness is EXHAUSTED

//+------------------------------------------------------------------+
//| Send an event to the current chart                               |
//+------------------------------------------------------------------+
void SendEvent(ushort eventID, long lparam,double dparam,string sparam) {

   long currChart=ChartID();

   EventChartCustom(currChart,eventID,lparam,dparam,sparam);
}

//+------------------------------------------------------------------+
//| Broadcast an event to all open charts                            |
//+------------------------------------------------------------------+
void BroadcastEvent(ushort eventID, long lparam,double dparam,string sparam) {

   long currChart=ChartFirst();

   // We have certainly no more than CHARTS_MAX open charts
   for(int i = 0; i < CHARTS_MAX; i++) {
      // Send the event to currChart
      EventChartCustom(currChart,eventID,lparam,dparam,sparam);
      currChart=ChartNext(currChart); // We have received a new chart from the previous
      if(currChart==-1) break;        // Reached the end of the charts list
   }
}