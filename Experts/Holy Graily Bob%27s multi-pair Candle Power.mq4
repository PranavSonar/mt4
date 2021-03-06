//+------------------------------------------------------------------+
//|                    Holy Graily Bob's multi-pair Candle Power.mq4 |
//|                                           Steve Hopwood + Tomele |
//|                                https://www.stevehopwoodforex.com |
//+------------------------------------------------------------------+
#property copyright "Steve Hopwood"
#property link      "https://www.stevehopwoodforex.com"
#property strict
#define version "Version 1f"

/*
The dashboard code is provided by Thomas. Thanks Thomas; you are a star. 
This EA is Thomas' original "Thomas´ CP dashboard EA" with automated 
trading added by me. 
*/

//#include <WinUser32.mqh>
#include <stdlib.mqh>

//Code to minimise charts provided by Rene. Many thanks again, Rene.
#import "user32.dll"
int GetParent(int hWnd);
bool ShowWindow(int hWnd, int nCmdShow);
#import

#define  AllTrades 10 //Tells CloseAllTrades() to close/delete everything belonging to the passed symbol
#define  AllSymbols "All symbols"//Tells CloseAllTrades() to close/delete everything on the platform, regardless of pair
#define  million 1000000;
//Define the FifoBuy/SellTicket fields for offsetting
#define  TradeTicket 1

#define  SW_FORCEMINIMIZE   11
#define  SW_MAXIMIZE         3

#define  up "Up"
#define  down "Down"
#define  NL    "\n"

//Using hgi_lib
//The HGI library functionality was added by tomele. Many thanks Thomas.
#import "hgi_lib.ex4"
   enum SIGNAL {NONE=0,TRENDUP=1,TRENDDN=2,RANGEUP=3,RANGEDN=4,RADUP=5,RADDN=6};
   enum SLOPE {UNDEFINED=0,RANGEABOVE=1,RANGEBELOW=2,TRENDABOVE=3,TRENDBELOW=4};
   SIGNAL getHGISignal(string symbol,int timeframe,int shift);
   SLOPE getHGISlope (string symbol,int timeframe,int shift);
#import

//HGI constants
#define  hginoarrow "No signal"
#define  hgiuparrowtradable "Up arrow"
#define  hgidownarrowtradable "Dn arrow"
#define  hgibluewavylong "Up wave"
#define  hgibluewavyshort "Dn wave"
//Yellow wavy
#define  hgiyellowwavy "Yellow range wave"

//SuperSlope colours
#define  red "Red"
#define  blue "Blue"
//Changed by tomele
#define white "White"

//Peaky status
#define  longdirection "Long"
#define  shortdirection "Short"

//Trading status
#define  tradablelong "Tradable long"
#define  tradableshort "Tradable short"
#define  untradable "Not tradable"

//Spread array fields
enum SpreadFields
{
   currentspread = 0,
   averagespread = 1,
   spreadtotalsofar = 2,
   biggestspread = 3,
   tickscounted = 4,
   previousask=5,
};

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



extern string  cau="---- Chart automation ----";
//These inputs tell the ea to automate opening/closing of charts and
//what to load onto them
extern   bool  AutomateChartOpeningAndClosing=true;
extern bool    MinimiseChartsAfterOpening=false;
extern string  ReservedPair="XAUUSD";
extern string  TemplateName="CP M5";
extern string  s1="================================================================";
extern string  oad               ="---- Other stuff ----";
extern string  PairsToTrade   = "AUDCAD,AUDCHF,AUDNZD,AUDJPY,AUDUSD,CADCHF,CADJPY,CHFJPY,EURAUD,EURCAD,EURCHF,EURGBP,EURNZD,EURJPY,EURUSD,GBPCHF,GBPJPY,GBPUSD,NZDUSD,NZDJPY,USDCAD,USDCHF,USDJPY";
extern ENUM_TIMEFRAMES TradingTimeFrame=PERIOD_M5;
extern int     EventTimerIntervalSeconds=1;
extern int     ChartCloseTimerMultiple=15;
////////////////////////////////////////////////////////////////////////////////
int            NoOfPairs;// Holds the number of pairs passed by the user via the inputs screen
string         TradePair[]; //Array to hold the pairs traded by the user
string         tradingStatus[];//One of the trading status constants
datetime       ttfCandleTime[];
double         ask=0, bid=0, spread=0;//Replaces Ask. Bid, Digits. factor replaces Point
int            digits;//Replaces Digits.
double         longSwap=0, shortSwap=0;
int            OpenLongTrades=0, OpenShortTrades=0;
bool           BuySignal[], SellSignal[];
string         TradingTimeFrameDisplay="";
int            TimerCount=0;//Count timer events for closing charts
bool           ForceTradeClosure=false;
datetime       OldIndiReadBarTime[];//Read the indis at the open of each trading time frame bar
////////////////////////////////////////////////////////////////////////////////

extern string  ndt="================================================================";
extern string  orig="---- For non-directional trading ----";
extern string  hgi="-- HGI Inputs --"; 
extern ENUM_TIMEFRAMES HgiTimeFrame=PERIOD_M5;
extern bool    CloseOnLargeArrows=false;
extern bool    CloseOnBlueWavy=false;
extern bool    OnlyCloseWinningTrades=true;
////////////////////////////////////////////////////////////////////////////////////////
string         HgiStatus[];//Constants defined at top of file//Amended HGI code
string         HgiTimeFrameDisplay="";
datetime       OldNdHgiBarTime[];
////////////////////////////////////////////////////////////////////////////////////////

extern string  ads1="================================================================";
//Additional strategies. These can be used in conjunction with all the original Candle Power
//features. 
extern string  DirectionalTrading="---- Directional trade filters ----";
extern string  thgi="-- HGI --";
extern bool    UseHgiTrendFilter=true;
extern ENUM_TIMEFRAMES HgiTradeFilterTimeFrame=PERIOD_H4;
extern bool    TradeTrendArrows=true;
extern bool    TradeBlueWavyLines=true;
extern bool    HgiCloseOnOppositeSignal=true;
extern bool    HgiCloseOnYellowWavy=false;
////////////////////////////////////////////////////////////////////////////////////////
string         TradeHgiStatus[];//Constants defined at top of file//Amended HGI code
string         TradeHgiTimeFrameDisplay="";
////////////////////////////////////////////////////////////////////////////////////////

extern string  asep1="----";
extern string  ssl="-- Super Slope --";
extern bool    UseSuperSlope=true;
extern ENUM_TIMEFRAMES SsTimeFrame=PERIOD_D1;
extern int     SsTradingMaxBars              = 0;
extern bool    SsTradingAutoTimeFrame        = true;
extern double  SsTradingDifferenceThreshold  = 0.0;
extern double  SsTradingLevelCrossValue      = 2.0;
extern int     SsTradingSlopeMAPeriod        = 5; 
extern int     SsTradingSlopeATRPeriod       = 50; 
extern bool    SsCloseTradesOnColourChange=true;
////////////////////////////////////////////////////////////////////////////////////////
string         SsStatus[];//Colours defined at top of file
string         SsTimeFrameDisplay="";
////////////////////////////////////////////////////////////////////////////////////////

extern string  asep2="----";
//Bob's H4 240 trend filter. Market above the ma = buy only; below ma = sell only
extern string  mai="---- Moving average ----";
extern bool    UseBobMovingAverage=false;
//Defaults to Bob's favourite
extern ENUM_TIMEFRAMES MaTimeFrame=PERIOD_H4;
 int     MaShift=0;
extern int     MaPeriod=240;
extern ENUM_MA_METHOD MaMethod= MODE_EMA;
extern ENUM_APPLIED_PRICE MaAppliedPrice=PRICE_CLOSE;
extern bool    MaCloseTradesOnTrendChange=true;
////////////////////////////////////////////////////////////////////////////////////////
string         MaStatus[];//up, down or none constants
string         MaTimeFrameDisplay="";
////////////////////////////////////////////////////////////////////////////////////////

extern string  asep3="----";
extern string  pea="-- Peaky --";
extern bool    UsePeaky = true;
extern ENUM_TIMEFRAMES PeakyTimeFrame=PERIOD_M5;
extern int     NoOfBarsOnChart=1682;
extern bool    PeakyCloseTradesOnDirectionChange=true;
////////////////////////////////////////////////////////////////////////////////////////
string         PeakyStatus[];// One of the longdirection/shortdirection constants
string         PeakyTimeFrameDisplay="";
datetime       OldPeakyBarTime[];//Hold the open time of each candle.
////////////////////////////////////////////////////////////////////////////////////////

extern string  tsep1="================================================================";
extern string  tsep2="================================================================";
extern string  tsep3="================================================================";
extern string  aut="---- Using the dashboard as an auto-trader ----";
extern bool    AutoTradingEnabled=true;
extern double  Lot=0.01;
//Set RiskPercent to zero to disable and use Lot
extern double  RiskPercent=0;
//LotsPerDollopOfCash over rides Lot. Zero input to cancel.
extern double  LotsPerDollopOfCash=0;
extern double  SizeOfDollop=1000;
extern bool    UseBalance=false;
extern bool    UseEquity=true;
//extern int     MaxTradesAllowed=1;//For multi-trade EA's
extern int     MinDistanceBetweenTradesPips;
extern bool    StopTrading=false;
extern bool    TradeLong=true;
extern bool    TradeShort=true;
extern int     TakeProfitPips=0;
extern int     StopLossPips=0;
extern int     MagicNumber=0;
extern string  TradeComment="Candle Power multi-pair";
extern bool    IsGlobalPrimeOrECNCriminal=false;
extern int     MaxSlippagePips=5;
//We need more safety to combat the cretins at Crapperquotes managing to break Matt's OR code occasionally.
//EA will make no further attempt to trade for PostTradeAttemptWaitSeconds seconds, whether OR detects a receipt return or not.
extern int     PostTradeAttemptWaitSeconds=60;
////////////////////////////////////////////////////////////////////////////////////////
datetime       TimeToStartTrading[];//Re-start calling LookForTradingOpportunities() at this time.
double         TakeProfit, StopLoss;
string         GvName="Under management flag";//The name of the GV that tells the EA not to send trades whilst the manager is closing them.
//'Close all trades this pair only script' sets a GV to tell EA's not to attempt a trade during closure
string         LocalGvName = "Local closure in operation " + Symbol();
//'Nuclear option script' sets a GV to tell EA's not to attempt a trade during closure
string         NuclearGvName = "Nuclear option closure in operation " + Symbol();
//For FIFO
int            FifoTicket[];//Array to store trade ticket numbers in FIFO mode, to cater for
                            //US citizens and to make iterating through the trade closure loop 
                            //quicker.
//An array to store ticket numbers of trades that need closing, should an offsetting OrderClose fail
int            ForceCloseTickets[];
bool           RemoveExpert=false;
double         MinDistanceBetweenTrades=0;
////////////////////////////////////////////////////////////////////////////////////////

extern string  sep2="================================================================";
extern string  btp="---- Hedged Basket take profit inputs ----";
extern int     HedgedBasketCashTakeProfit=20;
////////////////////////////////////////////////////////////////////////////////////////
bool           Hedged=false;
////////////////////////////////////////////////////////////////////////////////////////

extern string  sepb="================================================================";
extern string  off="---- Offsetting ----";
//Simple offset and double-sided complex offset
extern bool    UseOffsetting=false;
//Allow complex single-sided offset. Not allowed if UseOffsetting = false
extern bool    AllowComplexSingleSidedOffsets=true;
//Only use offsetting if there are at least this number of trades in the group
extern int     MinOpenTradesToStartOffset=4;

extern string  sep2a="================================================================";
extern string  ubp="---- Unbalanced positions inputs ----";
extern int     PositionIsUnbalancedAt=5;//The difference between open buys and sells to constitute an unbalanced position.
                                        //Set this to a high value to disable the feature.
extern string  rec="-- Offsetting for unbalanced positions --";
extern bool    UseOffsettingForBalanceRecovery=false;
//Allow complex single-sided offset. Not allowed if UseOffsetting = false
extern bool    AllowComplexSingleSidedOffsetsRecovery=true;
extern int     MinTradesToStartUnbalancedOffset=6;
extern string  nco="-- Nuclear option closure --";
//Close the position the moment it becomes unbalanced.
extern bool    UseInstantClosure=false;
//Only close when the margin level drops
extern bool    UseMarginLevelClosure=false;
//to this point.
extern int     ClosureMarginLevel=500;     
////////////////////////////////////////////////////////////////////////////////////////
//Some variables to turn off the management features to allow for a form of
//recovery basket trading in an unbalanced position.
bool           AllowTradeManagement=true, Unbalanced=false;
////////////////////////////////////////////////////////////////////////////////////////

//Basket trading individual pairs
extern string  sep7="================================================================";
extern string  tbb="---- Trading individual pairs as a basket ----";
extern bool    TradeIndividualPairsAsBasket=false;
//Use IndividualPairsBasketCashTarget as the target if TradeIndividualPairsAsBasket is enabled 
extern bool    UseIndividualPairsBasketCashTarget=false;
extern double  IndividualPairsBasketCashTarget=0;
//Use IndividualPairsBasketPipsTarget as the target if TradeIndividualPairsAsBasket is enabled 
extern bool    UseIndividualPairsBasketPipsTarget=false;
extern int     IndividualPairsBasketPipsTarget=0;

//Basket trading every trade
extern string  sep7f="================================================================";
extern string  tbp="---- Trading all trades as a basket ----";
extern bool    TradeWholePositionAsBasket=false;
//Use WholePositionBasketCashTarget as the target if TradeWholePositionAsBasket is enabled 
extern bool    UseWholePositionBasketCashTarget=false;
extern double  WholePositionBasketCashTarget=0;
//Use WholePositionBasketPipsTarget as the target if UseWholePositionBasketPipsTarget is enabled 
extern bool    UseWholePositionBasketPipsTarget=false;
extern int     WholePositionBasketPipsTarget=0;
////////////////////////////////////////////////////////////////////////////////////////
double         WholePositionCashUpl=0, WholePositionPipsUpl=0;
bool           WholePositionForceTradeClosure = false;
////////////////////////////////////////////////////////////////////////////////////////

extern string  sep1a="================================================================";
extern string  sfs="----SafetyFeature----";
//Minimum time to pass after a trade closes, until the ea can open another.
extern int     MinMinutesBetweenTrades=0;
////////////////////////////////////////////////////////////////////////////////////////
bool           SafetyViolation;//For chart display
bool           RobotSuspended=false;
////////////////////////////////////////////////////////////////////////////////////////

extern string  sep7c="================================================================";
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
//Ignore signals at and after this time on Friday.
//Local time input. >23 to disable.
extern int     FridayStopTradingHour=14;
//Friday time to close all open trades/delete stop orders for the weekend.
//Local time input. >23 to disable.
extern int     FridayCloseAllHour=20;
//For those in Upside Down Land.  
extern int     SaturdayStopTradingHour=24;
//For those in Upside Down Land.
//Local time input. >23 to disable.
extern int     SaturdayCloseAllHour=24;  
//Only close all trades when the negative cash upl is less than this.
//Converted into a negative value in OnInit()
extern int     MaxAllowableCashLoss=-20;
extern bool    TradeSundayCandle=false;
//24h local time     
extern int     MondayStartHour=8;
//Thursday tends to be a reversal day, so avoid it.                               
 bool    TradeThursdayCandle=true;

//This code by tomele. Thank you Thomas. Wonderful stuff.
extern string  sep7b="================================================================";
extern string  roll="---- Rollover time ----";
extern bool    DisableEaDuringRollover=true;
extern string  ro1 = "Use 24H format, SERVER time.";
extern string  ro2 = "Example: '23.55'";
extern string  RollOverStarts="23.55";
extern string  RollOverEnds="00.15";
////////////////////////////////////////////////////////////////////////////////////////
bool           RolloverInProgress=false;//Tells DisplayUserFeedback() to display the rollover message
////////////////////////////////////////////////////////////////////////////////////////

extern string  sep8="================================================================";
extern string  bf="----Trading balance filters----";
extern bool    UseZeljko=false;
extern bool    OnlyTradeCurrencyTwice=false;
////////////////////////////////////////////////////////////////////////////////////////
bool           CanTradeThisPair;
////////////////////////////////////////////////////////////////////////////////////////

extern string  sep9="================================================================";
extern string  pts="----Swap filter----";
extern bool    CadPairsPositiveOnly=false;
extern bool    AudPairsPositiveOnly=false;
extern bool    NzdPairsPositiveOnly=false;
extern bool    OnlyTradePositiveSwap=false;
////////////////////////////////////////////////////////////////////////////////////////
double         LongSwap,ShortSwap;
////////////////////////////////////////////////////////////////////////////////////////

extern string  sep10="================================================================";
extern string  amc="----Available Margin checks----";
extern string  sco="Scoobs";
extern bool    UseScoobsMarginCheck=false;
extern string  fk="ForexKiwi";
extern bool    UseForexKiwi=false;
extern int     FkMinimumMarginPercent=1500;
////////////////////////////////////////////////////////////////////////////////////////
bool           EnoughMargin;
string         MarginMessage;
////////////////////////////////////////////////////////////////////////////////////////

extern string  sep11="================================================================";
extern string  asi="----Average spread inputs----";
bool    RunInSpreadDetectionMode=false;
//The ticks to count whilst canculating the av spread
extern int     TicksToCount=5;
extern double  MultiplierToDetectStopHunt=10;
////////////////////////////////////////////////////////////////////////////////////////
double         SpreadArray[][6];
string         SpreadGvName;//A GV will hold the calculated average spread
////////////////////////////////////////////////////////////////////////////////////////

extern string  sep13="================================================================";
extern string  tmm="----Trade management module----";
//Breakeven has to be enabled for JS and TS to work.
extern string  BE="Break even settings";
extern bool    BreakEven=false;
extern int     BreakEvenTargetPips=20;
extern int     BreakEvenTargetProfit=2;
extern bool    PartCloseEnabled=false;
//Percentage of the trade lots to close
extern double  PartClosePercent=50;
////////////////////////////////////////////////////////////////////////////////////////
double         BreakEvenPips,BreakEvenProfit;
bool           TradeHasPartClosed=false;
////////////////////////////////////////////////////////////////////////////////////////

extern string  sep14="================================================================";
extern string  JSL="Jumping stop loss settings";
extern bool    JumpingStop=true;
extern int     JumpingStopTargetPips=2;
////////////////////////////////////////////////////////////////////////////////////////
double         JumpingStopPips;
////////////////////////////////////////////////////////////////////////////////////////

extern string  sep15="================================================================";
extern string  cts="----Candlestick jumping stop----";
extern bool    UseCandlestickTrailingStop=false;
//Defaults to current chart
extern int     CstTimeFrame=0;
//Defaults to previous candle
extern int     CstTrailCandles=1;
extern bool    TrailMustLockInProfit=true;
////////////////////////////////////////////////////////////////////////////////////////
int            OldCstBars;//For candlestick ts
////////////////////////////////////////////////////////////////////////////////////////

extern string  sep16="================================================================";
extern string  TSL="Trailing stop loss settings";
extern bool    TrailingStop=false;
extern int     TrailingStopTargetPips=20;
////////////////////////////////////////////////////////////////////////////////////////
double         TrailingStopPips;
////////////////////////////////////////////////////////////////////////////////////////

extern string  s2="================================================================";
//Enhanced screen feedback display code provided by Paul Batchelor (lifesys). Thanks Paul; this is fantastic.
extern string  chf               ="---- Chart feedback display ----";
int     ChartRefreshDelaySeconds=0;
// if using Comments
int     DisplayGapSize    = 30; 
// ****************************** added to make screen Text more readable
// replaces Comment() with OBJ_LABEL text
bool    DisplayAsText     = true;  
//Disable the chart in foreground CrapTx setting so the candles do not obscure the textbool    KeepTextOnTop     = true;
extern int     DisplayX          = 100;
extern int     DisplayY          = 0;
extern int     fontSise          = 10;
extern double  RowDistance       = 2.5;
extern string  fontName          = "Arial";
extern color   colour            = Yellow;

extern color   UpColor           = Lime;
extern color   DnColor           = Red;
extern color   NoColor           = Gray;

////////////////////////////////////////////////////////////////////////////////////////
int            DisplayCount;
string         Gap,ScreenMessage,WhatToShow="All";

////////////////////////////////////////////////////////////////////////////////////////

//Calculating the factor needed to turn pip values into their correct points value to accommodate different Digit size.
//Thanks to Tommaso for coding the function.
double         factor;//For pips/points stuff.

//Matt's O-R stuff
int            O_R_Setting_max_retries=10;
double         O_R_Setting_sleep_time=4.0; /* seconds */
double         O_R_Setting_sleep_max=15.0; /* seconds */
int            RetryCount=10;//Will make this number of attempts to get around the trade context busy error.


//Auto trading variables
datetime       CandleOpenTime[];//An array to hold the candle open time for each chart symbol

//Variables for building a picture of the open position
int            MarketTradesTotal=0;//Total of open market trades
int            PendingTradesTotal=0;//Total of pending orders
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
//Variables for storing market trade ticket numbers
datetime       LatestTradeTime=0, EarliestTradeTime=0;//More specific times are in each individual section
int            LatestTradeTicketNo=-1, EarliestTradeTicketNo=-1;
//We need to know the UPL values
double         PipsUpl[];//For keeping track of the pips PipsUpl of multi-trade positions. Aplies to the individual pair.
double         CashUpl[];//For keeping track of the cash PipsUpl of multi-trade positions. Aplies to the individual pair.

//Offsetting arrays
int            GridOrderBuyTickets[][2]; // number of lines will be equal to MarketBuysOpen - 1
int            GridOrderSellTickets[][2];
//Variable for the hedging/recovery code to tell if there are tp's and sl's set
bool           TpSet=false, SlSet=false;


//+------------------------------------------------------------------+
//| Expert initialization function                                   |
//+------------------------------------------------------------------+
int OnInit()
{

   //create timer
   EventSetTimer(EventTimerIntervalSeconds);

   StopLoss=StopLossPips;
   TakeProfit=TakeProfitPips;
   BreakEvenPips=BreakEvenTargetPips;
   BreakEvenProfit = BreakEvenTargetProfit;
   JumpingStopPips = JumpingStopTargetPips;
   TrailingStopPips= TrailingStopTargetPips;
   //HiddenPips=PipsHiddenFromCriminal;
   MinDistanceBetweenTrades = MinDistanceBetweenTradesPips;

   //Extract the pairs traded by the user
   ExtractPairs();

   Gap="";
   if (DisplayGapSize >0)
   {
      for (int cc=0; cc< DisplayGapSize; cc++)
      {
         Gap = StringConcatenate(Gap, " ");
      }   
   }//if (DisplayGapSize >0)

   
   ReadIndicatorValues();//Initial read

   if (MinimiseChartsAfterOpening)
      ShrinkCharts();

   TradeHgiTimeFrameDisplay = GetTimeFrameDisplay(HgiTradeFilterTimeFrame);
   SsTimeFrameDisplay = GetTimeFrameDisplay(SsTimeFrame);
   MaTimeFrameDisplay = GetTimeFrameDisplay(MaTimeFrame);
   PeakyTimeFrameDisplay = GetTimeFrameDisplay(PeakyTimeFrame);
   TradingTimeFrameDisplay = GetTimeFrameDisplay(TradingTimeFrame);
   
   //Set up the trading hours
   tradingHoursDisplay=tradingHours;//For display
   initTradingHours();//Sets up the trading hours array

   DisplayUserFeedback();

   
   return(INIT_SUCCEEDED);
}

void ExtractPairs()
{
   
   StringSplit(PairsToTrade,',',TradePair);
   NoOfPairs = ArraySize(TradePair);
   
   
   string AddChar = StringSubstr(Symbol(),6,4);
   
   // Resize the arrays appropriately
   ArrayResize(TradePair, NoOfPairs);
   ArrayResize(tradingStatus, NoOfPairs);
   ArrayResize(ttfCandleTime, NoOfPairs);
   ArrayResize(TradeHgiStatus, NoOfPairs);
   ArrayResize(SsStatus, NoOfPairs);
   ArrayResize(OldPeakyBarTime, NoOfPairs);
   ArrayResize(PeakyStatus, NoOfPairs);
   ArrayResize(MaStatus, NoOfPairs);
   ArrayResize(CandleOpenTime, NoOfPairs);
   ArrayResize(HgiStatus, NoOfPairs);
   ArrayResize(BuySignal, NoOfPairs);
   ArrayResize(SellSignal, NoOfPairs);
   ArrayResize(TimeToStartTrading, NoOfPairs);
   ArrayResize(OldNdHgiBarTime, NoOfPairs);
   ArrayResize(OldIndiReadBarTime, NoOfPairs);
   ArrayResize(SpreadArray, NoOfPairs);
   ArrayInitialize(SpreadArray, 0);
   ArrayResize(PipsUpl, NoOfPairs);
   ArrayInitialize(PipsUpl, 0);
   ArrayResize(CashUpl, NoOfPairs);
   ArrayInitialize(CashUpl, 0);
   

   
   for (int cc = 0; cc < NoOfPairs; cc ++)
   {
      TradePair[cc] = StringTrimLeft(TradePair[cc]);
      TradePair[cc] = StringTrimRight(TradePair[cc]);
      TradePair[cc] = StringConcatenate(TradePair[cc], AddChar);
      //Ensure the ea waits for the new candle to open before trading
      CandleOpenTime[cc] = iTime(TradePair[cc], TradingTimeFrame, 0);
      TimeToStartTrading[cc] = 0;
      OldNdHgiBarTime[cc] = 0;
      OldIndiReadBarTime[cc] = 0;
      //Average spread
      SpreadGvName=TradePair[cc] + " average spread";
      SpreadArray[cc][averagespread]=GlobalVariableGet(SpreadGvName);//If no gv, then the value will be left at zero.
      //Create a Global Variable with the current spread if this does not already exist
      if (CloseEnough(SpreadArray[cc][averagespread], 0))
      {
         GetBasics(TradePair[cc]);//Includes the current spread
         SpreadArray[cc][averagespread] = NormalizeDouble(spread, 2);
         GlobalVariableSet(SpreadGvName, spread);
      }//if (CloseEnough(SpreadArray[cc][averagespread], 0))
      SpreadArray[cc][previousask] = 0;//Used to update the tick counter when there is a price change
   }//for (int cc; cc<NoOfPairs; cc ++)

}//End void ExtractPairs()


//+------------------------------------------------------------------+
//| Expert deinitialization function                                 |
//+------------------------------------------------------------------+
void OnDeinit(const int reason)
{
    
   ArrayFree(TradePair);
   ArrayFree(tradingStatus);
   ArrayFree(ttfCandleTime);
   ArrayFree(TradeHgiStatus);
   ArrayFree(OldIndiReadBarTime);
   ArrayFree(SsStatus);
   ArrayFree(OldPeakyBarTime);
   ArrayFree(PeakyStatus);
   ArrayFree(MaStatus);
   ArrayFree(HgiStatus);
   ArrayFree(BuySignal);
   ArrayFree(SellSignal);
   ArrayFree(TimeToStartTrading);
   ArrayFree(OldNdHgiBarTime);
   ArrayFree(PipsUpl);
   ArrayFree(CashUpl);
   

   removeAllObjects();
   
   //--- destroy timer
   EventKillTimer();
       
}

//For OrderSelect() Craptrader documentation states:
//   The pool parameter is ignored if the order is selected by the ticket number. The ticket number is a unique order identifier. 
//   To find out from what list the order has been selected, its close time must be analyzed. If the order close time equals to 0, 
//   the order is open or pending and taken from the terminal open orders list.
//This function heals this and allows use of pool parameter when selecting orders by ticket number.
//Tomele provided this code. Thanks Thomas.
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



//+------------------------------------------------------------------+
//| Expert tick function                                             |
//+------------------------------------------------------------------+
void OnTick()
{
//---
   
}

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
   uint w,h;
   
   for (int cc = 0; cc < 5; cc++)
   {
      textpart[cc] = StringSubstr(text,cc*63,64);
      if (StringLen(textpart[cc]) ==0) continue;
      lab_str = lab_str + IntegerToString(cc);
      
      ObjectCreate(lab_str, OBJ_LABEL, 0, 0, 0);
      ObjectSet(lab_str, OBJPROP_CORNER, 0);
      ObjectSet(lab_str, OBJPROP_XDISTANCE, DisplayX + ofset);
      ObjectSet(lab_str, OBJPROP_YDISTANCE, DisplayY+DisplayCount*(int)(fontSise*1.5));
      ObjectSet(lab_str, OBJPROP_BACK, false);
      ObjectSetText(lab_str, textpart[cc], fontSise, fontName, colour);
      
      /////////////////////////////////////////////////
      //Calculate label size
      //Tomele supplied this code to eliminate the gaps in the text.
      //Thanks Thomas.
      TextSetFont(fontName,-fontSise*10,0,0);
      TextGetSize(textpart[cc],w,h);
      
      //Trim trailing space
      if (StringSubstr(textpart[cc],63,1)==" ")
         ofset+=(int)(w-fontSise*0.3);
      else
         ofset+=(int)(w-fontSise*0.7);
      /////////////////////////////////////////////////
         
   }//for (int cc = 0; cc < 5; cc++)
}

void DisplayUserFeedback()
{
   string text = "";
   //int cc = 0;
   
 
   //   ************************* added for OBJ_LABEL
   DisplayCount = 1;
   //removeAllObjects();
   //   *************************

 
   ScreenMessage = "";
   //ScreenMessage = StringConcatenate(ScreenMessage,Gap + NL);
   //SM(NL);
   
   SM("Updates for this EA are to be found at http://www.stevehopwoodforex.com"+NL);
   SM("Feeling generous? Help keep the coder going with a small Paypal donation to pianodoodler@hotmail.com"+NL);
   SM("Broker time = "+TimeToStr(TimeCurrent(),TIME_DATE|TIME_SECONDS)+": Local time = "+TimeToStr(TimeLocal(),TIME_DATE|TIME_SECONDS)+NL);
   SM(version + NL);
   
   SM(NL);
   
   text = "HG = Holy Graily Bob Indicator, SS = Super Slope, PK = Peaky, MA = Bobs Moving Averages, TS = Trading Status";
   if (TradeIndividualPairsAsBasket)
   {
      if (UseIndividualPairsBasketCashTarget)
         text = text + ", CUpl = Basket Cash UPL";
      if (UseIndividualPairsBasketPipsTarget)
         text = text + ", BUpl = Basket Pips UPL";   
   }//if (TradeIndividualPairsAsBasket)
      
   SM(text + NL);
   SM("Click a pair to open its chart. Click the cyan table name to switch between all pairs, tradable pairs and pairs with open trades"+NL);
   if (TradeWholePositionAsBasket)
      SM(NL);
   
   if (TradeIndividualPairsAsBasket)
   {
      text = "Trading each individual pair as a basket: ";
      if (UseIndividualPairsBasketCashTarget)
         text = text + "Cash profit target = " + DoubleToStr(IndividualPairsBasketCashTarget, 2);
      if (UseIndividualPairsBasketPipsTarget)
         text = text + ": Pips profit target = " + IntegerToString(IndividualPairsBasketPipsTarget)
                + " pips";
      SM(text + NL);          
   }//if (TradeIndividualPairsAsBasket)
   
   if (TradeWholePositionAsBasket)
   {
      text = "Trading the whole position as a basket: ";
      if (UseWholePositionBasketCashTarget)
         text = text + "Cash profit target = " + DoubleToStr(WholePositionBasketCashTarget, 2)
                + ": Cash UPL = " + DoubleToStr(WholePositionCashUpl, 2);
      if (UseWholePositionBasketPipsTarget)
         text = text + ": Pips profit target = " + IntegerToString(WholePositionBasketPipsTarget)
                + " Pips UPL = " + DoubleToStr(WholePositionPipsUpl, 2);
      SM(text + NL);          
   }//if (TradeWholePositionAsBasket)
   
   SM(NL);

   if (AutoTradingEnabled)
      if(RolloverInProgress)
      {
         SM(NL);
         SM("---------- ROLLOVER IN PROGRESS. I am taking no action until "+RollOverEnds+" ----------"+NL+NL);
      }//if (RolloverInProgress)
   
   DisplayMatrix();
 
   //Comment(ScreenMessage);

}//End void DisplayUserFeedback()

void DisplayMatrix()
{
   int TextXPos=0;
   int TextYPos=DisplayY+DisplayCount*(int)(fontSise*1.5)+(int)(fontSise*3);
   
   int TPLength=(int)(fontSise*7);
   int HGLength=(int)(fontSise*4);
   int SSLength=(int)(fontSise*4);
   int PKLength=(int)(fontSise*4);
   int MALength=(int)(fontSise*4);
   int TSLength=(int)(fontSise*7.5);
   int TRLength=(int)(fontSise*7);
   int SWLength=(int)(fontSise*5);
   int SPLength=(int)(fontSise*7);
   
   //Display Headers
   
   TextXPos=DisplayX;
   
   string text1,text2;
   
   if (WhatToShow=="All")
   {
      text1="All";
      text2="Pairs";
   }
   else if (WhatToShow=="Tradables")
   {
      text1="Tradable";
      text2="Pairs";
   }
   else if (WhatToShow=="OpenTrades")
   {
      text1="Open";
      text2="Trades";
   }
   
   DisplayTextLabel(text1,TextXPos,TextYPos,ANCHOR_LEFT_UPPER,"SWITCH", 0, Cyan);
   DisplayTextLabel(text2,TextXPos,TextYPos+(int)(fontSise*1.5),ANCHOR_LEFT_UPPER,"SWITCH", 0, Cyan);
   
   TextXPos+=TPLength;
   TextXPos+=fontSise*2;
      
   if (UseHgiTrendFilter)
   {
      DisplayTextLabel("HG",TextXPos,TextYPos+(int)(fontSise*1.5));
      TextXPos+=HGLength;
   }
   
   if (UseSuperSlope)
   {
      DisplayTextLabel("SS",TextXPos,TextYPos+(int)(fontSise*1.5));
      TextXPos+=HGLength;
   }
   
   if (UsePeaky)
   {
      DisplayTextLabel("PK",TextXPos,TextYPos+(int)(fontSise*1.5));
      TextXPos+=PKLength;
   }
   
   if (UseBobMovingAverage)
   {
      DisplayTextLabel("MA",TextXPos,TextYPos+(int)(fontSise*1.5));
      TextXPos+=MALength;
   }
   
   DisplayTextLabel("TS",TextXPos,TextYPos+(int)(fontSise*1.5));
   TextXPos+=TSLength;
   
   DisplayTextLabel("Open",TextXPos,TextYPos,ANCHOR_RIGHT_UPPER);
   DisplayTextLabel("Trades",TextXPos,TextYPos+(int)(fontSise*1.5),ANCHOR_RIGHT_UPPER);
   TextXPos+=TRLength;
   
   DisplayTextLabel(" Long",TextXPos,TextYPos,ANCHOR_RIGHT_UPPER);
   DisplayTextLabel("Swap",TextXPos,TextYPos+(int)(fontSise*1.5),ANCHOR_RIGHT_UPPER);
   TextXPos+=SWLength;
   
   DisplayTextLabel(" Short",TextXPos,TextYPos,ANCHOR_RIGHT_UPPER);
   DisplayTextLabel("Swap",TextXPos,TextYPos+(int)(fontSise*1.5),ANCHOR_RIGHT_UPPER);
   TextXPos+=SWLength;
   
   TextXPos+=fontSise*3;
   
   
   DisplayTextLabel("Actual",TextXPos,TextYPos,ANCHOR_RIGHT_UPPER);
   DisplayTextLabel("Spread",TextXPos,TextYPos+(int)(fontSise*1.5),ANCHOR_RIGHT_UPPER);

   
   TextXPos+=SWLength;
   TextXPos+=fontSise*3;
   DisplayTextLabel("Average",TextXPos,TextYPos,ANCHOR_RIGHT_UPPER);
   DisplayTextLabel("Spread",TextXPos,TextYPos+(int)(fontSise*1.5),ANCHOR_RIGHT_UPPER);
   
   TextXPos+=SWLength;
   TextXPos+=fontSise*3;
   DisplayTextLabel("Biggest",TextXPos,TextYPos,ANCHOR_RIGHT_UPPER);
   DisplayTextLabel("Spread",TextXPos,TextYPos+(int)(fontSise*1.5),ANCHOR_RIGHT_UPPER);
   
   if (TradeIndividualPairsAsBasket)
   {
      if (UseIndividualPairsBasketCashTarget)
      {
         TextXPos+=SWLength;
         TextXPos+=fontSise*3;
         DisplayTextLabel("CUpl",TextXPos,TextYPos+(int)(fontSise*1.5),ANCHOR_RIGHT_UPPER);
      }//if (UseIndividualPairsBasketCashTarget)
      
      if (UseIndividualPairsBasketPipsTarget)
      {
         TextXPos+=SWLength;
         TextXPos+=fontSise*3;
         DisplayTextLabel("PUpl",TextXPos,TextYPos+(int)(fontSise*1.5),ANCHOR_RIGHT_UPPER);
      }//if (UseIndividualPairsBasketPipsTarget)
      
   }//if (TradeIndividualPairsAsBasket)
   
   
   //Point to the next YPos
   TextYPos+=3*(int)(fontSise*1.5);
   
   //Display trade pairs 
        
   for (int cc = 0; cc <= ArraySize(TradePair) - 1; cc++)
   {
      CountTradesForDashboard(TradePair[cc]);
      
      if (WhatToShow=="Tradables")
         if (tradingStatus[cc]==untradable)
            continue;
         
      if (WhatToShow=="OpenTrades")
         if (OpenTrades==0)
           continue;

      GetBasics(TradePair[cc]);
      
      TextXPos=DisplayX;
      DisplayTextLabel(TradePair[cc],TextXPos,TextYPos, ANCHOR_LEFT_UPPER,TradePair[cc]);
      TextXPos+=TPLength;

      TextXPos+=fontSise*2;
      
      if (UseHgiTrendFilter)
      {
         DisplayTextLabel(TradeHgiStatus[cc],TextXPos,TextYPos);
         TextXPos+=HGLength;
      }
      
      if (UseSuperSlope)
      {
         DisplayTextLabel(SsStatus[cc],TextXPos,TextYPos);
         TextXPos+=SSLength;
      }
      
      if (UsePeaky)
      {
         DisplayTextLabel(PeakyStatus[cc],TextXPos,TextYPos);
         TextXPos+=PKLength;
      }
      
      if (UseBobMovingAverage)
      {
         DisplayTextLabel(MaStatus[cc],TextXPos,TextYPos);
         TextXPos+=MALength;
      }
      
      DisplayTextLabel(tradingStatus[cc],TextXPos,TextYPos);
      TextXPos+=TSLength;

      string trades="";
      if (OpenLongTrades==0 && OpenShortTrades==0)
         trades="----";
      else if (OpenLongTrades>0 && OpenShortTrades>0)
         trades=StringConcatenate(IntegerToString(OpenLongTrades),"B,",IntegerToString(OpenShortTrades),"S");
      else if (OpenLongTrades>0)
         trades=StringConcatenate(IntegerToString(OpenLongTrades),"B");
      else if (OpenShortTrades>0)
         trades=StringConcatenate(IntegerToString(OpenShortTrades),"S");
         
      color tcolor=NoColor;
      if (OpenLongTrades>OpenShortTrades)
         tcolor=UpColor;
      else if (OpenLongTrades<OpenShortTrades)
         tcolor=DnColor;
      
      DisplayTextLabel(trades,TextXPos,TextYPos,ANCHOR_RIGHT_UPPER, "", 0, tcolor);
      TextXPos+=TRLength;
      
      DisplayTextLabel(DoubleToStr(longSwap, 2),TextXPos,TextYPos,ANCHOR_RIGHT_UPPER);
      TextXPos+=SWLength;
      
      DisplayTextLabel(DoubleToStr(shortSwap, 2),TextXPos,TextYPos,ANCHOR_RIGHT_UPPER);
      TextXPos+=SWLength;
      
      TextXPos+=fontSise*3;
      
      DisplayTextLabel(DoubleToStr(spread, 1) + " pips",TextXPos,TextYPos,ANCHOR_RIGHT_UPPER);

      TextXPos+=SWLength;
      TextXPos+=fontSise*3;
      DisplayTextLabel(DoubleToStr(SpreadArray[cc][averagespread], 1) + " pips",TextXPos,TextYPos,ANCHOR_RIGHT_UPPER);

      TextXPos+=SWLength;
      TextXPos+=fontSise*3;
      DisplayTextLabel(DoubleToStr(SpreadArray[cc][biggestspread], 1) + " pips",TextXPos,TextYPos,ANCHOR_RIGHT_UPPER);

      if (TradeIndividualPairsAsBasket)
      {
         if (UseIndividualPairsBasketCashTarget)
            if (!CloseEnough(CashUpl[cc], 0) )
            {
               TextXPos+=SWLength;
               TextXPos+=fontSise*3;
               DisplayTextLabel(DoubleToStr(CashUpl[cc], 2),TextXPos,TextYPos,ANCHOR_RIGHT_UPPER);
            }//if (!CloseEnough(CashUpl[cc], 0) )
      
         if (UseIndividualPairsBasketPipsTarget)
            if (!CloseEnough(PipsUpl[cc], 0) )
            {
               TextXPos+=SWLength;
               TextXPos+=fontSise*3;
               DisplayTextLabel(DoubleToStr(PipsUpl[cc], 2),TextXPos,TextYPos,ANCHOR_RIGHT_UPPER);
            }//if (!CloseEnough(CashUpl[cc], 0) )
      
      }//if (TradeIndividualPairsAsBasket)
      
      //Point to the next YPos to start a new line
      TextYPos+=(int)(fontSise*RowDistance);
        
   }//for (cc = 0; cc <= ArraySize(TradePair) -1; cc++)
   
}//End void DisplayMatrix()

void DisplayTextLabel(string text, int xpos, int ypos, ENUM_ANCHOR_POINT anchor=ANCHOR_LEFT_UPPER, string pair="", int tf=0, color scol=NONE)
{

   if (scol==NONE)
      scol=colour;
      
   if (text=="Long"||text=="Blue"||text=="Up arrow"||text=="Up wave"||text=="Up"||text=="Tradable long") scol=UpColor;
   else if (text=="Short"||text=="Red"||text=="Dn arrow"||text=="Dn wave"||text=="Down"||text=="Tradable short") scol=DnColor;
   else if (text=="No signal"||text=="White"||text=="Not tradable")scol=NoColor;
   else if (text=="Yellow range wave")scol=Yellow;
   
   if (text=="Long"||text=="Blue"||text=="Up arrow"||text=="Up") text="á";
   else if (text=="Short"||text=="Red"||text=="Dn arrow"||text=="Down") text="â";
   else if (text=="Up wave"||text=="Dn wave"||text=="Yellow range wave") text="h";
   else if (text=="Tradable long"||text=="Tradable short") text="ü";
   else if (text=="No signal"||text=="White"||text=="Not tradable")text="û";
   
   string font=fontName;
   int sise=fontSise;
   if (text=="á"||text=="â"||text=="h"||text=="ü"||text=="û")
   {
      font="Wingdings";
      sise=(int)MathRound(fontSise*1.2);
   }
   
   string lab_str;
   if (pair=="") 
      //Text label
      lab_str = "OAM-X" + IntegerToString(xpos) + "Y" + IntegerToString(ypos);   
   else if (pair=="CLOSE") 
      //Close other charts button
      lab_str = "OAM-CLOSE-X" + IntegerToString(xpos) + "Y" + IntegerToString(ypos);   
   else if (pair=="SWITCH") 
      //Switch displays button
      lab_str = "OAM-SWITCH-X" + IntegerToString(xpos) + "Y" + IntegerToString(ypos);   
   else 
      //Clickable label needs pair and timeframe for OpenChart()
      lab_str = "OAM-BTN-" + pair + "-" + IntegerToString(tf)+"-X" + IntegerToString(xpos) + "Y" + IntegerToString(ypos);   

   ObjectCreate(lab_str, OBJ_LABEL, 0, 0, 0); 
   ObjectSet(lab_str, OBJPROP_CORNER, 0);
   ObjectSet(lab_str, OBJPROP_XDISTANCE, xpos); 
   ObjectSet(lab_str, OBJPROP_YDISTANCE, ypos); 
   ObjectSet(lab_str, OBJPROP_BACK, false);
   ObjectSetText(lab_str, text, sise, font, scol);
   ObjectSetInteger(0,lab_str,OBJPROP_ANCHOR,anchor); 
   
}//End void DisplayTextLabel(string text, int xpos, int ypos, ENUM_ANCHOR_POINT anchor=ANCHOR_LEFT_UPPER)

void GetBasics(string symbol)
{
   //Sets up bid, ask, digits, factor for the passed pair
   bid = MarketInfo(symbol, MODE_BID);
   ask = MarketInfo(symbol, MODE_ASK);
   digits = (int)MarketInfo(symbol, MODE_DIGITS);
   factor = GetPipFactor(symbol);
   spread = (ask - bid) * factor;
   longSwap = MarketInfo(symbol, MODE_SWAPLONG);
   shortSwap = MarketInfo(symbol, MODE_SWAPSHORT);
   
      
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


void ChartAutomation(string symbol, int index)
{
   long currChart = 0, prevChart = ChartFirst();
   int cc = 0, limit = ArraySize(TradePair) -1;
   
   //We want to close charts that are not tradable
   if (TimerCount==0)//We do this only every ChartCloseTimerMultiple cycle
      if (tradingStatus[index] == untradable)
      {
         //We cannot close charts with open trades
         CountTradesForDashboard(symbol);
         if (OpenTrades > 0)
            return;
            
         while (cc < limit)
         {
            currChart = ChartNext(prevChart); // Get the new chart ID by using the previous chart 
            if(currChart < 0) 
               return;// Have reached the end of the chart list 
         
            //We do not want to close the reserved chart
            if (ChartSymbol(currChart) == ReservedPair)
            {
               prevChart=currChart;// let's save the current chart ID for the ChartNext() 
               cc++;
               continue;
            }//if (ChartSymbol() == ReservedPair)
               
            if (ChartSymbol(currChart) == symbol)
               ChartClose(currChart);   
            
            prevChart=currChart;// let's save the current chart ID for the ChartNext() 
            cc++;
         }//while (cc < limit)
         
         return;   
      }//if (tradingStatus[cc] == untradable)
   
   //Now open a new chart if there is not one already open.
   //First check that the chart is a tradable chart
   if (tradingStatus[index] != tradablelong)
      if (tradingStatus[index] != tradableshort)
         return;
         
   bool found = false;
   prevChart = ChartFirst();
   //Look for a chart already opened
   while (cc < limit)
   {
      currChart = ChartNext(prevChart); // Get the new chart ID by using the previous chart 
      if(currChart < 0) 
         break;// Have reached the end of the chart list 
   
      
      if (ChartSymbol(currChart) !=ReservedPair)
         if (ChartSymbol(currChart) == symbol)
         {
            found = true;
            break;
         }//if (ChartSymbol(currChart) == symbol)
            
      prevChart=currChart;// let's save the current chart ID for the ChartNext() 
      cc++;
   }//while (cc < limit)
   
   if (!found)
   {
      //Chart not found, so open one
      long newChartId = ChartOpen(symbol, TradingTimeFrame);
      //Alert(symbol, "  ", TemplateName);
      ChartApplyTemplate(newChartId, TemplateName);
      ChartRedraw(newChartId);
   }//if (!found)
   
   
}//End void ChartAutomation(string symbol)

double GetSuperSlope(string symbol, int tf, int maperiod, int atrperiod, int pShift )
{
   double dblTma, dblPrev;
   int shiftWithoutSunday = pShift;
   
   double atr = iATR( symbol, tf, atrperiod, shiftWithoutSunday + 10 ) / 10;
   double result = 0.0;
   if ( atr != 0 )
   {
      dblTma = iMA( symbol, tf, maperiod, 0, MODE_LWMA, PRICE_CLOSE, shiftWithoutSunday );
      dblPrev = ( iMA( symbol, tf, maperiod, 0, MODE_LWMA, PRICE_CLOSE, shiftWithoutSunday + 1 ) * 231 + iClose( symbol, tf, shiftWithoutSunday ) * 20 ) / 251;

      result = ( dblTma - dblPrev ) / atr;
   }
   
   return ( result );
   
}//GetSuperSlope(}

void GetPeakyTradeDirection(string symbol, int tf, int bars, int index)
{
   //Set PeakyStatus to the direction implied by the chart peak hilo
   
   int Highest = iHighest(symbol, tf, MODE_CLOSE, bars);
   int Lowest = iLowest(symbol, tf, MODE_CLOSE, bars);
   
   PeakyStatus[index] = longdirection;//Default
   if (Highest < Lowest)
      PeakyStatus[index] = shortdirection;

}//End void GetPeakyTradeDirection(string symbol, int tf, int bars)

double GetMa(string symbol, int tf, int period, int mashift, int method, int ap, int shift)
{
   return(iMA(symbol, tf, period, mashift, method, ap, shift) );
}//End double GetMa(int tf, int period, int mashift, int method, int ap, int shift)

void ReadIndicatorValues()
{

   removeAllObjects();
   //Comment(Gap, "******************** DOING THE CALCULATIONS ********************");
   
   for (int PairIndex = 0; PairIndex <= ArraySize(TradePair) - 1; PairIndex++)
   {
      double val = 0;
      int cc = 0;
      
      string symbol = TradePair[PairIndex];//Makes typing easier
      GetBasics(symbol);//Bid etc
  
      //Non-directional trading
      if (OldNdHgiBarTime[PairIndex] != iTime(symbol, TradingTimeFrame, 0) )
      {
         OldNdHgiBarTime[PairIndex] = iTime(symbol, TradingTimeFrame, 0);
       
         BuySignal[PairIndex] = false;
         SellSignal[PairIndex] = false;
         
         ///////////////////////////////////////
         //Indi reading code goes here
                  
      
         //Using hgi_lib
         //The HGI library functionality was added by tomele. Many thanks Thomas.
         SIGNAL signal = 0;
         SLOPE  slope  = 0;
   
         if (CloseOnLargeArrows || CloseOnBlueWavy)
         {
              
            signal = getHGISignal(symbol, HgiTimeFrame, 1);//This library function looks for arrows.
            slope  = getHGISlope (symbol, HgiTimeFrame, 1);//This library function looks for wavy lines.
   
            HgiStatus[PairIndex] = hginoarrow;
            
            if (signal==TRENDUP)
            {
               if (CloseOnLargeArrows)
               HgiStatus[PairIndex] = hgiuparrowtradable;
            }
            else 
            if (signal==TRENDDN)
            {
               if (CloseOnLargeArrows)
                  HgiStatus[PairIndex] = hgidownarrowtradable;
            }
            else 
            if (slope==TRENDBELOW)
            {
               if (CloseOnBlueWavy)
                  HgiStatus[PairIndex] = hgibluewavylong;
            }
            else 
            if (slope==TRENDABOVE)
            {
               if (CloseOnBlueWavy)
                  HgiStatus[PairIndex] = hgibluewavyshort;
            }
            /*else
            if (signal==RADUP)
            {
               if (RadTradingAllowed)
               HgiStatus[PairIndex] = hgiuparrowtradable;
            }
            else 
            if (signal==RADDN)
            {
               if (RadTradingAllowed)
                  HgiStatus[PairIndex] = hgiuparrowtradable;
            */
         
         
         }//if (CloseOnLargeArrows || CloseOnBlueWavy)
         
         
         //////////////////////////////////////////////////////////////////////////////////      
         
         /*The rest of this function is concerned with the optional filters added for those
         who prefer to trade in the direction of one or more, of the well established indi's
         available at SHF. Those that I offer here are:
            * HGI
            * SuperSlope
            * Bob's H4 Moving Average trend filter
            *Peaky*/
            
         //Set BuySignal and SellSignal to true if none of the filters are selected so that
         //LookForTradingOpportunities() can still trade, then move on to the next pairn.
         if (!UseHgiTrendFilter)
            if (!UseSuperSlope)
               if (!UseBobMovingAverage)
                  if (!UsePeaky)
                  {
                     BuySignal[PairIndex] = true;
                     SellSignal[PairIndex] = true;
                     continue;
                  }//if (!UsePeaky)
                  
      }//if (OldNdHgiBarTime[PairIndex] != iTime(symbol, TradingTimeFrame, 0) )
      
         
      tradingStatus[PairIndex] = untradable;
      
      //Read the remaining indis once a minute
      if (OldIndiReadBarTime[PairIndex] != iTime(symbol, TradingTimeFrame, 0) )//Pair does not matter as we only require once a minute reading
      { 
         OldIndiReadBarTime[PairIndex] = iTime(symbol, TradingTimeFrame, 0);
         
         //HGI
         if (UseHgiTrendFilter)
         {
               
            //Using hgi_lib
            //The HGI library functionality was added by tomele. Many thanks Thomas.
            SIGNAL signal = 0;
            SLOPE  slope  = 0;

            cc = 1;   
            TradeHgiStatus[PairIndex] = hginoarrow;
            
            while(TradeHgiStatus[PairIndex] == hginoarrow)
            {
               signal = getHGISignal(symbol, HgiTradeFilterTimeFrame, cc);//This library function looks for arrows.
               slope  = getHGISlope (symbol, HgiTradeFilterTimeFrame, cc);//This library function looks for wavy lines.
            
               if (signal==TRENDUP)
               {
                  if (TradeTrendArrows)
                  TradeHgiStatus[PairIndex] = hgiuparrowtradable;
               }
               else 
               if (signal==TRENDDN)
               {
                  if (TradeTrendArrows)
                     TradeHgiStatus[PairIndex] = hgidownarrowtradable;
               }
               else 
               if (slope==TRENDBELOW)
               {
                  if (TradeBlueWavyLines)
                     TradeHgiStatus[PairIndex] = hgibluewavylong;
               }
               else 
               if (slope==TRENDABOVE)
               {
                  if (TradeBlueWavyLines)
                     TradeHgiStatus[PairIndex] = hgibluewavyshort;
               }
               //Yellow wavy
               else
               if (slope == RANGEABOVE || slope == RANGEBELOW)
               {
                  TradeHgiStatus[PairIndex] = hgiyellowwavy;
               }

               /*else
               if (signal==RADUP)
               {
                  if (RadTradingAllowed)
                  TradeHgiStatus[PairIndex] = hgiuparrowtradable;
               }
               else 
               if (signal==RADDN)
               {
                  if (RadTradingAllowed)
                     TradeHgiStatus[PairIndex] = hgiuparrowtradable;
               */
               
               cc++;
            }//while(TradeHgiStatus[PairIndex] == hginoarrow)
         
      
         }//if (UseHgiTrendFilter)
         
      
         //Read SuperSlope at the open of each new trading time frame candle
         if (UseSuperSlope)
         {   
            val = GetSuperSlope(symbol, SsTimeFrame,SsTradingSlopeMAPeriod,SsTradingSlopeATRPeriod,0);
               
            //Changed by tomele. Many thanks Thomas.
            //Set the colours
            SsStatus[PairIndex] = white;
            
            if (val > 0)  //buy
               if (val - SsTradingDifferenceThreshold/2 > 0) //blue
                  SsStatus[PairIndex] = blue;
   
            if (val < 0)  //sell
               if (val + SsTradingDifferenceThreshold/2 < 0) //red
                  SsStatus[PairIndex] = red;
                                                     
         }//if (UseSuperSlope)
   
   
         //Peaky
         if (UsePeaky)
         {
            GetPeakyTradeDirection(symbol, PeakyTimeFrame, NoOfBarsOnChart, PairIndex);
         }//if (UsePeaky)
         
         
         //Bob's moving average. Read once a minute so it is up to dayt
         if (UseBobMovingAverage)
         {
            val = GetMa(symbol, MaTimeFrame, MaPeriod, MaShift, MaMethod, MaAppliedPrice, 0);
            if (bid > val) 
            {
               MaStatus[PairIndex] = up;
            }//if (bid > val) 
            
            if (bid < val) 
            {
               MaStatus[PairIndex] = down;
            }//if (bid < val) 

         }//if (UseBobMovingAverage)
         
      }//if (OldIndiBarTime != iTime(symbol, TradingTimeFrame, 0) )
         
      
      //Code to compare all the indi values and generate a signal if they all pass
      if (!UseBobMovingAverage || MaStatus[PairIndex] == up)
         if (!UseSuperSlope || SsStatus[PairIndex] == blue)
            if (!UseHgiTrendFilter || (TradeHgiStatus[PairIndex] == hgiuparrowtradable || TradeHgiStatus[PairIndex] == hgibluewavylong) )
               if (!UsePeaky || PeakyStatus[PairIndex] == longdirection)
               {
                  tradingStatus[PairIndex] = tradablelong;//For display
                  BuySignal[PairIndex] = true;//For trading
               }//if (!UsePeaky || PeakyStatus[PairIndex] == longdirection)
               
      if (!UseBobMovingAverage || MaStatus[PairIndex] == down)
         if (!UseSuperSlope || SsStatus[PairIndex] == red)
            if (!UseHgiTrendFilter || (TradeHgiStatus[PairIndex] == hgidownarrowtradable || TradeHgiStatus[PairIndex] == hgibluewavyshort) )
               if (!UsePeaky || PeakyStatus[PairIndex] == shortdirection)
               {
                  tradingStatus[PairIndex] = tradableshort;//For display
                  SellSignal[PairIndex] = true;//For trading
               }//if (!UsePeaky || PeakyStatus[PairIndex] == shortdirection)
               
      //Yellow wavy
      if (UseHgiTrendFilter)
         if (TradeHgiStatus[PairIndex] == hgiyellowwavy)
            tradingStatus[PairIndex] = untradable;

     //Chart automation
     // if (tradingStatus[PairIndex] == tradablelong || tradingStatus[PairIndex] == tradableshort)
         if (AutomateChartOpeningAndClosing)
            ChartAutomation(symbol, PairIndex);
            
      
   }//for (int cc = 0; cc <= ArraySize(TradePair); cc++)

   Comment("");
   
}//void ReadIndicatorValues()

void CountOpenTrades(string symbol, int PairIndex)
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
   MarketTradesTotal = 0;
   TicketNo=-1;OpenTrades=0;
   LatestTradeTime=0; EarliestTradeTime=TimeCurrent();//More specific times are in each individual section
   LatestTradeTicketNo=-1; EarliestTradeTicketNo=-1;
   PipsUpl[PairIndex]=0;//For keeping track of the pips PipsUpl of multi-trade/hedged positions
   CashUpl[PairIndex]=0;//For keeping track of the cash PipsUpl of multi-trade/hedged positions
   WholePositionCashUpl = 0;//All trades belonging to the EA cash
   WholePositionPipsUpl = 0;//All trades belonging to the EA pips
   //Recovery
   TpSet = false; SlSet = false;

   
   //FIFO ticket resize
   ArrayFree(FifoTicket);
   
   //For opposite side offsetting
   ArrayFree(GridOrderBuyTickets);
   ArrayFree(GridOrderSellTickets);
    
   
   int type;//Saves the OrderType() for consulatation later in the function
   
   
   if (OrdersTotal() == 0) return;
   
   //Iterating backwards through the orders list caters more easily for closed trades than iterating forwards
   for (int cc = OrdersTotal() - 1; cc >= 0; cc--)
   {
      bool TradeWasClosed = false;//See 'check for possible trade closure'

      //Ensure the trade is still open
      if (!BetterOrderSelect(cc, SELECT_BY_POS, MODE_TRADES) ) continue;

      //Whole position monitor if TradeWholePositionAsBasket is enabled
      double pips = 0;
      if (TradeWholePositionAsBasket)
         if (OrderType() < 2)
         {
            WholePositionCashUpl+= (OrderProfit() + OrderSwap() + OrderCommission());
            pips = CalculateTradeProfitInPips(OrderType());
            WholePositionPipsUpl+= pips;
         }//if (OrderType() < 2)
         

      //Ensure the EA 'owns' this trade
      if (OrderSymbol() != symbol ) continue;
      if (OrderMagicNumber() != MagicNumber) continue;
      if (OrderCloseTime() > 0) continue; 
      
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
      
      
      
      //Buile up the position picture of market trades
      if (OrderType() < 2)
      {
         CashUpl[PairIndex]+= (OrderProfit() + OrderSwap() + OrderCommission()); 
         MarketTradesTotal++;
         pips = CalculateTradeProfitInPips(OrderType());
         PipsUpl[PairIndex]+= pips;
         
         //Buys
         if (OrderType() == OP_BUY)
         {
            BuyOpen = true;
            BuyTicketNo = OrderTicket();
            MarketBuysCount++;
            BuyPipsUpl+= pips;
            BuyCashUpl+= (OrderProfit() + OrderSwap() + OrderCommission()); 

            ArrayResize(GridOrderBuyTickets, MarketBuysCount + 1);
            GridOrderBuyTickets[MarketBuysCount][TradeTicket] = OrderTicket();
             
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
            SellOpen = true;
            SellTicketNo = OrderTicket();
            MarketSellsCount++;
            SellPipsUpl+= pips;
            SellCashUpl+= (OrderProfit() + OrderSwap() + OrderCommission()); 
 
            ArrayResize(GridOrderSellTickets, MarketSellsCount + 1);
            GridOrderSellTickets[MarketSellsCount][TradeTicket] = OrderTicket();
            
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
      
      
      //Maximum spread. We do not want any trading operations  during a wide spread period
      if (!SpreadCheck(PairIndex) ) 
         continue;
      
      
      if (!Unbalanced && !Hedged)
      {
         if (CloseEnough(OrderStopLoss(), 0) && !CloseEnough(StopLoss, 0)) InsertStopLoss(OrderTicket());
         if (CloseEnough(OrderTakeProfit(), 0) && !CloseEnough(TakeProfit, 0)) InsertTakeProfit(OrderTicket() );
      }//if (!Unbalanced)
      
      
      TradeWasClosed = false;
      if (OrderType() < 2)
         TradeWasClosed = LookForTradeClosure(OrderTicket(), PairIndex);
      if (TradeWasClosed) 
      {
         if (type == OP_BUY) BuyOpen = false;//Will be reset if subsequent trades are buys that are not closed
         if (type == OP_SELL) SellOpen = false;//Will be reset if subsequent trades are sells that are not closed
         cc++;
         continue;
      }//if (TradeWasClosed)

      //Profitable trade management
      if (OrderProfit() > 0) 
      {
         TradeManagementModule(OrderTicket() );
      }//if (OrderProfit() > 0) 
      
               
      
   }//for (int cc = OrdersTotal() - 1; cc <= 0; c`c--)
   
   //Sort ticket numbers for FIFO
   if (ArraySize(FifoTicket) > 0)
      ArraySort(FifoTicket, WHOLE_ARRAY, 0, MODE_DESCEND);

   
   //Hedging
   Hedged = false;
   if (BuyOpen)
      if (SellOpen)
         Hedged = true;
   
   //Balance
   Unbalanced = false;
   if (MathAbs(MarketBuysCount - MarketSellsCount) >= PositionIsUnbalancedAt)
   {
      Unbalanced = true;
      AllowTradeManagement = false;

      if (TpSet)
         RemoveTakeProfits(symbol);

      if (SlSet)
         RemoveStopLosses(symbol);

   }//if (MathAbs(MarketBuysCount - MarketSellsCount) >= PositionIsUnbalancedAt)
   
   //Resume individual trade management if we are not in recovery.
   if (!Unbalanced)
      AllowTradeManagement = true;

   if (ArraySize(GridOrderBuyTickets) > 0)
      ArraySort(GridOrderBuyTickets, WHOLE_ARRAY, 0, MODE_DESCEND);
   
   if (ArraySize(GridOrderSellTickets) > 0)
      ArraySort(GridOrderSellTickets, WHOLE_ARRAY, 0, MODE_DESCEND);
    
}//End void CountOpenTrades();
//+------------------------------------------------------------------+

void RemoveTakeProfits(string symbol)
{

   for (int cc = OrdersTotal() - 1; cc >= 0; cc--)
   {
      if (!BetterOrderSelect(cc, SELECT_BY_POS) ) continue;
      if (OrderSymbol() != symbol ) continue;
      if (OrderMagicNumber() != MagicNumber) continue;

      if (!CloseEnough(OrderTakeProfit(), 0) )
         ModifyOrder(OrderTicket(), OrderOpenPrice(), OrderStopLoss(), 0, 
                     OrderExpiration(), clrNONE, __FUNCTION__, tpm);
      
      
  
   }//for (int cc = OrdersTotal() - 1; cc >= 0; cc--)

}//void RemoveTakeProfits()

void RemoveStopLosses(string symbol)
{

   for (int cc = OrdersTotal() - 1; cc >= 0; cc--)
   {
      if (!BetterOrderSelect(cc, SELECT_BY_POS) ) continue;
      if (OrderSymbol() != symbol ) continue;
      if (OrderMagicNumber() != MagicNumber) continue;

      if (!CloseEnough(OrderStopLoss(), 0) )
         ModifyOrder(OrderTicket(), OrderOpenPrice(), 0, OrderTakeProfit(), 
                     OrderExpiration(), clrNONE, __FUNCTION__, tpm);
      
   }//for (int cc = OrdersTotal() - 1; cc >= 0; cc--)

}//void RemoveStopLosses()

void InsertStopLoss(int ticket)
{
   //Inserts a stop loss if the ECN crim managed to swindle the original trade out of the modification at trade send time
   //Called from CountOpenTrades() if StopLoss > 0 && OrderStopLoss() == 0.
   
   if (!BetterOrderSelect(ticket, SELECT_BY_TICKET)) return;
   if (OrderCloseTime() > 0) return;//Somehow, we are examining a closed trade
   if (OrderStopLoss() > 0) return;//Function called unnecessarily.
   
   while(IsTradeContextBusy()) Sleep(100);
   
   double stop = 0;
   
   if (OrderType() == OP_BUY)
   {
      stop = CalculateStopLoss(OP_BUY, OrderOpenPrice());
   }//if (OrderType() == OP_BUY)
   
   if (OrderType() == OP_SELL)
   {
      stop = CalculateStopLoss(OP_SELL, OrderOpenPrice());
   }//if (OrderType() == OP_SELL)
   
   if (CloseEnough(stop, 0) ) return;
   
   //In case some errant behaviour/code creates a sl the wrong side of the market, which would cause an instant close.
   if (OrderType() == OP_BUY && stop > OrderOpenPrice() ) 
   {
      stop = 0;
      ReportError(" InsertStopLoss()", " stop loss > market ");
   }//if (OrderType() == OP_BUY && take < OrderOpenPrice() ) 
   
   if (OrderType() == OP_SELL && stop < OrderOpenPrice() ) 
   {
      stop = 0;
      ReportError(" InsertStopLoss()", " stop loss > market ");
   }//if (OrderType() == OP_SELL && take > OrderOpenPrice() ) 

   
   if (!CloseEnough(stop, OrderStopLoss())) 
   {
      bool result = ModifyOrder(OrderTicket(), OrderOpenPrice(), stop, OrderTakeProfit(), OrderExpiration(), clrNONE, __FUNCTION__, slim);
   }//if (!CloseEnough(stop, OrderStopLoss())) 

}//End void InsertStopLoss(int ticket)

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void InsertTakeProfit(int ticket)
{
   //Inserts a TP if the ECN crim managed to swindle the original trade out of the modification at trade send time
   //Called from CountOpenTrades() if TakeProfit > 0 && OrderTakeProfit() == 0.
   
   if (!BetterOrderSelect(ticket, SELECT_BY_TICKET)) return;
   if (OrderCloseTime() > 0) return;//Somehow, we are examining a closed trade
   if (!CloseEnough(OrderTakeProfit(), 0) ) return;//Function called unnecessarily.
   
   while(IsTradeContextBusy()) Sleep(100);
   
   double take = 0;
   
   if (OrderType() == OP_BUY)
   {
      take = CalculateTakeProfit(OP_BUY, OrderOpenPrice());
   }//if (OrderType() == OP_BUY)
   
   if (OrderType() == OP_SELL)
   {
      take = CalculateTakeProfit(OP_SELL, OrderOpenPrice());
   }//if (OrderType() == OP_SELL)
   
   if (CloseEnough(take, 0) ) return;
   
   //In case some errant behaviour/code creates a tp the wrong side of the market, which would cause an instant close.
   if (OrderType() == OP_BUY && take < OrderOpenPrice()  && !CloseEnough(take, 0) ) 
   {
      take = 0;
      ReportError(" InsertTakeProfit()", " take profit < market ");
      return;
   }//if (OrderType() == OP_BUY && take < OrderOpenPrice() ) 
   
   if (OrderType() == OP_SELL && take > OrderOpenPrice() ) 
   {
      take = 0;
      ReportError(" InsertTakeProfit()", " take profit < market ");
      return;
   }//if (OrderType() == OP_SELL && take > OrderOpenPrice() ) 
   
   
   if (!CloseEnough(take, OrderTakeProfit()) ) 
   {
      bool result = ModifyOrder(OrderTicket(), OrderOpenPrice(), OrderStopLoss(), take, OrderExpiration(), clrNONE, __FUNCTION__, slim);
   }//if (!CloseEnough(take, OrderTakeProfit()) ) 

}//End void InsertTakeProfit(int ticket)

bool LookForTradeClosure(int ticket, int PairIndex)
{
   //Close the trade if the close conditions are met.
   //Called from within CountOpenTrades(). Returns true if a close is needed and succeeds, so that COT can increment cc,
   //else returns false
   
   if (!BetterOrderSelect(ticket, SELECT_BY_TICKET) ) return(true);
   if (BetterOrderSelect(ticket, SELECT_BY_TICKET) && OrderCloseTime() > 0) return(true);
   
   bool CloseThisTrade = false;
   
   //I have left the tpsl code in case non GP members need stealth
   double take = OrderTakeProfit();
   double stop = OrderStopLoss();
   
   //Direction hgi yellow range wave   
   if (HgiCloseOnYellowWavy)
      if (TradeHgiStatus[PairIndex] == hgiyellowwavy)
         CloseThisTrade = true;
        
   ///////////////////////////////////////////////////////////////////////////////////////////////////////////
   if (!CloseThisTrade)
   {
      if (OrderType() == OP_BUY || OrderType() == OP_BUYSTOP || OrderType() == OP_BUYLIMIT)
      {
         //TP
         if (bid >= take && !CloseEnough(take, 0) && !CloseEnough(take, OrderTakeProfit()) ) CloseThisTrade = true;
         //SL
         if (bid <= stop && !CloseEnough(stop, 0)  && !CloseEnough(stop, OrderStopLoss())) CloseThisTrade = true;
   
         
         
      
      
         //Original Hgi closure
         if (!CloseThisTrade)
            if (CloseOnLargeArrows)
               if (HgiStatus[PairIndex] == hgidownarrowtradable)
                  if (!OnlyCloseWinningTrades || (OrderProfit() + OrderCommission() + OrderSwap()) > 0)
                     if (OrderOpenTime() < iTime(OrderSymbol(), HgiTimeFrame, 0) )//Don't close trades opened during the current HGI candle
                        CloseThisTrade = true;
            
         if (!CloseThisTrade)
            if (CloseOnBlueWavy)
               if (HgiStatus[PairIndex] == hgibluewavyshort)
                  if (!OnlyCloseWinningTrades || (OrderProfit() + OrderCommission() + OrderSwap()) > 0)
                     if (OrderOpenTime() < iTime(OrderSymbol(), HgiTimeFrame, 0) )//Don't close trades opened during the current HGI candle
                        CloseThisTrade = true;
      
         //Directional trade closures
         //Opposite direction directional hgi
         if (!CloseThisTrade)
            if (UseHgiTrendFilter)
               if (HgiCloseOnOppositeSignal)
                  if (TradeHgiStatus[PairIndex] == hgidownarrowtradable || TradeHgiStatus[PairIndex] == hgibluewavyshort)
                     CloseThisTrade = true;
                  
             
         //Change of SS colour
         if (!CloseThisTrade)
            if (UseSuperSlope)
               if (SsCloseTradesOnColourChange)
                  if (SsStatus[PairIndex] == red)
                     CloseThisTrade = true; 

         //Change of moving average trend
         if (!CloseThisTrade)
            if (UseBobMovingAverage)
               if (MaCloseTradesOnTrendChange)
                  if (MaStatus[PairIndex] == down)
                     CloseThisTrade = true;

         //Change of peaky direction
         if (!CloseThisTrade)
            if (UsePeaky)
               if (PeakyCloseTradesOnDirectionChange)
                  if (PeakyStatus[PairIndex] == shortdirection)
                     CloseThisTrade = true;

            
      }//if (OrderType() == OP_BUY)
      
      
      ///////////////////////////////////////////////////////////////////////////////////////////////////////////
      if (OrderType() == OP_SELL || OrderType() == OP_SELLSTOP || OrderType() == OP_SELLLIMIT)
      {
         //TP
         if (bid <= take && !CloseEnough(take, 0) && !CloseEnough(take, OrderTakeProfit()) ) CloseThisTrade = true;
         //SL
         if (bid >= stop && !CloseEnough(stop, 0)  && !CloseEnough(stop, OrderStopLoss())) CloseThisTrade = true;
   
   
         
         //Original Hgi closure
         if (CloseOnLargeArrows)
            if (HgiStatus[PairIndex] == hgiuparrowtradable)
               if (!OnlyCloseWinningTrades || (OrderProfit() + OrderCommission() + OrderSwap()) > 0)
                  if (OrderOpenTime() < iTime(OrderSymbol(), HgiTimeFrame, 0) )//Don't close trades opened during the current HGI candle
                     CloseThisTrade = true;
         
         if (!CloseThisTrade)
            if (CloseOnBlueWavy)
               if (HgiStatus[PairIndex] == hgibluewavylong)
                  if (!OnlyCloseWinningTrades || (OrderProfit() + OrderCommission() + OrderSwap()) > 0)
                     if (OrderOpenTime() < iTime(OrderSymbol(), HgiTimeFrame, 0) )//Don't close trades opened during the current HGI candle
                        CloseThisTrade = true;
      
         //Directional trade closures
         //Opposite direction directional hgi
         if (!CloseThisTrade)
            if (UseHgiTrendFilter)
               if (HgiCloseOnOppositeSignal)
                  if (TradeHgiStatus[PairIndex] == hgiuparrowtradable || TradeHgiStatus[PairIndex] == hgibluewavylong)
                     CloseThisTrade = true;

         //Change of SS colour
         if (!CloseThisTrade)
            if (UseSuperSlope)
               if (SsCloseTradesOnColourChange)
                  if (SsStatus[PairIndex] == blue)
                     CloseThisTrade = true; 

         //Change of moving average trend
         if (!CloseThisTrade)
            if (UseBobMovingAverage)
               if (MaCloseTradesOnTrendChange)
                  if (MaStatus[PairIndex] == up)
                     CloseThisTrade = true;

         //Change of peaky direction
         if (!CloseThisTrade)
            if (UsePeaky)
               if (PeakyCloseTradesOnDirectionChange)
                  if (PeakyStatus[PairIndex] == longdirection)
                     CloseThisTrade = true;

            
      }//if (OrderType() == OP_SELL)
   }//if (!CloseThisTrade)
   
   ///////////////////////////////////////////////////////////////////////////////////////////////////////////
   if (CloseThisTrade)
   {
      bool result = false;
      
      if (OrderType() < 2)//Market orders
         result = CloseOrder(ticket);
      else
         result = OrderDelete(ticket, clrNONE);
            
      //Actions when trade close succeeds
      if (result)
      {
         TicketNo = -1;//TicketNo is the most recently trade opened, so this might need editing in a multi-trade EA
         OpenTrades--;//Rather than OpenTrades = 0 to cater for multi-trade EA's
         return(true);//Makes CountOpenTrades increment cc to avoid missing out ccounting a trade
      }//if (result)
   
      //Actions when trade close fails
      if (!result)
      {
         return(false);//Do not increment cc
      }//if (!result)
   }//if (CloseThisTrade)
   
   //Got this far, so no trade closure
   return(false);//Do not increment cc
   
}//End bool LookForTradeClosure()

double CalculateStopLoss(int type, double price)
{
   //Returns the stop loss for use in LookForTradingOpps and InsertMissingStopLoss
   double stop = 0;

   RefreshRates();
   

   
   if (type == OP_BUY)
   {
      if (!CloseEnough(StopLoss, 0) ) 
      {
         stop = price - (StopLoss / factor);
         //HiddenStopLoss = stop;
      }//if (!CloseEnough(StopLoss, 0) ) 

      //if (HiddenPips > 0 && stop > 0) stop = NormalizeDouble(stop - (HiddenPips / factor), Digits);
   }//if (type == OP_BUY)
   
   if (type == OP_SELL)
   {
      if (!CloseEnough(StopLoss, 0) ) 
      {
         stop = price + (StopLoss / factor);
         //HiddenStopLoss = stop;         
      }//if (!CloseEnough(StopLoss, 0) ) 
      
      //if (HiddenPips > 0 && stop > 0) stop = NormalizeDouble(stop + (HiddenPips / factor), Digits);

   }//if (type == OP_SELL)
   
   return(stop);
   
}//End double CalculateStopLoss(int type)

double CalculateTakeProfit(int type, double price)
{
   //Returns the stop loss for use in LookForTradingOpps and InsertMissingStopLoss
   double take = 0;

   RefreshRates();
   
   
   if (type == OP_BUY)
   {
      if (!CloseEnough(TakeProfit, 0) )
      {
         take = price + (TakeProfit / factor);
         //HiddenTakeProfit = take;
      }//if (!CloseEnough(TakeProfit, 0) )

               
      //if (HiddenPips > 0 && take > 0) take = NormalizeDouble(take + (HiddenPips / factor), Digits);

   }//if (type == OP_BUY)
   
   if (type == OP_SELL)
   {
      if (!CloseEnough(TakeProfit, 0) )
      {
         take = price - (TakeProfit / factor);
         //HiddenTakeProfit = take;         
      }//if (!CloseEnough(TakeProfit, 0) )
      
      
      //if (HiddenPips > 0 && take > 0) take = NormalizeDouble(take - (HiddenPips / factor), Digits);

   }//if (type == OP_SELL)
   
   return(take);
   
}//End double CalculateTakeProfit(int type)

bool CloseOrder(int ticket)
{   
   while(IsTradeContextBusy()) Sleep(100);
   bool orderselect=BetterOrderSelect(ticket,SELECT_BY_TICKET,MODE_TRADES);
   if (!orderselect) return(false);

   bool result = OrderClose(ticket, OrderLots(), OrderClosePrice(), 1000, clrBlue);

   //Actions when trade send succeeds
   if (result)
   {
      return(true);
   }//if (result)
   
   //Actions when trade send fails
   if (!result)
   {
      ReportError(" CloseOrder()", ocm);
      return(false);
   }//if (!result)
   
   return(0);
}//End bool CloseOrder(ticket)

//+------------------------------------------------------------------+
//| NormalizeLots(string symbol, double lots)                        |
//+------------------------------------------------------------------+
//function added by fxdaytrader
//Lot size must be adjusted to be a multiple of lotstep, which may not be a power of ten on some brokers
//see also the original function by WHRoeder, http://forum.mql4.com/45425#564188, fxdaytrader
double NormalizeLots(string symbol,double lots)
{
   if(MathAbs(lots)==0.0) return(0.0); //just in case ... otherwise it may happen that after rounding 0.0 the result is >0 and we have got a problem, fxdaytrader
   double ls=MarketInfo(symbol,MODE_LOTSTEP);
   lots=MathMin(MarketInfo(symbol,MODE_MAXLOT),MathMax(MarketInfo(symbol,MODE_MINLOT),lots)); //check if lots >= min. lots && <= max. lots, fxdaytrader
   return(MathRound(lots/ls)*ls);
}
////////////////////////////////////////////////////////////////////////////////////////

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
void BreakEvenStopLoss(int ticket) // Move stop loss to breakeven
{

   //Security check
   if (!BetterOrderSelect(ticket, SELECT_BY_TICKET, MODE_TRADES))
      return;
      
   double NewStop = 0;
   bool result = true;
   bool modify=false;
   double sl = OrderStopLoss();
   double target = OrderOpenPrice();
   
   
   if (OrderType()==OP_BUY)
   {
      //if (HiddenPips > 0) target-= (HiddenPips / factor);
      if (OrderStopLoss() >= target) return;
      if (bid >= OrderOpenPrice () + (BreakEvenPips / factor) )          
      {
         //Calculate the new stop
         NewStop = NormalizeDouble(OrderOpenPrice()+(BreakEvenProfit / factor), digits);
         modify = true;   
      }//if (bid >= OrderOpenPrice () + (Point*BreakEvenPips) && 
   }//if (OrderType()==OP_BUY)               			         
    
   if (OrderType()==OP_SELL)
   {
     //if (HiddenPips > 0) target+= (HiddenPips / factor);
     if (OrderStopLoss() <= target && OrderStopLoss() > 0) return;
     if (ask <= OrderOpenPrice() - (BreakEvenPips / factor) ) 
     {
         //Calculate the new stop
         NewStop = NormalizeDouble(OrderOpenPrice()-(BreakEvenProfit / factor), digits);
         modify = true;   
     }//if (ask <= OrderOpenPrice() - (Point*BreakEvenPips) && (OrderStopLoss()>OrderOpenPrice()|| OrderStopLoss()==0))     
   }//if (OrderType()==OP_SELL)

   //Move 'hard' stop loss whether hidden or not. Don't want to risk losing a breakeven through disconnect.
   if (modify)
   {
      if (NewStop == OrderStopLoss() ) return;
      while (IsTradeContextBusy() ) Sleep(100);
      result = ModifyOrder(OrderTicket(), OrderOpenPrice(), NewStop, OrderTakeProfit(), OrderExpiration(), clrNONE, __FUNCTION__, slm);
      if (!result)
         Sleep(10000);//10 seconds before trying again
         
      while (IsTradeContextBusy() ) Sleep(100);
      if (PartCloseEnabled && OrderComment() == TradeComment) bool success = PartCloseOrder(OrderTicket() );
   }//if (modify)
   
} // End BreakevenStopLoss sub

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
bool PartCloseOrder(int ticket)
{
   //Close PartClosePercent of the initial trade.
   //Return true if close succeeds, else false
   if (!BetterOrderSelect(ticket, SELECT_BY_TICKET, MODE_TRADES)) return(true);//in case the trade closed
   
   bool Success = false;
   double CloseLots = NormalizeLots(OrderSymbol(),OrderLots() * (PartClosePercent / 100));
   
   Success = OrderClose(ticket, CloseLots, OrderClosePrice(), 1000, Blue); //fxdaytrader, NormalizeLots(...
   if (Success) TradeHasPartClosed = true;//Warns CountOpenTrades() that the OrderTicket() is incorrect.
   if (!Success) 
   {
       //mod. fxdaytrader, orderclose-retry if failed with ordercloseprice(). Maybe very seldom, but it can happen, so it does not hurt to implement this:
       while(IsTradeContextBusy()) Sleep(100);
       RefreshRates();
       if (OrderType()==OP_BUY) Success = OrderClose(ticket, CloseLots, MarketInfo(OrderSymbol(),MODE_BID), 5000, Blue);
       if (OrderType()==OP_SELL) Success = OrderClose(ticket, CloseLots, MarketInfo(OrderSymbol(),MODE_ASK), 5000, Blue);
       //end mod.  
       //original:
       if (Success) TradeHasPartClosed = true;//Warns CountOpenTrades() that the OrderTicket() is incorrect.
   
       if (!Success) 
       {
         ReportError(" PartCloseOrder()", pcm);
         return (false);
       } 
   }//if (!Success) 
      
   //Got this far, so closure succeeded
   return (true);   

}//bool PartCloseOrder(int ticket)

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void JumpingStopLoss(int ticket)
{
  // Jump sl by pips and at intervals chosen by user .

   //Thomas substantially rewrote this function. Many thanks, Thomas.
   
  //Security check
  if (!OrderSelect(ticket, SELECT_BY_TICKET, MODE_TRADES))
     return;

  //if (OrderProfit() < 0) return;//Nothing to do
  double sl = OrderStopLoss();
  
  //if (CloseEnough(sl, 0) ) return;//No line, so nothing to do
  double NewStop = 0;
  bool modify=false;
  bool result = false;
  
  double JSWidth=JumpingStopPips/factor;//Thomas
  int JSMultiple;//Thomas
  
   if (OrderType()==OP_BUY)
   {
      if (sl < OrderOpenPrice() ) return;//Not at breakeven yet
      // Increment sl by sl + JumpingStopPips.
      // This will happen when market price >= (sl + JumpingStopPips)
      //if (Bid>= sl + ((JumpingStopPips*2) / factor) )
      if (CloseEnough(sl, 0) ) sl = MathMax(OrderStopLoss(), OrderOpenPrice());
      if (bid >= sl + (JSWidth * 2))//Thomas
      {
         JSMultiple = (int)floor((bid-sl)/(JSWidth))-1;//Thomas
         NewStop = NormalizeDouble(sl + (JSMultiple*JSWidth), digits);//Thomas
         if (NewStop - OrderStopLoss() >= Point) modify = true;//George again. What a guy
      }// if (bid>= sl + (JumpingStopPips / factor) && sl>= OrderOpenPrice())    
   }//if (OrderType()==OP_BUY)
      
      if (OrderType()==OP_SELL)
      {
         if (sl > OrderOpenPrice() ) return;//Not at breakeven yet
         // Decrement sl by sl - JumpingStopPips.
         // This will happen when market price <= (sl - JumpingStopPips)
         //if (bid<= sl - ((JumpingStopPips*2) / factor)) Original code
         if (CloseEnough(sl, 0) ) sl = MathMin(OrderStopLoss(), OrderOpenPrice());
         if (CloseEnough(sl, 0) ) sl = OrderOpenPrice();
         if (bid <= sl - (JSWidth * 2))//Thomas
         {
            JSMultiple = (int)floor((sl-bid)/(JSWidth))-1;//Thomas
            NewStop = NormalizeDouble(sl - (JSMultiple*JSWidth), digits);//Thomas
            if (OrderStopLoss() - NewStop >= Point || OrderStopLoss() == 0) modify = true;//George again. What a guy  
         }// close if (bid>= sl + (JumpingStopPips / factor) && sl>= OrderOpenPrice())        
      }//if (OrderType()==OP_SELL)

  //Move 'hard' stop loss whether hidden or not. Don't want to risk losing a breakeven through disconnect.
  if (modify)
  {
     while (IsTradeContextBusy() ) Sleep(100);
     result = ModifyOrder(OrderTicket(), OrderOpenPrice(), NewStop, OrderTakeProfit(), OrderExpiration(), clrNONE, __FUNCTION__, slm);      
  }//if (modify)

} //End of JumpingStopLoss
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void TrailingStopLoss(int ticket)
{

   //Security check
   if (!BetterOrderSelect(ticket, SELECT_BY_TICKET, MODE_TRADES))
      return;
   
   if (OrderProfit() < 0) return;//Nothing to do
   double sl = OrderStopLoss();
   
   double NewStop = 0;
   bool modify=false;
   bool result = false;
   
    if (OrderType()==OP_BUY)
       {
          if (sl < OrderOpenPrice() ) return;//Not at breakeven yet
          // Increment sl by sl + TrailingStopPips.
          // This will happen when market price >= (sl + JumpingStopPips)
          //if (bid>= sl + (TrailingStopPips / factor) ) Original code
          if (CloseEnough(sl, 0) ) sl = MathMax(OrderStopLoss(), OrderOpenPrice());
          if (bid >= sl + (TrailingStopPips / factor) )//George
          {
             NewStop = NormalizeDouble(sl + (TrailingStopPips / factor), digits);
             if (NewStop - OrderStopLoss() >= Point) modify = true;//George again. What a guy
          }//if (bid >= MathMax(sl,OrderOpenPrice()) + (TrailingStopPips / factor) )//George
       }//if (OrderType()==OP_BUY)
       
       if (OrderType()==OP_SELL)
       {
          if (sl > OrderOpenPrice() ) return;//Not at breakeven yet
          // Decrement sl by sl - TrailingStopPips.
          // This will happen when market price <= (sl - JumpingStopPips)
          //if (bid<= sl - (TrailingStopPips / factor) ) Original code
          if (CloseEnough(sl, 0) ) sl = MathMin(OrderStopLoss(), OrderOpenPrice());
          if (CloseEnough(sl, 0) ) sl = OrderOpenPrice();
          if (bid <= sl  - (TrailingStopPips / factor))//George
          {
             NewStop = NormalizeDouble(sl - (TrailingStopPips / factor), digits);
             if (OrderStopLoss() - NewStop >= Point || OrderStopLoss() == 0) modify = true;//George again. What a guy   
          }//if (bid <= MathMin(sl, OrderOpenPrice() ) - (TrailingStopPips / factor) )//George
       }//if (OrderType()==OP_SELL)


   //Move 'hard' stop loss whether hidden or not. Don't want to risk losing a breakeven through disconnect.
   if (modify)
   {
      while (IsTradeContextBusy() ) Sleep(100);
      result = ModifyOrder(OrderTicket(), OrderOpenPrice(), NewStop, OrderTakeProfit(), OrderExpiration(), clrNONE, __FUNCTION__, slm);
   }//if (modify)
      
} // End of TrailingStopLoss sub
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void CandlestickTrailingStop(int ticket)
{

   //Security check
   if (!BetterOrderSelect(ticket, SELECT_BY_TICKET, MODE_TRADES))
      return;
   
   //Trails the stop at the hi/lo of the previous candle shifted by the user choice.
   //Only tries to do this once per bar, so an invalid stop error will only be generated once. I could code for
   //a too-close sl, but cannot be arsed. Coders, sort this out for yourselves.
   
   if (OldCstBars == iBars(NULL, CstTimeFrame)) return;
   OldCstBars = iBars(NULL, CstTimeFrame);

   if (OrderProfit() < 0) return;//Nothing to do
   double sl = OrderStopLoss();
   double NewStop = 0;
   bool modify=false;
   bool result = false;
   

   if (OrderType() == OP_BUY)
   {
      if (iLow(NULL, CstTimeFrame, CstTrailCandles) > sl)
      {
         NewStop = NormalizeDouble(iLow(NULL, CstTimeFrame, CstTrailCandles), digits);
         //Check that the new stop is > the old. Exit the function if not.
         if (NewStop < OrderStopLoss() || CloseEnough(NewStop, OrderStopLoss()) ) return;
         //Check that the new stop locks in profit, if the user requires this.
         if (TrailMustLockInProfit && NewStop < OrderOpenPrice() ) return;
         
         modify = true;   
      }//if (iLow(NULL, CstTimeFrame, CstTrailCandles) > sl)
   }//if (OrderType == OP_BUY)
   
   if (OrderType() == OP_SELL)
   {
      if (iHigh(NULL, CstTimeFrame, CstTrailCandles) < sl)
      {
         NewStop = NormalizeDouble(iHigh(NULL, CstTimeFrame, CstTrailCandles), digits);
         
         //Check that the new stop is < the old. Exit the function if not.
         if (NewStop > OrderStopLoss() || CloseEnough(NewStop, OrderStopLoss()) ) return;
         //Check that the new stop locks in profit, if the user requires this.
         if (TrailMustLockInProfit && NewStop > OrderOpenPrice() ) return;
         
         modify = true;   
      }//if (iHigh(NULL, CstTimeFrame, CstTrailCandles) < sl)
   }//if (OrderType() == OP_SELL)
   
   //Move 'hard' stop loss whether hidden or not. Don't want to risk losing a breakeven through disconnect.
   if (modify)
   {
      while (IsTradeContextBusy() ) Sleep(100);
      result = ModifyOrder(OrderTicket(), OrderOpenPrice(), NewStop, OrderTakeProfit(), OrderExpiration(), clrNONE, __FUNCTION__, slm);
      if (!result) 
      {
         OldCstBars = 0;
      }//if (!result) 
      
   }//if (modify)

}//End void CandlestickTrailingStop()
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void TradeManagementModule(int ticket)
{

   //Is individual trade management allowed?
   if (!AllowTradeManagement)
      return;
      
   // Call the working subroutines one by one. 

   //Candlestick trailing stop
   if(UseCandlestickTrailingStop) CandlestickTrailingStop(ticket);

   // Breakeven
   if(BreakEven) BreakEvenStopLoss(ticket);

   // JumpingStop
   if(JumpingStop) JumpingStopLoss(ticket);

   //TrailingStop
   if(TrailingStop) TrailingStopLoss(ticket);


}//void TradeManagementModule()
//END TRADE MANAGEMENT MODULE
////////////////////////////////////////////////////////////////////////////////////////


void CountTradesForDashboard(string symbol)
{

   OpenTrades=0;
   OpenLongTrades=0;
   OpenShortTrades=0;
   
   if (OrdersTotal() == 0)
      return;
      
   for (int cc = OrdersTotal() - 1; cc >= 0; cc--)
   {
      
      //Ensure the trade is still open
      if (!OrderSelect(cc, SELECT_BY_POS, MODE_TRADES) ) continue;
      //Ensure the EA 'owns' this trade
      if (OrderSymbol() != symbol ) continue;
      if (OrderMagicNumber() != MagicNumber) continue;
      if (OrderCloseTime() > 0) continue; 
      
      OpenTrades++;
      
      if (OrderType()==OP_BUY)
         OpenLongTrades++;
         
      if (OrderType()==OP_SELL)
         OpenShortTrades++;
      
   }//for (int cc = OrdersTotal() - 1; cc >= 0; cc--)
   
}//End void CountOpenTrades()

bool chartMinimize(long chartID = 0) 
{

   //This code was provided by Rene. Many thanks Rene.
   
   if (chartID == 0) chartID = ChartID();
   
   int chartHandle = (int)ChartGetInteger( chartID, CHART_WINDOW_HANDLE, 0 );
   int chartParent = GetParent(chartHandle);
   
   return( ShowWindow( chartParent, SW_FORCEMINIMIZE ) );
}//End bool chartMinimize(long chartID = 0) 

void ShrinkCharts()
{
   //Code provided by Rene. Many thanks, Rene
   
   long chartID = ChartFirst();
   
   while( chartID >= 0 ) {
      if ( !chartMinimize( chartID ) ) {
         PrintFormat("Couldn't minimize %I64d (Symbol: %s, Timeframe: %s)", chartID, ChartSymbol(chartID), EnumToString(ChartPeriod(chartID)) );
         //break;
      }
      chartID = ChartNext( chartID );
   }
   
   //PrintFormat("Waiting 10 seconds");
   //Sleep(10000);

}//End void ShrinkCharts()


//+------------------------------------------------------------------+
//| Chart Event function                                             |
//+------------------------------------------------------------------+
void OnChartEvent(const int id,const long &lparam,const double &dparam,const string &sparam)
{
   if(id==CHARTEVENT_OBJECT_CLICK)
      if(StringFind(sparam,"OAM-BTN")>=0)
      {
         ObjectSetInteger(0,sparam,OBJPROP_STATE,0);
         
         string result[];
         int tokens=StringSplit(sparam,StringGetCharacter("-",0),result);
         string pair=result[2];
         int tf=TradingTimeFrame;
         
         OpenChart(pair,tf);
         return;
      }
      
      else if(StringFind(sparam,"OAM-SWITCH")>=0)
      {
         ObjectSetInteger(0,sparam,OBJPROP_STATE,0);
         
         SwitchDisplays();
         return;
      }
      
}//End void OnChartEvent(const int id,const long &lparam,const double &dparam,const string &sparam)

void OpenChart(string pair,int tf)
{
   //If chart is already open, bring it to top
   long nextchart=ChartFirst();
   do
   {
      string symbol=ChartSymbol(nextchart);
      int period=ChartPeriod(nextchart);
      
      if(symbol==pair && period==tf && nextchart!=ChartID())
      {
         ChartSetInteger(nextchart,CHART_BRING_TO_TOP,true);
         return;
      }
   }
   while((nextchart=ChartNext(nextchart))!=-1);
   
   //Chart not found, so open a new one
   long newchartid=ChartOpen(pair,tf);
   ChartApplyTemplate(newchartid,TemplateName);
   
   TimerCount=1;//Restart timer to keep it from closing too early
  
}//End void OpenChart(string pair,int tf)
 

void SwitchDisplays()
{
   if (WhatToShow=="All")
      WhatToShow="Tradables";
   else if (WhatToShow=="Tradables")
      WhatToShow="OpenTrades";
   else if (WhatToShow=="OpenTrades")
      WhatToShow="All";
   DisplayUserFeedback();
}//End void SwitchDisplays()

bool EnoughDistance(string symbol, int type, double price)
{
   //Returns false if the is < MinDistanceBetweenTradesPips
   //between the price and the nearest order open prices.
   
   double pips = 0;
   
   //No market order yet
   if (type == OP_BUY)
      if (!BuyOpen)
         return(true);
      
   if (type == OP_SELL)
      if (!SellOpen)
         return(true);
      
   for (int cc = OrdersTotal() - 1; cc >= 0; cc--)
   {
      if (!BetterOrderSelect(cc, SELECT_BY_POS, MODE_TRADES) ) continue;
      if (OrderSymbol() != symbol ) continue;
      if (OrderMagicNumber() != MagicNumber) continue;
      if (OrderType() != type) continue;

      pips = MathAbs(price - OrderOpenPrice() ) * factor;
      if (pips < MinDistanceBetweenTrades)
         return(false);
   }//for (int cc = OrdersTotal() - 1; cc >= 0; cc--)

 
   //Got here, so OK to trade
   return(true);

   

}//End bool EnoughDistance(int type, double price)

double CalculateLotSize(string symbol, double price1,double price2)
{
   //Calculate the lot size by risk. Code kindly supplied by jmw1970. Nice one jmw.

   if(price1==0 || price2==0) return(Lot);//Just in case

   double FreeMargin= AccountFreeMargin();
   double TickValue = MarketInfo(symbol,MODE_TICKVALUE);
   double LotStep=MarketInfo(symbol,MODE_LOTSTEP);

   double SLPts=MathAbs(price1-price2);
   //SLPts/=Point;//No idea why *= factor does not work here, but it doesn't
   SLPts = int(SLPts * factor * 10);//Code from Radar. Thanks Radar; much appreciated

   double Exposure=SLPts*TickValue; // Exposure based on 1 full lot

   double AllowedExposure=(FreeMargin*RiskPercent)/100;

   int TotalSteps = (int)((AllowedExposure / Exposure) / LotStep);
   double LotSize = TotalSteps * LotStep;

   double MinLots = MarketInfo(symbol, MODE_MINLOT);
   double MaxLots = MarketInfo(symbol, MODE_MAXLOT);

   if(LotSize < MinLots) LotSize = MinLots;
   if(LotSize > MaxLots) LotSize = MaxLots;
   return(LotSize);

}//double CalculateLotSize(double price1, double price1)

bool LookForTradingOpportunities(string symbol, int PairIndex)
{

   double take, stop, price;
   int type;
   bool result = false;

   double SendLots = Lot;
   //Check filters
   if (!IsTradingAllowed(symbol, PairIndex) ) 
      return(false);
   
   bool SendTrade = false;
   double targetHigh = 0, targetLow = 0;//For the hilo of market trades open
   int err = 0;
   
   //Long 
   if (!BuyStopOpen && TradeLong && BuySignal[PairIndex])
   {
       
      //The idea is to place a stop order at the top of the previous candle,
      //so send an immediate market order it the price already exceeds this.
      if (ask >= iHigh(symbol, TradingTimeFrame, 1) )
      {
         type=OP_BUY;
         price = ask;//Change this to whatever the price needs to be
      }//if (ask >= iHigh(symbol, TradingTimeFrame, 1) )
      else
      {
         type = OP_BUYSTOP;
         price = iHigh(symbol, TradingTimeFrame, 1);      
      }//else
        
      //The market must be MinDistanceBetweenTradesPips away from the existing market trades
      //to avoid bunching.
      SendTrade = true;
      if (BuyOpen)
         if (MinDistanceBetweenTradesPips > 0)
         {
            if (!EnoughDistance(symbol, OP_BUY, price) )
               SendTrade = false;                  
         }//if (MinDistanceBetweenTradesPips > 0)
         
    
      
      if (SendTrade)
      {
         if (UseZeljko && !BalancedPair(symbol, OP_BUY) ) return(true);
         
         stop = CalculateStopLoss(OP_BUY, price);
         
         
         take = CalculateTakeProfit(OP_BUY, price);
         
         
         //Lot size calculated by risk
         if (!CloseEnough(RiskPercent, 0)) SendLots = CalculateLotSize(symbol, price, stop);
   
            
         result = SendSingleTrade(symbol, type, TradeComment, SendLots, price, stop, take);
         
   
         if (result) 
         {
            if (type == OP_BUYSTOP)
               BuyStopOpen = true;
            if (type == OP_BUY)
               BuyOpen = true;
               
            //The latest garbage from the morons at Crapperquotes appears to oPairIndexasionally break Matt's OR code, so tell the
            //ea not to trade for a while, to give time for the trade receipt to return from the server.
            TimeToStartTrading[PairIndex] = TimeCurrent() + PostTradeAttemptWaitSeconds;         
            if (BetterOrderSelect(TicketNo, SELECT_BY_TICKET, MODE_TRADES) )
            {         
               CheckTpSlAreCorrect(type);
            }//if (BetterOrderSelect(TicketNo, SELECT_BY_TICKET, MODE_TRADES) )   
         }//if (result)          
               
         //If a stop level error prevented the stop order being sent, then send a market order instead
         if (!result)
         {
            err = GetLastError();
            if (err == 130)
            {
               result = SendSingleTrade(symbol, OP_BUY, TradeComment, SendLots, price, stop, take);
               TimeToStartTrading[PairIndex] = TimeCurrent() + PostTradeAttemptWaitSeconds;         
               if (BetterOrderSelect(TicketNo, SELECT_BY_TICKET, MODE_TRADES) )
                  CheckTpSlAreCorrect(OrderType() );
            }//if (err == 130)
         }//if (!result)
         
         if (!result)
         {
            TimeToStartTrading[PairIndex] = 0;
         }//if (!result)
      
      }//if (SendTrade)
      
   
   }//if (!BuyStopOpen)
   
   //Short
   if (!SellStopOpen && TradeShort && SellSignal[PairIndex])
   {
      
      //The idea is to place a stop order at the bottom of the previous candle,
      //so send an immediate market order it the price already exceeds this.
      if (bid <= iLow(symbol, TradingTimeFrame, 1) )
      {
         type=OP_SELL;
         price = bid;//Change this to whatever the price needs to be
      }//if (bid <= iLow(symbol, TradingTimeFrame, 1) )
      else
      {
         type = OP_SELLSTOP;
         price = iLow(symbol, TradingTimeFrame, 1);      
      }//else
        
      
      //The market must be MinDistanceBetweenTradesPips away from the existing market trades
      //to avoid bunching.
      SendTrade = true;
      if (SellOpen)
         if (MinDistanceBetweenTradesPips > 0)
         {
            if (!EnoughDistance(symbol, OP_SELL, price) )
               SendTrade = false;                  
         }//if (MinDistanceBetweenTradesPips > 0)
        
      if (SendTrade)
      {
         if (UseZeljko && !BalancedPair(symbol, OP_SELL) ) return(true);
         
         stop = CalculateStopLoss(OP_SELL, price);
      
      
         take = CalculateTakeProfit(OP_SELL, price);
         
         
         //Lot size calculated by risk
         if (!CloseEnough(RiskPercent, 0)) SendLots = CalculateLotSize(symbol, price, stop);
   
            
         result = SendSingleTrade(symbol, type, TradeComment, SendLots, price, stop, take);
         
   
         if (result) 
         {
            if (type == OP_SELLSTOP)
               SellStopOpen = true;
            if (type == OP_SELL)
               SellOpen = true;
            
            //The latest garbage from the morons at Crapperquotes appears to oPairIndexasionally break Matt's OR code, so tell the
            //ea not to trade for a while, to give time for the trade receipt to return from the server.
            TimeToStartTrading[PairIndex] = TimeCurrent() + PostTradeAttemptWaitSeconds;         
            if (BetterOrderSelect(TicketNo, SELECT_BY_TICKET, MODE_TRADES) )
            {         
               CheckTpSlAreCorrect(type);
            }//if (BetterOrderSelect(TicketNo, SELECT_BY_TICKET, MODE_TRADES) )   
         }//if (result)          

         //If a stop level error prevented the stop order being sent, then send a market order instead
         if (!result)
         {
            err = GetLastError();
            if (err == 130)
            {
               result = SendSingleTrade(symbol, OP_SELL, TradeComment, SendLots, price, stop, take);
               TimeToStartTrading[PairIndex] = TimeCurrent() + PostTradeAttemptWaitSeconds;         
               if (BetterOrderSelect(TicketNo, SELECT_BY_TICKET, MODE_TRADES) )
                  CheckTpSlAreCorrect(OrderType() );
            }//if (err == 130)
         }//if (!result)
               
         if (!result)
         {
            TimeToStartTrading[PairIndex] = 0;
         }//if (!result)
         
      }//if (SendTrade)
      
         
   }// if (!SellStopOpen)
   
   
   
   return(true);


}//End void LookForTradingOpportunities(string symbol, int PairIndex)

bool BalancedPair(string symbol, int type)
{

   //Only allow an individual currency to trade if it is a balanced trade
   //e.g. UJ Buy open, so only allow Sell xxxJPY.
   //The passed parameter is the proposed trade, so an existing one must balance that

   //This code courtesy of Zeljko (zkucera) who has my grateful appreciation.
   
   string BuyCcy1, SellCcy1, BuyCcy2, SellCcy2;

   if (type == OP_BUY || type == OP_BUYSTOP)
   {
      BuyCcy1 = StringSubstrOld(symbol, 0, 3);
      SellCcy1 = StringSubstrOld(symbol, 3, 3);
   }//if (type == OP_BUY || type == OP_BUYSTOP)
   else
   {
      BuyCcy1 = StringSubstrOld(symbol, 3, 3);
      SellCcy1 = StringSubstrOld(symbol, 0, 3);
   }//else

   for (int cc = OrdersTotal() - 1; cc >= 0; cc--)
   {
      if (!BetterOrderSelect(cc, SELECT_BY_POS)) continue;
      if (OrderSymbol() == symbol) continue;
      if (OrderMagicNumber() != MagicNumber) continue;      
      if (OrderType() == OP_BUY || OrderType() == OP_BUYSTOP)
      {
         BuyCcy2 = StringSubstrOld(OrderSymbol(), 0, 3);
         SellCcy2 = StringSubstrOld(OrderSymbol(), 3, 3);
      }//if (OrderType() == OP_BUY || OrderType() == OP_BUYSTOP)
      else
      {
         BuyCcy2 = StringSubstrOld(OrderSymbol(), 3, 3);
         SellCcy2 = StringSubstrOld(OrderSymbol(), 0, 3);
      }//else
      if (BuyCcy1 == BuyCcy2 || SellCcy1 == SellCcy2) return(false);
   }//for (int cc = OrdersTotal() - 1; cc >= 0; cc--)

   //Got this far, so it is ok to send the trade
   return(true);

}//End bool BalancedPair(int type)

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

double CalculateTradeProfitInPips(int type)
{
   //This code supplied by Lifesys. Many thanks Paul.
   
   //Returns the pips Upl of the currently selected trade. Called by CountOpenTrades()
   double profit = 0;
  
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
bool SendSingleTrade(string symbol,int type,string comment,double lotsize,double price,double stop,double take)
{

   double slippage=MaxSlippagePips*MathPow(10,digits)/factor;
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
         ticket=OrderSend(symbol,type,lotsize,price,(int)slippage,stop,take,comment,MagicNumber,expiry,col);
         //ticket=OrderSend(symbol,type,lotsize,price,slippage,stop,take,comment,MagicNumber,expiry,col);

      //Is a 2 stage criminal
      if(IsGlobalPrimeOrECNCriminal)
      {
         ticket=OrderSend(symbol,type,lotsize,price,(int)slippage,0,0,comment,MagicNumber,expiry,col);
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
         if (type < 2)
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
         Alert(symbol," sent trade not in your trade history yet. Turn of this ea NOW.");
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

   if (!BetterOrderSelect(ticket, SELECT_BY_TICKET) ) return;//Trade does not exist, so no mod needed
   
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
         if(BetterOrderSelect(c,SELECT_BY_POS,MODE_TRADES)==true) 
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
            if(BetterOrderSelect(c,SELECT_BY_POS,MODE_HISTORY)==true) 
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
         Print("Did not find #"+IntegerToString(ticket)+" in history, sleeping, then doing retry #"+IntegerToString(cnt));
         O_R_Sleep(O_R_Setting_sleep_time,O_R_Setting_sleep_max);
        }
     }
// Select back the prior ticket num in case caller was using it.
   if(lastTicket>=0) 
     {
      bool s = BetterOrderSelect(lastTicket,SELECT_BY_TICKET,MODE_TRADES);
     }
   if(!success) 
     {
      Print("Never found #"+IntegerToString(ticket)+" in history! crap!");
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
   int ms = (int)t*1000;
   if (ms < 10) {
      ms=10;
   }//if (ms < 10) {
   
   Sleep(ms);
}//End void O_R_Sleep(double mean_time, double max_time)

////////////////////////////////////////////////////////////////////////////////////////

void CheckTpSlAreCorrect(int type)
{
   //Looks at an open trade and checks to see that the exact tp/sl were sent with the trade.
   
   
   double stop = 0, take = 0, diff = 0;
   bool ModifyStop = false, ModifyTake = false;
   bool result;
   
   //Is the stop at BE?
   if (type == OP_BUY && OrderStopLoss() >= OrderOpenPrice() ) return;
   if (type == OP_SELL && OrderStopLoss() <= OrderOpenPrice() ) return;
   
   if (type == OP_BUY || type == OP_BUYSTOP || type == OP_BUYLIMIT)
   {
      if (!CloseEnough(OrderStopLoss(), 0) )
      {
         diff = (OrderOpenPrice() - OrderStopLoss()) * factor;
         if (!CloseEnough(diff, StopLoss) ) 
         {
            ModifyStop = true;
            stop = CalculateStopLoss(OP_BUY, OrderOpenPrice());
         }//if (!CloseEnough(diff, StopLoss) )          
      }//if (!CloseEnough(OrderStopLoss(), 0) )      

      if (!CloseEnough(OrderTakeProfit(), 0) )
      {
         diff = (OrderTakeProfit() - OrderOpenPrice()) * factor;
         if (!CloseEnough(diff, TakeProfit) ) 
         {
            ModifyTake = true;
            take = CalculateTakeProfit(OP_BUY, OrderOpenPrice());
         }//if (!CloseEnough(diff, TakeProfit) )          
      }//if (!CloseEnough(OrderStopLoss(), 0) )      
   }//if (type == OP_BUY)
   
   if (type == OP_SELL || type == OP_SELLSTOP || type == OP_SELLLIMIT)
   {
      if (!CloseEnough(OrderStopLoss(), 0) )
      {
         diff = (OrderStopLoss() - OrderOpenPrice() ) * factor;
         if (!CloseEnough(diff, StopLoss) ) 
         {
            ModifyStop = true;
            stop = CalculateStopLoss(OP_SELL, OrderOpenPrice());

         }//if (!CloseEnough(diff, StopLoss) )          
      }//if (!CloseEnough(OrderStopLoss(), 0) )      

      if (!CloseEnough(OrderTakeProfit(), 0) )
      {
         diff = (OrderOpenPrice() - OrderTakeProfit() ) * factor;
         if (!CloseEnough(diff, TakeProfit) ) 
         {
            ModifyTake = true;
            take = CalculateTakeProfit(OP_SELL, OrderOpenPrice());
         }//if (!CloseEnough(diff, TakeProfit) )          
      }//if (!CloseEnough(OrderStopLoss(), 0) )      
   }//if (type == OP_SELL)
   
   if (ModifyStop)
   {
      result = ModifyOrder(OrderTicket(), OrderOpenPrice(), stop, OrderTakeProfit(), OrderExpiration(), clrNONE, __FUNCTION__, slim);
   }//if (ModifyStop)
   
   if (ModifyTake)
   {
      result = ModifyOrder(OrderTicket(), OrderOpenPrice(), OrderStopLoss(), take, OrderExpiration(), clrNONE, __FUNCTION__, tpm);
   }//if (ModifyStop)
   

}//void CheckTpSlAreCorrect(int type)

void LookForHedgedBasketClosure(string symbol, int PairIndex)
{
   bool ClosePosition = false;
   
   //Cash upl
   if (CashUpl[PairIndex] >= HedgedBasketCashTakeProfit)
   {
      ClosePosition = true;
   }//if (CashUpl >= BasketCashTakeProfit)


   if (ClosePosition)   
   {
      Alert(symbol, " Candle Power has hit its hedged basket take profit. All trades should have closed.");
      CloseAllTrades(symbol, AllTrades);
      if (ForceTradeClosure)
      {
         CloseAllTrades(symbol, AllTrades);
         if (ForceTradeClosure)
         {
            CloseAllTrades(symbol, AllTrades);
         }//if (ForceTradeClosure)                     
         if (ForceTradeClosure)
         {
            return;
         }//if (ForceTradeClosure)                     
      }//if (ForceTradeClosure)  

   }//if (ClosePosition)   
   
   //Got this far, so all the trades have been closed/deleted. Clear all the variables.
   CountOpenTrades(symbol, PairIndex);

}//End void LookForHedgedBasketClosure(string symbol, int PairIndex)


void CloseAllTrades(string symbol, int type)
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
         if (!BetterOrderSelect(FifoTicket[cc], SELECT_BY_TICKET, MODE_TRADES) ) continue;
         if (OrderMagicNumber() != MagicNumber) continue;
         if (OrderSymbol() != symbol) 
            if (symbol != AllSymbols)
               continue;
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


}//End void CloseAllTrades(string symbol, int type)

void CloseAllTradesBelongingToEA()
{

   WholePositionForceTradeClosure = false;
   
   if (OrdersTotal() == 0) return;
   
   bool result = false;
   for (int pass = 0; pass <= 1; pass++)
   {
      if (OrdersTotal() == 0 || OpenTrades == 0)
         break;
      for (int cc = ArraySize(FifoTicket) - 1; cc >= 0; cc--)
      {
         if (!BetterOrderSelect(FifoTicket[cc], SELECT_BY_TICKET, MODE_TRADES) ) continue;
         if (OrderMagicNumber() != MagicNumber) continue;
         
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
               if (!result) WholePositionForceTradeClosure = true;
            }//if (OrderType() > 1) 
            
      }//for (int cc = ArraySize(FifoTicket) - 1; cc >= 0; cc--)
   }//for (int pass = 0; pass <= 1; pass++)
   
   //If full closure succeeded, then allow new trading
   if (!WholePositionForceTradeClosure) 
   {
      OpenTrades = 0;
      BuyOpen = false;
      SellOpen = false;
   }//if (!ForceTradeClosure) 


}//End void CloseAllTradesBelongingToEA()

void ShutDownForTheWeekend(int PairIndex)
{

   //Close/delete all trades to be flat for the weekend.
   
   int day = TimeDayOfWeek(TimeLocal() );
   int hour = TimeHour(TimeLocal() );
   bool CloseDelete = false;
   
   //Friday
   if (day == 5)
   {
      if (hour >= FridayCloseAllHour)
         if (CashUpl[PairIndex] > MaxAllowableCashLoss)//MaxAllowableCashLoss is a negative number
            CloseDelete = true;
   }//if (day == 5)
 
   //Saturday
   if (day == 6)
   {
      if (hour >= SaturdayCloseAllHour)
         if (CashUpl[PairIndex] > MaxAllowableCashLoss)//MaxAllowableCashLoss is a negative number
            CloseDelete = true;
   }//if (day == 6)
   
   if (CloseDelete)
   {
      CloseAllTrades(AllSymbols, AllTrades);
      if (ForceTradeClosure)
         CloseAllTrades(AllSymbols, AllTrades);
      if (ForceTradeClosure)
         CloseAllTrades(AllSymbols, AllTrades);
   }//if (CloseDelete)
      

}//End void ShutDownForTheWeekend()

bool MopUpTradeClosureFailures()
{
   //Cycle through the ticket numbers in the ForceCloseTickets array, and attempt to close them
   
   bool Success = true;
   
   for (int cc = ArraySize(ForceCloseTickets) - 1; cc >= 0; cc--)
   {
      //Order might have closed during a previous attempt, so ensure it is still open.
      if (!BetterOrderSelect(ForceCloseTickets[cc], SELECT_BY_TICKET, MODE_TRADES) )
         continue;
   
      bool result = CloseOrder(OrderTicket() );
      if (!result)
         Success = false;
   }//for (int cc = ArraySize(ForceCloseTickets) - 1; cc >= 0; cc--)
   
   if (Success)
      ArrayFree(ForceCloseTickets);
   
   return(Success);


}//END bool MopUpTradeClosureFailures()


void ShouldTradesBeClosed(string symbol, int PairIndex, int NoOfTradesMustBeOpen)
{
   //Examine baskets of trades for possible closure
   
   if (OpenTrades == 0)
      return;//Nothing to do

   //Can younger winners be offset against the oldest loser?
   if (UseOffsetting)
   {
      if (CanTradesBeOffset(symbol, PairIndex, NoOfTradesMustBeOpen))
      {
         CountOpenTrades(symbol, PairIndex);
         return;
      }//if (CanTradesBeOffset())
      //In case any trade closures failed
      if (ArraySize(ForceCloseTickets) > 0)
      {
         MopUpTradeClosureFailures();
         return;
      }//if (ArraySize(ForceCloseTickets) > 0)      
   }//if (UseOffsetting)
        
}//void ShouldTradesBeClosed()

bool CanTradesBeOffset(string symbol, int PairIndex, int NoOfTradesMustBeOpen)
{

   double pips = 0;//The pips upl of the highest buy or lowest sell
   double loss = 0;//Convers pips to a positive value for comparison with (MinDistanceBetweenTradesPips / factor)
   double profit = 0;//Cash upl of the side being calculated to see if they can combine to close a loser on the other side
   int TradesToClose = 0;
   bool result = false;
   int cc = 0;
   double HighestTradeCash = 0;
   double LowestTradeCash = 0;
   int tries = 0;
   int cas = 0;//ForceCloseTickets array size
   double CashLoss = 0;
   double CashProfit = 0;
   int NoOfTrades = 0;
   double ThisOrderProfit = 0;
   bool ClosePossible = false;
   int ClosureTickets[];
   double ThisTradeProfit = 0;
                                             
   ArrayFree(ForceCloseTickets);
   
   //Look for a simple offset opportunity of a losing buy at the
   //top of the pile by the winner at the bottom.
   if (MarketBuysCount > NoOfTradesMustBeOpen)//Impossible with < 4
   {
      //Do we have a losing buy?
      if (OrderSelect(HighestBuyTicketNo, SELECT_BY_TICKET, MODE_TRADES) )
      {
         //Calculate the pips upl of the highest, and so latest, buy
         pips = CalculateTradeProfitInPips(OP_BUY);
         if (pips < 0)//Only continue if it is losing
         {
            loss = (pips * -1);//Turn the loss into a positive number for the comparison
            if (loss >= MinDistanceBetweenTradesPips)//Only continue if losing by at least 1 grid level
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
                              ArrayFree(ForceCloseTickets);
                              ArrayResize(ForceCloseTickets, 1);
                              ForceCloseTickets[0] = LowestBuyTicketNo;
                              return(false);
                           }//if (tries >= 20)  
                        }//if (!result)
                        
                     }//while (!result)
                  }//if (OrderSelect(LowestBuyTicketNo, SELECT_BY_TICKET, MODE_TRADES) )
                     
                  return(true);//Routine succeeded
                  
               }//if ((HighestTradeCash + LowestTradeCash) > 0)                  
            }//if (loss >= MinDistanceBetweenTradesPips)
            
         }//if (pips < 0)
      }//if (OrderSelect(HighestBuyTicketNo, SELECT_BY_TICKET, MODE_TRADES) )
      ArrayFree(ForceCloseTickets);
   }//if (MarketBuysCount > 3)
     
   //Look for a simple offset opportunity of a losing sell at the
   //top of the pile by the winner at the bottom.
   if (MarketSellsCount > NoOfTradesMustBeOpen)//Impossible with < 3
   {

      //Do we have a losing buy?
      if (OrderSelect(LowestSellTicketNo, SELECT_BY_TICKET, MODE_TRADES) )
      {
         //Calculate the pips upl of the lowest, and so latest, sell
         pips = CalculateTradeProfitInPips(OP_SELL);

         if (pips < 0)//Only continue if it is losing
         {
            loss = (pips * -1);//Turn the loss into a positive number for the comparison

            if (loss >= MinDistanceBetweenTradesPips)//Only continue if losing by at least 1 grid level
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
                              ArrayFree(ForceCloseTickets);
                              ArrayResize(ForceCloseTickets, 1);
                              ForceCloseTickets[0] = HighestSellTicketNo;
                              return(false);
                           }//if (tries >= 20)  
                        }//if (!result)      
                     }//while (!result)
                  }//if (OrderSelect(HighestSellTicketNo, SELECT_BY_TICKET, MODE_TRADES) )
                     
                  return(true);//Routine succeeded
                  
               }//if ((HighestTradeCash + LowestTradeCash) > 0)               
            }//if (loss >= MinDistanceBetweenTradesPips)
            
         }//if (pips < 0)
      }//if (OrderSelect(LowestSellTicketNo, SELECT_BY_TICKET, MODE_TRADES) )
      ArrayFree(ForceCloseTickets);
          
   }//if (MarketSellsCount  > 3)
       
    
   ////////////////////////////////////////////////////////////////////////
   //Got this far, so see if the combined winners on one side can combine
   //to close a loser on the other side.
   
   if (Hedged)
   {
      ArrayInitialize(ClosureTickets, -1);
      tries = 0;
      int as = 0;//Array size

      //Can we offset some buy trades against the lowest losing sell trade
      if (BuyCashUpl > 0)//The buy side of the hedge must be profitable overall
         if (MarketBuysCount >= NoOfTradesMustBeOpen)//Must be sufficient trades open to start offsetting
            if (OrderSelect(LowestSellTicketNo, SELECT_BY_TICKET, MODE_TRADES))//Select the lowest sell
            {
            
                //Calculate the pips upl of the lowest, and so latest, sell
                if((CalculateTradeProfitInPips(OP_SELL)*-1)>=MinDistanceBetweenTradesPips) // Only continue if the trade is losing by more than MinDistanceBetweenTradesPips
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
                           }//if (OrderSelect(FifoBuyTicket[cc - 1][ticket], SELECT_BY_TICKET, MODE_TRADES) )
                           
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
                              CountOpenTrades(symbol, PairIndex);
                              return(true);
                           }//if (ArraySize(ForceCloseTickets) == 0)
                           else
                           {
                              return(false);
                           }//else                              
                        }//if (ClosePossible)
                     }//if (CashLoss < 0)
                  }// if((CalculateTradeProfitInPips(OP_SELL)*-1)>=MinDistanceBetweenTradesPips)
            }//if (OrderSelect(LowestSellTicketNo, SELECT_BY_TICKET, MODE_TRADES))
            
      CashLoss = 0;
      CashProfit = 0;
      NoOfTrades = 0;
      ClosePossible = false;
      ArrayFree(ForceCloseTickets);
      tries = 0;

      //Can we offset some sell trades against the highest losing buy trade
      if (SellCashUpl > 0)//The sell side of the hedge must be profitable overall
         if (MarketSellsCount >= NoOfTradesMustBeOpen)//Must be sufficient trades open to start offsetting
            if (OrderSelect(HighestBuyTicketNo, SELECT_BY_TICKET, MODE_TRADES))//Select the highest buy
            {
               
               //Calculate the pips upl of the lowest, and so latest, sell
               if((CalculateTradeProfitInPips(OP_BUY)*-1)>=MinDistanceBetweenTradesPips) // Only continue if the trade is losing by more than MinDistanceBetweenTradesPips
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
                              if (!result)
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
                           CountOpenTrades(symbol, PairIndex);
                           return(true);
                        }//if (ArraySize(ForceCloseTickets) == 0)
                        else
                        {
                           return(false);
                        }//else                              
                     }//if (ClosePossible)
                  }//if (CashLoss < 0)
               }//if((CalculateTradeProfitInPips(OP_SELL)*-1)>=MinDistanceBetweenTradesPips)
            }//if (OrderSelect(HighestBuyTicketNo, SELECT_BY_TICKET, MODE_TRADES))
   
   }//if (Hedged)

//////////////////////////////////////////////////////////////////////////////////////
// Added single side offset below:


   if(AllowComplexSingleSidedOffsets)//then allow buy side single offsets
   {
       CashLoss = 0;
       CashProfit = 0;
       NoOfTrades = 0;
       ArrayFree(ForceCloseTickets);
      
 
      ////////////////////////////////////////////////////////////////
      ///As above but one sided; complex hedge closure - looking for a group of winning buys to close the worst losing buy:     
      //Can we offset some buy trades against the worst losing buy trade?
      //if (BuyCashUpl > 0)//The buy side of the hedge must be profitable overall // not true for single sided
      
      // buy side only variables
      bool ClosePossibleBuySide = false;
      int ClosureTicketsBuySide[];
      ArrayInitialize(ClosureTicketsBuySide, -1);
      
      
      if (MarketBuysCount >= NoOfTradesMustBeOpen)//Must be sufficient trades open to start offsetting
         if (OrderSelect(HighestBuyTicketNo, SELECT_BY_TICKET, MODE_TRADES))//Select the highest buy which will be the worst loser
         {
         
            //Calculate the pips upl of the lowest, and so latest, sell
            if((CalculateTradeProfitInPips(OP_BUY)*-1)>=MinDistanceBetweenTradesPips) // Only continue if the trade is losing by more than MinDistanceBetweenTradesPips
            {
            
            CashLoss = (OrderSwap() + OrderCommission() + OrderProfit());//Calculate its cash position
            CashLoss*= -1;//Convert to a positive for comparison with the profit on the other side
            //if (CashLoss < 0)//Is it losing?  // changed to check for MinDistanceBetweenTradesPips
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
                     CountOpenTrades(symbol, PairIndex);
                     return(true);
                  }//if (ArraySize(ForceCloseTickets) == 0)
                  else
                  {
                     return(false);
                  }//else                              
               }// if (ClosePossibleBuySide)
            }//if (CashLoss >= MinDistanceBetweenTradesPips)
         }//if((CalculateTradeProfitInPips(OP_BUY)*-1)>=MinDistanceBetweenTradesPips)
      }//if (OrderSelect(HighestBuyTicketNo, SELECT_BY_TICKET, MODE_TRADES))
         
      CashLoss = 0;
      CashProfit = 0;
      NoOfTrades = 0;
      ClosePossibleBuySide = false;
      ArrayFree(ClosureTicketsBuySide);
      
   
   //END - buy side only complex hedge
   
   ///////////////////////////////////////////
 
 
   ///One Sided complex hedge closure - looking for a group of winning sells to close the worst losing sell:
      // sell side only variables
      bool ClosePossibleSellSide = false;
      int ClosureTicketsSellSide[];
      
      //Can we offset some sell trades against the lowest losing sell trade
      
      if (MarketSellsCount >= NoOfTradesMustBeOpen)//Must be sufficient trades open to start offsetting
         if (OrderSelect(LowestSellTicketNo, SELECT_BY_TICKET, MODE_TRADES))//Select the lowest sell which will be the worst loser
         {
            
            //Calculate the pips upl of the lowest, and so latest, sell
            if((CalculateTradeProfitInPips(OP_SELL)*-1)>=MinDistanceBetweenTradesPips) // Only continue if the trade is losing by more than MinDistanceBetweenTradesPips
            {
               CashLoss = (OrderSwap() + OrderCommission() + OrderProfit());//Calculate its cash position
               CashLoss*= -1;//Convert to a positive for comparison with the profit on the other side
               
               //if (CashLoss < 0)//Is it losing?  // changed to check for MinDistanceBetweenTradesPips.
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
                        CountOpenTrades(symbol, PairIndex);
                        return(true);
                     }//if (ArraySize(ForceCloseTickets) == 0)
                     else
                     {
                        return(false);
                     }//else                              

                  }//if (ClosePossibleSellSide)
               }//if (CashLoss >= MinDistanceBetweenTradesPips)
            }//if((CalculateTradeProfitInPips(OP_SELL)*-1)>=MinDistanceBetweenTradesPips) 
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

bool MarginCheck()
{

   EnoughMargin = true;//For user display
   MarginMessage = "";
   if (UseScoobsMarginCheck && OpenTrades > 0)
   {
      if(AccountMargin() > (AccountFreeMargin()/100)) 
      {
         MarginMessage = "There is insufficient margin to allow trading. You might want to turn off the UseScoobsMarginCheck input.";
         return(false);
      }//if(AccountMargin() > (AccountFreeMargin()/100)) 
      
   }//if (UseScoobsMarginCheck)


   if (UseForexKiwi && AccountMargin() > 0)
   {
      double ml = NormalizeDouble(AccountEquity() / AccountMargin() * 100, 2);
      if (ml < FkMinimumMarginPercent)
      {
         MarginMessage = StringConcatenate("There is insufficient margin percent to allow trading. ", DoubleToStr(ml, 2), "%");
         return(false);
      }//if (ml < FkMinimumMarginPercent)
   }//if (UseForexKiwi && AccountMargin() > 0)
   
  
   //Got this far, so there is sufficient margin for trading
   return(true);
}//End bool MarginCheck()

void NuclearOptions(string symbol, int PairIndex)
{
   //Respond to the user's choice of options when a position becomes unbalanced.
   
   //Instant closure of the position.
   if (UseInstantClosure)
   {
      CloseAllTrades(AllSymbols, AllTrades);
      if(ForceTradeClosure)
      {
         CloseAllTrades(AllSymbols, AllTrades);
         if (ForceTradeClosure)
            return;
      }//if (ForceTradeClosure) 
      
      //Closure succeeded, so rebuild a picture of the position.
      CountOpenTrades(symbol, PairIndex);
   }//if (UseInstantClosure)
   
   //Margin level
   if (UseMarginLevelClosure)
   {
      //Use the existing MarginCheck function
      //Store the user' choices
      bool OldFk = UseForexKiwi;
      int OldFkMin = FkMinimumMarginPercent;
      UseForexKiwi = true;
      FkMinimumMarginPercent = ClosureMarginLevel;
      
      bool MarginOk = MarginCheck();
      
      //Restore the user's choices
      UseForexKiwi = OldFk;
      FkMinimumMarginPercent = OldFkMin;
      
      if (!MarginOk)
      {
         CloseAllTrades(AllSymbols, AllTrades);
         if(ForceTradeClosure)
         {
            CloseAllTrades(AllSymbols, AllTrades);
            if (ForceTradeClosure)
               return;
         }//if (ForceTradeClosure) 
      
         //Closure succeeded, so rebuild a picture of the position.
         CountOpenTrades(symbol, PairIndex);
      }//if (!MarginOk() )
      
      
   }//if (UseMarginLevelClosure)
   
   
   
}//End void NuclearOptions()

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
		i++;		
		if ( i == ArraySize( tradeHours ) ) break;
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
		ArrayFree(tradeHours);
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
			ArrayFree( tradeHours );
			return ( true );
		}

		if ( ( prefix == "+" && lastPrefix == "+" ) || ( prefix == "-" && lastPrefix == "-" ) )	
		{
			Print("ERROR IN TRADINGHOURS INPUT (START OR CLOSE IN WRONG ORDER), ASSUME 24HOUR TRADING.");
			ArrayFree ( tradeHours );
			return ( true );
		}
		
		lastPrefix = prefix;

		// Convert to time in minutes
		part = StringSubstrOld( part, 1 );
		double time = StrToDouble( part );
		int hour = (int)MathFloor( time );
		int minutes = (int)MathRound( ( time - hour ) * 100 );

		// Add to array
		tradeHours[size] = 60 * hour + minutes;

		// Trim input string
		tradingHours = StringSubstrOld( tradingHours, i + 1 );
		i = StringFind( tradingHours, "," );
	}//while (i != -1) 

	return ( true );
}//End bool initTradingHours() 

// for 6xx build compatibilità added by milanese
string StringSubstrOld(string x,int a,int b=-1) 
{
   if(a<0) a=0; // Stop odd behaviour
   if(b<=0) b=-1; // new MQL4 EOL flag
   return StringSubstr(x,a,b);
}

bool SundayMondayFridayStuff()
{

   //Friday/Saturday stop trading hour
   int d = TimeDayOfWeek(TimeLocal());
   int h = TimeHour(TimeLocal());
   if (d == 5)
      if (h >= FridayStopTradingHour)
         if (OpenTrades == 0)
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

bool IsTradingAllowed(string symbol, int PairIndex)
{
   //Returns false if any of the filters should cancel trading, else returns true to allow trading
   
      
   //Maximum spread. We do not want any trading operations  during a wide spread period
   if (!SpreadCheck(PairIndex) ) 
      return(false);
   
    
   //An individual currency can only be traded twice, so check for this
   CanTradeThisPair = true;
   if (OnlyTradeCurrencyTwice && OpenTrades == 0)
   {
      IsThisPairTradable(symbol);      
   }//if (OnlyTradeCurrencyTwice)
   if (!CanTradeThisPair) return(false);
   
   //Swap filter
   if (OpenTrades == 0) TradeDirectionBySwap(symbol);
   
   //Order close time safety feature
   if (TooClose(symbol)) return(false);

   return(true);


}//End bool IsTradingAllowed()

bool IsThisPairTradable(string symbol)
{
   //Checks to see if either of the currencies in the pair is already being traded twice.
   //If not, then return true to show that the pair can be traded, else return false
   
   string c1 = StringSubstrOld(symbol, 0, 3);//First currency in the pair
   string c2 = StringSubstrOld(symbol, 3, 3);//Second currency in the pair
   int c1open = 0, c2open = 0;
   CanTradeThisPair = true;
   for (int cc = OrdersTotal() - 1; cc >= 0; cc--)
   {
      if (!BetterOrderSelect(cc, SELECT_BY_POS) ) continue;
      if (OrderSymbol() != symbol ) continue;
      if (OrderMagicNumber() != MagicNumber) continue;
      int index = StringFind(OrderSymbol(), c1);
      if (index > -1)
      {
         c1open++;         
      }//if (index > -1)
   
      index = StringFind(OrderSymbol(), c2);
      if (index > -1)
      {
         c2open++;         
      }//if (index > -1)
   
      if (c1open == 1 && c2open == 1) 
      {
         CanTradeThisPair = false;
         return(false);   
      }//if (c1open == 1 && c2open == 1) 
   }//for (int cc = OrdersTotal() - 1; cc >= 0; cc--)

   //Got this far, so ok to trade
   return(true);
   
}//End bool IsThisPairTradable()

void TradeDirectionBySwap(string symbol)
{

   //Sets TradeLong & TradeShort according to the positive/negative swap it attracts

   //Swap is read in init() and start()


   if (CadPairsPositiveOnly)
   {
      if (StringSubstrOld(symbol, 0, 3) == "CAD" || StringSubstrOld(symbol, 0, 3) == "cad" || StringSubstrOld(symbol, 3, 3) == "CAD" || StringSubstrOld(symbol, 3, 3) == "cad" )      
      {
         if (LongSwap > 0) TradeLong = true;
         else TradeLong = false;
         if (ShortSwap > 0) TradeShort = true;
         else TradeShort = false;         
      }//if (StringSubstrOld()      
   }//if (CadPairsPositiveOnly)
   
   if (AudPairsPositiveOnly)
   {
      if (StringSubstrOld(symbol, 0, 3) == "AUD" || StringSubstrOld(symbol, 0, 3) == "aud" || StringSubstrOld(symbol, 3, 3) == "AUD" || StringSubstrOld(symbol, 3, 3) == "aud" )      
      {
         if (LongSwap > 0) TradeLong = true;
         else TradeLong = false;
         if (ShortSwap > 0) TradeShort = true;
         else TradeShort = false;         
      }//if (StringSubstrOld()      
   }//if (AudPairsPositiveOnly)
   
   
   if (NzdPairsPositiveOnly)
   {
      if (StringSubstrOld(symbol, 0, 3) == "NZD" || StringSubstrOld(symbol, 0, 3) == "nzd" || StringSubstrOld(symbol, 3, 3) == "NZD" || StringSubstrOld(symbol, 3, 3) == "nzd" )      
      {
         if (LongSwap > 0) TradeLong = true;
         else TradeLong = false;
         if (ShortSwap > 0) TradeShort = true;
         else TradeShort = false;         
      }//if (StringSubstrOld()      
   }//if (AudPairsPositiveOnly)
   
   //OnlyTradePositiveSwap filter
   if (OnlyTradePositiveSwap)
   {
      if (LongSwap < 0) TradeLong = false;
      if (ShortSwap < 0) TradeShort = false;      
   }//if (OnlyTradePositiveSwap)
   

}//void TradeDirectionBySwap()

bool TooClose(string symbol)
{
   //Returns false if the previously closed trade and the proposed new trade are sufficiently far apart, else return true. Called from IsTradeAllowed().
   
   if (OrdersHistoryTotal() == 0) return(false);
   
   for (int cc = OrdersHistoryTotal() - 1; cc >= 0; cc--)
   {
      if (!BetterOrderSelect(cc, SELECT_BY_POS, MODE_HISTORY) ) continue;
      if (OrderMagicNumber() != MagicNumber) continue;
      if (OrderSymbol() != symbol ) continue;
      if (OrderType() > 1) continue;
      
      
      //Examine the OrderCloseTime to see if it closed far enought back in time.
      if (TimeCurrent() - OrderCloseTime() < (MinMinutesBetweenTrades * 60))
      {
         return(true);//Too close, so disallow the trade
      }//if (OrderCloseTime() - TimeCurrent() < (MinMinutesBetweenTrades * 60))
      break;      
   }//for (int cc = OrdersHistoryTotal() - 1; cc >= 0; cc--)
   
   //Got this far, so there is no disqualifying trade in the history
   return(false);
   
}//bool TooClose()

void RunningSpreadCalculation(string symbol, int PairIndex)
{
   //Keeps a running total of each pair's average spread
 
   //Has there been a new tick since the last OnTimer() event?
   if (!CloseEnough(SpreadArray[PairIndex][previousask], ask) )
   {
      //Yes, so update the counters
      SpreadArray[PairIndex][previousask] = ask;//Store the latest quote
      SpreadArray[PairIndex][spreadtotalsofar]+= spread;//Add the spread to the total of spreads
      if (spread > SpreadArray[PairIndex][biggestspread])
         SpreadArray[PairIndex][biggestspread] = spread;//Reset the biggest spread
      SpreadArray[PairIndex][tickscounted]++;//Update the spread calculation tick counter
      
      //Do we need to update the average spread?
      if (SpreadArray[PairIndex][tickscounted] >= 5)
      {
         SpreadArray[PairIndex][averagespread] = SpreadArray[PairIndex][spreadtotalsofar] / 5;
         SpreadArray[PairIndex][tickscounted] = 0;
         SpreadArray[PairIndex][spreadtotalsofar] = 0;
         SpreadGvName = symbol + " average spread";
         GlobalVariableSet(SpreadGvName, SpreadArray[PairIndex][averagespread]);
      }//if (SpreadArray[PairIndex][tickscounted] >= 5)
      
         
   }//if (!CloseEnough(SpreadArray[PairIndex][previousask]), ask)
   

}//End void RunningSpreadCalculation(int PairIndex)

bool SpreadCheck(int PairIndex)
{
   //Returns 'false' if the check fails, else returns 'true'
   
   //Craptesting
   if (IsTesting() )
      return(true);//Spread is not relevant
   
   if (spread >= (SpreadArray[PairIndex][averagespread] * MultiplierToDetectStopHunt) )
      return(false);
   
   //Got this far, so ok to continue
   return(true);

}//End bool SpreadCheck(int PairIndex)

void LookForIndividualPairBasketClosure(string symbol, int PairIndex)
{

   bool ClosePosition = false;
   
   //Cash upl
   if (UseIndividualPairsBasketCashTarget)
      if (CashUpl[PairIndex] >= IndividualPairsBasketCashTarget)
      {
         ClosePosition = true;
      }//if (CashUpl >= IndividualPairsBasketCashTarget)

   //Pips upl
   if (UseIndividualPairsBasketPipsTarget)
      if (PipsUpl[PairIndex] >= IndividualPairsBasketPipsTarget)
      {
         ClosePosition = true;
      }//if (PipsUpl >= IndividualPairsBasketPipsTarget)


   if (ClosePosition)   
   {
      Alert(symbol, " Candle Power has hit its individual pair's basket take profit. All trades should have closed.");
      CloseAllTrades(symbol, AllTrades);
      if (ForceTradeClosure)
      {
         CloseAllTrades(symbol, AllTrades);
         if (ForceTradeClosure)
         {
            CloseAllTrades(symbol, AllTrades);
         }//if (ForceTradeClosure)                     
         if (ForceTradeClosure)
         {
            return;
         }//if (ForceTradeClosure)                     
      }//if (ForceTradeClosure)  

   }//if (ClosePosition)   
   
   //Got this far, so all the trades have been closed/deleted. Clear all the variables.
   CountOpenTrades(symbol, PairIndex);


}//End void LookForIndividualPairBasketClosure(string symbol, int PairIndex)

bool LookForEntirePositionClosure()
{
   //This function treats all trades belonging to the EA as a basket and
   //looks for an opportunity to close all at a designated profit target.
   
   bool ClosePosition = false;
   
   //Cash upl
   if (UseWholePositionBasketCashTarget)
      if (WholePositionCashUpl >= WholePositionBasketCashTarget)
      {
         ClosePosition = true;
      }//if (WholePositionCashUpl >= WholePositionBasketCashTarget)

   //Pips upl
   if (UseWholePositionBasketPipsTarget)
      if (WholePositionPipsUpl >= WholePositionBasketPipsTarget)
      {
         ClosePosition = true;
      }//if (WholePositionPipsUpl >= WholePositionBasketPipsTarget)


   if (ClosePosition)   
   {
      Alert("Candle Power has hit its whole position basket take profit. All trades should have closed.");
      CloseAllTrades(AllSymbols, AllTrades);
      if (WholePositionForceTradeClosure)
      {
         CloseAllTrades(AllSymbols, AllTrades);
         if (WholePositionForceTradeClosure)
         {
            CloseAllTrades(AllSymbols, AllTrades);
         }//if (ForceTradeClosure)                     
                             
      }//if (ForceTradeClosure)  
      return(true);
   }//if (ClosePosition)   
     
   
   
   //Got this far, so no closure
   return(false);

}//End bool LookForEntirePositionClosure()

//This code by tomele. Thank you Thomas. Wonderful stuff.
bool AreWeAtRollover()
{

   double time;
   int hours,minutes,rstart,rend,ltime;
   
   time=StrToDouble(RollOverStarts);
   hours=(int)MathFloor(time);
   minutes=(int)MathRound((time-hours)*100);
   rstart=60*hours+minutes;
      
   time=StrToDouble(RollOverEnds);
   hours=(int)MathFloor(time);
   minutes=(int)MathRound((time-hours)*100);
   rend=60*hours+minutes;
   
   ltime=TimeHour(TimeCurrent())*60+TimeMinute(TimeCurrent());

   if (rend>rstart)
     if(ltime>rstart && ltime<rend)
       return(true);
   if (rend<rstart) //Over midnight
     if(ltime>rstart || ltime<rend)
       return(true);

   //Got here, so not at rollover
   return(false);

}//End bool AreWeAtRollover()


void AutoTrading()
{
   //Think of this being the equivalent to OnTimer() in a multi-pair
   //EA without the dashboard element.
  
   for (int PairIndex = 0; PairIndex < ArraySize(TradePair); PairIndex++)
   {
      string symbol = TradePair[PairIndex];
      GetBasics(symbol);
      
      //In case any order close/delete failed
      if (ForceTradeClosure)
      {
         CloseAllTrades(symbol, AllTrades);
         if (ForceTradeClosure)
         {
            CloseAllTrades(symbol, AllTrades);
            if (ForceTradeClosure)
               PairIndex--;
         }//if (ForceTradeClosure)
         continue;
      }//if (ForceTradeClosure)
      
      //In case any global order close/delete failed
      if (WholePositionForceTradeClosure)
      {
         CloseAllTrades(AllSymbols, AllTrades);
         if (WholePositionForceTradeClosure)
         {
            CloseAllTrades(AllSymbols, AllTrades);
            return;//Start again at the next event timer interval
         }//if (WholePositionForceTradeClosure)
      }//if (WholePositionForceTradeClosure)

      //Rollover
      if (DisableEaDuringRollover)
      {
         RolloverInProgress = false;
         if (AreWeAtRollover())
         {
            RolloverInProgress = true;
            return;
         }//if (AreWeAtRollover)
      }//if (DisableEaDuringRollover)
         
        
      //Average spread
      RunningSpreadCalculation(symbol, PairIndex);
      //Is spread ok to allow accions on this pair
      if (!SpreadCheck(PairIndex) )
         continue;

      CountOpenTrades(symbol, PairIndex);

      //Trading the individual pair as a basket
      if (TradeIndividualPairsAsBasket)
      {
         LookForIndividualPairBasketClosure(symbol, PairIndex);
         //In case any order close/detele failed
         if (ForceTradeClosure)
         {
            CloseAllTrades(symbol, AllTrades);
            if (ForceTradeClosure)
            {
               CloseAllTrades(symbol, AllTrades);
               if (ForceTradeClosure)
                  PairIndex--;
            }//if (ForceTradeClosure)
            continue;
         }//if (ForceTradeClosure)
      }//if (TradeIndividualPairsAsBasket)
      
      //Treating every trade belonging to the EA as a basket
      if (TradeWholePositionAsBasket)
      {
         if (LookForEntirePositionClosure() )
            return;//Start again at the next event timer interval
      }//if (TradeWholePositionAsBasket)
      

      //Possible shut down for the weekend
      if (OpenTrades > 0)
      {
         ShutDownForTheWeekend(PairIndex);
         if (ForceTradeClosure)
         {
            CloseAllTrades(AllSymbols, AllTrades);
            return;
         }//if (ForceTradeClosure)

      //Offsetting in a balanced position
      if (!Unbalanced)
         if (UseOffsetting)
         {
            ShouldTradesBeClosed(symbol, PairIndex, MinOpenTradesToStartOffset);
            //In case any trade closures failed
            if (ArraySize(ForceCloseTickets) > 0)
            {
               MopUpTradeClosureFailures();
               return;
            }//if (ArraySize(ForceCloseTickets) > 0)        
         }//if (UseOffsetting)
      
      
      //Unbalanced positions
      if (Unbalanced)
      {
         //Offsetting in Recovery
         if (UseOffsettingForBalanceRecovery)
         {
            //Save the user inputs
            bool OldAllowComplex = AllowComplexSingleSidedOffsets;//Save the user input
            AllowComplexSingleSidedOffsets = AllowComplexSingleSidedOffsetsRecovery;
            int OldMinTrades = MinOpenTradesToStartOffset;
            MinOpenTradesToStartOffset = MinTradesToStartUnbalancedOffset;
            CanTradesBeOffset(symbol, PairIndex, 0);
            //Restore the user's inputs
            AllowComplexSingleSidedOffsets = OldAllowComplex;
            MinTradesToStartUnbalancedOffset = OldMinTrades;
            //In case any trade closures failed
            if (ArraySize(ForceCloseTickets) > 0)
            {
               MopUpTradeClosureFailures();
               return;
            }//if (ArraySize(ForceCloseTickets) > 0)        
         }//if (UseOffsettingForBalanceRecovery)
      
         //User's choice of 'nuclear options' when a position becomes unbalanced.
         NuclearOptions(symbol, PairIndex);
         if(ForceTradeClosure)
         {
            CloseAllTrades(AllSymbols, AllTrades);
            if (ForceTradeClosure)
               return;
         }//if (ForceTradeClosure) 
      }//if (Unbalanced)
         
   }//if (OpenTrades > 0)
      
      if (Hedged || Unbalanced)
         LookForHedgedBasketClosure(symbol, PairIndex);
         
      if (ForceTradeClosure)
      {
         CloseAllTrades(symbol, AllTrades);
         if (ForceTradeClosure)
         {
            CloseAllTrades(symbol, AllTrades);
            if (ForceTradeClosure)
            {
               return;
            }//if (ForceTradeClosure)                     
         }//if (ForceTradeClosure)         
      }//if (ForceTradeClosure)      
      
      if (CandleOpenTime[PairIndex] == iTime(symbol, TradingTimeFrame, 0) )
         continue;
         
      CandleOpenTime[PairIndex] = iTime(symbol, TradingTimeFrame, 0);

      //Outstanding stop orders from the previous candle need deleting.
      bool result;
      if(BuyStopOpen)
      {
         if (BetterOrderSelect(BuyStopTicketNo, SELECT_BY_TICKET, MODE_TRADES) && OrderType() > 1)
         {
            result = OrderDelete(OrderTicket());
            if (result)
            {
               OpenTrades--;
               BuyStopOpen = 0;
            }//if (result)
            
            if (!result)
            {
               CandleOpenTime[PairIndex] =  0;//Force a retry at the next tick.
               continue;//Await the next tick.
            }//if (!result)            
         }//if (BetterOrderSelect(BuyStopTicketNo, SELECT_BY_TICKET, MODE_TRADES))         
      }//if(BuyStopOpen)
      
      if(SellStopOpen)
      {
         if (BetterOrderSelect(SellStopTicketNo, SELECT_BY_TICKET, MODE_TRADES) && OrderType() > 1)
         {
            result = OrderDelete(OrderTicket());
            if (result)
            {
               OpenTrades--;
               SellStopOpen = 0;
            }//if (result)

            if (!result)
            {
               CandleOpenTime[PairIndex] = 0;//Force a retry at the next tick.
               continue;//Await the next tick.
            }//if (!result)            
         }//if (BetterOrderSelect(SellStopTicketNo, SELECT_BY_TICKET, MODE_TRADES))         
      }//if(SellStopOpen)

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
   
      //Check that there is sufficient margin for trading
      if(!MarginCheck())
      {
         DisplayUserFeedback();
         return;
      }//if (!MarginCheck() )
            
         if (TimeCurrent() >= TimeToStartTrading[PairIndex])
            if (!StopTrading)              
            {
               TimeToStartTrading[PairIndex] = 0;//Set to TimeCurrent() + (PostTradeAttemptWaitMinutes * 60) when there is an OrderSend() attempt)
               if (!LookForTradingOpportunities(symbol, PairIndex) )
                  CandleOpenTime[PairIndex] = 0;//Something went wrong, so force a retry next time around
            }//if (!StopTrading)

         
         
   
   }//for (int PairIndex = 0; PairIndex < ArraySize(TradePair); PairIndex++)
   



//LookForTradingOpportunities(symbol, PairIndex);
     


}//void AutoTrading()



//+------------------------------------------------------------------+
//| Timer function                                                   |
//+------------------------------------------------------------------+
void OnTimer()
{
//---

   if (RemoveExpert)
   {
      ExpertRemove();
      return;
   }//if (RemoveExpert)
   
   //mptm sets a Global Variable when it is closing the trades.
   //This tells this ea not to send any fresh trades.
   if (GlobalVariableCheck(GvName))
      return;
   //'Close all trades this pair only script' sets a GV to tell EA's not to attempt a trade during closure
   if (GlobalVariableCheck(LocalGvName))
      return;
   //'Nuclear option script' sets a GV to tell EA's not to attempt a trade during closure
   if (GlobalVariableCheck(NuclearGvName))
      return;

   if (!IsTradeAllowed() )
   {
      Comment("                          THIS EXPERT HAS LIVE TRADING DISABLED");
      return;
   }//if (!IsTradeAllowed() )
   
   
   TimerCount++;
   if (TimerCount>=ChartCloseTimerMultiple)//Now we have a chart closing cycle
      TimerCount=0;

   //ReadIndicatorValues() also contains the call to LookForTradingOpportunities(),
   //right at the end of the function.
   ReadIndicatorValues();
   
   if (MinimiseChartsAfterOpening)
      ShrinkCharts();
   
   //Using the EA to trade
   if (AutoTradingEnabled)
      AutoTrading();
   
   DisplayUserFeedback();
   
}
//+------------------------------------------------------------------+
