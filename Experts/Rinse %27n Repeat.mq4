//+-------------------------------------------------------------------+
//|                                               Rinse 'n Repeat.mq4 |
//|                                    Copyright 2012, Steve Hopwood  |
//|                              http://www.hopwood3.freeserve.co.uk  |
//+-------------------------------------------------------------------+
#define  version "Version 1p"

#property description "Inspired by an idea of: Remon Reffat, remon78eg, Egypt"

#property copyright "Copyright 2012, Steve Hopwood"
#property link      "http://www.hopwood3.freeserve.co.uk"
#include <WinUser32.mqh>
#include <stdlib.mqh>
#define  NL    "\n"
#define  up "Up"
#define  down "Down"
#define  ranging "Ranging"
#define  none "None"
#define  both "Both"
#define  buy "Buy"
#define  sell "Sell"

//Trend Arrow constants
#define  Trenduparrow " Big green up Trend arrow "
#define  Trenddownarrow " Big red down Trend arrow "

//Wavy line constants
#define  Waverange " Yellow Range wave "
#define  Wavebuytrend " Blue wave buy trend"
#define  Waveselltrend " Blue wave sell trend"

//No signal
#define  hginosignal " No signal"

#define  TjfHedgeComment "TJF defensive hedge"

#define  AllTrades 10 //Tells CloseAllTrades() to close/delete everything
#define  million 1000000;

#define  baseline "Base line"

//Define the FifoBuy/SellTicket fields
#define  TradeOpenTime 0
#define  TradeTicket 1
#define  TradeProfitCash 2 //Cash profit
#define  TradeProfitPips 3 //Pips profit

//Define the GridBuy/SellTicket fields

#define  TradeOpenPrice 0
//#define  TradeTicket 1 /// can use the one above.

//Error reporting
#define  slm " stop loss modification failed with error "
#define  tpm " take profit modification failed with error "
#define  ocm " order close failed with error "
#define  odm " order delete failed with error "
#define  pcm " part close failed with error "
#define  spm " shirt-protection close failed with error "
#define  slim " stop loss insertion failed with error "
#define  tpim " take profit insertion failed with error "
#define  tpsl " take profit or stop loss insertion failed with error "
#define  oop " pending order price modification failed with error "

/*

Matt Kennel has provided the code for bool O_R_CheckForHistory(int ticket). Cheers Matt, You are a star.

Code for adding debugging Sleep
Alert("G");
int x = 0;
while (x == 0) Sleep(100);

Standard order loop code
   for (int cc = OrdersTotal() - 1; cc >= 0; cc--)
   {
      if (!OrderSelect(cc, SELECT_BY_POS) ) continue;
      if (OrderSymbol() != Symbol() ) continue;
      if (OrderMagicNumber() != MagicNumber) continue;

   }//for (int cc = OrdersTotal() - 1; cc >= 0; cc--)

Code from George, to detect the shift of an order open time
int shift = iBarShift(NULL,Period(),OrderOpenTime(), false);

To calculate what percentage a small number is of a larger one:
(Given amount Divided by Total amount) x100 = %
as in UpperWickPercentage = (UpperWick / CandleSize) * 100; where CandleSize is the size of the the candle and UpperWick the size of the top of the body to the High.

Example of iHighest and iLowest
double lastHigh = iHigh( symbolNames[i], PERIOD_H1, iHighest( symbolNames[i], PERIOD_H1, MODE_HIGH, 24, 1 ) );
double lastLow = iLow( symbolNames[i], PERIOD_H1, iLowest( symbolNames[i], PERIOD_H1, MODE_LOW, 24, 1 ) );

   Full snippet to force closure of all open trades. Use whichever part is most appropriate.
   if (ForceTradeClosure)
   {
      CloseAllTrades();
      if (ForceTradeClosure)
      {
         CloseAllTrades();
         if (ForceTradeClosure)
         {
            return;
         }//if (ForceTradeClosure)                     
      }//if (ForceTradeClosure)         
   }//if (ForceTradeClosure)      

*/






extern string  gen="----General inputs----";
/*
Note to coders about TradingTimeFrame. Be consistent in your calls to indicators etc and always use TradingTimeFrame i.e.
double v = iClose(Symbol(), TradingTimeFrame, shift) instead of Close[shift].
This allows the user to change time frames without disturbing the ea. There is a line of code in OnInit(), just above the call
to DisplayUserFeedback() that forces the EA to wait until the open of a new TradingTimeFrame candle; you might want to comment
this out during your EA development.
*/
extern double  Lot=0.01;
//Lot size by x lots per y of equity or balance. Default 0.01 lots per $1000 of equity
extern double  LotsPerDollopOfCash=0;//Over rides Lot. Zero input to cancel.
extern double  SizeOfDollop=1000;
extern bool    UseBalance=false;
extern bool    UseEquity=true;
extern double  EmergencyStopLossPercentageOfBalance=0;//Percentage of the account to use as an emergency stop loss. Zero to disable
extern double  PartialEmergencyStopLossPercentOfBalance=20;//Close the worst performing trade when DD reaches this level.
extern bool    TradeLong=true;
extern bool    TradeShort=true;
extern bool    StopTrading=false;
extern int     MagicNumber=0;
extern string  TradeComment="RnR";
extern bool    IsGlobalPrimeOrECNCriminal=false;
extern double  MaxSlippagePips=5;
//We need more safety to combat the cretins at Crapperquotes managing to break Matt's OR code occasionally.
//EA will make no further attempt to trade for PostTradeAttemptWaitMinutes minutes, whether OR detects a receipt return or not.
extern int     PostTradeAttemptWaitSeconds=30;
////////////////////////////////////////////////////////////////////////////////////////
double         EmergencyStopLoss=0;//Hold the calculation of the sl based on EmergencyStopLossPercentageOfBalance
double         PartialEmergencyStopLoss=0;////Hold the calculation of the sl based on PartialEmergencyStopLossPercentageOfBalance
datetime       TimeToStartTrading=0;//Re-start calling LookForTradingOpportunities() at this time.
double         TakeProfit, StopLoss;
datetime       OldBarsTime;
double         dPriceFloor = 0, dPriceCeiling = 0;//Next x0 numbers
double         PriceCeiling100 = 0, PriceFloor100 = 0;// Next 'big' numbers
string         GvName="Under management flag";//The name of the GV that tells the EA not to send trades whilst the manager is closing them.
string         TradingTimeFrameDisplay="";
//For FIFO
int            FifoTicket[];//Array to store trade ticket numbers in FIFO mode, to cater for
                            //US citizens and to make iterating through the trade closure loop 
                            //quicker.

double         GridOrderBuyTickets[][2]; // number of lines will be equal to MarketBuysOpen - 1
double         GridOrderSellTickets[][2];
//An array to store ticket numbers of trades that need closing, should an offsetting OrderClose fail
double         ForceCloseTickets[];


extern string  sep1b="================================================================";
extern string  gri="---- Grid inputs ----";
extern int     DistanceBetweenTradesPips=5;
extern color   BaseLineColour=Yellow;
////////////////////////////////////////////////////////////////////////////////////////
double         DistanceBetweenTrades=0;
int            GridTradesTotal=0;//Total of market, stop and limit trades
int            PendingTradesTotal=0;//Total of stop and limit trades
int            MarketTradesTotal=0;//Total of open market trades
bool           GridSent=false;//true if CountOpenTrades finds a trade
bool           Hedged=true;//Set to true if there are both market buys and sells open,
                            //to prevent closure on an opposite direction signal. Initialised
                            //as true to avoid closure first time around CountOpenTrades
string         BaseLineName=baseline;
double         BaseLinePrice=0;//The value of the base line defined by BaseLineName
////////////////////////////////////////////////////////////////////////////////////////

extern string  sep1c="================================================================";
extern string  btp="---- Basket take profits. Zero value to disable. ----";
extern int     HedgedBasketPips=50;
extern int     ClearBasketPips=100;
////////////////////////////////////////////////////////////////////////////////////////
double         HedgedBasket=0, ClearBasket=0;
////////////////////////////////////////////////////////////////////////////////////////

extern string  sep1i="================================================================";
extern string  off="---- Offsetting ----";
bool    UseOffsetting=true;//Simple offset and double-sided complex offset
extern bool    AllowComplexSingleSidedOffsets=true;//Allow complex single-sided offset. Not allowed if UseOffsetting = false
extern int     MinOpenTradesToStartOffset=4;//Only use offsetting if there are at least this number of trades in the group

extern string  sep1j="================================================================";
extern string  tjf="---- TraderJoeForex hedging ----";
extern bool    UseTJF=true;
extern int     MinimumTradesToCauseImBalance=30;
extern string  hgi="-- HGI Inputs --"; 
extern string  HGI_Name="HGI_v16.05";
extern int     HgiReadDelaySeconds=60;//cpu saver. Read the indi every minute by default
extern ENUM_TIMEFRAMES HgiTimeFrame=PERIOD_H4;//Defaults to current chart
extern bool    HedgeOnTrendArrow=true;
extern bool    HedgeOnBlueWavy=true;
extern bool    CloseHedgeOnYellowWave=true;
extern bool    OffsetLosersWhenClosingHedge=true;
////////////////////////////////////////////////////////////////////////////////////////
datetime       NextReadTime=0;//Time the indi will next be read
bool           RemoveExpert=false;
double         TotalBuyLots=0, TotalSellLots=0;
bool           TjfHedgeOpen=false;
int            TjfTicketNo=0;
string         HgiStatus="";
////////////////////////////////////////////////////////////////////////////////////////

extern string  sep1h="================================================================";
extern string  si="---- Sixths ----";
extern bool    UseSixths=true;
extern ENUM_TIMEFRAMES SixthTimeFrame=PERIOD_M5;
extern int     BarCount=120;
extern int     ClosureDistancePips=10;
////////////////////////////////////////////////////////////////////////////////////////
double         SixthLineVal[8];//Will use 1 to seven. Bottom line is 1.
double         SixthsHigh=0;
double         SixthsLow=0;
double         SixthsVal=0;
double         SixthsHeight=0;
double         ClosureDistance=0;
string         IndiPrefix = "Indi-Sixth for EA";
////////////////////////////////////////////////////////////////////////////////////////

extern string  sep1d="================================================================";
extern string  sfs="----SafetyFeature----";
//Safety feature. Sometimes an unexpected concatenation of inputs choice and logic error can cause rapid opening-closing of trades. Use the next input 
//in combination with TooClose() to abort the trade if the previous one closed within the time limit.
extern int     MinMinutesBetweenTradeOpenClose=1;//For spotting possible rogue trades
extern int     MinMinutesBetweenTrades=1;//Minimum time to pass after a trade closes, until the ea can open another.
////////////////////////////////////////////////////////////////////////////////////////
bool           SafetyViolation;//For chart display
bool           RobotSuspended=false;
////////////////////////////////////////////////////////////////////////////////////////

extern string  sep7="================================================================";
//CheckTradingTimes. Baluda has provided all the code for this. Mny thanks Paul; you are a star.
extern string  trh            = "----Trading hours----";
extern string  tr1            = "tradingHours is a comma delimited list";
extern string  tr1a="of start and stop times.";
extern string  tr2="Prefix start with '+', stop with '-'";
extern string  tr2a="Use 24H format, local time.";
extern string  tr3="Example: '+07.00,-10.30,+14.15,-16.00'";
extern string  tr3a="Do not leave spaces";
extern string  tr4="Blank input means 24 hour trading.";
extern string  tradingHours="";
////////////////////////////////////////////////////////////////////////////////////////
double         TradeTimeOn[];
double         TradeTimeOff[];
// trading hours variables
int            tradeHours[];
string         tradingHoursDisplay;//tradingHours is reduced to "" on initTradingHours, so this variable saves it for screen display.
bool           TradeTimeOk;
////////////////////////////////////////////////////////////////////////////////////////

extern string  sep1de="================================================================";
extern string  fssmt="---- Inputs applied to individual days ----";
extern int     FridayStopTradingHour=24;//Ignore signals at and after this time on Friday.
                                        //Local time input. >23 to disable.
extern int     SaturdayStopTradingHour=24;//For those in Upside Down Land.  
extern bool    TradeSundayCandle=true;
extern int     MondayStartHour=0;//24h local time     
extern bool    TradeThursdayCandle=true;//Thursday tends to be a reversal day, so avoid it.                               

extern string  sep11="================================================================";
extern string  asi="----Average spread inputs----";
extern bool    RunInSpreadDetectionMode=false;
extern int     TicksToCount=5;//The ticks to count whilst canculating the av spread
extern double  MultiplierToDetectStopHunt=10;
////////////////////////////////////////////////////////////////////////////////////////
double         AverageSpread=0;
string         SpreadGvName;//A GV will hold the calculated average spread
int            CountedTicks=0;//For status display whilst calculating the spread
double         BiggestSpread=0;//Holds a record of the widest spread since the EA was loaded
////////////////////////////////////////////////////////////////////////////////////////

extern string  sep11a="================================================================";
extern string  ccs="---- Chart snapshots ----";
extern bool    TakeSnapshots=false;//Tells ea to take snaps when it opens and closes a trade
extern int     PictureWidth=800;
extern int     PictureHeight=600;

//Enhanced screen feedback display code provided by Paul Batchelor (lifesys). Thanks Paul; this is fantastic.
extern string  se52  ="================================================================";
extern string  oad               ="----Odds and ends----";
extern int     ChartRefreshDelaySeconds=0;
extern int     DisplayGapSize    = 30; // if using Comments
// ****************************** added to make screen Text more readable
extern bool    DisplayAsText     = true;  // replaces Comment() with OBJ_LABEL text
extern bool    KeepTextOnTop     = true;//Disable the chart in foreground CrapTx setting so the candles do not obscure the text
extern int     DisplayX          = 100;
extern int     DisplayY          = 0;
extern int     fontSise          = 10;
extern string  fontName          = "Arial";
extern color    colour            = Yellow;
extern double  spacingtweek      = 0.6; // adjustment to reform lines for different font size
////////////////////////////////////////////////////////////////////////////////////////
int            DisplayCount;
string         Gap,ScreenMessage;
////////////////////////////////////////////////////////////////////////////////////////
//  *****************************

//Calculating the factor needed to turn pip values into their correct points value to accommodate different Digit size.
//Thanks to Lifesys for providing this code. Coders, you need to briefly turn of Wrap and turn on a mono-spaced font to view this properly and see how easy it is to make changes.
string         pipFactor[]  = {"JPY","XAG","SILVER","BRENT","WTI","XAU","GOLD","SP500","S&P","UK100","WS30","DAX30","DJ30","NAS100","CAC400"};
double         pipFactors[] = { 100,  100,  100,     100,    100,  10,   10,    10,     10,   1,      1,     1,      1,     1,       1};
double         factor;//For pips/points stuff. Set up in int init()
////////////////////////////////////////////////////////////////////////////////////////

//Matt's O-R stuff
int            O_R_Setting_max_retries=10;
double         O_R_Setting_sleep_time=4.0; /* seconds */
double         O_R_Setting_sleep_max=15.0; /* seconds */
int            RetryCount=10;//Will make this number of attempts to get around the trade context busy error.


//Variables for building a picture of the open position
//Market Buy trades
bool           BuyOpen=false;
int            MarketBuysCount=0;
double         LatestBuyPrice=0, EarliestBuyPrice=0, HighestBuyPrice=0, LowestBuyPrice=0;
int            BuyTicketNo=-1, HighestBuyTicketNo=-1, LowestBuyTicketNo=-1, LatestBuyTicketNo=-1, EarliestBuyTicketNo=-1;
double         BuyPipsUpl=0;
double         BuyCashUpl=0;
datetime       LatestBuyTradeTime=0;
datetime       EarliestBuyTradeTime=0;

//Market Sell trades
bool           SellOpen=false;
int            MarketSellsCount=0;
double         LatestSellPrice=0, EarliestSellPrice=0, HighestSellPrice=0, LowestSellPrice=0;
int            SellTicketNo=-1, HighestSellTicketNo=-1, LowestSellTicketNo=-1, LatestSellTicketNo=-1, EarliestSellTicketNo=-1;;
double         SellPipsUpl=0;
double         SellCashUpl=0;
datetime       LatestSellTradeTime=0;
datetime       EarliestSellTradeTime=0;

//BuyStop trades
bool           BuyStopOpen=false;
int            BuyStopsCount=0;
double         LatestBuyStopPrice=0, EarliestBuyStopPrice=0, HighestBuyStopPrice=0, LowestBuyStopPrice=0;
int            BuyStopTicketNo=-1, HighestBuyStopTicketNo=-1, LowestBuyStopTicketNo=-1, LatestBuyStopTicketNo=-1, EarliestBuyStopTicketNo=-1;;
datetime       LatestBuyStopTradeTime=0;
datetime       EarliestBuyStopTradeTime=0;

//BuyLimit trades
bool           BuyLimitOpen=false;
int            BuyLimitsCount=0;
double         LatestBuyLimitPrice=0, EarliestBuyLimitPrice=0, HighestBuyLimitPrice=0, LowestBuyLimitPrice=0;
int            BuyLimitTicketNo=-1, HighestBuyLimitTicketNo=-1, LowestBuyLimitTicketNo=-1, LatestBuyLimitTicketNo=-1, EarliestBuyLimitTicketNo=-1;;
datetime       LatestBuyLimitTradeTime=0;
datetime       EarliestBuyLimitTradeTime=0;

/////SellStop trades
bool           SellStopOpen=false;
int            SellStopsCount=0;
double         LatestSellStopPrice=0, EarliestSellStopPrice=0, HighestSellStopPrice=0, LowestSellStopPrice=0;
int            SellStopTicketNo=-1, HighestSellStopTicketNo=-1, LowestSellStopTicketNo=-1, LatestSellStopTicketNo=-1, EarliestSellStopTicketNo=-1;;
datetime       LatestSellStopTradeTime=0;
datetime       EarliestSellStopTradeTime=0;

//SellLimit trades
bool           SellLimitOpen=false;
int            SellLimitsCount=0;
double         LatestSellLimitPrice=0, EarliestSellLimitPrice=0, HighestSellLimitPrice=0, LowestSellLimitPrice=0;
int            SellLimitTicketNo=-1, HighestSellLimitTicketNo=-1, LowestSellLimitTicketNo=-1, LatestSellLimitTicketNo=-1, EarliestSellLimitTicketNo=-1;;
datetime       LatestSellLimitTradeTime=0;
datetime       EarliestSellLimitTradeTime=0;

//Not related to specific order types
int            TicketNo=-1,OpenTrades,OldOpenTrades;
//Variables to tell the ea that it has a trading signal
bool           BuySignal=false, SellSignal=false;
//Variables to tell the ea that it has a trading closure signal
bool           BuyCloseSignal=false, SellCloseSignal=false;
//Variables for storing market trade ticket numbers
datetime       LatestTradeTime=0, EarliestTradeTime=0;//More specific times are in each individual section
int            LatestTradeTicketNo=-1, EarliestTradeTicketNo=-1;
double         PipsUpl;//For keeping track of the pips PipsUpl of multi-trade/hedged positions
double         CashUpl;//For keeping track of the cash PipsUpl of multi-trade/hedged positions
//Variable for the hedging code to tell if there are tp's and sl's set
bool           TpSet=false, SlSet=false;
////////////////////////////////////////////////////////////////////////////////////////



//Running total of trades
int            LossTrades,WinTrades;
double         OverallProfit;

//Misc
int            OldBars;
string         PipDescription=" pips";
bool           ForceTradeClosure;
int            TurnOff=0;//For turning off functions without removing their code
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void DisplayUserFeedback()
{

   if(IsTesting() && !IsVisualMode()) return;

   string text = "";
   int cc = 0;

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
   
   SM("Updates for this EA are to be found at http://www.stevehopwoodforex.com"+NL);
   SM("Feeling generous? Help keep the coder going with a small Paypal donation to pianodoodler@hotmail.com"+NL);
   SM("Broker time = "+TimeToStr(TimeCurrent(),TIME_DATE|TIME_SECONDS)+": Local time = "+TimeToStr(TimeLocal(),TIME_DATE|TIME_SECONDS)+NL);
   SM(version+NL);
/*
   //Code for time to bar-end display donated by Baluda. Cheers Paul.
   SM( TimeToString( iTime(Symbol(), TradingTimeFrame, 0) + TradingTimeFrame * 60 - CurTime(), TIME_MINUTES|TIME_SECONDS ) 
   + " left to bar end" + NL );
  */
   
   SM(NL);
   if(SafetyViolation) SM("*************** CANNOT TRADE YET. TOO SOON AFTER CLOSE OF PREVIOUS TRADE***************"+NL);

   if(!TradeTimeOk)
   {
      SM(NL);
      SM("----------OUTSIDE TRADING HOURS. Will continue to monitor opent trades.----------"+NL+NL);
   }//if (!TradeTimeOk)

   SM(NL);
   
   SM("Distance between trades = " + DoubleToStr(DistanceBetweenTrades, 0) + " pips" + NL);
   SM("Base line price = " + DoubleToStr(BaseLinePrice, Digits) + NL);
   if (!CloseEnough(EmergencyStopLoss, 0))
      SM("Emergency cash stop loss = " + DoubleToStr(EmergencyStopLoss, 2) + NL);
   if (!CloseEnough(PartialEmergencyStopLossPercentOfBalance, 0))
      SM("Partial emergency cash stop loss = " + DoubleToStr(PartialEmergencyStopLoss, 2) + NL);
   
   
   SM(NL);     
   text = "Market trades open = ";
   if (Hedged)
   {
      text = "Hedged position. Market trades open = ";
   }
   SM(text + IntegerToString(MarketTradesTotal) + ": Pips UPL = " + DoubleToStr(PipsUpl, 0)
   +  ": Cash UPL = " + DoubleToStr(CashUpl, 2) + NL);
   if (BuyOpen)
   {
      SM("Buy trades = " + IntegerToString(MarketBuysCount)
         + ": Pips upl = " + IntegerToString(BuyPipsUpl)
         + ": Cash upl = " + DoubleToStr(BuyCashUpl, 2)
         + NL);
   
      /*for (cc = MarketBuysCount - 1; cc >= 0; cc--)
      {
         SM("      Time sent " + TimeToStr(FifoBuyTicket[cc][TradeOpenTime], TIME_MINUTES) 
         + ": " + IntegerToString(FifoBuyTicket[cc][TradeTicket])
         + ": Cash profit " + DoubleToStr(FifoBuyTicket[cc][TradeProfitCash], 2)
         + ": Pips profit " + DoubleToStr(FifoBuyTicket[cc][TradeProfitPips], 2)
         + NL);
      }//for (cc = MarketBuysCount - 1; cc >= 0; cc--)*/
   }//if (BuyOpen)
   
   if (SellOpen)
   {
      SM("Sell trades = " + IntegerToString(MarketSellsCount)
         + ": Pips upl = " + IntegerToString(SellPipsUpl)
         + ": Cash upl = " + DoubleToStr(SellCashUpl,2)
         + NL);
      
      /*for (cc = MarketSellsCount - 1; cc >= 0; cc--)
      {
         SM("      Time sent " + TimeToStr(FifoSellTicket[cc][TradeOpenTime], TIME_MINUTES) 
         + ": " + IntegerToString(FifoSellTicket[cc][TradeTicket])
         + ": Cash profit " + DoubleToStr(FifoSellTicket[cc][TradeProfitCash], 2)
         + ": Pips profit " + DoubleToStr(FifoSellTicket[cc][TradeProfitPips], 2)
         + NL);
      }//for (cc = MarketSellsCount - 1; cc >= 0; cc--)*/
   }//if (SellOpen)
   
   if (UseTJF)
      if (Hedged)
      {
         SM("HGI status: " + HgiStatus + NL);
      }
      
   if (TjfHedgeOpen)
   {
      SM("There is a defensive hedge open." + NL);
   }//if (TjfHedgeOpen)
   
   
   SM(NL);
   SM("Lot size: "+DoubleToStr(Lot,2)+" (Criminal's minimum lot size: "+DoubleToStr(MarketInfo(Symbol(),MODE_MINLOT),2)+")"+NL);
   if(TradeLong) SM("Taking long trades"+NL);
   if(TradeShort) SM("Taking short trades"+NL);
   if(!CloseEnough(TakeProfit,0)) SM("Take profit: "+DoubleToStr(TakeProfit,0)+PipDescription+NL);
   if(!CloseEnough(StopLoss,0)) SM("Stop loss: "+DoubleToStr(StopLoss,0)+PipDescription+NL);
   SM("Magic number: "+IntegerToString(MagicNumber)+NL);
   SM("Trade comment: "+TradeComment+NL);
   if(IsGlobalPrimeOrECNCriminal) SM("IsGlobalPrimeOrECNCriminal = true"+NL);
   else SM("IsGlobalPrimeOrECNCriminal = false"+NL);
   double spread=(Ask-Bid)*factor;
   SM("Average Spread = "+DoubleToStr(AverageSpread,1)+": Spread = "+DoubleToStr(spread,1)+": Widest since loading = "+DoubleToStr(BiggestSpread,1)+NL);
   SM(NL);

   //Trading hours
   if(tradingHoursDisplay!="") SM("Trading hours: "+tradingHoursDisplay+NL);
   else SM("24 hour trading: "+NL);

   
   //Running total of trades
   SM(Gap+NL);
   SM("Results today. Wins: "+IntegerToString(WinTrades)+": Losses "+IntegerToString(LossTrades)+": P/L "+DoubleToStr(OverallProfit,2)+NL);

   SM(NL);

     
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
//| expert initialization function                                   |
//+------------------------------------------------------------------+
int OnInit()
{
//----

   //Mindless dimwit check
   if (UseTJF)
      if (!indiExists( HGI_Name ))
      {
         Alert("The required indicator " + HGI_Name + " does not exist on your platform. I am removing myself from your chart.");
         RemoveExpert = true;
         ExpertRemove();
         return(0);
      }//if (! indiExists( "wanker" ))

   DeleteSixthsLines();


//~ Set up the pips factor. tp and sl etc.
//~ The EA uses doubles and assume the value of the integer user inputs. This: 
//~    1) minimises the danger of the inputs becoming corrupted by restarts; 
//~    2) the integer inputs cannot be divided by factor - doing so results in zero.

   factor=PFactor(Symbol());
   DistanceBetweenTrades = DistanceBetweenTradesPips;
   HedgedBasket = HedgedBasketPips;
   ClearBasket = ClearBasketPips;
   ClosureDistance = ClosureDistancePips;
   
   //Calculate the emergency stop loss
   if (!CloseEnough(EmergencyStopLossPercentageOfBalance, 0))
   {
      EmergencyStopLoss = AccountBalance() * (EmergencyStopLossPercentageOfBalance / 100);
      if (EmergencyStopLoss > 0)//It should be but I like to make sure of stuff like this
         EmergencyStopLoss*= -1;
   }//if (!CloseEnough(EmergencyStopLossPercentageOfBalance, 0))
   
   //Calculate the partial emergency stop loss. Bruster again. Thanks fella.
   if (!CloseEnough(PartialEmergencyStopLossPercentOfBalance, 0))
   {
      PartialEmergencyStopLoss = AccountBalance() * (PartialEmergencyStopLossPercentOfBalance / 100);
      if (PartialEmergencyStopLoss > 0)//It should be but I like to make sure of stuff like this
         PartialEmergencyStopLoss*= -1;
   }//if (!CloseEnough(PartialEmergencyStopLossPercentOfBalance, 0))
   
   
   while(IsConnected()==false)
   {
      Comment("Waiting for MT4 connection...");
      Comment("");

      Sleep(1000);
   }//while (IsConnected()==false)

   
/*
   //check Partial close parameters
   if (PartCloseEnabled == true)
   {
      if (Lot < Close_Lots + Preserve_Lots || Lot < MarketInfo(Symbol(), MODE_MINLOT) + Close_Lots )
      {
         Alert(Symbol()+" PartCloseEnabled is disabled because Lot < Close_Lots + Preserve_Lots or Lot < MarketInfo(Symbol(), MODE_MINLOT) + Close_Lots !");
         PartCloseEnabled = false;
      }//if (Lot < Close_Lots + Preserve_Lots || Lot < MarketInfo(Symbol(), MODE_MINLOT) + Close_Lots )
   }//if (PartCloseEnabled == true)
   */


   
   Gap="";
   if (DisplayGapSize >0)
   {
      for (int cc=0; cc< DisplayGapSize; cc++)
      {
         Gap = StringConcatenate(Gap, " ");
      }   
   }//if (DisplayGapSize >0)

   //Reset CriminIsECN if crim is IBFX and the punter does not know or, like me, keeps on forgetting
   string name= TerminalCompany();
   int ispart = StringFind(name,"IBFX",0);
   if(ispart<0) ispart=StringFind(name,"Interbank FX",0);
   if(ispart>-1) IsGlobalPrimeOrECNCriminal=true;
   ispart=StringFind(name,"Global Prime",0);
   if(ispart>-1) IsGlobalPrimeOrECNCriminal=true;

   //Set up the trading hours
   tradingHoursDisplay=tradingHours;//For display
   initTradingHours();//Sets up the trading hours array

   if(TradeComment=="") TradeComment=" ";
   OldBars=Bars;
   TicketNo=-1;
   CountOpenTrades();
   OldOpenTrades=OpenTrades;
   TradeTimeOk=CheckTradingTimes();
   
   //Lot size based on account size
   if (OpenTrades == 0)
      if (!CloseEnough(LotsPerDollopOfCash, 0))
         CalculateLotAsAmountPerCashDollops();

   
   //The apread global variable
   if (!IsTesting() )
   {
      SpreadGvName=Symbol()+" average spread";
      AverageSpread=GlobalVariableGet(SpreadGvName);//If no gv, then the value will be left at zero.
   }//if (!IsTesting() )
   
   //Chart display
   if (DisplayAsText)
      if (KeepTextOnTop)
         ChartForegroundSet(false,0);// change chart to background
   
   
   ReadOrCreateBaseLine();
   
   DisplayUserFeedback();


   //Call sq's show trades indi
   //iCustom(NULL, 0, "SQ_showTrades",Magic, 0,0);


//----
   return(0);
}
//+------------------------------------------------------------------+
//| expert deinitialization function                                 |
//+------------------------------------------------------------------+
void OnDeinit(const int reason)
{
//----
   Comment("");
   removeAllObjects();
   DeleteSixthsLines();
   
   ObjectDelete(BaseLineName);
//----
   return;
}

bool indiExists( string indiName ) 
{

   //Returns true if a custom indi exists in the user's indi folder, else false
   bool exists = false;
   
   ResetLastError();
   double value = iCustom( Symbol(), Period(), indiName, 0, 0 );
   if ( GetLastError() == 0 ) exists = true;
   
   return(exists);

}//End bool indiExists( string indiName ) 

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
bool SendSingleTrade(string symbol,int type,string comment,double lotsize,double price,double stop,double take)
{
//pah (Paul) contributed the code to get around the trade context busy error. Many thanks, Paul.

   double slippage=MaxSlippagePips*MathPow(10,Digits)/PFactor(Symbol());
   int ticket = -1;

   color col=Red;
   if(type==OP_BUY || type==OP_BUYSTOP || type == OP_BUYLIMIT) col=Green;

   datetime expiry=0;
   //if (SendPendingTrades) expiry = TimeCurrent() + (PendingExpiryMinutes * 60);

   //RetryCount is declared as 10 in the Trading variables section at the top of this file
   for(int cc=0; cc<RetryCount; cc++)
     {
      //for (int d = 0; (d < RetryCount) && IsTradeContextBusy(); d++) Sleep(100);

      while(IsTradeContextBusy()) Sleep(100);//Put here so that excess slippage will cancel the trade if the ea has to wait for some time.
      
      RefreshRates();
      if(type == OP_BUY) price = MarketInfo(symbol, MODE_ASK);
      if(type == OP_SELL) price = MarketInfo(symbol, MODE_BID);

      
      if(!IsGlobalPrimeOrECNCriminal) 
         ticket=OrderSend(symbol,type,lotsize,price,slippage,stop,take,comment,MagicNumber,expiry,col);

      //Is a 2 stage criminal
      if(IsGlobalPrimeOrECNCriminal)
      {
         ticket=OrderSend(symbol,type,lotsize,price,slippage,0,0,comment,MagicNumber,expiry,col);
         if(ticket>-1)
         {
            ModifyOrderTpSl(ticket,stop,take);
         }//if (ticket > 0)}
      }//if (IsGlobalPrimeOrECNCriminal)

      if(ticket>-1) break;//Exit the trade send loop
      if(cc == RetryCount - 1) return(false);

      //Error trapping for both
      if(ticket<0)
        {
         string stype;
         if(type == OP_BUY) stype = "OP_BUY";
         if(type == OP_SELL) stype = "OP_SELL";
         if(type == OP_BUYLIMIT) stype = "OP_BUYLIMIT";
         if(type == OP_SELLLIMIT) stype = "OP_SELLLIMIT";
         if(type == OP_BUYSTOP) stype = "OP_BUYSTOP";
         if(type == OP_SELLSTOP) stype = "OP_SELLSTOP";
         int err=GetLastError();
         Alert(symbol," ",WindowExpertName()," ",stype," order send failed with error(",err,"): ",ErrorDescription(err));
         Print(symbol," ",WindowExpertName()," ",stype," order send failed with error(",err,"): ",ErrorDescription(err));
         return(false);
        }//if (ticket < 0)  
     }//for (int cc = 0; cc < RetryCount; cc++);

   TicketNo=ticket;
   //Make sure the trade has appeared in the platform's history to avoid duplicate trades.
   //My mod of Matt's code attempts to overcome the bastard crim's attempts to overcome Matt's code.
   bool TradeReturnedFromCriminal=false;
   while(!TradeReturnedFromCriminal)
     {
      TradeReturnedFromCriminal=O_R_CheckForHistory(ticket);
      if(!TradeReturnedFromCriminal)
        {
         Alert(Symbol()," sent trade not in your trade history yet. Turn of this ea NOW.");
        }//if (!TradeReturnedFromCriminal)
     }//while (!TradeReturnedFromCriminal)

   //Got this far, so trade send succeeded
   return(true);

}//End bool SendSingleTrade(int type, string comment, double lotsize, double price, double stop, double take)
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void ModifyOrderTpSl(int ticket, double stop, double take)
{
   //Modifies an order already sent if the crim is ECN.

   if (CloseEnough(stop, 0) && CloseEnough(take, 0) ) return; //nothing to do

   if (!OrderSelect(ticket, SELECT_BY_TICKET) ) return;//Trade does not exist, so no mod needed
   
   if (OrderCloseTime() > 0) return;//Somehow, we are examining a closed trade
   
   //In case some errant behaviour/code creates a tp the wrong side of the market, which would cause an instant close.
   if (OrderType() == OP_BUY && take < OrderOpenPrice() && !CloseEnough(take, 0) ) 
   {
      take = 0;
      ReportError(" ModifyOrder()", " take profit < market ");
   }//if (OrderType() == OP_BUY && take < OrderOpenPrice() ) 
   
   if (OrderType() == OP_SELL && take > OrderOpenPrice() ) 
   {
      take = 0;
      ReportError(" ModifyOrder()", " take profit < market ");
   }//if (OrderType() == OP_SELL && take > OrderOpenPrice() ) 
   
   //In case some errant behaviour/code creates a sl the wrong side of the market, which would cause an instant close.
   if (OrderType() == OP_BUY && stop > OrderOpenPrice() ) 
   {
      stop = 0;
      ReportError(" ModifyOrder()", " stop loss > market ");
   }//if (OrderType() == OP_BUY && take < OrderOpenPrice() ) 
   
   if (OrderType() == OP_SELL && stop < OrderOpenPrice()  && !CloseEnough(stop, 0) ) 
   {
      stop = 0;
      ReportError(" ModifyOrder()", " stop loss < market ");
   }//if (OrderType() == OP_SELL && take > OrderOpenPrice() ) 
   
   string Reason;
   //RetryCount is declared as 10 in the Trading variables section at the top of this file   
   for (int cc = 0; cc < RetryCount; cc++)
   {
      for (int d = 0; (d < RetryCount) && IsTradeContextBusy(); d++) Sleep(100);
        if (!CloseEnough(take, 0) && !CloseEnough(stop, 0) )
        {
           while(IsTradeContextBusy()) Sleep(100);
           if (ModifyOrder(ticket, OrderOpenPrice(), stop, take, OrderExpiration(), clrNONE, __FUNCTION__, tpsl)) return;
        }//if (take > 0 && stop > 0)
   
        if (!CloseEnough(take, 0) && CloseEnough(stop, 0))
        {
           while(IsTradeContextBusy()) Sleep(100);
           if (ModifyOrder(ticket, OrderOpenPrice(), OrderStopLoss(), take, OrderExpiration(), clrNONE, __FUNCTION__, tpm)) return;
        }//if (take == 0 && stop != 0)

        if (CloseEnough(take, 0) && !CloseEnough(stop, 0))
        {
           while(IsTradeContextBusy()) Sleep(100);
           if (ModifyOrder(ticket, OrderOpenPrice(), stop, OrderTakeProfit(), OrderExpiration(), clrNONE, __FUNCTION__, slm)) return;
        }//if (take == 0 && stop != 0)
   }//for (int cc = 0; cc < RetryCount; cc++)
   
   
   
}//void ModifyOrderTpSl(int ticket, double tp, double sl)

//=============================================================================
//                           O_R_CheckForHistory()
//
//  This function is to work around a very annoying and dangerous bug in MT4:
//      immediately after you send a trade, the trade may NOT show up in the
//      order history, even though it exists according to ticket number.
//      As a result, EA's which count history to check for trade entries
//      may give many multiple entries, possibly blowing your account!
//
//  This function will take a ticket number and loop until
//  it is seen in the history.
//
//  RETURN VALUE:
//     TRUE if successful, FALSE otherwise
//
//
//  FEATURES:
//     * Re-trying under some error conditions, sleeping a random
//       time defined by an exponential probability distribution.
//
//     * Displays various error messages on the log for debugging.
//
//  ORIGINAL AUTHOR AND DATE:
//     Matt Kennel, 2010
//
//=============================================================================
bool O_R_CheckForHistory(int ticket)
  {
//My thanks to Matt for this code. He also has the undying gratitude of all users of my trading robots

   int lastTicket=OrderTicket();

   int cnt =0;
   int err=GetLastError(); // so we clear the global variable.
   err=0;
   bool exit_loop=false;
   bool success=false;
   int c = 0;

   while(!exit_loop) 
     {
/* loop through open trades */
      int total=OrdersTotal();
      for(c=0; c<total; c++) 
        {
         if(OrderSelect(c,SELECT_BY_POS,MODE_TRADES)==true) 
           {
            if(OrderTicket()==ticket) 
              {
               success=true;
               exit_loop=true;
              }
           }
        }
      if(cnt>3) 
        {
/* look through history too, as order may have opened and closed immediately */
         total=OrdersHistoryTotal();
         for(c=0; c<total; c++) 
           {
            if(OrderSelect(c,SELECT_BY_POS,MODE_HISTORY)==true) 
              {
               if(OrderTicket()==ticket) 
                 {
                  success=true;
                  exit_loop=true;
                 }
              }
           }
        }

      cnt=cnt+1;
      if(cnt>O_R_Setting_max_retries) 
        {
         exit_loop=true;
        }
      if(!(success || exit_loop)) 
        {
         Print("Did not find #"+ticket+" in history, sleeping, then doing retry #"+cnt);
         O_R_Sleep(O_R_Setting_sleep_time,O_R_Setting_sleep_max);
        }
     }
// Select back the prior ticket num in case caller was using it.
   if(lastTicket>=0) 
     {
      bool s = OrderSelect(lastTicket,SELECT_BY_TICKET,MODE_TRADES);
     }
   if(!success) 
     {
      Print("Never found #"+ticket+" in history! crap!");
     }
   return(success);
  }//End bool O_R_CheckForHistory(int ticket)
//=============================================================================
//                              O_R_Sleep()
//
//  This sleeps a random amount of time defined by an exponential
//  probability distribution. The mean time, in Seconds is given
//  in 'mean_time'.
//  This returns immediately if we are backtesting
//  and does not sleep.
//
//=============================================================================
void O_R_Sleep(double mean_time, double max_time)
{
   if (IsTesting()) 
   {
      return;   // return immediately if backtesting.
   }

   double p = (MathRand()+1) / 32768.0;
   double t = -MathLog(p)*mean_time;
   t = MathMin(t,max_time);
   int ms = t*1000;
   if (ms < 10) {
      ms=10;
   }//if (ms < 10) {
   
   Sleep(ms);
}//End void O_R_Sleep(double mean_time, double max_time)

////////////////////////////////////////////////////////////////////////////////////////

bool IsTradingAllowed()
{
   //Returns false if any of the filters should cancel trading, else returns true to allow trading

   //Maximum spread
   if(!IsTesting())
   {
      double spread=(Ask-Bid)*factor;
      if(spread > AverageSpread * MultiplierToDetectStopHunt) return(false);
   }//if (!IsTesting )



   
   return(true);


}//End bool IsTradingAllowed()

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
bool AtNewBuyLevel()
{
   double Buy_Gap = MathAbs(Ask - BaseLinePrice); // buy a
   double Distance = (DistanceBetweenTrades/factor); //b
   int Buy_Int_Only = Buy_Gap/Distance;
   
   //double Residue = MathAbs(a-(intonly*b));
   double Buy_Residue = MathAbs(MathMod(Buy_Gap,Distance));
   
   if(Buy_Residue >= 0 && Buy_Residue <= 0.1/factor)return (true); // will have to refine the variance for "close enough"
  // if(Buy_Residue == 0) // will have to refine the variance
     
   return(false);
}

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
bool AtNewSellLevel()
{
   double Sell_Gap = MathAbs(Bid - BaseLinePrice); // sell a
   double Distance = (DistanceBetweenTrades/factor); //b
   int Sell_Int_Only = Sell_Gap/Distance;
   
   //double Residue = MathAbs(a-(intonly*b));
   double Sell_Residue = MathAbs(MathMod(Sell_Gap,Distance));
     
   if(Sell_Residue >= 0 && Sell_Residue <= 0.1/factor)return (true);// will have to refine the variance
  // if(Sell_Residue == 0)// will have to refine the variance
   
   return(false);
}

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
bool NoBuyTradesAtThisLevel()
{

   // scan open buy and sell trades to see if their open price is near to this level
   double Distance = (DistanceBetweenTrades/factor);
   
   for (int cc = OrdersTotal() - 1; cc >= 0; cc--)
      {
         if (!OrderSelect(cc,SELECT_BY_POS,MODE_TRADES) ) continue;
         if (OrderSymbol() != Symbol() ) continue;
         if (OrderMagicNumber() != MagicNumber) continue;
         if(OrderType()!=OP_BUY) continue;
           
         if(OrderType()==OP_BUY)
         {
            if(MathAbs((Ask-OrderOpenPrice())) > (Distance*0.5))
            {continue;} // order is further away than 0.5*Distance
              else {return(false);} // there is a buy trade at this level
         }
      }//for (int cc = OrdersTotal() - 1; cc >= 0; cc--)   
   return (true); // No buy trades at this level
}
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+

bool NoSellTradesAtThisLevel()
{

   // scan open buy and sell trades to see if their open price is near to this level
   double Distance = (DistanceBetweenTrades/factor);
   
   for (int cc = OrdersTotal() - 1; cc >= 0; cc--)
      {
         if (!OrderSelect(cc,SELECT_BY_POS,MODE_TRADES) ) continue;
         if (OrderSymbol() != Symbol() ) continue;
         if (OrderMagicNumber() != MagicNumber) continue;
         if(OrderType()!=OP_SELL) continue;
         
         if(OrderType()==OP_SELL)
         {
            if(MathAbs((OrderOpenPrice()- Bid)) > (Distance*0.5))
            {continue;} // order is further away than 0.5*Distance
              else {return(false);}
         }
      }//for (int cc = OrdersTotal() - 1; cc >= 0; cc--)   
   return (true);
}

void GetLosingTradesTickets(int type, double profit)
{
   //This function is called when the ea closes a defensive hedge.
   //It offsets losers on the other side against the winning hedge,
   //assuming it is profitable.

   ArrayResize(ForceCloseTickets, 0);
   double CashLoss = 0;
   int NoOfTrades = 0;
   double ThisOrderProfit = 0;
   bool ClosePossible = false;
   ArrayInitialize(ForceCloseTickets, -1);
   double ThisTradeProfit = 0;
   int cc = 0;

   //The hedge is a buy
   if (type == OP_BUY)
   {
      for (cc = MarketSellsCount; cc > 0; cc--)
      {
         if (OrderSelect(GridOrderSellTickets[cc - 1][TradeTicket], SELECT_BY_TICKET, MODE_TRADES) )
         {
            ThisTradeProfit = (OrderSwap() + OrderCommission() + OrderProfit());
            if (ThisTradeProfit < 0)
               if (!CloseEnough(ThisTradeProfit, 0) )
               {
                  ThisTradeProfit*= -1;//Needs to be converted to a positive
                  if (CashLoss + ThisTradeProfit > profit)
                     break;//No need to go further   
                  NoOfTrades++;
                  ArrayResize(ForceCloseTickets, NoOfTrades);
                  ForceCloseTickets[NoOfTrades - 1] = OrderTicket();
                  CashLoss+= ThisTradeProfit;
               }//if (!CloseEnough(CashProfit, 0) )
         }//if (OrderSelect(GridOrderBuyTickets[cc - 1][TradeTicket], SELECT_BY_TICKET, MODE_TRADES) )
      }//for (int cc = MarketBuysCount; cc >= 0; cc--)
      
   }//if (type == OP_BUY)
   
   //The hedge is a sell
   if (type == OP_SELL)
   {
      for (cc = MarketBuysCount; cc > 0; cc--)
      {
         if (OrderSelect(GridOrderBuyTickets[cc - 1][TradeTicket], SELECT_BY_TICKET, MODE_TRADES) )
         {
            ThisTradeProfit = (OrderSwap() + OrderCommission() + OrderProfit());
            if (ThisTradeProfit < 0)
               if (!CloseEnough(ThisTradeProfit, 0) )
               {
                  ThisTradeProfit*= -1;//Needs to be converted to a positive
                  if (CashLoss + ThisTradeProfit > profit)
                     break;//No need to go further   
                  NoOfTrades++;
                  ArrayResize(ForceCloseTickets, NoOfTrades);
                  ForceCloseTickets[NoOfTrades - 1] = OrderTicket();
                  CashLoss+= ThisTradeProfit;
               }//if (!CloseEnough(CashProfit, 0) )
         }//if (OrderSelect(GridOrderBuyTickets[cc - 1][TradeTicket], SELECT_BY_TICKET, MODE_TRADES) )
      }//for (int cc = MarketBuysCount; cc >= 0; cc--)
      
   }//if (type == OP_SELL)
   
   
}//void GetLosingTradesTickets(int type)

bool LookForTradeClosure(int ticket)
{
   //In this ea, this function is only called if there is a defensive hedge in place.
   //Trades will close on an opposite HGI or optional wavy line. This decision
   //is taken within ReadIndicatorValues()
   
   
   if (!OrderSelect(ticket, SELECT_BY_TICKET) ) return(true);
   if (OrderSelect(ticket, SELECT_BY_TICKET) && OrderCloseTime() > 0) return(true);
   
   bool CloseThisTrade = false;
   bool TradeIsProfitable = false;
   double profit = (OrderSwap() + OrderCommission() + OrderProfit() > 0);
   if (profit > 0)   
      TradeIsProfitable = true;
   
   
   
   ///////////////////////////////////////////////////////////////////////////////////////////////////////////
   if (OrderType() == OP_BUY)
   {
         
      //Close trade on opposite direction signal
      if (BuyCloseSignal)
         CloseThisTrade = true;

               
   }//if (OrderType() == OP_BUY)
   
   
   ///////////////////////////////////////////////////////////////////////////////////////////////////////////
   if (OrderType() == OP_SELL)
   {
      
      //Close trade on opposite direction signal
      if (SellCloseSignal)
         CloseThisTrade = true;
      
   }//if (OrderType() == OP_SELL)
   
   ///////////////////////////////////////////////////////////////////////////////////////////////////////////
   if (CloseThisTrade)
   {
      bool result = false;
      
      if (OffsetLosersWhenClosingHedge)
         if (TradeIsProfitable)
            GetLosingTradesTickets(OrderType(), profit);
         
      result = CloseOrder(ticket);
      if (result)
      {
         if (OffsetLosersWhenClosingHedge)
            if (TradeIsProfitable)
               if (ArraySize(ForceCloseTickets) > 0)
                  MopUpTradeClosureFailures();//Use this function to close the appropriate trades
         return(true);
      }//if (result)
      
   }//if (CloseThisTrade)
   
   //Got this far, so no trade closure
   return(false);//Do not increment cc
   
}//End bool LookForTradeClosure()

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void LookForTradingOpportunities()
{

   RefreshRates();
   double take,stop,price;
   int type;
   string stype;//For the alert
   bool SendTrade=false,result=false;

   double SendLots=Lot;
   //Check filters
   if(!IsTradingAllowed() ) return;


/////////////////////////////////////////////////////////////////////////////////////

   //Trading decision.
   bool SendLong=false,SendShort=false;

   //Long trade

   //Specific system filters
   if (!CloseEnough(BaseLinePrice, 0))
   {
   
   
  
      //Bruster recoded the trading decision to enable filling in blank spaces in the grid
      //created by offsetting closures. Wonderful stuff Bruster. Thanks.
      if (AtNewBuyLevel() && Bid>BaseLinePrice)// we should consider a trade here; price is moving up and we're at a new level
      { 
         if(MarketTradesTotal==0)SendLong=true; // at a new level and there are no buys open
         
         if(NoBuyTradesAtThisLevel()) // no buy trades already at this level - but could be one or more above or below here
         {
            SendLong = true;        
         }//if(NoBuyTradesAtThisLevel())        
      }//if (AtNewBuyLevel() && Bid>BaseLinePrice)// we should consider a trade here; price is moving up and we're at a new level
      

   //Usual filters
   if(!SendLong)
   {
      
      //Bruster recoded the trading decision to enable filling in blank spaces in the grid
      //created by offsetting closures. Wonderful stuff Bruster. Thanks.
      if (AtNewSellLevel() && Ask<BaseLinePrice)// we should consider a trade here; price is moving down and we're at a new level
      { 
         if(MarketTradesTotal==0)SendShort=true;
         
         if(NoSellTradesAtThisLevel()) // no sell trades already at this level - but could be one or more above or below here
         {
            SendShort = true;
         }//if(NoSellTradesAtThisLevel())           
      }//if (AtNewSellLevel() && Ask<BaseLinePrice)  
         
   }//if (!SendLong)


//bruster400/END///////////////


}


////////////////////////////////////////////////////////////////////////////////////////

   //Long 
   if(SendLong)
   {

      //User choice of trade direction
      if(!TradeLong) return;

      stype =" Buy ";
      price=Ask;//Change this to whatever the price needs to be

      
      type=OP_BUY;
      SendTrade=true;

   }//if (SendLong)

   //Short
   if(SendShort)
   {
      //User choice of trade direction
      if(!TradeShort) return;

      stype =" Sell ";
      price=Bid;//Change this to whatever the price needs to be

      type=OP_SELL;
    
      SendTrade=true;

   }//if (SendShort)

   if(SendTrade)
   {
     
      result = SendSingleTrade(Symbol(),type,TradeComment,SendLots,price,stop,take);
      //The latest garbage from the morons at Crapperquotes appears to occasionally break Matt's OR code, so tell the
      //ea not to trade for a while, to give time for the trade receipt to return from the server.
      TimeToStartTrading = TimeCurrent() + PostTradeAttemptWaitSeconds;
      if(result)
      {
         if (TakeSnapshots)
         {
            DisplayUserFeedback();
            TakeChartSnapshot(TicketNo, " open");
         }//if (TakeSnapshots)
         
         ObjectDelete(BaseLineName);//Force the ea to recreate it at the new level
         
         
         bool s = OrderSelect(TicketNo,SELECT_BY_TICKET,MODE_TRADES);
         //The latest garbage from the morons at Crapperquotes appears to occasionally break Matt's OR code, so send the
         //ea to sleep for a minute to give time for the trade receipt to return from the server.
         //Sleep(60000);
      }//if (result)          
     
      
   }//if (SendTrade)

   

  }//void LookForTradingOpportunities()

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
bool CloseOrder(int ticket)
{   
   while(IsTradeContextBusy()) Sleep(100);
   bool orderselect=OrderSelect(ticket,SELECT_BY_TICKET,MODE_TRADES);
   if (!orderselect) return(false);

   bool result = OrderClose(ticket, OrderLots(), OrderClosePrice(), 1000, clrBlue);

   //Actions when trade send succeeds
   if (result)
   {
      if (TakeSnapshots)
      {
         DisplayUserFeedback();
         TakeChartSnapshot(TicketNo, " close");
      }//if (TakeSnapshots)
      
      return(true);
   }//if (result)
   
   //Actions when trade send fails
   if (!result)
   {
      ReportError(" CloseOrder()", ocm);
      return(false);
   }//if (!result)
   
   return(result);
}//End bool CloseOrder(ticket)

////////////////////////////////////////////////////////////////////////////////////////
//Indicator module

void CheckForSpreadWidening()
{
   if (CloseEnough(AverageSpread, 0)) return;
   //Detect a dramatic widening of the spread and pause the ea until this passes
   double TargetSpread = AverageSpread * MultiplierToDetectStopHunt;
   double spread = (Ask - Bid) * factor;
   
   if (spread >= TargetSpread)
   {
      if (OpenTrades == 0) Comment(Gap + "PAUSED DURING A MASSIVE SPREAD EVENT");
      if (OpenTrades > 0) Comment(Gap + "PAUSED DURING A MASSIVE SPREAD EVENT. STILL MONITORING TRADES.");
      while (spread >= TargetSpread)
      {
         RefreshRates();
         spread = (Ask - Bid) * factor;
         
         CountOpenTrades();
         
         if (ForceTradeClosure) return;//Emergency measure to force a retry at the next tick
         
         OldOpenTrades = OpenTrades;
         
         Sleep(1000);

      }//while (spread >= TargetSpread)      
   }//if (spread >= TargetSpread)
}//End void CheckForSpreadWidening()

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void CalculateDailyResult()
{
   //Calculate the no of winners and losers from today's trading. These are held in the history tab.

   LossTrades = 0;
   WinTrades = 0;
   OverallProfit = 0;
   
   
   for (int cc = 0; cc <= OrdersHistoryTotal(); cc++)
   {
      if (!OrderSelect(cc, SELECT_BY_POS, MODE_HISTORY) ) continue;
      if (OrderSymbol() != Symbol() ) continue;
      if (OrderMagicNumber() != MagicNumber) continue;
      if (OrderCloseTime() < iTime(Symbol(), PERIOD_D1, 0) ) continue;
      
      OverallProfit+= (OrderProfit() + OrderSwap() + OrderCommission() );
      if (OrderProfit() > 0) WinTrades++;
      if (OrderProfit() < 0) LossTrades++;
   }//for (int cc = 0; cc <= tot -1; cc++)
   
   

}//End void CalculateDailyResult()

//+------------------------------------------------------------------+
//| GetSlope()                                                       |
//+------------------------------------------------------------------+
void GetAverageSpread()
{

//   ************************* added for OBJ_LABEL
   DisplayCount = 1;
   removeAllObjects();
//   *************************

   static double SpreadTotal=0;
   AverageSpread=0;

   //Add spread to total and keep track of the ticks
   double Spread=(Ask-Bid)*factor;
   SpreadTotal+=Spread;
   CountedTicks++;

   //All ticks counted?
   if(CountedTicks>=TicksToCount)
   {
      AverageSpread=NormalizeDouble(SpreadTotal/TicksToCount,1);
      //Save the average for restarts.
      GlobalVariableSet(SpreadGvName,AverageSpread);
      RunInSpreadDetectionMode=false;
   }//if (CountedTicks >= TicksToCount)


}//void GetAverageSpread()


//End Indicator module
////////////////////////////////////////////////////////////////////////////////////////


void CloseAllTrades(int type)
{

   ForceTradeClosure= false;
   
   if (OrdersTotal() == 0) return;
   
   bool result = false;
   for (int pass = 0; pass <= 1; pass++)
   {
      if (OrdersTotal() == 0 || OpenTrades == 0)
         break;
      for (int cc = ArraySize(FifoTicket) - 1; cc >= 0; cc--)
      {
         if (!OrderSelect(FifoTicket[cc], SELECT_BY_TICKET, MODE_TRADES) ) continue;
         if (OrderMagicNumber() != MagicNumber) continue;
         if (OrderSymbol() != Symbol() ) continue;
         if (OrderType() != type) 
            if (type != AllTrades)
               continue;
         
         while(IsTradeContextBusy()) Sleep(100);
         if (OrderType() < 2)
         {
            result = OrderClose(OrderTicket(), OrderLots(), OrderClosePrice(), 1000, CLR_NONE);
            if (result) 
            {
               cc++;
               OpenTrades--;
            }//(result) 
            
            if (!result) ForceTradeClosure= true;
         }//if (OrderType() < 2)
         
         if (pass == 1)
            if (OrderType() > 1) 
            {
               result = OrderDelete(OrderTicket(), clrNONE);
               if (result) 
               {
                  cc++;
                  OpenTrades--;
               }//(result) 
            if (!result) ForceTradeClosure= true;
            }//if (OrderType() > 1) 
            
      }//for (int cc = ArraySize(FifoTicket) - 1; cc >= 0; cc--)
   }//for (int pass = 0; pass <= 1; pass++)
   
   //If full closure succeeded, then allow new trading
   if (!ForceTradeClosure) 
   {
      OpenTrades = 0;
      BuyOpen = false;
      SellOpen = false;
   }//if (!ForceTradeClosure) 


}//End void CloseAllTradesFifo()


//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
bool CheckTradingTimes() 
{

	// Trade 24 hours if no input is given
	if ( ArraySize( tradeHours ) == 0 ) return ( true );

	// Get local time in minutes from midnight
    int time = TimeHour( TimeLocal() ) * 60 + TimeMinute( TimeLocal() );
   
	// Don't you love this?
	int i = 0;
	while ( time >= tradeHours[i] ) 
	{	
		if ( i == ArraySize( tradeHours ) ) break;
		i++;		
	}
	if ( i % 2 == 1 ) return ( true );
	return ( false );
}//End bool CheckTradingTimes2() 
//+------------------------------------------------------------------+
//| Initialize Trading Hours Array                                   |
//+------------------------------------------------------------------+
bool initTradingHours() 
{
   // Called from init()
   
	// Assume 24 trading if no input found
	if ( tradingHours == "" )	
	{
		ArrayResize( tradeHours, 0 );
		return ( true );
	}

	int i;

	// Add 00:00 start time if first element is stop time
	if ( StringSubstrOld( tradingHours, 0, 1 ) == "-" ) 
	{
		tradingHours = StringConcatenate( "+0,", tradingHours );   
	}
	
	// Add delimiter
	if ( StringSubstrOld( tradingHours, StringLen( tradingHours ) - 1) != "," ) 
	{
		tradingHours = StringConcatenate( tradingHours, "," );   
	}
	
	string lastPrefix = "-";
	i = StringFind( tradingHours, "," );
	
	while (i != -1) 
	{

		// Resize array
		int size = ArraySize( tradeHours );
		ArrayResize( tradeHours, size + 1 );

		// Get part to process
		string part = StringSubstrOld( tradingHours, 0, i );

		// Check start or stop prefix
		string prefix = StringSubstrOld ( part, 0, 1 );
		if ( prefix != "+" && prefix != "-" ) 
		{
			Print("ERROR IN TRADINGHOURS INPUT (NO START OR CLOSE FOUND), ASSUME 24HOUR TRADING.");
			ArrayResize ( tradeHours, 0 );
			return ( true );
		}

		if ( ( prefix == "+" && lastPrefix == "+" ) || ( prefix == "-" && lastPrefix == "-" ) )	
		{
			Print("ERROR IN TRADINGHOURS INPUT (START OR CLOSE IN WRONG ORDER), ASSUME 24HOUR TRADING.");
			ArrayResize ( tradeHours, 0 );
			return ( true );
		}
		
		lastPrefix = prefix;

		// Convert to time in minutes
		part = StringSubstrOld( part, 1 );
		double time = StrToDouble( part );
		int hour = MathFloor( time );
		int minutes = MathRound( ( time - hour ) * 100 );

		// Add to array
		tradeHours[size] = 60 * hour + minutes;

		// Trim input string
		tradingHours = StringSubstrOld( tradingHours, i + 1 );
		i = StringFind( tradingHours, "," );
	}//while (i != -1) 

	return ( true );
}//End bool initTradingHours() 

 
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void CountOpenTrades()
{
   //Not all these will be needed. Which ones are depends on the individual EA.
   //Market Buy trades
   BuyOpen=false;
   MarketBuysCount=0;
   LatestBuyPrice=0; EarliestBuyPrice=0; HighestBuyPrice=0; LowestBuyPrice=million;
   BuyTicketNo=-1; HighestBuyTicketNo=-1; LowestBuyTicketNo=-1; LatestBuyTicketNo=-1; EarliestBuyTicketNo=-1;
   BuyPipsUpl=0;
   BuyCashUpl=0;
   LatestBuyTradeTime=0;
   EarliestBuyTradeTime=TimeCurrent();
   
   //Market Sell trades
   SellOpen=false;
   MarketSellsCount=0;
   LatestSellPrice=0; EarliestSellPrice=0; HighestSellPrice=0; LowestSellPrice=million;
   SellTicketNo=-1; HighestSellTicketNo=-1; LowestSellTicketNo=-1; LatestSellTicketNo=-1; EarliestSellTicketNo=-1;;
   SellPipsUpl=0;
   SellCashUpl=0;
   LatestSellTradeTime=0;
   EarliestSellTradeTime=TimeCurrent();
   
   //BuyStop trades
   BuyStopOpen=false;
   BuyStopsCount=0;
   LatestBuyStopPrice=0; EarliestBuyStopPrice=0; HighestBuyStopPrice=0; LowestBuyStopPrice=million;
   BuyStopTicketNo=-1; HighestBuyStopTicketNo=-1; LowestBuyStopTicketNo=-1; LatestBuyStopTicketNo=-1; EarliestBuyStopTicketNo=-1;;
   LatestBuyStopTradeTime=0;
   EarliestBuyStopTradeTime=TimeCurrent();
   
   //BuyLimit trades
   BuyLimitOpen=false;
   BuyLimitsCount=0;
   LatestBuyLimitPrice=0; EarliestBuyLimitPrice=0; HighestBuyLimitPrice=0; LowestBuyLimitPrice=million;
   BuyLimitTicketNo=-1; HighestBuyLimitTicketNo=-1; LowestBuyLimitTicketNo=-1; LatestBuyLimitTicketNo=-1; EarliestBuyLimitTicketNo=-1;;
   LatestBuyLimitTradeTime=0;
   EarliestBuyLimitTradeTime=TimeCurrent();
   
   /////SellStop trades
   SellStopOpen=false;
   SellStopsCount=0;
   LatestSellStopPrice=0; EarliestSellStopPrice=0; HighestSellStopPrice=0; LowestSellStopPrice=million;
   SellStopTicketNo=-1; HighestSellStopTicketNo=-1; LowestSellStopTicketNo=-1; LatestSellStopTicketNo=-1; EarliestSellStopTicketNo=-1;;
   LatestSellStopTradeTime=0;
   EarliestSellStopTradeTime=TimeCurrent();
   
   //SellLimit trades
   SellLimitOpen=false;
   SellLimitsCount=0;
   LatestSellLimitPrice=0; EarliestSellLimitPrice=0; HighestSellLimitPrice=0; LowestSellLimitPrice=million;
   SellLimitTicketNo=-1; HighestSellLimitTicketNo=-1; LowestSellLimitTicketNo=-1; LatestSellLimitTicketNo=-1; EarliestSellLimitTicketNo=-1;;
   LatestSellLimitTradeTime=0;
   EarliestSellLimitTradeTime=TimeCurrent();
   
   //Not related to specific order types
   TicketNo=-1;OpenTrades=0;
   LatestTradeTime=0; EarliestTradeTime=million;//More specific times are in each individual section
   LatestTradeTicketNo=-1; EarliestTradeTicketNo=-1;
   PipsUpl=0;//For keeping track of the pips PipsUpl of multi-trade/hedged positions
   CashUpl=0;//For keeping track of the cash PipsUpl of multi-trade/hedged positions
   MarketTradesTotal = 0;
   TotalBuyLots=0; TotalSellLots=0;
   TjfHedgeOpen=false;
   TjfTicketNo=0;
   
   //FIFO ticket resize
   ArrayResize(FifoTicket, 0);
   
   ArrayResize(GridOrderBuyTickets, 0);
   ArrayInitialize(GridOrderBuyTickets, 0);
   ArrayResize(GridOrderSellTickets, 0);
   ArrayInitialize(GridOrderSellTickets, 0);
   
   int type;//Saves the OrderType() for consulatation later in the function
   
   
   if (OrdersTotal() == 0) 
   {
      Hedged = false;
      return;
   }//if (OrdersTotal() == 0) 
   
   
   
   //Iterating backwards through the orders list caters more easily for closed trades than iterating forwards
   for (int cc = OrdersTotal() - 1; cc >= 0; cc--)
   {
      bool TradeWasClosed = false;//See 'check for possible trade closure'

      //Ensure the trade is still open
      if (!OrderSelect(cc, SELECT_BY_POS, MODE_TRADES) ) continue;
      //Ensure the EA 'owns' this trade
      if (OrderSymbol() != Symbol() ) continue;
      if (OrderMagicNumber() != MagicNumber) continue;
      if (OrderCloseTime() > 0) continue; 
      
      if (OrderComment() == TjfHedgeComment)
      {
         TjfHedgeOpen = true;
         TjfTicketNo = OrderTicket();//So it can be selected later on
      }//if (OrderComment() == TjfHedgeComment)
      
      //The time of the most recent trade
      if (OrderOpenTime() > LatestTradeTime)
      {
         LatestTradeTime = OrderOpenTime();
         LatestTradeTicketNo = OrderTicket();
      }//if (OrderOpenTime() > LatestTradeTime)
      
      //The time of the earliest trade
      if (OrderOpenTime() < EarliestTradeTime)
      {
         EarliestTradeTime = OrderOpenTime();
         EarliestTradeTicketNo = OrderTicket();
      }//if (OrderOpenTime() < EarliestTradeTime)
      
      //All conditions passed, so carry on
      type = OrderType();//Store the order type
      
      if (!CloseEnough(OrderTakeProfit(), 0) )
         TpSet = true;
      if (!CloseEnough(OrderStopLoss(), 0) )
         SlSet = true;

      OpenTrades++;
      //Store the latest trade sent. Most of my EA's only need this final ticket number as either they are single trade
      //bots or the last trade in the sequence is the important one. Adapt this code for your own use.
      if (TicketNo  == -1) TicketNo = OrderTicket();
      
      //Store ticket numbers for FIFO
      ArrayResize(FifoTicket, OpenTrades + 1);
      FifoTicket[OpenTrades] = OrderTicket();
      
      
      
      
      //The next line of code calculates the pips upl of an open trade. As yet, I have done nothing with it.
      //something = CalculateTradeProfitInPips()
      
      double pips = 0;
      
      //Buile up the position picture of market trades
      if (OrderType() < 2)
      {
         CashUpl+= (OrderProfit() + OrderSwap() + OrderCommission()); 
         MarketTradesTotal++;
         pips = CalculateTradeProfitInPips(OrderType());
         PipsUpl+= pips;
         Lot = OrderLots();//We need consistent lot sizing
         
         //Buys
         if (OrderType() == OP_BUY)
         {
            
            ArrayResize(GridOrderBuyTickets, MarketBuysCount + 1);
            GridOrderBuyTickets[MarketBuysCount][TradeOpenPrice] = OrderOpenPrice();  //can be sorted by price
            GridOrderBuyTickets[MarketBuysCount][TradeTicket] = OrderTicket();
            
            
            BuyOpen = true;
            BuyTicketNo = OrderTicket();
            MarketBuysCount++;
            BuyPipsUpl+= pips;
            BuyCashUpl+= (OrderProfit() + OrderSwap() + OrderCommission()); 
            
            //Total of buy lots
            TotalBuyLots+= OrderLots();
            
            //Latest trade
            if (OrderOpenTime() > LatestBuyTradeTime)
            {
               LatestBuyTradeTime = OrderOpenTime();
               LatestBuyPrice = OrderOpenPrice();
               LatestBuyTicketNo = OrderTicket();
            }//if (OrderOpenTime() > LatestBuyTradeTime)  
 
            //Furthest back in time
            if (OrderOpenTime() < EarliestBuyTradeTime)
            {
               EarliestBuyTradeTime = OrderOpenTime();
               EarliestBuyPrice = OrderOpenPrice();
               EarliestBuyTicketNo = OrderTicket();
            }//if (OrderOpenTime() < EarliestBuyTradeTime)
            
            //Highest trade price
            if (OrderOpenPrice() > HighestBuyPrice)
            {
               HighestBuyPrice = OrderOpenPrice();
               HighestBuyTicketNo = OrderTicket();
            }//if (OrderOpenPrice() > HighestBuyPrice)
            
            //Lowest trade price
            if (OrderOpenPrice() < LowestBuyPrice)
            {
               LowestBuyPrice = OrderOpenPrice();
               LowestBuyTicketNo = OrderTicket();
            }//if (OrderOpenPrice() > LowestBuyPrice)
              
         }//if (OrderType() == OP_BUY)
         
         //Sells
         if (OrderType() == OP_SELL)
         {
            
            ArrayResize(GridOrderSellTickets, MarketSellsCount + 1);
            GridOrderSellTickets[MarketSellsCount][TradeOpenPrice] = OrderOpenPrice();  //can be sorted by price
            GridOrderSellTickets[MarketSellsCount][TradeTicket] = OrderTicket();
            
            SellOpen = true;
            SellTicketNo = OrderTicket();
            MarketSellsCount++;
            SellPipsUpl+= pips;
            SellCashUpl+= (OrderProfit() + OrderSwap() + OrderCommission()); 

            //Total of sell lots
            TotalSellLots+= OrderLots();
            
            //Latest trade
            if (OrderOpenTime() > LatestSellTradeTime)
            {
               LatestSellTradeTime = OrderOpenTime();
               LatestSellPrice = OrderOpenPrice();
               LatestSellTicketNo = OrderTicket();
            }//if (OrderOpenTime() > LatestSellTradeTime)  
 
            //Furthest back in time
            if (OrderOpenTime() < EarliestSellTradeTime)
            {
               EarliestSellTradeTime = OrderOpenTime();
               EarliestSellPrice = OrderOpenPrice();
               EarliestSellTicketNo = OrderTicket();
            }//if (OrderOpenTime() < EarliestSellTradeTime)
            
            //Highest trade price
            if (OrderOpenPrice() > HighestSellPrice)
            {
               HighestSellPrice = OrderOpenPrice();
               HighestSellTicketNo = OrderTicket();
            }//if (OrderOpenPrice() > HighestSellPrice)
            
            //Lowest trade price
            if (OrderOpenPrice() < LowestSellPrice)
            {
               LowestSellPrice = OrderOpenPrice();
               LowestSellTicketNo = OrderTicket();
            }//if (OrderOpenPrice() > LowestSellPrice)
              
         }//if (OrderType() == OP_SELL)
         
         
      }//if (OrderType() < 2)
      
      
      //Build up the position details of stop/limit orders
      if (OrderType() > 1)
      {
         //Buystops
         if (OrderType() == OP_BUYSTOP)
         {
            BuyStopOpen = true;
            BuyStopTicketNo = OrderTicket();
            BuyStopsCount++;
            
            //Latest trade
            if (OrderOpenTime() > LatestBuyStopTradeTime)
            {
               LatestBuyStopTradeTime = OrderOpenTime();
               LatestBuyStopPrice = OrderOpenPrice();
               LatestBuyStopTicketNo = OrderTicket();
            }//if (OrderOpenTime() > LatestBuyStopTradeTime)  
 
            //Furthest back in time
            if (OrderOpenTime() < EarliestBuyStopTradeTime)
            {
               EarliestBuyStopTradeTime = OrderOpenTime();
               EarliestBuyStopPrice = OrderOpenPrice();
               EarliestBuyStopTicketNo = OrderTicket();
            }//if (OrderOpenTime() < EarliestBuyStopTradeTime)
            
            //Highest trade price
            if (OrderOpenPrice() > HighestBuyStopPrice)
            {
               HighestBuyStopPrice = OrderOpenPrice();
               HighestBuyStopTicketNo = OrderTicket();
            }//if (OrderOpenPrice() > HighestBuyStopPrice)
            
            //Lowest trade price
            if (OrderOpenPrice() < LowestBuyStopPrice)
            {
               LowestBuyStopPrice = OrderOpenPrice();
               LowestBuyStopTicketNo = OrderTicket();
            }//if (OrderOpenPrice() > LowestBuyStopPrice)
              
         }//if (OrderType() == OP_BUYSTOP)
         
         //Sellstops
         if (OrderType() == OP_SELLSTOP)
         {
            SellStopOpen = true;
            SellStopTicketNo = OrderTicket();
            SellStopsCount++;
            
            //Latest trade
            if (OrderOpenTime() > LatestSellStopTradeTime)
            {
               LatestSellStopTradeTime = OrderOpenTime();
               LatestSellStopPrice = OrderOpenPrice();
               LatestSellStopTicketNo = OrderTicket();
            }//if (OrderOpenTime() > LatestSellStopTradeTime)  
 
            //Furthest back in time
            if (OrderOpenTime() < EarliestSellStopTradeTime)
            {
               EarliestSellStopTradeTime = OrderOpenTime();
               EarliestSellStopPrice = OrderOpenPrice();
               EarliestSellStopTicketNo = OrderTicket();
            }//if (OrderOpenTime() < EarliestSellStopTradeTime)
            
            //Highest trade price
            if (OrderOpenPrice() > HighestSellStopPrice)
            {
               HighestSellStopPrice = OrderOpenPrice();
               HighestSellStopTicketNo = OrderTicket();
            }//if (OrderOpenPrice() > HighestSellStopPrice)
            
            //Lowest trade price
            if (OrderOpenPrice() < LowestSellStopPrice)
            {
               LowestSellStopPrice = OrderOpenPrice();
               LowestSellStopTicketNo = OrderTicket();
            }//if (OrderOpenPrice() > LowestSellStopPrice)
              
         }//if (OrderType() == OP_SELLSTOP)
         
         //Buy limits
         if (OrderType() == OP_BUYLIMIT)
         {
            BuyLimitOpen = true;
            BuyLimitTicketNo = OrderTicket();
            BuyLimitsCount++;
            
            //Latest trade
            if (OrderOpenTime() > LatestBuyLimitTradeTime)
            {
               LatestBuyLimitTradeTime = OrderOpenTime();
               LatestBuyLimitPrice = OrderOpenPrice();
               LatestBuyLimitTicketNo = OrderTicket();
            }//if (OrderOpenTime() > LatestBuyLimitTradeTime)  
 
            //Furthest back in time
            if (OrderOpenTime() < EarliestBuyLimitTradeTime)
            {
               EarliestBuyLimitTradeTime = OrderOpenTime();
               EarliestBuyLimitPrice = OrderOpenPrice();
               EarliestBuyLimitTicketNo = OrderTicket();
            }//if (OrderOpenTime() < EarliestBuyLimitTradeTime)
            
            //Highest trade price
            if (OrderOpenPrice() > HighestBuyLimitPrice)
            {
               HighestBuyLimitPrice = OrderOpenPrice();
               HighestBuyLimitTicketNo = OrderTicket();
            }//if (OrderOpenPrice() > HighestBuyLimitPrice)
            
            //Lowest trade price
            if (OrderOpenPrice() < LowestBuyLimitPrice)
            {
               LowestBuyLimitPrice = OrderOpenPrice();
               LowestBuyLimitTicketNo = OrderTicket();
            }//if (OrderOpenPrice() > LowestBuyLimitPrice)
              
         }//if (OrderType() == OP_BUYLIMIT)
         
         //Sell limits
         if (OrderType() == OP_SELLLIMIT)
         {
            SellLimitOpen = true;
            SellLimitTicketNo = OrderTicket();
            SellLimitsCount++;
            
            //Latest trade
            if (OrderOpenTime() > LatestSellLimitTradeTime)
            {
               LatestSellLimitTradeTime = OrderOpenTime();
               LatestSellLimitPrice = OrderOpenPrice();
               LatestSellLimitTicketNo = OrderTicket();
            }//if (OrderOpenTime() > LatestSellLimitTradeTime)  
 
            //Furthest back in time
            if (OrderOpenTime() < EarliestSellLimitTradeTime)
            {
               EarliestSellLimitTradeTime = OrderOpenTime();
               EarliestSellLimitPrice = OrderOpenPrice();
               EarliestSellLimitTicketNo = OrderTicket();
            }//if (OrderOpenTime() < EarliestSellLimitTradeTime)
            
            //Highest trade price
            if (OrderOpenPrice() > HighestSellLimitPrice)
            {
               HighestSellLimitPrice = OrderOpenPrice();
               HighestSellLimitTicketNo = OrderTicket();
            }//if (OrderOpenPrice() > HighestSellLimitPrice)
            
            //Lowest trade price
            if (OrderOpenPrice() < LowestSellLimitPrice)
            {
               LowestSellLimitPrice = OrderOpenPrice();
               LowestSellLimitTicketNo = OrderTicket();
            }//if (OrderOpenPrice() > LowestSellLimitPrice)
              
         }//if (OrderType() == OP_SELLLIMIT)
         
      
      }//if (OrderType() > 1)
      
      
      
      
               
      
   }//for (int cc = OrdersTotal() - 1; cc <= 0; c`c--)
   
   
   //Sort open prices for Grid Based Trading:
   // Both arrays sorted descending as for loops take account of direction
   
   if (ArraySize(GridOrderBuyTickets) > 0)
      ArraySort(GridOrderBuyTickets, WHOLE_ARRAY, 0, MODE_DESCEND);
   
   if (ArraySize(GridOrderSellTickets) > 0)
      ArraySort(GridOrderSellTickets, WHOLE_ARRAY, 0, MODE_DESCEND);
   
   //Sort ticket numbers for FIFO
   if (ArraySize(FifoTicket) > 0)
      ArraySort(FifoTicket, WHOLE_ARRAY, 0, MODE_DESCEND);
   
  
   
      
   //Is the position hedged?
   Hedged = false;
   if (BuyOpen)
      if (SellOpen)
         Hedged=true;

   
}//End void CountOpenTrades();



////////////////////////////////////////////////////////////////////////////////////////
//TRADE MANAGEMENT MODULE

void ReportError(string function, string message)
{
   //All purpose sl mod error reporter. Called when a sl mod fails
   
   int err=GetLastError();
   if (err == 1) return;//That bloody 'error but no error' report is a nuisance
   
      
   Alert(WindowExpertName(), " ", OrderTicket(), " ", function, message, err,": ",ErrorDescription(err));
   Print(WindowExpertName(), " ", OrderTicket(), " ", function, message, err,": ",ErrorDescription(err));
   
}//void ReportError()

bool ModifyOrder(int ticket, double price, double stop, double take, datetime expiry, color col, string function, string reason)
{
   //Multi-purpose order modify function
   
   bool result = OrderModify(ticket, price ,stop , take, expiry, col);

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

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void TradeManagementModule(int ticket)
{

   //Nothing in the Bugger All version.
   
   // Call the working subroutines one by one. 



}//void TradeManagementModule()
//END TRADE MANAGEMENT MODULE
////////////////////////////////////////////////////////////////////////////////////////



double CalculateTradeProfitInPips(int type)
{
   //This code supplied by Lifesys. Many thanks Paul.
   
   //Returns the pips Upl of the currently selected trade. Called by CountOpenTrades()
   double profit = 0;
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
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
bool CloseEnough(double num1,double num2)
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

   if(num1==0 && num2==0) return(true); //0==0
   if(MathAbs(num1 - num2) / (MathAbs(num1) + MathAbs(num2)) < 0.00000001) return(true);

//Doubles are unequal
   return(false);

}//End bool CloseEnough(double num1, double num2)
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
double PFactor(string symbol)
{
//This code supplied by Lifesys. Many thanks Paul - we all owe you. Gary was trying to make me see this, but I could not understand his explanation. Paul used Janet and John words

   for(int i=ArraySize(pipFactor)-1; i>=0; i--)
      if(StringFind(symbol,pipFactor[i],0)!=-1)
         return (pipFactors[i]);
   return(10000);

}//End double PFactor(string pair)
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
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
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void DrawHorizontalLine(string name,double price,color col,int style,int width)
{

   ObjectDelete(name);

   ObjectCreate(name,OBJ_HLINE,0,TimeCurrent(),price);
   ObjectSet(name,OBJPROP_COLOR,col);
   ObjectSet(name,OBJPROP_STYLE,style);
   ObjectSet(name,OBJPROP_WIDTH,width);

}//void DrawLine(string name, double price, color col)
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void DrawVerticalLine(string name,color col,int style,int width)
{
   //ObjectCreate(vline,OBJ_VLINE,0,iTime(NULL, TimeFrame, 0), 0);
   ObjectDelete(name);
   ObjectCreate(name,OBJ_VLINE,0,iTime(NULL,0,0),0);
   ObjectSet(name,OBJPROP_COLOR,col);
   ObjectSet(name,OBJPROP_STYLE,style);
   ObjectSet(name,OBJPROP_WIDTH,width);

}//void DrawVerticalLine()
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
////////////////////////////////////////////////////////////////////////////////////////
string StringSubstrOld(string x,int a,int b=-1) 
{
   if(a<0) a=0; // Stop odd behaviour
   if(b<=0) b=-1; // new MQL4 EOL flag
   return StringSubstr(x,a,b);
}

void TakeChartSnapshot(int ticket, string oc)
{

   //Takes a snapshot of the chart after a trade open or close. Files are stored in the MQL4/Files folder
   //of the platform.
   
   //--- Prepare a text to show on the chart and a file name.
   //oc is either " open" or " close"
   string name="ChartScreenShot " + string(ticket) + oc + ".gif";
   
   //--- Save the chart screenshot in a file in the terminal_directory\MQL4\Files\
   if(ChartScreenShot(0,name, PictureWidth, PictureHeight, ALIGN_RIGHT))
      Alert("Screen snapshot taken ",name);
   //---
   

}//void TakeChartSnapshot()

bool TooClose()
{
   //Returns false if the previously closed trade and the proposed new trade are sufficiently far apart, else return true. Called from IsTradeAllowed().
   
   SafetyViolation = false;//For chart feedback
         
   if (OrdersHistoryTotal() == 0) return(false);
   
   for (int cc = OrdersHistoryTotal() - 1; cc >= 0; cc--)
   {
      if (!OrderSelect(cc, SELECT_BY_POS, MODE_HISTORY) ) continue;
      if (OrderMagicNumber() != MagicNumber) continue;
      if (OrderSymbol() != Symbol() ) continue;
      
      //Examine the OrderCloseTime to see if it closed far enought back in time.
      if (TimeCurrent() - OrderCloseTime() < (MinMinutesBetweenTrades * 60))
      {
         SafetyViolation = true;
         return(true);//Too close, so disallow the trade
      }//if (OrderCloseTime() - TimeCurrent() < (MinMinutesBetweenTrades * 60))
      break;      
   }//for (int cc = OrdersHistoryTotal() - 1; cc >= 0; cc--)
   
   //Got this far, so there is no disqualifying trade in the history
   return(false);
   
}//bool TooClose()

void ShouldTradesBeClosed()
{
   //Examine baskets of trades for possible closure
   
   if (OpenTrades == 0)
      return;//Nothing to do

   bool CloseTrades = false;
   
   double pips = 0;//The pips upl of the highest buy or lowest sell
   double loss = 0;//Convers pips to a positive value for comparison with (DistanceBetweenTrades / factor)
   double profit = 0;//Cash upl of the side being calculated to see if they can combine to close a loser on the other side
   int TradesToClose = 0;
   bool result = false;
   int cc = 0;
   double HighestTradeCash = 0;
   double LowestTradeCash = 0;
   int tries = 0;
   
   
   //Look for basket closure.
   //Hedged basket
   if (HedgedBasketPips > 0)
      if (PipsUpl >= HedgedBasket)
      {
         CloseAllTrades(AllTrades);
         if (ForceTradeClosure)
            CloseAllTrades(AllTrades);
         return;
      }//if (PipsUpl >= HedgedBasket)
      
   //Un-hedged
   if (ClearBasketPips > 0)
      if (PipsUpl >= ClearBasket)
      {
         CloseAllTrades(AllTrades);
         if (ForceTradeClosure)
            CloseAllTrades(AllTrades);
         return;
      }//if (PipsUpl >= HedgedBasket)
      
   //Emergency stop loss
   if (!CloseEnough(EmergencyStopLossPercentageOfBalance, 0))
      if (CashUpl < 0)
         if ((CashUpl) <= EmergencyStopLoss)
         {
            CloseAllTrades(AllTrades);
            if (ForceTradeClosure)
               CloseAllTrades(AllTrades);
            return;
         }//if ((CashUpl * -1) <= EmergencyStopLoss)
      
   //Close the worst trade if stop loss is hit
   if (!CloseEnough(PartialEmergencyStopLossPercentOfBalance, 0))
   {        
      if ((CashUpl) <= PartialEmergencyStopLoss)
      {
         // find the worst losing trade which is either going to be the highest buy or the lowest sell:
       
         if (OrderSelect(HighestBuyTicketNo, SELECT_BY_TICKET, MODE_TRADES) )
               double HighestBuyCash = OrderSwap() + OrderCommission() + OrderProfit();  
         
         if (OrderSelect(LowestSellTicketNo, SELECT_BY_TICKET, MODE_TRADES) )
               double LowestSellCash = OrderSwap() + OrderCommission() + OrderProfit(); 
       
         if ((HighestBuyCash < LowestSellCash)) // the buy is the worst trade
         {
            if (OrderSelect(HighestBuyTicketNo, SELECT_BY_TICKET, MODE_TRADES) )
            {
               result = CloseOrder(HighestBuyTicketNo);
               if(result)Print("Closed highest buy at partial emergency stop level");
               if (!result)
               {
                  CountOpenTrades(); // just in case it's a ticket number issue.
                  return;
               }//if (!result)        
            }//if (OrderSelect(HighestBuyTicketNo, SELECT_BY_TICKET, MODE_TRADES) )         
         }//if ((HighestBuyCash < LowestSellCash))
         else
         {
            if (OrderSelect(LowestSellTicketNo, SELECT_BY_TICKET, MODE_TRADES) )
            {   
               result = CloseOrder(LowestSellTicketNo);
               if(result)Print("Closed lowest sell at partial emergency stop level");
               if (!result)
               {
                  CountOpenTrades(); // just in case it's a ticket number issue.
                  return;
               }//if (!result)
            }//if (OrderSelect(LowestSellTicketNo, SELECT_BY_TICKET, MODE_TRADES) )
         }//else      
   
      }//if ((CashUpl) <= PartialEmergencyStopLoss)
   }//if (!CloseEnough(PartialEmergencyStopLossPercentOfBalance, 0))
   
   //Offsetting
   if (CanTradesBeOffset())
   {
      CountOpenTrades();
      return;
   }//if (CanTradesBeOffset())
   //In case any trade closures failed
   if (ArraySize(ForceCloseTickets) > 0)
   {
      MopUpTradeClosureFailures();
      return;
   }//if (ArraySize(ForceCloseTickets) > 0)     
}//void ShouldTradesBeClosed()


bool CanTradesBeOffset()
{

   bool CloseTrades = false;
   
   double pips = 0;//The pips upl of the highest buy or lowest sell
   double loss = 0;//Convers pips to a positive value for comparison with (DistanceBetweenTrades / factor)
   double profit = 0;//Cash upl of the side being calculated to see if they can combine to close a loser on the other side
   int TradesToClose = 0;
   bool result = false;
   int cc = 0;
   double HighestTradeCash = 0;
   double LowestTradeCash = 0;
   int tries = 0;
   int cas = 0;//ForceCloseTickets array size
                                             
   ArrayResize(ForceCloseTickets, 0);
   
   //Look for a simple offset opportunity of a losing buy at the
   //top of the pile by the winner at the bottom.
  
   if (MarketBuysCount > MinOpenTradesToStartOffset)//Impossible with < 4
   {
      //Do we have a losing buy?
      if (OrderSelect(HighestBuyTicketNo, SELECT_BY_TICKET, MODE_TRADES) )
      {
         //Calculate the pips upl of the highest, and so latest, buy
         pips = CalculateTradeProfitInPips(OP_BUY);
         if (pips < 0)//Only continue if it is losing
         {
            loss = (pips * -1);//Turn the loss into a positive number for the comparison
            if (loss >= DistanceBetweenTrades)//Only continue if losing by at least 1 grid level
            {
               HighestTradeCash = OrderSwap() + OrderCommission() + OrderProfit();
               if (OrderSelect(LowestBuyTicketNo, SELECT_BY_TICKET, MODE_TRADES) )
                  LowestTradeCash = OrderSwap() + OrderCommission() + OrderProfit();
               
               //Make sure we are closing at an overall cash profit
               if ((HighestTradeCash + LowestTradeCash) > 0)
               {
                  //The higest buy trade is losing by at least one grid level, so close it and the lowest buy
                  if (OrderSelect(HighestBuyTicketNo, SELECT_BY_TICKET, MODE_TRADES) )
                  {
                     result = CloseOrder(HighestBuyTicketNo);
                     if (!result)
                     {
                        return(false);
                     }//if (!result)
                  }//if (OrderSelect(HighestBuyTicketNo, SELECT_BY_TICKET, MODE_TRADES) )
                     
                  if (OrderSelect(LowestBuyTicketNo, SELECT_BY_TICKET, MODE_TRADES) )
                  {
                     result = false;
                     while (!result)
                     {
                        result = CloseOrder(LowestBuyTicketNo);
                        if (!result)
                        {
                           tries++;
                           if (tries >= 20)
                           {
                              //The closure attempt has failed, but must be retried.
                              //Save the ticket number in the array
                              ArrayResize(ForceCloseTickets, 1);
                              ForceCloseTickets[0] = LowestBuyTicketNo;
                              return(false);
                           }//if (tries >= 20)  
                        }//if (!result)
                        
                     }//while (!result)
                  }//if (OrderSelect(LowestBuyTicketNo, SELECT_BY_TICKET, MODE_TRADES) )
                     
                  return(true);//Routine succeeded
                  
               }//if ((HighestTradeCash + LowestTradeCash) > 0)                  
            }//if (loss >= DistanceBetweenTrades)
            
         }//if (pips < 0)
      }//if (OrderSelect(HighestBuyTicketNo, SELECT_BY_TICKET, MODE_TRADES) )
      ArrayResize(ForceCloseTickets, 0);
   }//if (MarketBuysCount > 3)
     
   //Look for a simple offset opportunity of a losing buy at the
   //top of the pile by the winner at the bottom.
   if (MarketSellsCount > MinOpenTradesToStartOffset)//Impossible with < 3
   {

      //Do we have a losing buy?
      if (OrderSelect(LowestSellTicketNo, SELECT_BY_TICKET, MODE_TRADES) )
      {
         //Calculate the pips upl of the lowest, and so latest, sell
         pips = CalculateTradeProfitInPips(OP_SELL);

         if (pips < 0)//Only continue if it is losing
         {
            loss = (pips * -1);//Turn the loss into a positive number for the comparison

            if (loss >= DistanceBetweenTrades)//Only continue if losing by at least 1 grid level
            {
               LowestTradeCash = OrderSwap() + OrderCommission() + OrderProfit();
               if (OrderSelect(HighestSellTicketNo, SELECT_BY_TICKET, MODE_TRADES) )
                  HighestTradeCash = OrderSwap() + OrderCommission() + OrderProfit();

               if ((HighestTradeCash + LowestTradeCash) > 0)
               {
                  if (OrderSelect(LowestSellTicketNo, SELECT_BY_TICKET, MODE_TRADES) )
                  {
                     result = CloseOrder(LowestSellTicketNo);
                     if (!result)
                     {
                        return(false);
                     }//if (!result)
                  }//if (OrderSelect(LowestSellTicketNo, SELECT_BY_TICKET, MODE_TRADES) )
                  
                  if (OrderSelect(HighestSellTicketNo, SELECT_BY_TICKET, MODE_TRADES) )
                  {   
                     result = false;
                     tries = 0;
                     while (!result)
                     {
                        result = CloseOrder(HighestSellTicketNo);               
                        if (!result)
                        {
                           tries++;
                           if (tries >= 20)
                           {
                              //The closure attempt has failed, but must be retried.
                              //Save the ticket number in the array
                              ArrayResize(ForceCloseTickets, 1);
                              ForceCloseTickets[0] = HighestSellTicketNo;
                              return(false);
                           }//if (tries >= 20)  
                        }//if (!result)      
                     }//while (!result)
                  }//if (OrderSelect(HighestSellTicketNo, SELECT_BY_TICKET, MODE_TRADES) )
                     
                  return(true);//Routine succeeded
                  
               }//if ((HighestTradeCash + LowestTradeCash) > 0)               
            }//if (loss >= DistanceBetweenTrades)
            
         }//if (pips < 0)
      }//if (OrderSelect(LowestSellTicketNo, SELECT_BY_TICKET, MODE_TRADES) )
      ArrayResize(ForceCloseTickets, 0);
          
   }//if (MarketSellsCount  > 3)
       
    
   ////////////////////////////////////////////////////////////////////////
   //Got this far, so see if the combined winners on one side can combine
   //to close a loser on the other side.
   
   if (Hedged)
   {
      double CashLoss = 0;
      double CashProfit = 0;
      int NoOfTrades = 0;
      double ThisOrderProfit = 0;
      bool ClosePossible = false;
      int ClosureTickets[];
      ArrayInitialize(ClosureTickets, -1);
      double ThisTradeProfit = 0;
      tries = 0;
      int as = 0;//Array size
      
      //Can we offset some buy trades against the lowest losing sell trade
      if (BuyCashUpl > 0)//The buy side of the hedge must be profitable overall
         if (MarketBuysCount >= MinOpenTradesToStartOffset)//Must be sufficient trades open to start offsetting
            if (OrderSelect(LowestSellTicketNo, SELECT_BY_TICKET, MODE_TRADES))//Select the lowest sell
            {
            
                //Calculate the pips upl of the lowest, and so latest, sell
                if((CalculateTradeProfitInPips(OP_SELL)*-1)>=DistanceBetweenTrades) // Only continue if the trade is losing by more than DistanceBetweenTrades
                {
          
                     CashLoss = (OrderSwap() + OrderCommission() + OrderProfit());//Calculate its cash position
                     if (CashLoss < 0)//Is it losing?
                     {
                        CashLoss*= -1;//Convert to a positive for comparison with the profit on the other side
                        //Calculate the profit on the other side of the hedge
                        for (cc = MarketBuysCount; cc > 0; cc--)
                        {
                           if (OrderSelect(GridOrderBuyTickets[cc - 1][TradeTicket], SELECT_BY_TICKET, MODE_TRADES) )
                           {
                              ThisTradeProfit = (OrderSwap() + OrderCommission() + OrderProfit());
                              if (ThisTradeProfit > 0)
                                 if (!CloseEnough(ThisTradeProfit, 0) )
                                 {
                                    NoOfTrades++;
                                    ArrayResize(ClosureTickets, NoOfTrades);
                                    ClosureTickets[NoOfTrades - 1] = OrderTicket();
                                    CashProfit+= ThisTradeProfit;
                                 }//if (!CloseEnough(CashProfit, 0) )
                           }//if (OrderSelect(GridOrderBuyTickets[cc - 1][TradeTicket], SELECT_BY_TICKET, MODE_TRADES) )
                           
                           //Is the profit big enough to close the trade on the other side of the hedge?
                           if (CashProfit >= CashLoss)
                           {
                              //Yippee
                              ClosePossible = true;
                              break;
                           }//if (CashProfit >= CashLoss)
                        }//for (int cc = MarketBuysCount; cc >= 0; cc--)
                        
                        //Are there closures to make?
                        if (ClosePossible)
                        {
                           ForceTradeClosure = true;
                           while (ForceTradeClosure)
                           {
                              ForceTradeClosure = false;
                              as = ArraySize(ClosureTickets) - 1;
                              if (OrderSelect(LowestSellTicketNo, SELECT_BY_TICKET, MODE_TRADES) )
                              {
                                 result = OrderCloseBy(LowestSellTicketNo, ClosureTickets[as]);
                                 if (!result)
                                   return(false);
                              }//if (OrderSelect(LowestSellTicketNo, SELECT_BY_TICKET, MODE_TRADES) )
                              
                              for (cc = ArraySize(ClosureTickets) - 2; cc >= 0; cc--)
                              {
                                 if (OrderSelect(ClosureTickets[cc], SELECT_BY_TICKET, MODE_TRADES))
                                 {
                                    result = CloseOrder(ClosureTickets[cc]);
                                  //  Print("Double Sided Complex buy closure"); // for debugging
                                    if (!result)
                                    {
                                       ForceTradeClosure = true;
                                       cc++;
                                       if (tries >= 20)//Something has gone wrong
                                       {   
                                          //The closure attempt has failed, but must be retried.
                                          //Save the ticket number in the array
                                          cas = ArraySize(ForceCloseTickets);
                                          ArrayResize(ForceCloseTickets, cas + 1);
                                          ForceCloseTickets[cas] = ClosureTickets[cc];
                                          cc--;//In case something has gone wrong and the trade no longer exists
                                       }//if (tries >= 20)                                       
                                    }//if (!result)
                                 }//if (OrderSelect(ClosureTickets[cc], SELECT_BY_TICKET, MODE_TRADES))                          
                              }//for (cc = ArraySize(ClosureTickets); cc >= 0; cc--)
                           }//while (ForceTradeClosure)
                           
                           if (ArraySize(ForceCloseTickets) == 0)
                           {
                              CountOpenTrades();
                              return(true);
                           }//if (ArraySize(ForceCloseTickets) == 0)
                           else
                           {
                              return(false);
                           }//else                              
                        }//if (ClosePossible)
                     }//if (CashLoss < 0)
                  }// if((CalculateTradeProfitInPips(OP_SELL)*-1)>=DistanceBetweenTrades)
            }//if (OrderSelect(LowestSellTicketNo, SELECT_BY_TICKET, MODE_TRADES))
            
      CashLoss = 0;
      CashProfit = 0;
      NoOfTrades = 0;
      ClosePossible = false;
      ArrayResize(ClosureTickets, 0);
      ArrayInitialize(ClosureTickets, -1);
      ArrayResize(ForceCloseTickets, 0);
      tries = 0;

      //Can we offset some sell trades against the highest losing buy trade
      if (SellCashUpl > 0)//The sell side of the hedge must be profitable overall
         if (MarketSellsCount >= MinOpenTradesToStartOffset)//Must be sufficient trades open to start offsetting
            if (OrderSelect(HighestBuyTicketNo, SELECT_BY_TICKET, MODE_TRADES))//Select the highest buy
            {
               
               //Calculate the pips upl of the lowest, and so latest, sell
               if((CalculateTradeProfitInPips(OP_BUY)*-1)>=DistanceBetweenTrades) // Only continue if the trade is losing by more than DistanceBetweenTrades
               {
               
                  CashLoss = (OrderSwap() + OrderCommission() + OrderProfit());//Calculate its cash position
                  if (CashLoss < 0)//Is it losing?
                  {
                     CashLoss*= -1;//Convert to a positive for comparison with the profit on the other side
                     //Calculate the profit on the other side of the hedge
                     for (cc = 0; cc < MarketSellsCount; cc++)
                     {
                        if (OrderSelect(GridOrderSellTickets[cc][TradeTicket], SELECT_BY_TICKET, MODE_TRADES) )
                        {
                           ThisTradeProfit = (OrderSwap() + OrderCommission() + OrderProfit());
                           if (ThisTradeProfit > 0)
                              if (!CloseEnough(ThisTradeProfit, 0) )
                              {
                                 NoOfTrades++;
                                 ArrayResize(ClosureTickets, NoOfTrades);
                                 ClosureTickets[NoOfTrades - 1] = OrderTicket();
                                 CashProfit+= ThisTradeProfit;
                              }//if (!CloseEnough(CashProfit, 0) )
                        }//if (OrderSelect(FifoSellTicket[cc1][TradeTicket], SELECT_BY_TICKET, MODE_TRADES) )
                        
                        //Is the profit big enough to close the trade on the other side of the hedge?
                        if (CashProfit >= CashLoss)
                        {
                           //Yippee
                           ClosePossible = true;
                           break;
                        }//if (CashProfit >= CashLoss)
                     }//for (cc = 0; cc < MarketSellsCount - 1; cc++)
                     
                     //Are there closures to make?
                     if (ClosePossible)
                     {
                        ForceTradeClosure = true;
                        while (ForceTradeClosure)
                        {
                           ForceTradeClosure = false;
                           if (OrderSelect(HighestBuyTicketNo, SELECT_BY_TICKET, MODE_TRADES) )
                           {
                              as = ArraySize(ClosureTickets) - 1;
                              result = OrderCloseBy(HighestBuyTicketNo, ClosureTickets[as]);
                              if(!result) 
                                 return(false);
                           }//if (OrderSelect(HighestBuyTicketNo, SELECT_BY_TICKET, MODE_TRADES) )
                           
                           for (cc = ArraySize(ClosureTickets) - 2; cc >= 0; cc--)
                           {
                              if (OrderSelect(ClosureTickets[cc], SELECT_BY_TICKET, MODE_TRADES))
                              {
                                 result = CloseOrder(ClosureTickets[cc]);
                                // Print("Double Sided Complex sell closure"); // for debugging
                                 if (!result)
                                 {
                                    ForceTradeClosure = true;
                                    cc++;
                                    tries++;
                                    if (tries >= 20)//Something has gone wrong
                                    {   
                                       //The closure attempt has failed, but must be retried.
                                       //Save the ticket number in the array
                                       cas = ArraySize(ForceCloseTickets);
                                       ArrayResize(ForceCloseTickets, cas + 1);
                                       ForceCloseTickets[cas] = ClosureTickets[cc];
                                       cc--;//In case something has gone wrong and the trade no longer exists
                                    }//if (tries >= 20)    
                                 }//if (!result)
                              }//if (OrderSelect(ClosureTickets[cc], SELECT_BY_TICKET, MODE_TRADES))                          
                           }//for (cc = ArraySize(ClosureTickets); cc >= 0; cc--)
                        }//while (ForceTradeClosure)
                        if (ArraySize(ForceCloseTickets) == 0)
                        {
                           CountOpenTrades();
                           return(true);
                        }//if (ArraySize(ForceCloseTickets) == 0)
                        else
                        {
                           return(false);
                        }//else                              
                     }//if (ClosePossible)
                  }//if (CashLoss < 0)
               }//if((CalculateTradeProfitInPips(OP_SELL)*-1)>=DistanceBetweenTrades)
            }//if (OrderSelect(HighestBuyTicketNo, SELECT_BY_TICKET, MODE_TRADES))
   
   }//if (Hedged)

//////////////////////////////////////////////////////////////////////////////////////
// Added single side offset below:


   if(AllowComplexSingleSidedOffsets)//then allow buy side single offsets
   {
       CashLoss = 0;
       CashProfit = 0;
       NoOfTrades = 0;
       ArrayResize(ForceCloseTickets, 0);
      
 
      ////////////////////////////////////////////////////////////////
      ///As above but one sided; complex hedge closure - looking for a group of winning buys to close the worst losing buy:     
      //Can we offset some buy trades against the worst losing buy trade?
      //if (BuyCashUpl > 0)//The buy side of the hedge must be profitable overall // not true for single sided
      
      // buy side only variables
      bool ClosePossibleBuySide = false;
      int ClosureTicketsBuySide[];
      ArrayInitialize(ClosureTicketsBuySide, -1);
      
      
      if (MarketBuysCount >= MinOpenTradesToStartOffset)//Must be sufficient trades open to start offsetting
         if (OrderSelect(HighestBuyTicketNo, SELECT_BY_TICKET, MODE_TRADES))//Select the highest buy which will be the worst loser
         {
         
            //Calculate the pips upl of the lowest, and so latest, sell
            if((CalculateTradeProfitInPips(OP_BUY)*-1)>=DistanceBetweenTrades) // Only continue if the trade is losing by more than DistanceBetweenTrades
            {
            
            CashLoss = (OrderSwap() + OrderCommission() + OrderProfit());//Calculate its cash position
            CashLoss*= -1;//Convert to a positive for comparison with the profit on the other side
            //if (CashLoss < 0)//Is it losing?  // changed to check for DistanceBetweenTrades
            if (CashLoss>0)//Only continue if losing by at least 1 grid level
            {
               //Calculate the profit on the other side of the hedge
               for (cc = MarketBuysCount; cc > 0; cc--)
               {
                  if (OrderSelect(GridOrderBuyTickets[cc - 1][TradeTicket], SELECT_BY_TICKET, MODE_TRADES) )
                  {
                     ThisOrderProfit = (OrderSwap() + OrderCommission() + OrderProfit());
                     
                     if (ThisOrderProfit > 0) // only want to include the trade if it is in profit - this also sorts out the trade order issue
                     {
                        NoOfTrades++;
                        ArrayResize(ClosureTicketsBuySide, NoOfTrades);
                        ClosureTicketsBuySide[NoOfTrades - 1] = OrderTicket();
                        CashProfit+= ThisOrderProfit;  // now we can add this trade's profit to the basket of offset trades
                     }// if (ThisOrderProfit > 0)
                  }//if (OrderSelect(FifoBuyTicket[cc - 1][ticket], SELECT_BY_TICKET, MODE_TRADES) )
                  
                  //Is the profit big enough to close the trade on the other side of the hedge?
                  if ((CashProfit) > CashLoss)
                  {
                     //Yippee
                     ClosePossibleBuySide = true;
                     break; // stop for loop here as don't need any more trades
                  }//if ((CashProfit) > CashLoss)
               }//for (int cc = MarketBuysCount; cc >= 0; cc--)
               
               //Are there closures to make?
               if (ClosePossibleBuySide)
               {
                  ForceTradeClosure = true;
                  while (ForceTradeClosure)
                  {
                     ForceTradeClosure = false;
                     if (OrderSelect(HighestBuyTicketNo, SELECT_BY_TICKET, MODE_TRADES) )
                     {
                        result = CloseOrder(HighestBuyTicketNo);
                        if (!result)
                           return(false);
                     }//if (OrderSelect(HighestBuyTicketNo, SELECT_BY_TICKET, MODE_TRADES) )
                     
                     for (cc = ArraySize(ClosureTicketsBuySide) - 1; cc >= 0; cc--)
                     {
                        tries = 0;
                        if (OrderSelect(ClosureTicketsBuySide[cc], SELECT_BY_TICKET, MODE_TRADES))
                        {
                           result = CloseOrder(ClosureTicketsBuySide[cc]);
                          // Print("Single Sided Complex buy closure"); // for debugging
                           
                           if (!result)
                           {
                              ForceTradeClosure = true;
                              cc++;
                              //We need to avoid an endless loop when something goes wrong
                              tries++;
                              if (tries >= 20)//Something has gone wrong
                              {   
                                 //The closure attempt has failed, but must be retried.
                                 //Save the ticket number in the array
                                 cas = ArraySize(ForceCloseTickets);
                                 ArrayResize(ForceCloseTickets, cas + 1);
                                 ForceCloseTickets[cas] = ClosureTicketsBuySide[cc];
                                 cc--;//In case something has gone wrong and the trade no longer exists
                              }//if (tries >= 20)                                      
                           }//if (!result)
                        }//if (OrderSelect(ClosureTickets[cc], SELECT_BY_TICKET, MODE_TRADES))                          
                     }//for (cc = ArraySize(ClosureTickets); cc >= 0; cc--)
                  }//while (ForceTradeClosure)
                  if (ArraySize(ForceCloseTickets) == 0)
                  {
                     CountOpenTrades();
                     return(true);
                  }//if (ArraySize(ForceCloseTickets) == 0)
                  else
                  {
                     return(false);
                  }//else                              
               }// if (ClosePossibleBuySide)
            }//if (CashLoss >= DistanceBetweenTrades)
         }//if((CalculateTradeProfitInPips(OP_BUY)*-1)>=DistanceBetweenTrades)
      }//if (OrderSelect(HighestBuyTicketNo, SELECT_BY_TICKET, MODE_TRADES))
         
      CashLoss = 0;
      CashProfit = 0;
      NoOfTrades = 0;
      ClosePossibleBuySide = false;
      ArrayResize(ClosureTicketsBuySide, 0);
      ArrayInitialize(ClosureTicketsBuySide, -1);
   
   
   //END - buy side only complex hedge
   
   ///////////////////////////////////////////
 
 
   ///One Sided complex hedge closure - looking for a group of winning sells to close the worst losing sell:
      // sell side only variables
      bool ClosePossibleSellSide = false;
      int ClosureTicketsSellSide[];
      ArrayInitialize(ClosureTicketsSellSide, -1);
      
      //Can we offset some sell trades against the lowest losing sell trade
      
      if (MarketSellsCount >= MinOpenTradesToStartOffset)//Must be sufficient trades open to start offsetting
         if (OrderSelect(LowestSellTicketNo, SELECT_BY_TICKET, MODE_TRADES))//Select the lowest sell which will be the worst loser
         {
            
            //Calculate the pips upl of the lowest, and so latest, sell
            if((CalculateTradeProfitInPips(OP_SELL)*-1)>=DistanceBetweenTrades) // Only continue if the trade is losing by more than DistanceBetweenTrades
            {
               CashLoss = (OrderSwap() + OrderCommission() + OrderProfit());//Calculate its cash position
               CashLoss*= -1;//Convert to a positive for comparison with the profit on the other side
               
               //if (CashLoss < 0)//Is it losing?  // changed to check for DistanceBetweenTrades.
               if (CashLoss>0)//Only continue if losing by at least 1 grid level
               {
                  //Calculate the profit on the other side of the hedge
                  for (cc = MarketSellsCount; cc > 0; cc--)
                  {
                                          
                     if (OrderSelect(GridOrderSellTickets[cc - 1][TradeTicket], SELECT_BY_TICKET, MODE_TRADES) )
                     {
                         ThisOrderProfit = (OrderSwap() + OrderCommission() + OrderProfit());
                        
                        if (ThisOrderProfit > 0) // only want to include the trade if it is in profit
                        {
                           NoOfTrades++;
                           ArrayResize(ClosureTicketsSellSide, NoOfTrades);
                           ClosureTicketsSellSide[NoOfTrades - 1] = OrderTicket();
                           CashProfit+= ThisOrderProfit;  // now we can add this trade's profit to the basket of offset trades
                        }//if (ThisOrderProfit > 0)
                     }//if (OrderSelect(GridOrderSellTickets[cc - 1][TradeTicket], SELECT_BY_TICKET, MODE_TRADES) )
                     
                     //Is the profit big enough to close the trade on the other side of the hedge?
                     if ((CashProfit) > CashLoss)
                     {
                        //Yippee
                        ClosePossibleSellSide = true;
                        break; // stop here as don't need any more trades
                     }//if ((CashProfit) > CashLoss)
                  }//for (int cc = MarketSellsCount; cc >= 0; cc--)
                  
                  //Are there closures to make?
                  if (ClosePossibleSellSide)
                  {
                     ForceTradeClosure = true;
                     while (ForceTradeClosure)
                     {
                        ForceTradeClosure = false;
                        if (OrderSelect(LowestSellTicketNo, SELECT_BY_TICKET, MODE_TRADES) )
                        {
                           result = CloseOrder(LowestSellTicketNo);
                           if (!result)
                              return(false);//First trade has not closed, so do not continue
                        }//if (OrderSelect(LowestSellTicketNo, SELECT_BY_TICKET, MODE_TRADES) )
                        
                        for (cc = ArraySize(ClosureTicketsSellSide) - 1; cc >= 0; cc--)
                        {
                           tries = 0;
                           if (OrderSelect(ClosureTicketsSellSide[cc], SELECT_BY_TICKET, MODE_TRADES))
                           {
                              result = CloseOrder(ClosureTicketsSellSide[cc]);
                              
                             // Print("Single Sided Complex sell closure"); // for debugging
                              if (!result)
                              {
                                 ForceTradeClosure = true;
                                 cc++;
                                 //We need to avoid an endless loop when something goes wrong
                                 tries++;
                                 if (tries >= 20)//Something has gone wrong
                                 {   
                                    //The closure attempt has failed, but must be retried.
                                    //Save the ticket number in the array
                                    cas = ArraySize(ForceCloseTickets);
                                    ArrayResize(ForceCloseTickets, cas + 1);
                                    ForceCloseTickets[cas] = ClosureTicketsSellSide[cc];
                                    cc--;//In case something has gone wrong and the trade no longer exists
                                 }//if (tries >= 20)  
                              }//if (!result)
                           }// if (OrderSelect(ClosureTicketsSellSide[cc], SELECT_BY_TICKET, MODE_TRADES))                        
                        }//for (cc = ArraySize(ClosureTicketsSellSide) - 1; cc >= 0; cc--)
                     }//while (ForceTradeClosure)
                     if (ArraySize(ForceCloseTickets) == 0)
                     {
                        CountOpenTrades();
                        return(true);
                     }//if (ArraySize(ForceCloseTickets) == 0)
                     else
                     {
                        return(false);
                     }//else                              

                  }//if (ClosePossibleSellSide)
               }//if (CashLoss >= DistanceBetweenTrades)
            }//if((CalculateTradeProfitInPips(OP_SELL)*-1)>=DistanceBetweenTrades) 
         }//if (OrderSelect(LowestSellTicketNo, SELECT_BY_TICKET, MODE_TRADES))
         
      CashLoss = 0;
      CashProfit = 0;
      NoOfTrades = 0;
   
   //END - sell side only complex hedge
   ///////////////////////////////////////////////////////////////////////////// 
   
 }// if(AllowComplexSingleSidedOffsets)



   // End of added single side offset

   ////////////////////////////////////////////////////////////////////////////
   //Got this far, so no trades closed
   return(false);

}//END bool CanTradesBeOffset()

bool SundayMondayFridayStuff()
{

   //Friday/Saturday stop trading hour
   int d = TimeDayOfWeek(TimeLocal());
   int h = TimeHour(TimeLocal());
   if (d == 5)
      if (h >= FridayStopTradingHour)
         return(false);
         
   if (d == 4)
      if (!TradeThursdayCandle)
         return(false);
        
   
   if (d == 6)
      if (h >= SaturdayStopTradingHour)
         return(false);
  
   //Sunday candle
   if (d == 0)
      if (!TradeSundayCandle)
         return(false);
         
   //Monday start hour
   if (d == 1)
      if (h < MondayStartHour)      
         return(false);
         
   //Got this far, so we are in a trading period
   return(true);      
   
}//End bool  SundayMondayFridayStuff()

void ReadOrCreateBaseLine()
{
   //Reads the base line value if it exists, or creates one if not
  
   if (ObjectFind(BaseLineName) > -1)
   {
      BaseLinePrice = ObjectGet(BaseLineName, OBJPROP_PRICE1);
      return;
   }//if (ObjectFind(BaseLineName) > -1)
   
   //We did not find a base line, so create one
   double price = Bid;
   if (LatestTradeTime > 0)
   {
      if (!OrderSelect(LatestTradeTicketNo, SELECT_BY_TICKET, MODE_TRADES) )
         return;//Something has gone wrong, so try again next tick
         
      price = OrderOpenPrice();   
   }//if (LatestTradeTime > 0)
   
   DrawHorizontalLine(BaseLineName, price, BaseLineColour, STYLE_DOT, 0);
   BaseLinePrice = price;

}//void ReadOrCreateBaseLine()

void CalculateLotAsAmountPerCashDollops()
{

   double lotstep = MarketInfo(Symbol(), MODE_LOTSTEP);
   double decimal = 0;
   if (CloseEnough(lotstep, 0.1) )
      decimal = 1;
   if (CloseEnough(lotstep, 0.01) )
      decimal = 2;
      
   double maxlot = MarketInfo(Symbol(), MODE_MAXLOT);
   double minlot = MarketInfo(Symbol(), MODE_MINLOT);
   double DoshDollop = AccountInfoDouble(ACCOUNT_BALANCE); 
   
   if (UseEquity)
      DoshDollop = AccountInfoDouble(ACCOUNT_EQUITY); 

   
   //Initial lot size
   Lot = NormalizeDouble((DoshDollop / SizeOfDollop) * LotsPerDollopOfCash, decimal);
     
   //Min/max size check
   if (Lot > maxlot)
      Lot = maxlot;
      
   if (Lot < minlot)
      Lot = minlot;      


}//void CalculateLotAsAmountPerCashDollops()

bool MopUpTradeClosureFailures()
{
   //Cycle through the ticket numbers in the ForceCloseTickets array, and attempt to close them
   
   bool Success = true;
   
   for (int cc = ArraySize(ForceCloseTickets) - 1; cc >= 0; cc--)
   {
      //Order might have closed during a previous attempt, so ensure it is still open.
      if (!OrderSelect(ForceCloseTickets[cc], SELECT_BY_TICKET, MODE_TRADES) )
         continue;
   
      bool result = CloseOrder(OrderTicket() );
      if (!result)
         Success = false;
   }//for (int cc = ArraySize(ForceCloseTickets) - 1; cc >= 0; cc--)
   
   if (Success)
      ArrayResize(ForceCloseTickets, 0);
   
   return(Success);


}//END bool MopUpTradeClosureFailures()

double GetHGI(string symbol, int tf, int buffer, int shift)
{

   //return(iCustom(symbol, tf, HGI_Name, 0, false, false, false, false, false, false, false, buffer, shift) );
   return(iCustom(symbol, tf, HGI_Name, true, buffer, shift));
   
}//double GetHGI()

void DeleteSixthsLines()
{
   for (int i=0;i<=7;i++) {
     ObjectDelete(IndiPrefix+i);
     ObjectDelete(IndiPrefix+"Future"+i);
   }
   ObjectDelete(IndiPrefix+"AnchorTime");
}

void GetSixths(string symbol, int tf, int barcount, int shift)
{

   SixthsHigh = High[iHighest(symbol,tf,MODE_HIGH,barcount,shift)];
   SixthsLow  = Low[iLowest(symbol,tf,MODE_LOW,barcount,shift)];
   SixthsVal = SixthsHigh-SixthsLow;      //SixthsVal top of the chart - SixthsVal buttom
   SixthsHeight = SixthsVal/6;

   SixthLineVal[1] = SixthsLow;
   SixthLineVal[7] = SixthsHigh;
   color SixthsColor[] = {clrNONE,Blue,Gold,Green,Magenta,Green,Gold,Blue};
   DeleteSixthsLines();

    ObjectCreate(IndiPrefix+1,OBJ_TREND,0,Time[shift],SixthsLow,Time[shift+barcount],SixthsLow);
    ObjectSet(IndiPrefix+1,OBJPROP_COLOR,SixthsColor[1]);
    ObjectSet(IndiPrefix+1,OBJPROP_STYLE,STYLE_SOLID);
    ObjectSet(IndiPrefix+1,OBJPROP_WIDTH,2);
    ObjectSet(IndiPrefix+1,OBJPROP_RAY,false);
   
    //draw dashed lines as "future continuation" of Sixth Lines
    ObjectCreate(IndiPrefix+"Future"+1,OBJ_TREND,0,Time[shift],SixthsLow,Time[shift]+barcount/4*Period()*60,SixthsLow);
    ObjectSet(IndiPrefix+"Future"+1,OBJPROP_COLOR,SixthsColor[1]);
    ObjectSet(IndiPrefix+"Future"+1,OBJPROP_STYLE,STYLE_DASH);
    ObjectSet(IndiPrefix+"Future"+1,OBJPROP_RAY,false);

  
   for (int cc = 2; cc <= 6; cc++)
   {
       SixthLineVal[cc] = SixthsLow + (SixthsHeight * (cc - 1));

       ObjectCreate(IndiPrefix+cc,OBJ_TREND,0,Time[shift],SixthsLow+(cc-1)*SixthsHeight,Time[shift+barcount],SixthsLow+(cc-1)*SixthsHeight);
       ObjectSet(IndiPrefix+cc,OBJPROP_COLOR,SixthsColor[cc]);
       ObjectSet(IndiPrefix+cc,OBJPROP_STYLE,STYLE_SOLID);
       ObjectSet(IndiPrefix+cc,OBJPROP_WIDTH,2);
       ObjectSet(IndiPrefix+cc,OBJPROP_RAY,false);
      
       //draw dashed lines as "future continuation" of Sixth Lines
       ObjectCreate(IndiPrefix+"Future"+cc,OBJ_TREND,0,Time[shift],SixthsLow+(cc-1)*SixthsHeight,Time[shift]+barcount/4*Period()*60,SixthsLow+(cc-1)*SixthsHeight);
       ObjectSet(IndiPrefix+"Future"+cc,OBJPROP_COLOR,SixthsColor[cc]);
       ObjectSet(IndiPrefix+"Future"+cc,OBJPROP_STYLE,STYLE_DASH);
       ObjectSet(IndiPrefix+"Future"+cc,OBJPROP_RAY,false);
      
   }//for (int cc = 1; cc <= 6; cc++)

    ObjectCreate(IndiPrefix+7,OBJ_TREND,0,Time[shift],SixthsHigh,Time[shift+barcount],SixthsHigh);
    ObjectSet(IndiPrefix+7,OBJPROP_COLOR,SixthsColor[7]);
    ObjectSet(IndiPrefix+7,OBJPROP_STYLE,STYLE_SOLID);
    ObjectSet(IndiPrefix+7,OBJPROP_WIDTH,2);
    ObjectSet(IndiPrefix+7,OBJPROP_RAY,false);
   
    //draw dashed lines as "future continuation" of Sixth Lines
    ObjectCreate(IndiPrefix+"Future"+7,OBJ_TREND,0,Time[shift],SixthsHigh,Time[shift]+barcount/4*Period()*60,SixthsHigh);
    ObjectSet(IndiPrefix+"Future"+7,OBJPROP_COLOR,SixthsColor[7]);
    ObjectSet(IndiPrefix+"Future"+7,OBJPROP_STYLE,STYLE_DASH);
    ObjectSet(IndiPrefix+"Future"+7,OBJPROP_RAY,false);


   // draw a vertical line at the anchor point of the SixthLines
   ObjectCreate(IndiPrefix+"AnchorTime",OBJ_VLINE,0,Time[shift],0);
   ObjectSet(IndiPrefix+"AnchorTime",OBJPROP_COLOR,Gold);
   ObjectSet(IndiPrefix+"AnchorTime",OBJPROP_STYLE,STYLE_DOT);


}//End void GetSixths(string symbol, int tf, int bars)


void ReadIndicatorValues()
{

   
   
   double val = 0;
   static datetime OldHgiReadTime = 0;
            
   
   /////////////////////////////////////////////////////////////////////////////////////
   //Read HGI only if necessary    
   if (UseTJF)
      if (Hedged)
         if (OldHgiReadTime <= TimeCurrent() )
         {
            OldHgiReadTime = TimeCurrent() + HgiReadDelaySeconds;
            
            BuyCloseSignal = false;
            SellCloseSignal = false;
            
            ///////////////////////////////////////
            //Indi reading code goes here
            HgiStatus = hginosignal;
            
            //Buffer 0 holds a buy trend arrow - large green up
            val=GetHGI(Symbol(),HgiTimeFrame,0,0);
            if(!CloseEnough(val,EMPTY_VALUE))
            {
               HgiStatus = Trenduparrow;
            }//if (!CloseEnough(val 0) )         
            else
            {
               //Buffer 1 hods a sell trend arrrow - large red down
               val=GetHGI(Symbol(),HgiTimeFrame,1,0);
               if(!CloseEnough(val,EMPTY_VALUE))
               {
                  HgiStatus = Trenddownarrow;
               }//if (!CloseEnough(val 0) 
               else
               {
                  //Buffer 7 holds a wavy trend - blue squiggle
                  val=GetHGI(Symbol(),HgiTimeFrame,7,0);
                  if(!CloseEnough(val,EMPTY_VALUE))
                  {
                     if(Bid>val)
                        HgiStatus = Wavebuytrend;
                     else
                        HgiStatus = Waveselltrend;
                  }//if (!CloseEnough(val 0) )  
                  else
                  {
                     if (CloseHedgeOnYellowWave)
                     {
                        //Look for a yellow range squggle.
                        //Buffer 6 holds a wavy range - yellow squiggle
                        val=GetHGI(Symbol(),HgiTimeFrame,6,0);
               
                        if(!CloseEnough(val,EMPTY_VALUE))
                        {
                           HgiStatus = Waverange;
                        }//if (!CloseEnough(val 0) )    
                     }//if (CloseHedgeOnYellowWave)
                  }//else                  
               }//else
            }//else
               
            ///////////////////////////////////////
            //Anything else?
            
            
            ///////////////////////////////////////
            
            
            //Close trades on an opposite direction signal
            if (CloseHedgeOnYellowWave && HgiStatus == Waverange)
            {
               SellCloseSignal = true;
               BuyCloseSignal = true;
            }//if (CloseHedgeOnYellowWave && HgiStatus == Waverange)
            
            if (HgiStatus == Trenduparrow || HgiStatus == Wavebuytrend)
               SellCloseSignal = true;
               
            if (HgiStatus == Trenddownarrow || HgiStatus == Waveselltrend)
               BuyCloseSignal = true;
               
            
         }//if (OldHgiReadTime <= TimeCurrent() )
         
   /////////////////////////////////////////////////////////////////////////////////////
   
   //Sixths for TJF defensive hedge closure
   if (UseSixths)
   {
      static datetime OldSixReadTime=0;
      if (OldSixReadTime != iTime(Symbol(), SixthTimeFrame, 0) )
      {
         OldSixReadTime = iTime(Symbol(), SixthTimeFrame, 0);
       
         
         GetSixths(Symbol(), SixthTimeFrame, BarCount, 1);
      
      }//if (OldSixReadTime != iTime(Symbol(), SixthTimeFrame, 0) )
   
      //Is there a defensive hedge in place? If so, can it be closed.
      if (!BuyCloseSignal)
         if (!SellCloseSignal)
            if (TjfHedgeOpen)
            {
               if (OrderSelect(TjfTicketNo, SELECT_BY_TICKET, MODE_TRADES) )
               {
                  double target = 0;
                  
                  if (OrderType() == OP_BUY)
                  {
                     target = SixthLineVal[7] - (ClosureDistance / factor);
                     //Did either the current or the previous candle open above target
                     if (iOpen(Symbol(), SixthTimeFrame, 0) > target || iOpen(Symbol(), SixthTimeFrame, 1) > target )
                        //Is the market below target
                        if (Bid < target)
                           BuyCloseSignal = true;
                  }//if (OrderType() == OP_BUY)
                  
                  if (OrderType() == OP_SELL)
                  {
                     target = SixthLineVal[1] + (ClosureDistance / factor);
                     //Did either the current or the previous candle open below target
                     if (iOpen(Symbol(), SixthTimeFrame, 0) < target || iOpen(Symbol(), SixthTimeFrame, 1) < target )
                        //Is the market above target
                        if (Bid > target)
                           SellCloseSignal = true;
                  }//if (OrderType() == OP_SELL)
                  
                  
               }//if (OrderSelect(TjfTicketNo, SELECT_BY_TICKET, MODE_TRADES) )
            }//if (TjfHedgeOpen)
            
      
   }//if (UseSixths)
         

}//void ReadIndicatorValues()
//End Indicator module
////////////////////////////////////////////////////////////////////////////////////////

void DoWeNeedDefensiveHedge()
{
   //Function called from start() if there is not already a hedge in place
   //and there is an HGI signal.
   
   //Is the position sufficiently imbalanced as to cause a need for a defensive hedge?
   if (MathAbs(MarketBuysCount - MarketSellsCount < MinimumTradesToCauseImBalance) )
      return;//Nope
   
   
   //It is, so set up some variables
   int type = 0;
   double SendLots = 0;
   
   //Define the trade to be sent
   //Too many sells?
   if (MarketSellsCount > MarketBuysCount)   
   {
      //Only send a defensive hedge on an HGI signal
      if (HgiStatus == Trenduparrow || HgiStatus == Wavebuytrend)
      {   
         type = OP_BUY;
         SendLots = TotalSellLots - TotalBuyLots;
      }//if (HgiStatus == Trenduparrow || HgiStatus == Wavebuytrend)      
   }//if (MarketSellsCount > MarketBuysCount)   
   
   //Too many buys?
   if (MarketBuysCount > MarketSellsCount)   
   {
      //Only send a defensive hedge on an HGI signal
      if (HgiStatus == Trenddownarrow || HgiStatus == Waveselltrend)
      {
         type = OP_SELL;
         SendLots = TotalBuyLots - TotalSellLots;
      }//if (HgiStatus == Trenddownarrow || HgiStatus == Waveselltrend)
   }//if (MarketBuysCount > MarketSellsCount)   
   
   
   SendSingleTrade(Symbol(), type, TjfHedgeComment, SendLots, Bid, 0, 0);

}//End void DoWeNeedDefensiveHedge()


//+------------------------------------------------------------------+
//| expert start function                                            |
//+------------------------------------------------------------------+
void OnTick()
{
//----
   //`int cc;
   
   if (RemoveExpert)
   {
      ExpertRemove();
      return;
   }//if (RemoveExpert)
   

   //Those stupid sods at MetaCrapper have ensured that stopping an ea by diabling AutoTrading no longer works. Ye Gods alone know why.
   //This routine provided by FxCoder. Thanks Bob.
   if ( !TerminalInfoInteger(TERMINAL_TRADE_ALLOWED) )
   {
      Comment("                          TERMINAL AUTOTRADING IS DISABLED");
      return;
      
   }//if ( !TerminalInfoInteger(TERMINAL_TRADE_ALLOWED) )
   if (!IsTradeAllowed() )
   {
      Comment("                          THIS EXPERT HAS LIVE TRADING DISABLED");
      return;
   }//if (!IsTradeAllowed() )
     
   //In case any trade closures failed
   if (ArraySize(ForceCloseTickets) > 0)
   {
      if (!MopUpTradeClosureFailures() )
         return;
   }//if (ArraySize(ForceCloseTickets) > 0)      


   //Spread calculation
   if (!IsTesting() )
   {   
      if(CloseEnough(AverageSpread,0) || RunInSpreadDetectionMode)
      {
         GetAverageSpread();
         ScreenMessage="";
         int left=TicksToCount-CountedTicks;
         SM("Calculating the average spread. "+DoubleToStr(left,0)+" left to count.");
         Comment(ScreenMessage);
         return;
      }//if (CloseEnough(AverageSpread, 0) || RunInSpreadDetectionMode) 
      //Keep the average spread updated
      double spread=(Ask-Bid)*factor;
      if(spread>BiggestSpread) BiggestSpread=spread;//Widest spread since the EA was loaded
      static double SpreadTotal=0;
      static int counter=0;
      SpreadTotal+=spread;
      counter++;
      if(counter>=500)
      {
         AverageSpread=NormalizeDouble(SpreadTotal/counter,1);
         //Save the average for restarts.
         GlobalVariableSet(SpreadGvName,AverageSpread);
         SpreadTotal=0;
         counter=0;
      }//if (counter >= 500)
   }//if (!IsTesting() )

   //Create a flashing comment if there has been a rogue trade
   if (RobotSuspended) 
   {
      while (RobotSuspended)
      {
         Comment(NL, Gap, "****************** ROBOT SUSPENDED. POSSIBLE ROGUE TRADING ACTIVITY. REMOVE THIE EA IMMEDIATELY ****************** ");
         Sleep(2000);
         Comment("");
         Sleep(1000);
         if ( !TerminalInfoInteger(TERMINAL_TRADE_ALLOWED) )
            return;
      }//while (RobotSuspended)           
      return;
   }//if (RobotSuspended) 

   //If HG is sleeping after a trade closure, is it time to awake?
   //TooClose();
   if(SafetyViolation)//TooClose() sets SafetyViolation
   {
      DisplayUserFeedback();
      return;
   }//if (SafetyViolation) 

   
/*
   People get twitchy when reading the code being removed from the ex4 file warning, so here is a neat method of turning off a function without deleting it, just in case you change your mind and want it later. 
   */
   if(TurnOff==1)
   {
      CalculateTradeProfitInPips(OP_BUY);//TurnOff is never 1, so the function is not called
      CloseEnough(1,1);
      DrawTrendLine("w",0,0,0,0,0,0,0,true);
      DrawHorizontalLine("w",0,0,0,0);
      DrawVerticalLine("w",Red,STYLE_DASH,0);
   }//if (TurnOff == 1) 

   if(OrdersTotal()==0)
   {
      TicketNo=-1;
      ForceTradeClosure=false;
   }//if (OrdersTotal() == 0)

   if(ForceTradeClosure)
   {
      CountOpenTrades();//Rebuild the picture
      CloseAllTrades(AllTrades);
      return;
   }//if (ForceTradeClosure) 

   //Check for a massive spread widening event and pause the ea whilst it is happening
   if (!IsTesting() )
      CheckForSpreadWidening();

   
   
   //Daily results so far - they work on what in in the history tab, so users need warning that
   //what they see displayed on screen depends on that.   
   //Code courtesy of TIG yet again. Thanks, George.
   static int OldHistoryTotal;
   if(OrdersHistoryTotal()!=OldHistoryTotal)
   {
      CalculateDailyResult();//Does no harm to have a recalc from time to time
      OldHistoryTotal=OrdersHistoryTotal();
   }//if (OrdersHistoryTotal() != OldHistoryTotal)

   
   
///////////////////////////////////////////////////////////////////////////////////
   //Find open trades.
   CountOpenTrades();
   //Lot size based on account size
   if (OpenTrades == 0)
      if (!CloseEnough(LotsPerDollopOfCash, 0))
         CalculateLotAsAmountPerCashDollops();
   
   //Read or create the base line
   ReadOrCreateBaseLine();
   
   ReadIndicatorValues();

   OldOpenTrades=OpenTrades;
   //Can we close a defensive hedge
   if (TjfHedgeOpen)
   {
      bool result = LookForTradeClosure(TjfTicketNo);
      if (result)
      {
         CountOpenTrades();
         DisplayUserFeedback();
         return;
      }//if (result)
   }//if (TjfHedgeOpen)
   
   //If no defensive hedge already open, do we need one?
   if (Hedged)
      if (UseTJF)
         if (!TjfHedgeOpen)
            if (HgiStatus != hginosignal)
               if (HgiStatus != Waverange)
                  DoWeNeedDefensiveHedge();
      
   //Reset various variables
   if(OpenTrades==0)
   {

   }//if (OpenTrades > 0)
   
   //The next function deals with hedge/basket closures, so uncomment it to use
   //Calculate the emergency stop loss
   if (!CloseEnough(EmergencyStopLossPercentageOfBalance, 0))
   {
      EmergencyStopLoss = AccountBalance() * (EmergencyStopLossPercentageOfBalance / 100);
      if (EmergencyStopLoss > 0)//It should be but I like to make sure of stuff like this
         EmergencyStopLoss*= -1;
   }//if (!CloseEnough(EmergencyStopLossPercentageOfBalance, 0))
   
   //Calculate the partial emergency stop loss. Bruster again. Thanks fella.
   if (!CloseEnough(PartialEmergencyStopLossPercentOfBalance, 0))
   {
      PartialEmergencyStopLoss = AccountBalance() * (PartialEmergencyStopLossPercentOfBalance / 100);
      if (PartialEmergencyStopLoss > 0)//It should be but I like to make sure of stuff like this
         PartialEmergencyStopLoss*= -1;
   }//if (!CloseEnough(PartialEmergencyStopLossPercentOfBalance, 0))
   
   if (!TjfHedgeOpen)
      ShouldTradesBeClosed();
   if (ArraySize(ForceCloseTickets) > 0)
   {
      MopUpTradeClosureFailures();
      return;
   }//if (ArraySize(ForceCloseTickets) > 0)      

///////////////////////////////////////////////////////////////////////////////////

   
   //Trading times
   TradeTimeOk=CheckTradingTimes();
   if(!TradeTimeOk)
   {
      DisplayUserFeedback();
      Sleep(1000);
      
      return;
   }//if (!TradeTimeOk)

   //Sunday trading, Monday start time, Friday stop time, Thursday trading
   TradeTimeOk = SundayMondayFridayStuff();
   if (!TradeTimeOk)
   {
      DisplayUserFeedback();
      return;
   }//if (!TradeTimeOk)

///////////////////////////////////////////////////////////////////////////////////

   //mptm sets a Global Variable when it is closing the trades.
   //This tells this ea not to send any fresh trades.
   if (GlobalVariableCheck(GvName))
      return;
   
   //Trading
   if (!TjfHedgeOpen)
      if (TimeCurrent() >= TimeToStartTrading)
         if (!StopTrading)            
         {
            TimeToStartTrading = 0;//Set to TimeCurrent() + (PostTradeAttemptWaitMinutes * 60) when there is an OrderSend() attempt)
            LookForTradingOpportunities();
         }//if (!StopTrading)
   
///////////////////////////////////////////////////////////////////////////////////

   DisplayUserFeedback();

//----
   return;
}
// for 6xx build compatibilità added by milanese


//+------------------------------------------------------------------+
