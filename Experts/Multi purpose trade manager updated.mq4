//+------------------------------------------------------------------+
//|                          Multi purpose trade manager updated.mq4 |
//|                                                    Steve Hopwood |
//|                                https://www.stevehopwoodforex.com |
//+------------------------------------------------------------------+
#property copyright "Steve Hopwood"
#property link      "https://www.stevehopwoodforex.com"
#property version   "1.00"
#property strict
#define   version "Version 1"


#include <WinUser32.mqh>
#include <stdlib.mqh>
#define  NL    "\n"

//Error reporting
#define  slm " stop loss modification failed with error "
#define  tpm " take profit modification failed with error "
#define  ocm " order close failed with error "
#define  odm " order delete failed with error "
#define  pcm " part close failed with error "
#define  spm " shirt-protection close failed with error "
#define  slim " stop loss insertion failed with error "
#define  tpim " take profit insertion failed with error "


extern string  gen="---- Event timer ----";
extern int     EventTimerSeconds=1;//Seconds in between calculation loops

extern string  sep1="================================================================";
extern string  ManagementStyle1              = "-------- Select your management style --------";
extern string  ManagementStyle2              = "You can select more than one option";
extern bool    ManageByMagicNumber           = false;//Manage trades by magic number,
extern int     MagicNumber                   = 0;//so long as they have this Magic Number.
extern bool    ManageByTradeComment          = false;//Manage trades by order comment,
extern string  TradeComment                  = "Fib";//so long as they have this comment.
extern bool    ManageByTickeNumber           = false;//Manage a specific trade by trade ticket number,
extern int     TicketNumber                  = 0;//and this is the ticket number to manage.
extern string  OverRide                      = "Managing this pair only will override all previous";
extern string  OverRide2                     = "or can be used in combination with any of the choices above";
extern bool    ManageThisPairOnly            = true;//Manage only this pair.
//############## ADDED BY CACUS
extern bool    ManageSpecifiedPairs          = false;//Manage the pairs specified in the next input.
extern string  PairsToManage="AUDJPY,AUDUSD,CHFJPY,EURCHF,EURGBP,EURJPY,EURUSD,GBPCHF,GBPJPY,GBPUSD,NZDJPY,NZDUSD,USDCHF,USDJPY";//Enter the pairs you want to manage here, separated by a comma.
// This allows the ea to manage all existing trades
extern string  OverRide1                     = "Managing all trades will override all other choices";
extern bool    ManageAllTrades               = false;//Manage all pairs traded on the account.
////////////////////////////////////////////////////////////////////////////////////////
//Position variables for CountOpenTrades
int            OpenTrades=0;

//For FIFO
int            FifoTicket[];//Array to store trade ticket numbers in FIFO mode, to cater for
                            //US citizens and to make iterating through the trade closure loop 
                            //quicker.
//Communication with my trading EA's or EA's coded using my shells
string         GvName="Under management flag";//The name of the GV that tells trading EA's not to send trades whilst the manager is closing them.
//############## ADDED BY CACUS for ManageSpecifiedPairs
string         String;
int            PairsQty;
string         suffix;
string         ManagePair[];
//############## ADDED BY CACUS
//Replacements for Bid, Ask etc
double         bid=0, ask=0, factor=0;
int            digits=0;
//Global variable name etc for picking up failed part closures.
string         TicketName                    = "GlobalVariableTicketNo";// For storing ticket numbers in global vars for picking up failed part-closes
bool           GlobalVariablesExist          = false;

////////////////////////////////////////////////////////////////////////////////////////

// Now give user a variety of facilities
extern string  bl1 = "====================================================================";
extern string  ManagementFacilities          = "Select the management facilities you want";
extern string  slf                           = "-------- Stop Loss & Take Profit Manipulation --------";
extern string  BE                            = "---- Break even settings ----";
extern bool    UseBreakEven                  = true;//Use Break Even.
extern int     BreakEvenPips                 = 50;//Pips to break even.
extern int     BreakEvenProfitPips           = 10;//Pips profit to lock in.
////////////////////////////////////////////////////////////////////////////////////////
double  BreakEven=0, BreakEvenProfit=0;
////////////////////////////////////////////////////////////////////////////////////////
extern string  z3                            = "---- Part-close at breakeven ----";
extern string  pcbe = "PartClose settings is used in";
extern string  pcbe1 = "conjunction with Breakeven and Jumping Stop settings";
extern bool    UsePartClose = false;//Allow partial trade closure at break even.
extern double  Close_LotsFract = 0.5;//Fraction of the trade lots to close.
extern double  Preserve_Lots = 0.5;//Fraction of the original trade lots to keep open.
////////////////////////////////////////////////////////////////////////////////////////
double         Close_Lots=0;
////////////////////////////////////////////////////////////////////////////////////////

extern string  z2                            = "----------------";
extern string  JSL                           = "---- Jumping stop loss settings ----";
extern bool    UseJumpingStop                = true;//Use a jumping stop loss.
extern int     JumpingStopPips               = 30;//Jump in this pips increment.
extern bool    JumpAfterBreakevenOnly        = true;//Only jump after break even has been achieved.
////////////////////////////////////////////////////////////////////////////////////////
double         JumpingStop=0;
////////////////////////////////////////////////////////////////////////////////////////

extern string  z4                            = "----------------";
extern string  TSL                           = "---- Trailing stop loss settings. Use standard of candlestick trail. ----";
//If using TS, the user has the option of a normal trail or a candlestick trail.
extern bool    UseStandardTrail              = false;//Use a standard trail.
extern int     TrailingStopPips              = 50;//Number of pips to trail.
extern bool    StopTrailAtProfitPips         = false;//Stop the trail when the profit reaches your target.
extern int     StopTrailPips                 = 0;//The target in pips to stop the trail.
////////////////////////////////////////////////////////////////////////////////////////
double         TrailingStop=0, StopTrailAtProfit=0, StopTrail=0;
////////////////////////////////////////////////////////////////////////////////////////
extern string  z5                            = "----------------";
extern bool    UseCandlestickTrail           = false;//Use a candlestick trailing stop
extern ENUM_TIMEFRAMES CandlestickTrailTimeFrame = PERIOD_H1;//Candlestick time frame
extern int     CandleShift                   = 1;//How many candles back to trail the stop.
extern string  rtb                           ="-- Related to both --";
extern bool    TrailAfterBreakevenOnly       = false;//Only trail after break even has been achieved.
extern int     StopTrailPipsTarget           = 0;//Stop trailing at this pips profit target. Zero to disable.

extern string  z9                            = "----------------";
extern string  MSLA                          = "---- Add a missing Stop Loss ----";
extern bool    AddMissingStopLoss            = false;//Add a stop loss to trades that do not have one.
extern int     MissingStopLossPips           = 200;//Stop loss size in pips.
extern bool    UseSlAtr                      = false;//Use ATR to calculate the stop loss.
extern int     AtrSlPeriod                   = 20;//ATR stop loss period.
extern ENUM_TIMEFRAMES AtrSlTimeFrame        = PERIOD_CURRENT;//ATR stop loss time frame.
extern double  AtrSlMultiplier               = 2;//ATR stop loss multiplier.
////////////////////////////////////////////////////////////////////////////////////////
double         MissingStopLoss=0;
double         AtrVal=0;
////////////////////////////////////////////////////////////////////////////////////////

extern string  z9a                           = "----------------";
extern string  hsl                           = "---- Hidden stop loss settings ----";
extern bool    UseHiddenStopLoss             = false;//Hide your stop loss from the broker.
extern int     HiddenStopLossPips            = 200;//'Real' pips stop loss.
////////////////////////////////////////////////////////////////////////////////////////
double         HiddenStopLoss=0;
////////////////////////////////////////////////////////////////////////////////////////

extern string  z10                           = "----------------";
extern string  tpi                           = "---- Take profit inputs ----";
extern string  MTPA                          = "-- Add a missing Take Profit --";
extern bool    AddMissingTakeProfit          = false;//Add a take profit to trades that do not have one.
extern int     MissingTakeProfitPips         = 200;//Take profit size in pips.
extern bool    UseTpAtr                      = false;//Use ATR to calculate the take profit.
extern int     AtrTpPeriod                   = 20;////ATR stop loss period.
extern ENUM_TIMEFRAMES AtrTpTimeFrame        = PERIOD_CURRENT;//ATR take profit time frame.
extern double  AtrTpMultiplier               = 3;//ATR take profit multiplier.
////////////////////////////////////////////////////////////////////////////////////////
double         MissingTakeProfit=0;
////////////////////////////////////////////////////////////////////////////////////////
extern string  htp                           = "-- Hidden take profit settings --";
extern bool    UseHiddenTakeProfit           = false;//Hide your take profit from the broker.
extern int     HiddenTakeProfitPips          = 200;//'Real' pips take profit.
////////////////////////////////////////////////////////////////////////////////////////
double         HiddenTakeProfit=0;
////////////////////////////////////////////////////////////////////////////////////////


extern string  bl6 = "====================================================================";
extern string  OtherStuff                    = "----Other stuff----";
extern bool    ShowAlerts                    = true;
// Added by Robert for those who do not want the comments.
extern bool    ShowComments                  = true;
// Added by Robert for those who do not want the journal messages.
extern bool    PrintToJournal                = true;

//Enhanced screen feedback display code provided by Paul Batchelor (lifesys). Thanks Paul; this is fantastic.
extern string  se52  ="================================================================";
extern string  oad               ="----Odds and ends----";
//extern int     ChartRefreshDelaySeconds=3;
extern int     DisplayGapSize    = 30; //Left margin size if displaying text as Comments
// ****************************** added to make screen Text more readable
// replaces Comment() with OBJ_LABEL text
extern bool    DisplayAsText     = true;
//Disable the chart in foreground CrapTx setting so the candles do not obscure the text
extern bool    KeepTextOnTop     = true;
extern int     DisplayX          = 100;
extern int     DisplayY          = 0;
extern int     fontSise          = 10;
extern string  fontName          = "Arial";
extern color   colour            = Yellow;
extern double  spacingtweek      = 0.6; // adjustment to reform lines for different font size
////////////////////////////////////////////////////////////////////////////////////////
int            DisplayCount;
string         Gap,ScreenMessage;
////////////////////////////////////////////////////////////////////////////////////////

//+------------------------------------------------------------------+
//| Expert initialization function                                   |
//+------------------------------------------------------------------+
int OnInit()
{
//--- create timer
   EventSetTimer(EventTimerSeconds);
   
   //Initialise the double variables
   BreakEven = BreakEvenPips;
   BreakEvenProfit = BreakEvenProfitPips;
   JumpingStop = JumpingStopPips;
   TrailingStop = TrailingStopPips;
   StopTrailPips = StopTrailPipsTarget;
   MissingStopLoss = MissingStopLossPips;
   MissingTakeProfit = MissingTakeProfitPips;
   HiddenTakeProfit = HiddenTakeProfitPips;
   HiddenStopLoss = HiddenStopLossPips;
   
   Gap="";
   if (DisplayGapSize >0)
      StringInit(Gap, DisplayGapSize, ' ');

   //############## ADDED BY CACUS
      
   if (ManageSpecifiedPairs)
   {
      //############## ADDED BY CACUS
      String=PairsToManage;
      if (StringSubstr(String, StringLen(String)-1) != ",") String = StringConcatenate(String,",");
      suffix = StringSubstr(Symbol(),6,4);
      int qty=PairsQty();
      ArrayResize(ManagePair, qty + 1);
      
      int i = 0;int j = 0;
      for (int k = 0; k < qty; k ++)
      {
         i = StringFind(String, ",",j);
         if (i > -1)
         {
            ManagePair[k] = StringSubstr(String, j,i-j);
            ManagePair[k] = StringTrimLeft(ManagePair[k]);
            ManagePair[k] = StringTrimRight(ManagePair[k]);
            ManagePair[k] = StringConcatenate(ManagePair[k], suffix);
            j = i+1;         
         }//if (i > -1)
      }//for (int k = 0; k < qty; k ++)
      
      
      //############## ADDED BY CACUS   
   
   }//if (ManageSpecifiedPairs)

      
//---
   return(INIT_SUCCEEDED);
}
//+------------------------------------------------------------------+
//| Expert deinitialization function                                 |
//+------------------------------------------------------------------+
void OnDeinit(const int reason)
{
//--- destroy timer
   EventKillTimer();
   removeAllObjects();
      
}
//+------------------------------------------------------------------+
//| Expert tick function                                             |
//+------------------------------------------------------------------+
void OnTick()
{
//---
   
}

//############## ADDED BY CACUS
int PairsQty()
{
   int i = 0;
   int j=0;
   int qty=0;
   
   while(i > -1)
      {
         i = StringFind(String, ",",j);
         if (i > -1)
         {
            qty ++;
            j = i+1;            
         }
      }
      return(qty);
}
//############## ADDED BY CACUS

void DisplayUserFeedback()
{

   string text = "";

   //cpu saving
   /*static datetime CurrentTime = 0;
   static datetime DisplayNow = 0;
   if (TimeCurrent() < DisplayNow )
      return;
   CurrentTime = TimeCurrent();
   DisplayNow = CurrentTime + ChartRefreshDelaySeconds;*/

   
//   ************************* added for OBJ_LABEL
   DisplayCount = 1;
   removeAllObjects();
//   *************************

   if(!IsExpertEnabled())
   {
      Comment("                          EXPERTS DISABLED");
      return;
   }//if (!IsExpertEnabled() )

   ScreenMessage="";
   //ScreenMessage = StringConcatenate(ScreenMessage,Gap + NL);
   SM(NL);
   
   SM("Updates for this EA are to be found at http://www.stevehopwoodforex.com"+NL);
   SM("Feeling generous? Help keep the coder going with a small Paypal donation to pianodoodler@hotmail.com"+NL);
   SM("Broker time = "+TimeToStr(TimeCurrent(),TIME_DATE|TIME_SECONDS)+": Local time = "+TimeToStr(TimeLocal(),TIME_DATE|TIME_SECONDS)+NL);
   SM(version+NL);
/*
   //Code for time to bar-end display donated by Baluda. Cheers Paul.
   SM( TimeToString( iTime(Symbol(), TradingTimeFrame, 0) + TradingTimeFrame * 60 - CurTime(), TIME_MINUTES|TIME_SECONDS ) 
   + " left to bar end" + NL );
  */
  
  if (!ShowComments)
   return;
   
  SM(NL); 
   
   //Display management style info
   if (!ManageAllTrades)
   {
      if (ManageByMagicNumber)
         SM("Managing by Magic Number = " + IntegerToString(MagicNumber) + NL);
      if (ManageByTradeComment)
         SM("Managing by Order Comment = " + TradeComment + NL);
      if (ManageByTickeNumber)
         SM("Managing by Order Ticket = " + IntegerToString(TicketNumber) + NL);
      if (ManageThisPairOnly)
         SM("Managing this pair only i.e. " + Symbol() + NL);
      if (ManageSpecifiedPairs)
         SM("Managing these pairs: " + PairsToManage + NL);
   }//if (!ManageAllTrades)
   
   if (ManageAllTrades)
      SM("Managing all trades on the account. " + NL);     
   
   text = " trades.";
   if (OpenTrades == 0)
      text = " trades. Hell's Bells, but I am bored.";
   if (OpenTrades == 1)
      text = " trade";
   SM("I am managing " + IntegerToString(OpenTrades) + text + NL);  
   
   SM(NL);
   if (UseBreakEven)
   {
      text = "Break even set to " + IntegerToString(BreakEvenPips) + " pips. ";
      if (BreakEvenProfitPips > 0)
         text = text + "Locking in " + IntegerToString(BreakEvenProfitPips) + " pips profit at BE.";
      SM(text + NL);   
   }//if (UseBreakEven)
   
   if (UseJumpingStop)
   {
      text = "Jumping stop set to jump every " + IntegerToString(JumpingStopPips) + " pips. ";
      SM(text + NL);   
   }//if (UseJumpingStop)
   
   if (UseStandardTrail)
   {
      text = "Using a standard trailing, stop set to " + IntegerToString(TrailingStopPips) + " pips. ";
      SM(text + NL);   
   }//if (UseTrailingStop)
   
   if (UseCandlestickTrail)
   {
      text = "Using a candlestic trailing stop set to the hilo of " + IntegerToString(CandleShift) + " candle ago.";
      if (CandleShift != 1)
         text = "Using a candlestic trailing stop set to the hilo of " + IntegerToString(CandleShift) + " candles ago.";
      SM(text + NL);   
   }//if (UseJumpingStop)
   
   if (AddMissingStopLoss)
      SM(ScreenMessage + NL + "Adding missing Stop Loss at " + IntegerToString(MissingStopLossPips) + " pips.");      

   if (AddMissingTakeProfit)
      SM (ScreenMessage + NL + "Adding missing Tske Profit at " + IntegerToString(MissingTakeProfitPips) + " pips.");      
   
   if (UseHiddenStopLoss)
      SM(ScreenMessage + NL + "Hidden stop loss is enabled. Hidden stop = " + IntegerToString(HiddenStopLossPips) + "pips");
     
   if (UseHiddenTakeProfit)
      SM(ScreenMessage + NL + "Hidden take profit is enabled. Hidden stop = " + IntegerToString(HiddenTakeProfitPips) + "pips");
     
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
   double ofset = 0;
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

bool AreWeManagingThisTrade(int ticket)
{

   //Returns 'true' if mptm is managing the trade indexed by ticket,
   //else returns 'false'.
   
   if (!BetterOrderSelect(ticket, SELECT_BY_TICKET, MODE_TRADES))
      return(false);//Somehow, the trade was closed.
      
   int cc = 0;
   
   //Managing all trades
   if (ManageAllTrades)
      return(true);
   
   //Specific pairs list
   if (ManageSpecifiedPairs)
      for (cc = ArraySize(ManagePair) - 1; cc >= 0; cc--)
      {
         if (OrderSymbol() == ManagePair[cc])
            return(true);
      }//for (cc = ArraySize(ManagePair) - 1; cc >= 0; cc--)
      
   //This pair only
   if (ManageThisPairOnly)
      if (OrderSymbol() == Symbol() )
         return(true);
         
   //Magic number
   if (ManageByMagicNumber)
      if (OrderMagicNumber() == MagicNumber )
         return(true);
         
   //Order comment
   if (ManageByTradeComment)
      if (OrderComment() == TradeComment)
         return(true);
         
   //Individual ticket number
   if (ManageByTickeNumber)
      if (OrderTicket() == TicketNumber)
         return(true);
         
            
   
   //Got this far, so we are not managing the trade
   return(false);

}//bool AreWeManagingThisTrade()


void CountOpenTrades()
{
   OpenTrades = 0;
   ArrayResize(FifoTicket, 0);
   
   
   if (OrdersTotal() == 0)
      return;//O open trades, so nothing to do
   
   int as = 0;
      
   for (int cc = OrdersTotal() - 1; cc >= 0; cc--)
   {
      if (!BetterOrderSelect(cc, SELECT_BY_POS, MODE_TRADES))
         continue;//Just in case.
      
      //Are we managing the trades in the orders list
      int ticket = OrderTicket();   
      if (!AreWeManagingThisTrade(ticket))   
         continue;

      OpenTrades++;
               
      //Yes we are, so store the order ticket number
      ArrayResize(FifoTicket, as + 1);
      FifoTicket[as] = ticket;
      as++;  
   
   }//for (int cc = OrdersTotal() - 1; cc >= 0; cc--)
   
      
   //Sort ticket numbers for FIFO
   if (ArraySize(FifoTicket) > 0)
      ArraySort(FifoTicket, WHOLE_ARRAY, 0, MODE_DESCEND);

}//End void CountOpenTrades()

//For OrderSelect() Craptrader documentation states:
//   The pool parameter is ignored if the order is selected by the ticket number. The ticket number is a unique order identifier. 
//   To find out from what list the order has been selected, its close time must be analyzed. If the order close time equals to 0, 
//   the order is open or pending and taken from the terminal open orders list.
//This function heals this and allows use of pool parameter when selecting orders by ticket number.
bool BetterOrderSelect(int index,int select,int pool=-1)
{
   if (select==SELECT_BY_POS)
   {
      if (pool==-1) //No pool given, so take default
         pool=MODE_TRADES;
         
      return(OrderSelect(index,select,pool));
   }
   
   if (select==SELECT_BY_TICKET)
   {
      if (pool==-1) //No pool given, so submit as is
         return(OrderSelect(index,select));
         
      if (pool==MODE_TRADES) //Only return true for existing open trades
         if(OrderSelect(index,select))
            if(OrderCloseTime()==0)
               return(true);
               
      if (pool==MODE_HISTORY) //Only return true for existing closed trades
         if(OrderSelect(index,select))
            if(OrderCloseTime()>0)
               return(true);
   }
   
   return(false);
}//End bool BetterOrderSelect(int index,int select,int pool=-1)

void GetBasics(string symbol)
{
   //Sets up bid, ask, digits, factor for the passed pair
   bid = MarketInfo(symbol, MODE_BID);
   ask = MarketInfo(symbol, MODE_ASK);
   digits = (int)MarketInfo(symbol, MODE_DIGITS);
   factor = GetPipFactor(symbol);
   //spread = (ask - bid) * factor;
   //LongSwap = MarketInfo(symbol, MODE_SWAPLONG);
   //ShortSwap = MarketInfo(symbol, MODE_SWAPSHORT);
     
}//End void GetBasics(string symbol)

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

//////////////////////////////////////////////////////////////////////////////////////////////////////////
//START OF TRADE MANAGEMENT MODULE
void ReportError(string function, string message)
{
   //All purpose sl mod error reporter. Called when a sl mod fails
   
   int err=GetLastError();
   if (err == 1) return;//That bloody 'error but no error' report is a nuisance
   
      
   if (ShowAlerts)
      Alert(WindowExpertName(), " ", OrderTicket(), " ", function, message, err,": ",ErrorDescription(err));
   Print(WindowExpertName(), " ", OrderTicket(), " ", function, message, err,": ",ErrorDescription(err));//Log the result just in case
   
}//void ReportError()

bool ModifyOrder(int ticket, double price, double stop, double take, datetime expiration, color col, string function, string reason)
{
   //Multi-purpose order modify function
   
   bool result = OrderModify(ticket, price ,stop , take, expiration, col);

   //Actions when trade close succeeds
   if (result)
   {
      return(true);
   }//if (result)
   
   //Actions when trade close fails
   if (!result)
      ReportError(function, reason);

   //Got this far, so modify failed
   return(false);
   
}// End bool ModifyOrder()

bool CloseOrder(int ticket, string function, double CloseLots, string reason)
{   
   //Closes open market trades. Deletes pending trades
   
   while(IsTradeContextBusy()) Sleep(100);
   bool orderselect=OrderSelect(ticket,SELECT_BY_TICKET,MODE_TRADES);
   if (!orderselect) return(false);

   bool result = false;
   
   //Market orders
   if (OrderType() < 2) 
   {
      result = OrderClose(ticket, CloseLots, OrderClosePrice(), 1000, clrBlue);
   }//if (OrderType() < 2) 
   
   //Pending trades
   if (OrderType() > 1) 
   {
      result = OrderDelete(ticket, clrNONE);
   }//if (OrderType() < 2) 
   
   //Actions when trade close succeeds
   if (result)
   {
      return(true);
   }//if (result)
   
   //Actions when trade close fails
   if (!result)
      ReportError(function, reason);
   
   //Got this far, so the order close failed. Leave it to the calling function to report the failure
   return(false);
   
}//End bool CloseOrder(ticket)


bool HideStopLoss(int ticket)
{
   //Checks to see if the market has hit the hidden sl and attempts to close the trade if so. 
   //Returns true if trade closure is successful, else returns false
   
   if (!BetterOrderSelect(ticket, SELECT_BY_TICKET, MODE_TRADES))
      return(false);//Order has closed, so nothing to do.    

   int err = 0;
   bool CloseThisTrade = false, result = false;
   double stop = OrderStopLoss();
   
   //Check buy trade
   if (OrderType() == OP_BUY)
   {
      stop = NormalizeDouble(stop + (HiddenStopLoss / factor), digits);
      if (bid <= stop)
         CloseThisTrade = true;

   }//if (OrderType() = OP_BUY)
   
   //Check buy trade
   if (OrderType() == OP_SELL)
   {
      stop = NormalizeDouble(stop - (HiddenStopLoss / factor), digits);
      if (bid >= stop)
         CloseThisTrade = true;
   }//if (OrderType() = OP_SELL)
   
   //Should the trade close?
   if (CloseThisTrade)
   {
      result = CloseOrder(OrderTicket(), __FUNCTION__,  OrderLots(), ocm );
      
   }//if (CloseThisTrade)
   
   
   //Return the result of this function
   return(result);


}//End bool HideStopLoss(int type, int iPipsAboveVisual, double stop )

bool PartCloseOrderFunction()
{
      // Called when any attempt to part-close a long trade is needed.
      // Trade has already been selected 
      // Returns 'true' if succeeds, else false.
      
      
            
      bool result = CloseOrder(OrderTicket(), __FUNCTION__,  Close_Lots, pcm );
     
      return(result);
      
}// End bool PartCloseOrderFunction()

int GetNextAvailableVariableNumber()
{
      // Called from the SetAGlobalTicketVariable() function.
      // Returns the first integer available.
      // The globla variable name consists of "GlobalVariableTicketNo" (stored in the 
      // string TicketName) and an integer.
            
      if (GlobalVariablesTotal()==0) return(1);
      
      for (int cc=1; cc > -1; cc++)
      {
         string ThisGlobalName = StringConcatenate(TicketName,DoubleToStr(cc,0));
         double v1 = GlobalVariableGet(ThisGlobalName);
         if(v1 == 0) return(cc);
         if (cc > 100) return(0);
      }
      
      return(0);
}//int GetNextAvailableVariableNumber()   
   
void SetAGlobalTicketVariable()
{
   // Called whenever an attempt to part-close a trade fails.
   // This function finds the first available global variable name and sets up 
   // a gv with the ticket number of the offending trade. These gv's will consist of
   // the string TicketName ("GlobalVariableTicketNo") and an integer
   int cc = GetNextAvailableVariableNumber();
   string GlobalName = StringConcatenate(TicketName,DoubleToStr(cc,0));
   GlobalVariableSet(GlobalName, OrderTicket());
   GlobalVariablesExist = true;
      
} // End void SetAGlobalTicketVariable();

void TryPartCloseAgain()
{
   // Called if GlobalVariablesExist is set to true and global variables exist.
   // Attempts to part-close where a previous attempt failed
   
   
   GlobalVariablesExist = false;
   if (GlobalVariablesTotal() == 0)
      return;
   
   string name;
   int index;
   int TN;
   for (int cc=0; cc < GlobalVariablesTotal(); cc++)
   {
      name = GlobalVariableName(cc);// Extract gv name
      index = StringFind(name, TicketName, 0);// Is it relevent to this function?
      if (index > -1)// If so, then retry the part-close
      {
         TN = (int)GlobalVariableGet(name);
         //Make sure trade was not closed previously
         if (BetterOrderSelect(TN, SELECT_BY_TICKET, MODE_TRADES) )
            if (OrderCloseTime() == 0)
            {
               bool PartCloseSuccess = PartCloseOrderFunction();
               if (PartCloseSuccess)
               {
                  GlobalVariableDel(name);
                  cc--;
               }//if (PartCloseSuccess)
               else
                  GlobalVariablesExist = false;
            }//if (OrderCloseTime() == 0)
            else
            {
               GlobalVariableDel(name);
               cc--;
            }//else
      }//if (index>-1)
   }//for (int cc=0; cc < GlobalVariablesTotal(); cc++)
}//void TryPartCloseAgain()

void BreakEvenStopLoss(int ticket) 
{

   // Move stop loss to breakeven
   
   if (!BetterOrderSelect(ticket, SELECT_BY_TICKET, MODE_TRADES))
      return;//Order has closed, so nothing to do.    

   //No need to continue if already at BE
   if (OrderType() == OP_BUY)
      if (OrderStopLoss() >= OrderOpenPrice() )
         return;
         
   if (OrderType() == OP_SELL)
      if (!CloseEnough(OrderStopLoss(), 0) )//Sell stops need this extra conditional to cater for no stop loss trades
         if (OrderStopLoss() <= OrderOpenPrice() )
            return;
             

   int err = 0;
   bool PartCloseSuccess = false;
   bool modify = false;
   double stop = 0;
   
  //Can we move the stop loss to breakeven?        
   if (OrderType()==OP_BUY)
      if (OrderStopLoss() < OrderOpenPrice() )
         if (bid >= OrderOpenPrice() + (BreakEven / factor) )
            if (OrderStopLoss() < OrderOpenPrice() )
            {
               modify = true;
               stop = NormalizeDouble(OrderOpenPrice() + (BreakEvenProfit / factor), digits);
            }//if (OrderStopLoss()<OrderOpenPrice())
   	                  			         
          
   if (OrderType()==OP_SELL)
      if (OrderStopLoss() > OrderOpenPrice() || CloseEnough(OrderStopLoss(), 0) )
         if (bid <= OrderOpenPrice() - (BreakEven / factor) )
         {
            modify = true;
            stop = NormalizeDouble(OrderOpenPrice() - (BreakEvenProfit / factor), digits);
         }//if (OrderStopLoss()>OrderOpenPrice()) 
         
   //Modify the order stop loss if BE has been achieved
   if (modify)
   {
      bool result = ModifyOrder(OrderTicket(), OrderOpenPrice(), stop, OrderTakeProfit(), 
                                OrderExpiration(), clrNONE, __FUNCTION__, slm);
      
   }//if (modify)
   

}//End void BreakEvenStopLoss(int ticket)

void JumpingStopLoss(int ticket) 
{
   // Jump stop loss by pips intervals chosen by user.
   // Also carry out partial closure if the user requires this

   if (!BetterOrderSelect(ticket, SELECT_BY_TICKET, MODE_TRADES))
      return;//Order has closed, so nothing to do.    


   // Abort the routine if JumpAfterBreakevenOnly is set to true and be stop is not yet set
   if (JumpAfterBreakevenOnly) 
   {
      if (OrderType()==OP_BUY)
         if(OrderStopLoss() < OrderOpenPrice() ) 
            return;
   
      if (OrderType()==OP_SELL)
         if(OrderStopLoss() > OrderOpenPrice() ) 
            return;
   }//if (JumpAfterBreakevenOnly)
   
  
   double stop = OrderStopLoss(); //Stop loss
   bool result = false, modify = false, TradeClosed = false;
   bool PartCloseSuccess = false;
   int err = 0;
   
   if (OrderType()==OP_BUY)
   {
      // First check if stop needs setting to breakeven
      if (CloseEnough(stop, 0) || stop < OrderOpenPrice() )
      {
         if (bid >= OrderOpenPrice() + (JumpingStop / factor))
         {
            stop = OrderOpenPrice();
            modify = true;
         }//if (ask >= OrderOpenPrice() + (JumpingStop / factor))
      }//if (CloseEnough(stop, 0) || stop<OrderOpenPrice())

      // Increment stop by stop + JumpingStop.
      // This will happen when market price >= (stop + JumpingStop)
      if (!modify)  
         if (stop >= OrderOpenPrice())      
            if (bid >= stop + ((JumpingStop * 2) / factor) ) 
            {
               stop+= (JumpingStop / factor);
               modify = true;
            }// if (bid>= stop + (JumpingStop / factor) && stop>= OrderOpenPrice())      
      
   
   }//if (OrderType()==OP_BUY)
   
   if (OrderType()==OP_SELL)
   {
      // First check if stop needs setting to breakeven
      if (CloseEnough(stop, 0) || stop > OrderOpenPrice())
      {
         if (bid <= OrderOpenPrice() - (JumpingStop / factor))
         {
            stop = OrderOpenPrice();
            modify = true;
         }//if (ask <= OrderOpenPrice() - (JumpingStop / factor))
      } // if (stop==0 || stop>OrderOpenPrice()

      // Decrement stop by stop - JumpingStop.
      // This will happen when market price <= (stop - JumpingStop)
      if (!modify)  
         if (stop <= OrderOpenPrice())      
            if (bid <= stop - ((JumpingStop * 2) / factor) ) 
            {
               stop-= (JumpingStop / factor);
               modify = true;
            }// if (bid>= stop + (JumpingStop / factor) && stop>= OrderOpenPrice())      
        
   }//if (OrderType()==OP_SELL)

   //Modify the order stop loss if a jump has been achieved
   if (modify)
   {
      result = ModifyOrder(OrderTicket(), OrderOpenPrice(), stop, OrderTakeProfit(), 
                                OrderExpiration(), clrNONE, __FUNCTION__, slm);
      if (result)
      {
         
         if (UsePartClose && OrderLots() > Preserve_Lots)//Call the partial close function.
         {
            PartCloseSuccess = PartCloseOrderFunction();
            if (!PartCloseSuccess) SetAGlobalTicketVariable();
         }//if (PartCloseEnabled && OrderLots() > Preserve_Lots)
      }//if (result)

   }//if (modify)


} //End void JumpingStopLoss(int ticket) 

void TrailingStopLoss(int ticket)
{
   if (!BetterOrderSelect(ticket, SELECT_BY_TICKET, MODE_TRADES))
      return;//Order has closed, so nothing to do.    

   
   // Abort the routine if TrailAfterBreakevenOnly is set to true and be stop is not yet set
   if (TrailAfterBreakevenOnly) 
   {
      if (OrderType()==OP_BUY)
         if(OrderStopLoss() < OrderOpenPrice() ) 
            return;
   
      if (OrderType()==OP_SELL)
         if(OrderStopLoss() < OrderOpenPrice() ) 
            if (!CloseEnough(OrderStopLoss(), 0) )
               return;
   }//if (TrailAfterBreakevenOnly)
     
   
   bool result;
   double stop=OrderStopLoss(); //Stop loss
   if (CloseEnough(OrderStopLoss(), 0) )
      stop = OrderOpenPrice();
   bool modify = false, TradeClosed = false;
   
   
   if (OrderType()==OP_BUY) 
      {
         
		   if (bid >= OrderOpenPrice() + (TrailingStop / factor))
	      {
	           if (bid > stop +  (TrailingStop / factor))
	           {
	              stop = bid - (TrailingStop / factor);
	              // Exit routine if user has chosen StopTrailPips and
	              // stop is past the profit point already
	              if (!CloseEnough(StopTrailPips, 0) )
	                  if (stop >= OrderOpenPrice() + (StopTrailPips / factor)) return;
	              
	              //Stop loss needs moving.
	              modify = true;  
	           }//if (bid > stop +  (TrailingStop / factor))
	      }//if (bid >= OrderOpenPrice() + (TrailingStop / factor))
	   
	   
		   
      }//if (OrderType()==OP_BUY) 

      if (OrderType()==OP_SELL) 
      {
		   
          if (bid <= OrderOpenPrice() - (TrailingStop / factor))
          {
              
              if (bid < stop - (TrailingStop / factor))
              {
                   stop = bid + (TrailingStop / factor);
                   // Exit routine if user has chosen StopTrailPips and
                   // stop is past the profit point already
                   if (!CloseEnough(StopTrailPips, 0) ) 
                     if (stop <= OrderOpenPrice() - (StopTrailPips / factor))
                         return;
                   
                  //Stop loss needs moving.
                  modify = true; 
              }//if (ask < stop -  (TrailingStop / factor))
          }//if (bid <= OrderOpenPrice() - (TrailingStop / factor))		   

			   
      }//if (OrderType()==OP_SELL) 

   //Modify the order stop loss if a jump has been achieved
   if (modify)
   {
      result = ModifyOrder(OrderTicket(), OrderOpenPrice(), stop, OrderTakeProfit(), 
                                OrderExpiration(), clrNONE, __FUNCTION__, slm);
      if (result)
      {
         if (UsePartClose && OrderLots() > Preserve_Lots)//Call the partial close function if enabled
         {
            bool PartCloseSuccess = PartCloseOrderFunction();
            if (!PartCloseSuccess) 
               SetAGlobalTicketVariable();
         }//if (PartCloseEnabled && OrderLots() > Preserve_Lots)
      }//if (result)

      
   }//if (modify)
      
}//End void TrailingStopLoss(int ticket)

void CandlestickTrailingStop(int ticket)
{


   if (!BetterOrderSelect(ticket, SELECT_BY_TICKET, MODE_TRADES))
      return;//Order has closed, so nothing to do.    

   // Abort the routine if JumpAfterBreakevenOnly is set to true and be stop is not yet set
   if (TrailAfterBreakevenOnly) 
   {
      if (OrderType()==OP_BUY)
         if(OrderStopLoss() < OrderOpenPrice() ) 
            return;
   
      if (OrderType()==OP_SELL)
         if(OrderStopLoss() < OrderOpenPrice() ) 
            if (!CloseEnough(OrderStopLoss(), 0) )
               return;
   }//if (TrailAfterBreakevenOnly)
     
   
   bool result;
   double stop=OrderStopLoss(); //Stop loss
   if (CloseEnough(OrderStopLoss(), 0) )
      stop = OrderOpenPrice();
   bool modify = false, TradeClosed = false;
   double ClosePrice = 0;
   double StopLevel = MarketInfo(OrderSymbol(), MODE_STOPLEVEL);//Min stop
   
   
   if (OrderType()==OP_BUY) 
      {
          
	   
		   if (UseCandlestickTrail)
		   {
		       ClosePrice = NormalizeDouble(iLow(OrderSymbol(), CandlestickTrailTimeFrame, CandleShift), digits);
		       if (ClosePrice >= OrderOpenPrice())
   		       if (ClosePrice > OrderStopLoss() )
   		       {
   		          //Min stop check
   		          if (ClosePrice - OrderStopLoss() >= (StopLevel  / factor) )
   		          {
   		             stop = ClosePrice;
   		             
   		             //Stop loss needs moving.
   		              modify = true;  
   		          }//if (ClosePrice - OrderStopLoss() >= (StopLevel  / factor) )		          
   		       }//if (ClosePrice > OrderStopLoss() )
		   }//if (UseCandlestickTrail)
		   
		   
      }//if (OrderType()==OP_BUY) 

      if (OrderType()==OP_SELL) 
      {
		   
		   if (UseCandlestickTrail)
		   {
		       ClosePrice = NormalizeDouble(iHigh(OrderSymbol(), CandlestickTrailTimeFrame, CandleShift), digits);
		       if (ClosePrice <= OrderOpenPrice())
   		       if (ClosePrice < OrderStopLoss() || OrderStopLoss() == 0)
   		       {
   		          if (MathAbs(OrderStopLoss() - ClosePrice) >= (StopLevel / factor) )
   		          {
   		             stop = ClosePrice;
   		             
   		             //Stop loss needs moving.
   		              modify = true;  
   		          }//if (OrderStopLoss() - ClosePrice >= (StopLevel / factor) )
   		       }//if (ClosePrice < OrderStopLoss())
		   }//if (UseCandlestickTrail)
		   
      }//if (OrderType()==OP_SELL) 

   //Modify the order stop loss if a jump has been achieved
   if (modify)
   {
      result = ModifyOrder(OrderTicket(), OrderOpenPrice(), stop, OrderTakeProfit(), 
                                OrderExpiration(), clrNONE, __FUNCTION__, slm);
      if (result)
      {
         
         if (UsePartClose && OrderLots() > Preserve_Lots)// Only try to do this if the jump stop worked
         {
            bool PartCloseSuccess = PartCloseOrderFunction();
            if (!PartCloseSuccess) 
               SetAGlobalTicketVariable();
         }//if (PartCloseEnabled && OrderLots() > Preserve_Lots)
      }//if (result)

      
   }//if (modify)


}//End void CandlestickTrailingStop(int ticket)

void InsertStopLoss(int ticket)
{
   //Inserts a stop los into a trade that lacks one.

   if (!BetterOrderSelect(ticket, SELECT_BY_TICKET, MODE_TRADES))
      return;//Order has closed, so nothing to do.    
   
   if (!CloseEnough(OrderStopLoss(), 0) || (MissingStopLossPips == 0 && !UseSlAtr) ) 
      return; //Nothing to do
   
   double stop = 0;
   bool result = false;
  
   //There is the option for the user to use Atr to calculate the stop
   if (UseSlAtr) 
      AtrVal = iATR(OrderSymbol(), AtrSlTimeFrame, AtrSlPeriod, 0) * AtrSlMultiplier;
   
   // Buy trade
   if (OrderType() == OP_BUY || OrderType() == OP_BUYLIMIT || OrderType() == OP_BUYSTOP)
   {
      stop = NormalizeDouble(OrderOpenPrice() - (MissingStopLoss / factor), digits);    
      if (UseSlAtr) 
         stop = NormalizeDouble(OrderOpenPrice() - AtrVal, digits);
   }//if (OrderType() == OP_BUY || OrderType() == OP_BUYLIMIT || OrderType() == OP_BUYSTOP)
   
   
   // Sell trade
   if (OrderType() == OP_SELL || OrderType() == OP_SELLLIMIT || OrderType() == OP_SELLSTOP)
   {
      stop = NormalizeDouble(OrderOpenPrice() + (MissingStopLoss / factor), digits); 
      if (UseSlAtr) 
         stop = NormalizeDouble(OrderOpenPrice() + AtrVal, digits);
   }//if (OrderType() == OP_SELL || OrderType() == OP_SELLLIMIT || OrderType() == OP_SELLSTOP)
   
   result = ModifyOrder(OrderTicket(), OrderOpenPrice(), stop, OrderTakeProfit(), 
                        OrderExpiration(), clrNONE, __FUNCTION__, slim);
   
   
}// End void InsertStopLoss(int ticket)

void InsertTakeProfit(int ticket)
{
 
    //Inserts a take profit into a trade that lacks one.

   if (!BetterOrderSelect(ticket, SELECT_BY_TICKET, MODE_TRADES))
      return;//Order has closed, so nothing to do.    
  
   if (!CloseEnough(OrderStopLoss(), 0) || (MissingTakeProfitPips == 0 && !UseTpAtr) ) 
      return; //Nothing to do

   double take = 0;
   bool result = false;
   
   //There is the option for the user to use Atr to calculate the stop
   if (UseTpAtr) 
      AtrVal = iATR(OrderSymbol(), AtrTpTimeFrame, AtrTpPeriod, 0) * AtrTpMultiplier;
   
   // Buy trade
   if (OrderType() == OP_BUY || OrderType() == OP_BUYLIMIT || OrderType() == OP_BUYSTOP)
   {
      take = NormalizeDouble(ask + (MissingTakeProfit / factor), digits);
      if (UseSlAtr) 
         take = NormalizeDouble(OrderOpenPrice() + AtrVal, digits);
   }//if (OrderType() == OP_BUY || OrderType() == OP_BUYLIMIT || OrderType() == OP_BUYSTOP)
   
   
   // Sell trade
   if (OrderType() == OP_SELL || OrderType() == OP_SELLLIMIT || OrderType() == OP_SELLSTOP)
   {
      take = NormalizeDouble(bid - (MissingTakeProfit / factor), digits);
      if (UseSlAtr) 
         take = NormalizeDouble(OrderOpenPrice() - AtrVal, digits);
   }//if (OrderType() == OP_SELL || OrderType() == OP_SELLLIMIT || OrderType() == OP_SELLSTOP)
   
   result = ModifyOrder(OrderTicket(), OrderOpenPrice(), OrderStopLoss(), take,
                        OrderExpiration(), clrNONE, __FUNCTION__, tpim);
   
   
}// End void InsertTakeProfit(int ticket)

bool HideTakeProfit(int ticket)
{
   //Calculate whether a hidden take profit has been hit.
   //Returns 'true' if so, else 'false'.

   if (!BetterOrderSelect(ticket, SELECT_BY_TICKET, MODE_TRADES))
      return(true);//Order has closed, so nothing to do.    

   double take = 0;
   bool result = false;
   int err = 0;
   
   //Should the order close because the stop has been passed?
   //Buy trade
   if (OrderType() == OP_BUY)
   {
      take = NormalizeDouble(OrderOpenPrice() + (HiddenTakeProfit / factor), digits);
      if (bid >= take)
      {
         result = CloseOrder(OrderTicket(), __FUNCTION__,  OrderLots(), ocm );
         if (result)
         {
            if (ShowAlerts) 
               Alert("Take profit hit. Close of ", OrderSymbol(), " ticket no ", OrderTicket());      
            Print("Take profit hit. Close of ", OrderSymbol(), " ticket no ", OrderTicket());
         }//if (result)
         
      }//if (bid >= take)      
   }//if (OrderType() == OP_BUY)
   
   //Sell trade
   if (OrderType() == OP_SELL)
   {
      take = NormalizeDouble(OrderOpenPrice() - (HiddenTakeProfit / factor), digits);
      if (ask <= take)
      {
         result = CloseOrder(OrderTicket(), __FUNCTION__,  OrderLots(), ocm );
         if (result)
         {
            if (ShowAlerts==true) 
               Alert("Take profit hit. Close of ", OrderSymbol(), " ticket no ", OrderTicket());
            Print("Take profit hit. Close of ", OrderSymbol(), " ticket no ", OrderTicket());         
         }//if (result)
        
      }//if (bid <= take)   
   }//if (OrderType() == OP_SELL)
   
   return(result);

}//End bool HideTakeProfit(int ticket)


void DoTradeManagement()
{

   //Trades being managed by mptm are stored in an array. The user's choice of
   //management facilities does not matter here, only the type of management required.
   for (int cc = ArraySize(FifoTicket) - 1; cc >= 0; cc--)
   {
      if (!BetterOrderSelect(FifoTicket[cc], SELECT_BY_TICKET, MODE_TRADES) )
         continue;//Trade has closed.
      
      int ticket = FifoTicket[cc];
      
      GetBasics(OrderSymbol() );


		//Has a hidden SL been hit?
		if (UseHiddenStopLoss)
		   if (OrderType() < 2)//Only applies to market trades
		      if (HideStopLoss(ticket) )
		         continue;//Trade has closed, so no need to go further.   
		
 		//Has a hidden tp been hit?
		if (UseHiddenTakeProfit)
		   if (OrderType() < 2)//Only applies to market trades
		      if (HideTakeProfit(ticket) )
		         continue;//Trade has closed, so no need to go further.   
		   
     
      //For part close. Calculate the lot size to close if part-close is required.
      if (UsePartClose)
         if (!CloseEnough(Close_LotsFract, 0))
            if (Close_LotsFract < 1 )
      		{
      			Close_Lots = MathFloor(Close_LotsFract * OrderLots() * 100) / 100;
      			Preserve_Lots = OrderLots() - Close_Lots;
      		}//if (PartCloseEnabled && Close_LotsFract > 0 && Close_LotsFract < 1 )

      //Break even stop loss
      if (UseBreakEven)
         BreakEvenStopLoss(ticket);
   
		//Jumping stop loss
		if (UseJumpingStop)
		   JumpingStopLoss(ticket);
		
		//Standard trailing stop loss
		if (UseStandardTrail)
		   TrailingStopLoss(ticket);
		
		//Candlestick trailing stop loss
		if (UseCandlestickTrail)
		   CandlestickTrailingStop(ticket);
		
		//Add a missing stop loss
		if (AddMissingStopLoss)
		   InsertStopLoss(ticket);
		   
		//Add a missing take profit
		if (AddMissingTakeProfit)
		   InsertTakeProfit(ticket);
		   
		
   }//for (int cc = ArraySize(FifoTicket) - 1; cc >= 0; cc--)
   
   
   // Global variable to pick up on failed part-closes
   if (GlobalVariablesTotal() > 0) 
      GlobalVariablesExist = true;
   else
      return;
   TryPartCloseAgain();//Have another go
   if (GlobalVariablesExist)
      if (GlobalVariablesTotal() == 0) 
         GlobalVariablesExist = false;//And cancel the GV's if all closures succeeded
      

}//End void DoTradeManagement()


//END OF TRADE MANAGEMENT MODULE
//////////////////////////////////////////////////////////////////////////////////////////////////////////

//+------------------------------------------------------------------+
//| Timer function                                                   |
//+------------------------------------------------------------------+
void OnTimer()
{
//---
   
   if(!IsExpertEnabled())
   {
      removeAllObjects();
      Comment("                          EXPERTS DISABLED");
      return;
   }//if (!IsExpertEnabled() )
   
   //Build a picture of the position.
   CountOpenTrades();
   
   //Any trades to manage?
   if (OpenTrades > 0)
   {
      DoTradeManagement();
      if (GlobalVariablesExist)
         TryPartCloseAgain();
   }//if (OpenTrades > 0)
   
   
   DisplayUserFeedback();
   
}
//+------------------------------------------------------------------+
