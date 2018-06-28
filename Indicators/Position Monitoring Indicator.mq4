//+------------------------------------------------------------------+
//|                                                   GW monitor.mq4 |
//|                        Copyright 2016, MetaQuotes Software Corp. |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2016, MetaQuotes Software Corp."
#property link      "https://www.mql5.com"
#property version   "1.00"
//#property strict
#property indicator_chart_window
#include <WinUser32.mqh>
#include <stdlib.mqh>
#define  NL    "\n"


extern int     MagicNumber=0;
//Enhanced screen feedback display code provided by Paul Batchelor (lifesys). Thanks Paul; this is fantastic.
extern string  se52  ="================================================================";
extern string  oad               ="----Odds and ends----";
extern int     ChartRefreshDelaySeconds=3;
extern int     DisplayGapSize    = 60; // if using Comments
// ****************************** added to make screen Text more readable
extern bool    DisplayAsText     = true;  // replaces Comment() with OBJ_LABEL text
extern bool    KeepTextOnTop     = true;//Disable the chart in foreground CrapTx setting so the candles do not obscure the text
extern int     DisplayX          = 150;
extern int     DisplayY          = 0;
extern int     fontSise          = 10;
extern string  fontName          = "Arial";
extern color    colour            = Yellow;
extern double  spacingtweek      = 0.6; // adjustment to reform lines for different font size
////////////////////////////////////////////////////////////////////////////////////////
int            DisplayCount;
string         Gap,ScreenMessage;
////////////////////////////////////////////////////////////////////////////////////////

//Calculating the factor needed to turn pip values into their correct points value to accommodate different Digit size.
//Thanks to Lifesys for providing this code. Coders, you need to briefly turn of Wrap and turn on a mono-spaced font to view this properly and see how easy it is to make changes.
string         pipFactor[]  = {"JPY","XAG","SILVER","BRENT","WTI","XAU","GOLD","SP500","S&P","UK100","WS30","DAX30","DJ30","NAS100","CAC400"};
double         pipFactors[] = { 100,  100,  100,     100,    100,  10,   10,    10,     10,   1,      1,     1,      1,     1,       1};
double         factor;//For pips/points stuff. Set up in int init()

double         PipsUpl;//For keeping track of the pips PipsUpl of multi-trade/hedged positions
double         CashUpl;//For keeping track of the cash PipsUpl of multi-trade/hedged positions
//For chart display
int            MarketBuys=0, MarketSells=0;
double         BuyPipsUpl=0, SellPipsUpl=0;
double         BuyCashUpl=0, SellCashUpl=0;
int            TicketNo=-1,OpenTrades,OldOpenTrades;
int            BuyStops=0, SellStops=0;
bool           BuyOpen,SellOpen,BuyStopOpen,SellStopOpen, BuyLimitOpen, SellLimitOpen;//Might need further refinement to reflect the pending type
int            GridTradesTotal=0;//Total of market, stop and limit trades
int            PendingTradesTotal=0;//Total of stop and limit trades
int            MarketTradesTotal=0;//Total of open market trades
bool           GridSent=false;//true if CountOpenTrades finds a trade
bool           Hedged=true;
double         upl=0;

//Running total of trades
int            LossTrades, WinTrades;
double         OverallProfit;

//+------------------------------------------------------------------+
//| Custom indicator initialization function                         |
//+------------------------------------------------------------------+
int OnInit()
{
   
   factor=PFactor(Symbol());
   
   Gap="";
   if (DisplayGapSize >0)
   {
      for (int cc=0; cc< DisplayGapSize; cc++)
      {
         Gap = StringConcatenate(Gap, " ");
      }   
   }//if (DisplayGapSize >0)

   
   return(INIT_SUCCEEDED);
}

double PFactor(string symbol)
{
//This code supplied by Lifesys. Many thanks Paul - we all owe you. Gary was trying to make me see this, but I could not understand his explanation. Paul used Janet and John words

   for(int i=ArraySize(pipFactor)-1; i>=0; i--)
      if(StringFind(symbol,pipFactor[i],0)!=-1)
         return (pipFactors[i]);
   return(10000);

}//End double PFactor(string pair)

void CountOpenTrades()
{
  
   BuyStops=0;
   SellStops=0;
   PipsUpl = 0;//Unrealised profit and loss for hedging/recovery basket closure decisions
   CashUpl = 0;
   MarketTradesTotal=0;
   PendingTradesTotal=0;
   MarketBuys=0;
   MarketSells=0;
   BuyPipsUpl=0;
   SellPipsUpl=0;
   BuyCashUpl=0;
   SellCashUpl=0;
   
   
   upl = 0;//Unrealised profit and loss for hedging/recovery basket closure decisions

   if (OrdersTotal() == 0) return;
   
   //Iterating backwards through the orders list caters more easily for closed trades than iterating forwards
   for (int cc = OrdersTotal() - 1; cc >= 0; cc--)
   {
      
      //Ensure the trade is still open
      if (!OrderSelect(cc, SELECT_BY_POS, MODE_TRADES) ) continue;
      //Ensure the EA 'owns' this trade
      if (OrderSymbol() != Symbol() ) continue;
      if (OrderMagicNumber() != MagicNumber) continue;
      if (OrderCloseTime() > 0) continue; 
      
      
      OpenTrades++;
      
      //upl might not be needed. Depends on the individual EA
      upl+= (OrderProfit() + OrderSwap() + OrderCommission()); 
      //The next line of code calculates the pips upl of an open trade. As yet, I have done nothing with it.
      //something = CalculateTradeProfitInPips()
      
      CashUpl+= (OrderProfit() + OrderSwap() + OrderCommission()); 
      //The next block of code calculates the pips upl of an open trade. 
      double pips = 0;
      if (OrderType() < 2)
      {
         MarketTradesTotal++;
         pips = CalculateTradeProfitInPips(OrderType());
         PipsUpl+= pips;
         if (OrderType() == OP_BUY)
         {
            MarketBuys++;
            BuyPipsUpl+= pips;
            BuyCashUpl+= (OrderProfit() + OrderSwap() + OrderCommission()); 
         }//if (OrderType() == OP_BUY)
         
         if (OrderType() == OP_SELL)
         {
            MarketSells++;
            SellPipsUpl+= pips;
            SellCashUpl+= (OrderProfit() + OrderSwap() + OrderCommission());            
         }//if (OrderType() == OP_SELL)
         
      }//if (OrderType() < 2)
      
      if (OrderType() > 1)
      {
         PendingTradesTotal++;
      }//if (OrderType() > 1)
      
      
      //These might need extra coding if both stop and limit orders are used
      if (OrderType() == OP_BUYSTOP) 
      {
         BuyStopOpen = true; 
         BuyStops++;
      }//if (OrderType() == OP_BUYSTOP) 
      
     
      if (OrderType() == OP_SELLSTOP) 
      {
         SellStopOpen = true; 
         SellStops++;
      }//if (OrderType() == OP_SELLSTOP) 
      
      
      
       
      //Trade types and half-close, and adjust sl/tp in case slippage has caused them to be inaccurate when the trade was sent.
      if (OrderType() == OP_BUY) 
      {
         BuyOpen = true;         
     }//if (OrderType() == OP_BUY) 
      
      if (OrderType() == OP_SELL) 
      {
         SellOpen = true;         
      }//if (OrderType() == OP_SELL) 
      
   }//for (int cc = OrdersTotal() - 1; cc <= 0; c`c--)
   
      
   //Is the position hedged?
   Hedged = false;
   if (BuyOpen)
      if (SellOpen)
         Hedged=true;

   
}//End void CountOpenTrades();

void CalculateDailyResult()
{
   //Calculate the no of winners and losers from today's trading. These are held in the history tab.

   LossTrades = 0;
   WinTrades = 0;
   OverallProfit = 0;
   
   // (BA) Get the start second of the current day (server time)
   datetime TodayStart = iTime(Symbol(), PERIOD_D1, 0);
   
   for (int cc = 0; cc <= OrdersHistoryTotal(); cc++)
   {
      if (!OrderSelect(cc, SELECT_BY_POS, MODE_HISTORY) ) continue;
      if (OrderSymbol() != Symbol() ) continue;
      if (OrderMagicNumber() != MagicNumber) continue;
      if( OrderCloseTime() < TodayStart ) continue; // (BA) Not in the current day
      
      OverallProfit+= (OrderProfit() + OrderSwap() + OrderCommission() );
      if (OrderProfit() > 0) WinTrades++;
      if (OrderProfit() < 0) LossTrades++;
      
   }//for (int cc = 0; cc <= tot -1; cc++)
   
   

}//End void CalculateDailyResult()

double CalculateTradeProfitInPips(int type)
{
   //This code supplied by Lifesys. Many thanks Paul.
   
   //Returns the pips Upl of the currently selected trade. Called by CountOpenTrades()
   double profit;
   // double point = BrokerPoint(OrderSymbol() ); // no real use
   double ask = MarketInfo(OrderSymbol(), MODE_ASK);
   double bid = MarketInfo(OrderSymbol(), MODE_BID);

   if (type == OP_BUY)
   {
      profit = bid - OrderOpenPrice();
   }//if (OrderType() == OP_BUY)

   if (type == OP_SELL)
   {
      profit = OrderOpenPrice() - ask;
   }//if (OrderType() == OP_SELL)
   //profit *= PFactor(OrderSymbol()); // use PFactor instead of point. This line for multi-pair ea's
   profit *= factor; // use PFactor instead of point.

   return(profit); // in real pips
}//double CalculateTradeProfitInPips(int type)

void DisplayUserFeedback()
{

   if(IsTesting() && !IsVisualMode()) return;

   string text = "";

   //cpu saving
   static datetime CurrentTime = 0;
   static datetime DisplayNow = 0;
   if (TimeCurrent() < DisplayNow )
      return;
   CurrentTime = TimeCurrent();
   DisplayNow = CurrentTime + ChartRefreshDelaySeconds;

   if(IsTesting() && !IsVisualMode()) return;

//   ************************* added for OBJ_LABEL
   DisplayCount = 1;
   removeAllObjects();
//   *************************

   ScreenMessage="";
   //ScreenMessage = StringConcatenate(ScreenMessage,Gap + NL);
   SM(NL);
   
   
/*
   //Code for time to bar-end display donated by Baluda. Cheers Paul.
   SM( TimeToString( iTime(Symbol(), TradingTimeFrame, 0) + TradingTimeFrame * 60 - CurTime(), TIME_MINUTES|TIME_SECONDS ) 
   + " left to bar end" + NL );
  */
   
   

   SM(NL);     
   text = "Market trades open = ";
   if (Hedged)
   {
      text = "Hedged position. Market trades open = ";
   }
   SM(text + IntegerToString(MarketTradesTotal) + ": Pips UPL = " + DoubleToStr(PipsUpl, 0)
   +  ": Cash UPL = " + DoubleToStr(CashUpl, 2) + NL);
   if (BuyOpen)
      SM("Buy trades = " + IntegerToString(MarketBuys)
         + ": Pips upl = " + IntegerToString(BuyPipsUpl)
         + ": Cash upl = " + DoubleToStr(BuyCashUpl, 2)
         + NL);
   if (SellOpen)
      SM("Sell trades = " + IntegerToString(MarketSells)
         + ": Pips upl = " + IntegerToString(SellPipsUpl)
         + ": Cash upl = " + DoubleToStr(SellCashUpl,2)
         + NL);
   //if (Hedged)
     // SM("HedgeProfitPips = " + DoubleToStr(HedgeProfit, 0) + " pips" + NL);
   
   
   SM(NL);

   //Running total of trades
   SM(Gap + NL);
   SM("Results for this trading day as measured by your broker. Wins: " + WinTrades + ": Losses " + LossTrades + ": P/L " + DoubleToStr(OverallProfit, 2) + NL);
   

     
   Comment(ScreenMessage);

}//void DisplayUserFeedback()
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
//+--------------------------------------------------------------------+
//| Paul Bachelor's (lifesys) text display module to replace Comment()|
//+--------------------------------------------------------------------+
void SM(string message)
{
   if (DisplayAsText) 
   {
      DisplayCount++;
      Display(message);
   }
   else
      ScreenMessage = StringConcatenate(ScreenMessage,Gap, message);
      
}//End void SM()

//   ************************* added for OBJ_LABEL
void removeAllObjects()
{
   for(int i = ObjectsTotal() - 1; i >= 0; i--)
   if (StringFind(ObjectName(i),"OAM-",0) > -1) 
      ObjectDelete(ObjectName(i));
}//End void removeAllObjects()
//   ************************* added for OBJ_LABEL

void Display(string text)
{
   string lab_str = "OAM-" + IntegerToString(DisplayCount);   
   int ofset = 0;
   string textpart[5];
   for (int cc = 0; cc < 5; cc++) 
   {
      textpart[cc] = StringSubstr(text,cc*63,64);
      if (StringLen(textpart[cc]) ==0) continue;
      ofset = cc * 63 * fontSise * spacingtweek;
      lab_str = lab_str + IntegerToString(cc);
      ObjectCreate(lab_str, OBJ_LABEL, 0, 0, 0); 
      ObjectSet(lab_str, OBJPROP_CORNER, 0);
      ObjectSet(lab_str, OBJPROP_XDISTANCE, DisplayX + ofset); 
      ObjectSet(lab_str, OBJPROP_YDISTANCE, DisplayY+DisplayCount*(fontSise+4)); 
      ObjectSet(lab_str, OBJPROP_BACK, false);
      ObjectSetText(lab_str, textpart[cc], fontSise, fontName, colour);
   }//for (int cc = 0; cc < 5; cc++) 
}

string FormatNumber(double x, int width, int precision)
{
   string p = DoubleToStr(x, precision);   
   while(StringLen(p) < width)
      p = "  " + p;
   return(p);
}//End void Display(string text)

bool ChartForegroundSet(const bool value,const long chart_ID=0)
{
//--- reset the error value
   ResetLastError();
//--- set property value
   if(!ChartSetInteger(chart_ID,CHART_FOREGROUND,0,value))
   {
      //--- display the error message in Experts journal
      Print(__FUNCTION__+", Error Code = ",GetLastError());
      return(false);
   }//if(!ChartSetInteger(chart_ID,CHART_FOREGROUND,0,value))
//--- successful execution
   return(true);
}//End bool ChartForegroundSet(const bool value,const long chart_ID=0)
//+--------------------------------------------------------------------+
//| End of Paul's text display module to replace Comment()             |
//+--------------------------------------------------------------------+

//+------------------------------------------------------------------+
void OnDeinit(const int reason) {

   removeAllObjects();
   Comment("");

}


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


   CountOpenTrades();
   
   //Daily results so far - they work on what in in the history tab, so users need warning that
   //what they see displayed on screen depends on that.   
   //Code courtesy of TIG yet again. Thanks, George.
   static int OldHistoryTotal;
   if (OrdersHistoryTotal() != OldHistoryTotal)
   {
      CalculateDailyResult();//Does no harm to have a recalc from time to time
      OldHistoryTotal = OrdersHistoryTotal();
   }//if (OrdersHistoryTotal() != OldHistoryTotal)
   
   
   DisplayUserFeedback();

   return(rates_total);
}
//+------------------------------------------------------------------+
