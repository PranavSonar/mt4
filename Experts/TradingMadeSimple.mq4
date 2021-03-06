//+------------------------------------------------------------------+
//|                                                  ChaosTheory.mq4 |
//|                                                             monk |
//|                                https://www.stevehopwoodforex.com |
//+------------------------------------------------------------------+
#property copyright "Steve Hopwood"
#property link      "https://www.stevehopwoodforex.com"
#property strict
#include <stdlib.mqh>

#define  version "Version 1a"

/*
Based on Awesome Bells and Whistles, which was created by TraderJoForex, zaguy, Thomas and Steve
Thanks to all

CHANGELOG
23-11-2017
added. new signal TMS. Based on Trading Made Simple thread on FF by eelfranz
added. takeprofit and stoploss based on Average Range
code clean up and fixes

21-11-2017
added. new signal Chaos. Based on New Trading Dimensions:
How to Profit from Chaos in Stocks, Bonds, and Commodities by B. Williams
added. ProfitToday on the chart
added. Alerts on CloseonOpposite signal and News
added. All types of Basket tp on display
added. Basket tp Dollop Multiplier
added. Candlepower dashboard style display (arrows and tags)
added. TradeCommentPrefix
added. pushalert and email stuff
*/

//Using hgi_lib
#import "hgi_lib.ex4"
   enum SIGNAL {NONE=0,TRENDUP=1,TRENDDN=2,RANGEUP=3,RANGEDN=4,RADUP=5,RADDN=6};
   enum SLOPE {UNDEFINED=0,RANGEABOVE=1,RANGEBELOW=2,TRENDABOVE=3,TRENDBELOW=4};
   SIGNAL getHGISignal(string symbol,int timeframe,int shift);
   SLOPE getHGISlope (string symbol,int timeframe,int shift);
#import

#define  NL    "\n"

#define  AllTrades 10 //Tells CloseAllTrades() to close/delete everything
#define  million 1000000;

//Trade Status
#define  notrading "No Trades Allowed"
#define  bothdirection "Trading Long or Short"

//MinDistance
#define  untradable "Too near"
#define  tradable "Tradable"
//Peaky
#define  peakylongdirection "Long"
#define  peakyshortdirection "Short"
#define  peakynodirection "None"
#define  otfpeakylongdirection "Long"
#define  otfpeakyshortdirection "Short"
#define  otfpeakynodirection "None"
//SuperSlope colours
#define  red "Red"
#define  blue "Blue"
#define  white "White"
#define  otfred "Red"
#define  otfblue "Blue"
#define  otfwhite "White"
//Flying Buddha
#define  fbnoarrow "No signal"
#define  fbuparrow "Up arrow"
#define  fbdownarrow "Dn arrow"
#define  otffbnoarrow "No signal"
#define  otffbuparrow "Up arrow"
#define  otffbdownarrow "Dn arrow"
//Ma
#define  manotrend  "No trend"
#define  maUp "Up trend"
#define  maDown "Dn trend"
#define  otfmanotrend  "No trend"
#define  otfmaUp "Up trend"
#define  otfmaDown "Dn trend"
//HGI
#define  hginoarrow "No signal"
#define  hgiuparrow "Up arrow"
#define  hgidownarrow "Dn arrow"
#define  hgiupwave "Up wave"
#define  hgidownwave "Dn wave"
#define  hgiupradarrow "Up rad ar"
#define  hgidownradarrow "Dn rad ar"
#define  otfhginoarrow "No signal"
#define  otfhgiuparrow "Up arrow"
#define  otfhgidownarrow "Dn arrow"
#define  otfhgiupwave "Up wave"
#define  otfhgidownwave "Dn wave"
#define  otfhgiupradarrow "Up rad ar"
#define  otfhgidownradarrow "Dn rad ar"
//Trend
#define  notrend  "No trend"
#define  up "Up trend"
#define  down "Dn trend"
#define  otfnotrend  "No trend"
#define  otfup "Up trend"
#define  otfdown "Dn trend"
//OTFRangingDirection
#define  otfnodirection "Range"
#define  otfbothdirection "Trend"
//NewsFilter
#define  nonews "Tradable"
#define  yesnews "News"
//Chaos
#define  chaosno "No signal"
#define  chaosup "Up arrow"
#define  chaosdn "Dn arrow"
#define  otfchaosno "No signal"
#define  otfchaosup "Up arrow"
#define  otfchaosdn "Dn arrow"
//TMS
#define  tmsno "No signal"
#define  tmsup "Up arrow"
#define  tmsdn "Dn arrow"
#define  otftmsno "No signal"
#define  otftmsup "Up arrow"
#define  otftmsdn "Dn arrow"


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


extern string  gen="---- General Inputs ----";
extern string  PairsToTrade   = "AUDCAD,AUDCHF,AUDNZD,AUDJPY,AUDUSD,CADCHF,CADJPY,CHFJPY,EURAUD,EURCAD,EURGBP,EURNZD,EURJPY,EURUSD,GBPJPY,GBPUSD,NZDUSD,NZDJPY,USDCAD,USDCHF,USDJPY";
extern int     EventTimerIntervalSeconds=5;
//UsePriceChecks: check tp, sl, open price. Added by Gary. Cheers Gary.
extern bool    UsePriceChecks=true;
extern bool    PrintFailedChecks=false;
//For victims of the US mis-government.
extern bool    BrokerAllowsHedging=true;
//Minimum margin for trading
extern int     MinimumMarginPercent=1400;
//So US members can control the trading direction.
extern bool    TradeLong=true;
extern bool    TradeShort=true;
//Maximum no of pairs the user will allow to be trading at any one time
extern int     MaxPairsAllowed=30;
//Safety adapted from my shells
extern int     PostTradeAttemptWaitSeconds=30;
extern int     MinTradeDistanceAcrossTimeframesPips=10;
extern string  TradeCommentPrefix="ChaosTheory";
////////////////////////////////////////////////////////////////////////////////
int            TradingTimeCounter=0;
string         InputString="";//Holds the contents PairsToTrade for tidying yp etc
int            NoOfPairs=0;// Holds the number of pairs passed by the user via the inputs screen
string         TradePair[]; //Array to hold the pairs traded by the user
double         ask=0, bid=0, spread=0;//Replaces Ask. Bid, Digits. factor replaces Point
int            digits=0;//Replaces Digits.
double         longSwap=0, shortSwap=0;
//Calculating the factor needed to turn pip values into their correct points value to accommodate different Digit size.
//Thanks to Tommaso for coding the function.
double         factor=0;//For pips/points stuff.
//For FIFO
int            FifoTicket[];//Array to store trade ticket numbers in FIFO mode, to cater for
                            //US citizens and to make iterating through the trade closure loop 
                            //quicker.
bool           EnoughMargin=false;
string         MarginMessage="";                            
bool           ForceTradeClosure=false;
//An array to hold the symbols of the pairs with open trades.
string         PairsWithOpenTrades[];
//Open pairs counter
int            TradingPairs=0;
//Buy and sell open/close signal
bool           BuySignal=false, SellSignal=false, BuyCloseSignal=false, SellCloseSignal=false;
//Missing indi check
bool           RemoveExpert=false;
//Avoid duplicate trading
bool           AlreadyTradedThisPrice=false;
string         Tradeability[][4];

double         ProfitToday=0;

////////////////////////////////////////////////////////////////////////////////


extern string  sep1="================================================================";
extern string  pek="---- Peak HiLo inputs ----";
extern bool    UsePeakyOnTradingTimeFrame=false;
extern bool    UsePeakyOnOwnTimeFrame=false;
extern ENUM_TIMEFRAMES OwnPeakyTimeFrame=PERIOD_M30;
//No of bars to calculate the peak hilo 1682 max
extern int     NoOfBars=1682;
////////////////////////////////////////////////////////////////////////////////
//Market direction.
string         PeakyMarketDirection[][4];//The Overall market direction constants are defined at the top of this code.
string         OTFPeakyMarketDirection[];
////////////////////////////////////////////////////////////////////////////////


extern string  sep2="================================================================";
extern string  ssi="---- SuperSlope inputs ----";
extern bool    UseSuperSlopeOnTradingTimeFrame=false;
extern bool    UseSuperSlopeOnOwnTimeFrame=false;
extern ENUM_TIMEFRAMES OwnSuperSlopeTimeFrame=PERIOD_D1;
extern double  SsTradingDifferenceThreshold  = 1.0;
extern double  SsTradingLevelCrossValue      = 2.0;
extern int     SsTradingSlopeMAPeriod        = 7; 
extern int     SsTradingSlopeATRPeriod       = 50; 
////////////////////////////////////////////////////////////////////////////////////////
//I added HTF as an afterthought, so these variables are for TradingTimeFrame
double         SsTtfCurr1Val=0, SsTtfCurr2Val=0;
string         SsColour[][4];
string         OTFSsColour[];
bool           BrokerHasSundayCandles;
bool           LongTradeTrigger=false, ShortTradeTrigger=false;//Set to true when there is a signal on the TradingTimeFrame
////////////////////////////////////////////////////////////////////////////////////////


sinput string  sep3="================================================================";
sinput string  fbi="---- Flying Buddha inputs ----";
extern bool    UseFBOnTradingTimeFrame=false;
extern bool    UseFBOnOwnTimeFrame=false;
extern ENUM_TIMEFRAMES OwnFBTimeFrame=PERIOD_M5;
sinput int     FbFastPeriod=5;
sinput int     FbFastAvgMode=1;
sinput int     FbFastPrice=0;
sinput int     FbSlowPeriod=7;
sinput int     FbSlowAvgMode=1;
sinput int     FbSlowPrice=0;
sinput int     FbMaxBars=2000;
sinput double  FbFactorWindow=0.03;
string         FbStatus[][4];//Constants defined at top of file//Amended FB code
string         OTFFbStatus[];//Constants defined at top of file//Amended FB code
////////////////////////////////////////////////////////////////////////////////////////


sinput string  sepx1="================================================================";
sinput string  chi="---- Chaos inputs ----";
extern bool    UseChaosOnTradingTimeFrame=true;
extern bool    UseChaosOnOwnTimeFrame=false;
extern ENUM_TIMEFRAMES OwnChaosTimeFrame=PERIOD_M5;
extern bool    ShowChaosDimensions=false;
extern int     JawPeriod = 13;
extern int     JawShift = 8;
extern int     TeethPeriod = 8;
extern int     TeethShift = 5;
extern int     LipsPeriod = 5;
extern int     LipsShift = 3;
extern int     AlligatorMethod = 2;
extern int     AlligatorPrice = 4;
double upfractal, dwfractal;
string ChaosStatus[][4], ChaosD1[][4], ChaosD2[][4], ChaosD3[][4], ChaosD4[][4], ChaosD5[][4];
string OTFChaosStatus[], OTFChaosD1[], OTFChaosD2[], OTFChaosD3[], OTFChaosD4[], OTFChaosD5[];
////////////////////////////////////////////////////////////////////////////////////////


sinput string  septms="================================================================";
sinput string  tms="---- TMS inputs ----";
extern bool    UseTMSOnTradingTimeFrame=false;
extern bool    UseTMSOnOwnTimeFrame=false;
extern ENUM_TIMEFRAMES OwnTMSTimeFrame=PERIOD_H1;
extern bool    ShowTMSDimensions=true;
extern int     StochHigh=75;
extern int     StochLow=25;
extern int     TDiHigh=60;
extern int     TDiLow=40;
double TdiGreen, PrevTdiGreen, TdiRed, SmaVal, AskVal, BidVal, StochVal, PrevStochVal;
string TmsStatus[][4], TmsD1[][4], TmsD2[][4], TmsD3[][4], TmsD4[][4], TmsD5[][4], TmsD6[][4];
string OTFTmsStatus[], OTFTmsD1[], OTFTmsD2[], OTFTmsD3[], OTFTmsD4[], OTFTmsD5[], OTFTmsD6[];
////////////////////////////////////////////////////////////////////////////////////////
//Min distance between trades thingy
double         DistanceBetweenTrades=0;
////////////////////////////////////////////////////////////////////////////////////////


extern string  chs3="================================================================";
extern string  hgic="======== HGI inputs ========";
extern bool    UseHGIOnTradingTimeFrame=false;
extern bool    UseHGIOnOwnTimeFrame=false;
extern ENUM_TIMEFRAMES OwnHGITimeFrame=PERIOD_M5;
extern int     OwnHGITimeFrameCandlesLookBack=0;
//HGI trades on large arrows, smaller rad arrows and blue waves
extern bool    TrendTradingAllowed=false;
extern bool    BlueWaveTradingAllowed=false;
extern bool    RadTradingAllowed=false;

//HGI candles lookback on own Timeframe
////////////////////////////////////////////////////////////////////////////////////////
double         val = 0;
string         HgiStatus[][4];//Constants defined at top of file//Amended HGI code
string         OTFHgiStatus[];//Constants defined at top of file//Amended HGI code

////////////////////////////////////////////////////////////////////////////////////////


extern string  chs6="================================================================";
extern string  trend="---- Moving Average inputs ----";
extern bool    UseMaOnTradingTimeFrame=false;
extern bool    UseMaOnOwnTimeFrame=false;
extern ENUM_TIMEFRAMES OwnMaTimeFrame=PERIOD_M15;
extern int     MaTrendPeriodLow=3;
extern int     MaTrendPeriodHigh=14;
////////////////////////////////////////////////////////////////////////////////////////
double         MaVal1, MaVal2;
string         MaTrend[][4];
string         OTFMaTrend[];
////////////////////////////////////////////////////////////////////////////////////////

//Ranging Filter
extern string  RanFil1="================================================================";
extern string  RanFil2="---- Ranging Filter Inputs ----";
extern bool    UseRangingFilter=false;
extern ENUM_TIMEFRAMES  RangingTimeFrame=PERIOD_M5;
extern int     CandleRange=10;
extern int     RangeNoTradePips=14;
////////////////////////////////////////////////////////////////////////////////////////
string         OTFRangingDirection[];//Constants defined above
int            HighestHigh=0, LowestLow=0;
double         HighestHighValue=0, LowestLowValue=0;
////////////////////////////////////////////////////////////////////////////////////////
//News Filter
extern string  NewsFil1="================================================================";
extern string  NewsFil2="---- News Filter Inputs ----";
extern bool    UseNewsFilter=true;
//input string   CurrenciesToClose            = "";         // Comma-separated list of currencies to watch/close. Leave blank for all.
input bool     FilterOnHighImpactNews       = true;
input bool     FilterOnMediumImpactNews     = true;
input bool     FilterOnLowImpactNews        = false;
input int      StopTradingSecondsBeforeHighImpact   = 60;
input int      StopTradingSecondsBeforeMediumImpact = 60;
input int      StopTradingSecondsBeforeLowImpact    = 30;
//input string   NewsFilterex                   = "";         // Additional filter to target specific news. Leave blank for all.
input bool     CloseOnNews                  = false;
input bool     CloseOnHighImpactNews        = true;
input bool     CloseOnMediumImpactNews      = true;
input bool     CloseOnLowImpactNews         = false;
input int      CloseSecondsBeforeNews       = 60;
//input int      BrokerGMTOffSet              = 2;          // Broker time GMT OffSet in hours

string         NewsStatus[];
string         NewsFilter[];
string         newsarray[];
////////////////////////////////////////////////////////////////////////////////////////

//Spread filter
extern string  sep14="================================================================";
extern string  asi="---- Average spread inputs ----";
extern double  MultiplierToDetectStopHunt=3;
////////////////////////////////////////////////////////////////////////////////////////
string         SpreadGvName;//A GV will hold the calculated average spread
////////////////////////////////////////////////////////////////////////////////////////

extern string  s2="================================================================";
extern string  tfs="---- Trading Time Frames ----";
//Give the user 4 time frames to use.
extern string  tf1="-- Time Frame 1 --";
extern bool    TradeTF1=true;
extern ENUM_TIMEFRAMES Trade1TimeFrame=PERIOD_M1;
//Offer the option of an immediate market trade.
extern bool    Trade1ImmediateMarketOrder=true;
//The trading line buffer for the stop order.
extern int     Trade1BufferPips=10;
// when the signal changes while the stop order is not yet activated, close the stop order
extern bool    Trade1CloseStopOrderOnOppositePK=true;
extern bool    Trade1CloseStopOrderOnOppositeSS=true;
//This EA uses separate magic numbers for each time frame to recognise which tf the trade belongs to.
extern int     Trade1MagicNumber=100;
//It uses separate trade comments so the user can easily identify the trade's origin.
extern string  Trade1TradeComment="M1";
//We need individual take profit and stop loss for each time frame.
//A 'hard' tp
extern int     Trade1TakeProfitPips=0;
extern bool    Trade1UseAverageRangeTakeProfit=false;
extern ENUM_TIMEFRAMES Trade1AverageRangeTakeProfitTimeFrame=PERIOD_D1;
extern int     Trade1AverageRangeTakeProfitPeriod=24;
extern int     Trade1AverageRangeTakeProfitPipsShift=-2;
//A 'hard' sl
extern int     Trade1StopLossPips=0;
extern bool    Trade1UseAverageRangeStopLoss=false;
extern ENUM_TIMEFRAMES Trade1AverageRangeStopLossTimeFrame=PERIOD_D1;
extern int     Trade1AverageRangeStopLossPeriod=24;
extern int     Trade1AverageRangeStopLossPipsShift=2;
//Positive swap filter
extern bool    Trade1PositiveSwapTradesOnly=false;
extern string  lts1="-- Lot sizing --";
//'Hard' lot size.
extern double  Trade1Lot=0;
//Dynamic lot sizing
//Over rides Trade1Lot. Zero input to cancel.
extern double  Trade1LotsPerDollopOfCash=0.01;
extern double  Trade1SizeOfDollop=2000;
extern bool    Trade1UseBalance=false;
extern bool    Trade1UseEquity=true;
//Take every trade signal
sinput string  tri1="-- Take every signal inputs --";
sinput bool    Trade1TradeEverySignal=true;
//Up to this maximum
sinput int     Trade1MaxSignalsToFollow=5;
//With this distance between signals.
sinput int     Trade1MinTradeDistanceSingleTimeframePips=10;
//Use atr to calculate the minimum distance
sinput bool    Trade1UsePercentageOfAtrForDistance=false;
//over this period
sinput int     Trade1AtrPeriod=24;                     
//at this percentage.
sinput int     Trade1PercentageOfAtrToUse=100;         
sinput string  trcl="-- Trade closure inputs --";
//Close buys following a down arrow and sells at an up arrow
sinput bool    Trade1CloseOnOppositeFB=false;
sinput bool    Trade1CloseOnOppositeHGI=false;            
sinput bool    Trade1CloseOnOppositeMA=false;            
sinput bool    Trade1CloseOnOppositeChaos=true;
sinput bool    Trade1CloseOnOppositeTMS=false;
sinput bool    Trade1OnlyCloseWhenSuperSlopeAgrees=true;
sinput bool    Trade1OnlyCloseWhenPeakyAgrees=false; 
sinput bool    Trade1OnlyCloseWhenBothSuperSlopeAndPeakyAgrees=false;

/*
Recovery is where gap filling stop orders have filled. Take profit could be a long way away, so best 
to get out of the position at a reasonable profit.
*/
extern string  rec1="---- Recovery ----";
extern bool    Trade1UseRecovery=true;
extern int     Trade1TradesToConstituteRecovery=4;
extern int     Trade1RecoveryProfitPips=1;
extern int     Trade1RecoveryProfitCash=0;
extern string  tb1="---- Trade1 basket trading ----";
extern bool    Trade1AsBasket=true;
extern double  Trade1BasketCashTarget=1.00;
extern double  Trade1BasketCashPercentageTarget=0;
extern bool    Trade1BasketCashUseDollopMultiplier=true;
double         Trade1BasketProfitTarget;
//Individual trade management features
extern string  Trade1Itm="---- Individual trade management ----";
extern string  Trade1BE = "-- Break even --";
//Use Break Even.
extern bool    Trade1UseBreakEven=false;
//Pips to break even.
extern int     Trade1BreakEvenPips=50;
//Pips profit to lock in.
extern int     Trade1BreakEvenProfitPips=10;
extern string  Trade1JSL="-- Jumping stop loss --";
//Use a jumping stop loss.
extern bool    Trade1UseJumpingStop=false;
//Jump in this pips increment.
extern int     Trade1JumpingStopPips=30;
//Only jump after break even has been achieved.
extern bool    Trade1JumpAfterBreakevenOnly=true;

extern string  tf2="-- Time Frame 2 --";
extern bool    TradeTF2=true;
extern ENUM_TIMEFRAMES Trade2TimeFrame=PERIOD_M5;
extern bool    Trade2ImmediateMarketOrder=true;
//The trading line buffer for the stop order.
extern int     Trade2BufferPips=10;
// when the signal changes while the stop order is not yet activated, close the stop order
extern bool    Trade2CloseStopOrderOnOppositePK=true;
extern bool    Trade2CloseStopOrderOnOppositeSS=true;
//This EA uses separate magic numbers for each time frame to recognise which tf the trade belongs to.
extern int     Trade2MagicNumber=101;
//It uses separate trade comments so the user can easily identify the trade's origin.
extern string  Trade2TradeComment="M5";
//We need individual take profit and stop loss for each time frame.
//A 'hard' tp
extern int     Trade2TakeProfitPips=0;
extern bool    Trade2UseAverageRangeTakeProfit=false;
extern ENUM_TIMEFRAMES Trade2AverageRangeTakeProfitTimeFrame=PERIOD_D1;
extern int     Trade2AverageRangeTakeProfitPeriod=24;
extern int     Trade2AverageRangeTakeProfitPipsShift=-2;
//A 'hard' sl
extern int     Trade2StopLossPips=0;
extern bool    Trade2UseAverageRangeStopLoss=false;
extern ENUM_TIMEFRAMES Trade2AverageRangeStopLossTimeFrame=PERIOD_D1;
extern int     Trade2AverageRangeStopLossPeriod=24;
extern int     Trade2AverageRangeStopLossPipsShift=2;
//Positive swap filter
extern bool    Trade2PositiveSwapTradesOnly=false;
extern string  lts2="-- Lot sizing --";
//'Hard' lot size.
extern double  Trade2Lot=0;
//Dynamic lot sizing
//Over rides Trade2Lot. Zero input to cancel.
extern double  Trade2LotsPerDollopOfCash=0.01;
extern double  Trade2SizeOfDollop=2000;
extern bool    Trade2UseBalance=false;
extern bool    Trade2UseEquity=true;
//Take every trade signal
sinput string  tri2="-- Take every signal inputs --";
sinput bool    Trade2TradeEverySignal=true;
//Up to this maximum
sinput int     Trade2MaxSignalsToFollow=6;
//With this distance between signals.
sinput int     Trade2MinTradeDistanceSingleTimeframePips=12;
//Use atr to calculate the minimum distance
sinput bool    Trade2UsePercentageOfAtrForDistance=false;
//over this period
sinput int     Trade2AtrPeriod=24;                     
//at this percentage.
sinput int     Trade2PercentageOfAtrToUse=120;         
sinput string  trc2="-- Trade closure inputs --";
//Close buys following a down arrow and sells at an up arrow
sinput bool    Trade2CloseOnOppositeFB=false;            
sinput bool    Trade2CloseOnOppositeHGI=false; 
sinput bool    Trade2CloseOnOppositeMA=false;   
sinput bool    Trade2CloseOnOppositeChaos=true;
sinput bool    Trade2CloseOnOppositeTMS=false;
sinput bool    Trade2OnlyCloseWhenSuperSlopeAgrees=true; 
sinput bool    Trade2OnlyCloseWhenPeakyAgrees=false; 
sinput bool    Trade2OnlyCloseWhenBothSuperSlopeAndPeakyAgrees=false;
extern string  rec2="---- Recovery ----";
extern bool    Trade2UseRecovery=true;
extern int     Trade2TradesToConstituteRecovery=4;
extern int     Trade2RecoveryProfitPips=1;
extern int     Trade2RecoveryProfitCash=0;
extern string  tb2="---- Trade2 basket trading ----";
extern bool    Trade2AsBasket=true;
extern double  Trade2BasketCashTarget=1.00;
extern double  Trade2BasketCashPercentageTarget=0;
extern bool    Trade2BasketCashUseDollopMultiplier=true;
double         Trade2BasketProfitTarget;
//Individual trade management features
extern string  Trade2Itm="---- Individual trade management ----";
extern string  Trade2BE = "-- Break even --";
extern bool    Trade2UseBreakEven=false;
extern int     Trade2BreakEvenPips=50;
extern int     Trade2BreakEvenProfitPips=10;
extern string  Trade2JSL="-- Jumping stop loss --";
extern bool    Trade2UseJumpingStop=false;
extern int     Trade2JumpingStopPips=30;
extern bool    Trade2JumpAfterBreakevenOnly=true;

extern string  tf3="-- Time Frame 3 --";
extern bool    TradeTF3=true;
extern ENUM_TIMEFRAMES Trade3TimeFrame=PERIOD_M15;
extern bool    Trade3ImmediateMarketOrder=true;
//The trading line buffer for the stop order.
extern int     Trade3BufferPips=10;
// when the signal changes while the stop order is not yet activated, close the stop order
extern bool    Trade3CloseStopOrderOnOppositePK=true;
extern bool    Trade3CloseStopOrderOnOppositeSS=true;
//This EA uses separate magic numbers for each time frame to recognise which tf the trade belongs to.
extern int     Trade3MagicNumber=102;
//It uses separate trade comments so the user can easily identify the trade's origin.
extern string  Trade3TradeComment="M15";
//We need individual take profit and stop loss for each time frame.
//A 'hard' tp
extern int     Trade3TakeProfitPips=0;
extern bool    Trade3UseAverageRangeTakeProfit=false;
extern ENUM_TIMEFRAMES Trade3AverageRangeTakeProfitTimeFrame=PERIOD_D1;
extern int     Trade3AverageRangeTakeProfitPeriod=24;
extern int     Trade3AverageRangeTakeProfitPipsShift=-2;
//A 'hard' sl
extern int     Trade3StopLossPips=0;
extern bool    Trade3UseAverageRangeStopLoss=false;
extern ENUM_TIMEFRAMES Trade3AverageRangeStopLossTimeFrame=PERIOD_D1;
extern int     Trade3AverageRangeStopLossPeriod=24;
extern int     Trade3AverageRangeStopLossPipsShift=2;
//Positive swap filter
extern bool    Trade3PositiveSwapTradesOnly=false;
extern string  lts3="-- Lot sizing --";
//'Hard' lot size.
extern double  Trade3Lot=0;
//Dynamic lot sizing
//Over rides Trade3Lot. Zero input to cancel.
extern double  Trade3LotsPerDollopOfCash=0.01;
extern double  Trade3SizeOfDollop=2000;
extern bool    Trade3UseBalance=false;
extern bool    Trade3UseEquity=true;
//Take every trade signal
sinput string  tri3="-- Take every signal inputs --";
sinput bool    Trade3TradeEverySignal=true;
//Up to this maximum
sinput int     Trade3MaxSignalsToFollow=7;
//With this distance between signals.
sinput int     Trade3MinTradeDistanceSingleTimeframePips=20;
//Use atr to calculate the minimum distance
sinput bool    Trade3UsePercentageOfAtrForDistance=true;
//over this period
sinput int     Trade3AtrPeriod=24;                     
//at this percentage.
sinput int     Trade3PercentageOfAtrToUse=150;         
sinput string  trc3="-- Trade closure inputs --";
//Close buys following a down arrow and sells at an up arrow
sinput bool    Trade3CloseOnOppositeFB=false;            
sinput bool    Trade3CloseOnOppositeHGI=false;
sinput bool    Trade3CloseOnOppositeMA=false;   
sinput bool    Trade3CloseOnOppositeChaos=true;
sinput bool    Trade3CloseOnOppositeTMS=false;
sinput bool    Trade3OnlyCloseWhenSuperSlopeAgrees=true; 
sinput bool    Trade3OnlyCloseWhenPeakyAgrees=false; 
sinput bool    Trade3OnlyCloseWhenBothSuperSlopeAndPeakyAgrees=false; 
extern string  rec3="---- Recovery ----";
extern bool    Trade3UseRecovery=true;
extern int     Trade3TradesToConstituteRecovery=4;
extern int     Trade3RecoveryProfitPips=1;
extern int     Trade3RecoveryProfitCash=0;
extern string  tb3="---- Trade3 basket trading ----";
extern bool    Trade3AsBasket=true;
extern double  Trade3BasketCashTarget=1.00;
extern double  Trade3BasketCashPercentageTarget=0;
extern bool    Trade3BasketCashUseDollopMultiplier=true;
double         Trade3BasketProfitTarget;
//Individual trade management features
extern string  Trade3Itm="---- Individual trade management ----";
extern string  Trade3BE = "-- Break even --";
extern bool    Trade3UseBreakEven=false;
extern int     Trade3BreakEvenPips=50;
extern int     Trade3BreakEvenProfitPips=10;
extern string  Trade3JSL="-- Jumping stop loss --";
extern bool    Trade3UseJumpingStop=false;
extern int     Trade3JumpingStopPips=30;
extern bool    Trade3JumpAfterBreakevenOnly=true;

extern string  tf4="-- Time Frame 4 --";
extern bool    TradeTF4=true;
extern ENUM_TIMEFRAMES Trade4TimeFrame=PERIOD_M30;
extern bool    Trade4ImmediateMarketOrder=true;
//The trading line buffer for the stop order.
extern int     Trade4BufferPips=10;
// when the signal changes while the stop order is not yet activated, close the stop order
extern bool    Trade4CloseStopOrderOnOppositePK=true;
extern bool    Trade4CloseStopOrderOnOppositeSS=true;
//This EA uses separate magic numbers for each time frame to recognise which tf the trade belongs to.
extern int     Trade4MagicNumber=103;
//It uses separate trade comments so the user can easily identify the trade's origin.
extern string  Trade4TradeComment="M30";
//We need individual take profit and stop loss for each time frame.
//A 'hard' tp
extern int     Trade4TakeProfitPips=0;
extern bool    Trade4UseAverageRangeTakeProfit=false;
extern ENUM_TIMEFRAMES Trade4AverageRangeTakeProfitTimeFrame=PERIOD_D1;
extern int     Trade4AverageRangeTakeProfitPeriod=24;
extern int     Trade4AverageRangeTakeProfitPipsShift=-2;
//A 'hard' sl
extern int     Trade4StopLossPips=0;
extern bool    Trade4UseAverageRangeStopLoss=false;
extern ENUM_TIMEFRAMES Trade4AverageRangeStopLossTimeFrame=PERIOD_D1;
extern int     Trade4AverageRangeStopLossPeriod=24;
extern int     Trade4AverageRangeStopLossPipsShift=2;
//Positive swap filter
extern bool    Trade4PositiveSwapTradesOnly=false;
extern string  lts4="-- Lot sizing --";
//'Hard' lot size.
extern double  Trade4Lot=0;
//Dynamic lot sizing
//Over rides Trade4Lot. Zero input to cancel.
extern double  Trade4LotsPerDollopOfCash=0.01;
extern double  Trade4SizeOfDollop=2000;
extern bool    Trade4UseBalance=false;
extern bool    Trade4UseEquity=true;
//Take every trade signal
sinput string  tri4="-- Take every signal inputs --";
sinput bool    Trade4TradeEverySignal=true;
//Up to this maximum
sinput int     Trade4MaxSignalsToFollow=8;
//With this distance between signals.
sinput int     Trade4MinTradeDistanceSingleTimeframePips=30;
//Use atr to calculate the minimum distance
sinput bool    Trade4UsePercentageOfAtrForDistance=true;
//over this period
sinput int     Trade4AtrPeriod=24;                     
//at this percentage.
sinput int     Trade4PercentageOfAtrToUse=200;         
sinput string  trc4="-- Trade closure inputs --";
//Close buys following a down arrow and sells at an up arrow
sinput bool    Trade4CloseOnOppositeFB=false;            
sinput bool    Trade4CloseOnOppositeHGI=false;
sinput bool    Trade4CloseOnOppositeMA=false;
sinput bool    Trade4CloseOnOppositeChaos=true;
sinput bool    Trade4CloseOnOppositeTMS=false;
sinput bool    Trade4OnlyCloseWhenSuperSlopeAgrees=true; 
sinput bool    Trade4OnlyCloseWhenPeakyAgrees=false; 
sinput bool    Trade4OnlyCloseWhenBothSuperSlopeAndPeakyAgrees=false; 
extern string  rec4="---- Recovery ----";
extern bool    Trade4UseRecovery=true;
extern int     Trade4TradesToConstituteRecovery=4;
extern int     Trade4RecoveryProfitPips=1;
extern int     Trade4RecoveryProfitCash=0;
extern string  tb4="---- Trade4 basket trading ----";
extern bool    Trade4AsBasket=true;
extern double  Trade4BasketCashTarget=1.00;
extern double  Trade4BasketCashPercentageTarget=0;
extern bool    Trade4BasketCashUseDollopMultiplier=true;
double         Trade4BasketProfitTarget;
//Individual trade management features
extern string  Trade4Itm="---- Individual trade management ----";
extern string  Trade4BE = "-- Break even --";
extern bool    Trade4UseBreakEven=false;
extern int     Trade4BreakEvenPips=50;
extern int     Trade4BreakEvenProfitPips=10;
extern string  Trade4JSL="-- Jumping stop loss --";
extern bool    Trade4UseJumpingStop=false;
extern int     Trade4JumpingStopPips=30;
extern bool    Trade4JumpAfterBreakevenOnly=true;

////////////////////////////////////////////////////////////////////////////////
//Define arrays to store all the information from the user inputs. This saves
//a lot of typing further down the line. These arrays are populated in OnInit().
//Time frames
int            TimeFrames[];
//Buffer for the stop order i.e. trading line + Trade1Buffer.
double         TradeBuffers[];
//Magic numbers and trade comments.
bool           CloseStopOrderOnOppositePK[];
bool           CloseStopOrderOnOppositeSS[];
int            MagicNumbers[];
string         TradeComments[];
//TP and SL
double         TakeProfits[];
bool           UseAverageRangeTakeProfit[];
ENUM_TIMEFRAMES AverageRangeTakeProfitTimeFrame[];
int            AverageRangeTakeProfitPeriod[];
int            AverageRangeTakeProfitPipsShift[];
double         StopLosses[];
bool           UseAverageRangeStopLoss[];
ENUM_TIMEFRAMES AverageRangeStopLossTimeFrame[];
int            AverageRangeStopLossPeriod[];
int            AverageRangeStopLossPipsShift[];

//TP and SL use sixths choices. This means that the tp/sl will be one Sixth of the pips in between the peaks.
//Peak hilo and trading lines prices.
double         PeakHigh;
double         PeakLow;
//Swap filter
bool           PositiveSwapOnly[];
//Lot sizing
double         TradeLots[];
double         TradeLotsPerDollop[];
double         TradeSizeOfDollop[];
bool           TradeUseBalance[];
bool           TradeUseEquity[];
double         Lot=0.01;
double         LotsPerDollopOfCash=0.01;
double         SizeOfDollop=1000;
bool           UseBalance=false;
bool           UseEquity=true;
//Some arrays to hold candle opening times
datetime       TradingBarTime[];//Changed by CHS
datetime       PKBarTime[], SsBarTime[], FBBarTime[], MaBarTime[], HGIBarTime[], RanBarTime[], NewsBarTime[];//Changed by CHS
//Immediate market trades
bool           ImmediateMarketTrades[];
//Recovery
bool           UseRecovery[];
int            TradesToConstituteRecovery[];
double         RecoveryProfitPips[];
double         RecoveryProfitCash[];
int            BuyTickets[], SellTickets[];
bool           BuysInRecovery=false, SellsInRecovery=false;
double         RecoveryTargetPrice=0;//For pips based recovery.
double         RecoveryTargetCash=0;//For profit based recovery
//Individual time frame basket
bool           TradeAsBasket[];
double         TradeBasketCashTarget[];
double         TradeBasketCashPercentageTarget[];
bool           TradeBasketCashUseDollopMultiplier[];
double         TradeBasketProfitTarget[];
////////////////////////////////////////////////////////////////////////////////
//Management arrays
//Break even
bool           UseBreakEven[];
double         BreakEvenPips[];
double         BreakEvenProfitPips[];
//Jumping stop
bool           UseJumpingStop[];
double         JumpingStopPips[];
bool           JumpAfterBreakEvenOnly[];
//Safety adapted from my shells
//We need more safety to combat the cretins at Crapperquotes managing to break Matt's OR code occasionally.
//EA will make no further attempt to trade for PostTradeAttemptWaitMinutes minutes, whether OR detects a receipt return or not.
datetime       TimeToStartTrading[][4];//Time to start trading
//Spread filter
double         RunningTotalOfSpreads[];//Pair by pair running total of the spread at each OnTimer() event
double         AverageSpread[];//Per pair average spread

//Take every trade signal
bool           TradeEverySignal[];
int            MaxSignalsToFollow[];
double         MinTradeDistanceSingleTimeframePips[];
double         AtrVal=0;
bool           UsePercentageOfAtrForDistance[];
int            AtrPeriod[];
double         PercentageOfAtrToUs[];
bool           CloseOnOppositeFB[];
bool           CloseOnOppositeHGI[];
bool           CloseOnOppositeMA[];
bool           CloseOnOppositeChaos[];
bool           CloseOnOppositeTMS[];
bool           OnlyCloseWhenSuperSlopeAgrees[];
bool           OnlyCloseWhenPeakyAgrees[];
bool           OnlyCloseWhenBothSuperSlopeAndPeakyAgrees[];
////////////////////////////////////////////////////////////////////////////////

extern string  sep4="================================================================";
extern string  ftg="---- Fill the gap inputs ----";
extern bool    FollowAdverseMarketWithStopOrders=true;
extern int     MarketDistancePips=100;
//Maximum no of trades allowed on an individual time frame.
extern int     MaxTradesAllowedPerTimeFrame=6;
////////////////////////////////////////////////////////////////////////////////
double         MarketDistance=0;
////////////////////////////////////////////////////////////////////////////////


extern string  sep6="================================================================";
//Treating every trade open on the platform as part of a basket.
extern string  bas="---- Global Basket trading ----";
extern bool    AllTradesBelongToBasket=true;
//'Hard take profit'
extern double  AllBasketCashTakeProfit=1;
extern double  AllBasketCashPercentageTarget=0;
extern bool    AllBasketCashUseDollopMultiplier=true;
////////////////////////////////////////////////////////////////////////////////
//Close all trades on the platform if a full basket tp is hit.
double         AllBasketProfitTarget;
double         EntirePositionCashUpl=0;//Treats every trade on the platform as part of a basket and closes everything when it reaches the user's target
////////////////////////////////////////////////////////////////////////////////

extern string  sep6a="===============================================================";
//Treating every trade open on the platform as part of a basket.
//Added by orisb. Thanks Brenden
extern string  bas2="---- Symbol Basket trading ----";
extern bool    SymbolTradesBelongToBasket=true;
extern int     SymbolMinTradesOpenForBasket=1;
extern double  SymbolBasketCashTakeProfit=1;
extern double  SymbolBasketCashPercentageTarget=0;
extern bool    SymbolBasketCashUseDollopMultiplier=true;
////////////////////////////////////////////////////////////////////////////////
//Close all trades on the platform if a full basket tp is hit.
double         SymbolBasketProfitTarget;      
double         SymbolPositionCashUpl=0;//Treats all same symbol trades on the platform as part of a basket and closes everything when it reaches the user's target
int            SymbolMarketTrades=0;
int            SymbolMagicNumberCount=0;
int            SymbolMagicNumber[];
///////////////////////////////////////////////////////////////////////

//This code by tomele. Thank you Thomas. Wonderful stuff.
extern string  sep7="================================================================";
extern string  roll="---- Rollover time ----";
extern bool    DisablePoSDuringRollover=true;
extern string  ro1 = "Use 24H format, SERVER time.";
extern string  ro2 = "Example: '23.55'";
extern string  RollOverStarts="23.55";
extern string  RollOverEnds="00.15";
////////////////////////////////////////////////////////////////////////////////////////
bool           RolloverInProgress=false;//Tells DisplayUserFeedback() to display the rollover message
////////////////////////////////////////////////////////////////////////////////////////

//Trading hours
extern string  sepa7="================================================================";
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

//Profit targets
extern string  sep8="================================================================";
extern string  pro="---- Daily and weekly profit targets ----";
//A zero value in all the inputs turns this feature off.
extern string  dai="-- Daily --";
extern double  DailyCashProfitTarget=0;
extern double  DailyPercentOfBalanceProfitTarget=0;
extern string  wee="-- Weekly --";
extern double  WeeklyCashProfitTarget=0;
extern double  WeeklyPercentOfBalanceProfitTarget=0;
////////////////////////////////////////////////////////////////////////////////////////
bool           TradingDoneForTheDay=false, TradingDoneForTheWeek=false;
double         DailyProfitTarget=0, WeeklyProfitTarget=0;//For chart display.
////////////////////////////////////////////////////////////////////////////////////////

extern string  sep11a="================================================================";
extern string  ccs="---- Chart snapshots ----";
extern bool    TakeSnapshots=false;//Tells ea to take snaps when it opens and closes a trade
extern int     PictureWidth=800;
extern int     PictureHeight=600;
//extern string  ReservedPair="XAUUSD";
//extern string  TemplateName="Default";

extern string  sep12="================================================================";
extern string  ems="----Email thingies----";
extern bool    EmailTradeNotification=false;
//extern bool    SendAlertNotTrade=false;
extern bool    AlertPush=false;// Enable to send push notification on alert


extern string  s222="================================================================";
//Enhanced screen feedback display code provided by Paul Batchelor (lifesys). Thanks Paul; this is fantastic.
extern string  chf               ="---- Chart feedback display ----";
extern bool    ShowChartFeedback=true;
// if using Comments
extern int     DisplayGapSize    = 30;
// ****************************** added to make screen Text more readable
// replaces Comment() with OBJ_LABEL text
extern bool    DisplayAsText     = true;
//Disable the chart in foreground CrapTx setting so the candles do not obscure the text
extern bool    KeepTextOnTop     = true;
extern int     DisplayX          = 20;
extern int     DisplayY          = 0;
extern int     fontSise          = 8;
extern double  LineSpacing       = 1.68;
extern string  fontName          = "Arial";
extern color    colour            = Yellow;
// adjustment to reform lines for different font size
extern string  ChartTemplate     = "Default";
////////////////////////////////////////////////////////////////////////////////////////
int            DisplayCount;
string         Gap,ScreenMessage;
////////////////////////////////////////////////////////////////////////////////////////

//Matt's O-R stuff
int            O_R_Setting_max_retries=10;
double         O_R_Setting_sleep_time=4.0; /* seconds */
double         O_R_Setting_sleep_max=15.0; /* seconds */
int            RetryCount=10;//Will make this number of attempts to get around the trade context busy error.

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
//UPL variables
double         PipsUpl;//For keeping track of the pips PipsUpl of multi-trade positions. Aplies to the individual pair.
double         CashUpl;//For keeping track of the cash PipsUpl of multi-trade positions. Aplies to the individual pair.
//+------------------------------------------------------------------+
//| Expert initialization function                                   |
//+------------------------------------------------------------------+
int OnInit()
{


   //User message
   Comment("                              INITIALISING. PLEASE WAIT.");


   //Dimwit check
   //Using hgi_lib
   /*
   if (!indiExists( HGI_Name ))
   {
//      Alert(" Read the fucking user guide properly this time, you demented lazy and stupid dimwit.");
      Alert("The required indicator " + HGI_Name + " does not exist on your platform. I am removing myself from your chart.");
      ExpertRemove();
      return(0);
   }//if (!indiExists( HGI_Name ))
   */


   
   //Set up the doubles variables that replace the unser integer inputs
   MarketDistance = MarketDistancePips;
   
   
   
//--- create timer
   EventSetTimer(EventTimerIntervalSeconds);
   
   //Extract the pairs traded by the user
   ExtractPairs();
   //Populate all the arrays
   PopulateTheArrays();
   
   //Spread filter
   //Read the global variables' values into the AverageSpread[] array, or
   //create a GV if none already exists.
   for (int cc = 0; cc < NoOfPairs; cc++)
   {
      SpreadGvName = TradePair[cc] + " average spread";
      if (GlobalVariableCheck(SpreadGvName) )//GV found, so read it
      {
         AverageSpread[cc] = GlobalVariableGet(SpreadGvName);
      }//if (GlobalVariableCheck(SpreadGvName) )
      else//GV not found, so create it
      {
         GetBasics(TradePair[cc]);
         AverageSpread[cc] = spread;
         GlobalVariableSet(SpreadGvName, spread);      
      }//else      
   }//for (int cc = 0; cc <= NoOfPairs; cc++)
   



   Gap="";
   if (DisplayGapSize > 0)
      StringInit(Gap, DisplayGapSize, ' ');


   //Trading hours
   tradingHoursDisplay=tradingHours;//For display
   initTradingHours();//Sets up the trading hours array
   
//---
   return(INIT_SUCCEEDED);
}

//Missing indi check
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
//| Expert deinitialization function                                 |
//+------------------------------------------------------------------+
void OnDeinit(const int reason)
{
//--- destroy timer
   EventKillTimer();
   removeAllObjects();
   Comment("");
      
   //Free the arrays memory
   ArrayFree(TimeFrames);
   ArrayFree(TradeBuffers);
   ArrayFree(CloseStopOrderOnOppositePK);
   ArrayFree(CloseStopOrderOnOppositeSS);
   ArrayFree(MagicNumbers);
   ArrayFree(TradeComments);
   ArrayFree(TakeProfits);
   ArrayFree(UseAverageRangeTakeProfit);
   ArrayFree(AverageRangeTakeProfitTimeFrame);
   ArrayFree(AverageRangeTakeProfitPeriod);
   ArrayFree(AverageRangeTakeProfitPipsShift);
   ArrayFree(StopLosses);
   ArrayFree(UseAverageRangeStopLoss);
   ArrayFree(AverageRangeStopLossTimeFrame);
   ArrayFree(AverageRangeStopLossPeriod);
   ArrayFree(AverageRangeStopLossPipsShift);
   ArrayFree(PositiveSwapOnly);
   ArrayFree(PairsWithOpenTrades);
   ArrayFree(TradeLots);
   ArrayFree(TradeLotsPerDollop);
   ArrayFree(TradeSizeOfDollop);
   ArrayFree(TradeUseBalance);
   ArrayFree(TradeUseEquity);
   ArrayFree(ImmediateMarketTrades);
   ArrayFree(UseBreakEven);
   ArrayFree(BreakEvenPips);
   ArrayFree(BreakEvenProfitPips);
   ArrayFree(UseJumpingStop);
   ArrayFree(JumpingStopPips);
   ArrayFree(JumpAfterBreakEvenOnly);
   ArrayFree(RecoveryProfitPips);
   ArrayFree(RecoveryProfitCash);
   ArrayFree(NewsStatus);
   ArrayFree(newsarray);
   ArrayFree(ChaosStatus);
   ArrayFree(TmsStatus);

   //Take every trade signal
   ArrayFree(TradeEverySignal);
   ArrayFree(MaxSignalsToFollow);
   ArrayFree(MinTradeDistanceSingleTimeframePips);
   ArrayFree(UsePercentageOfAtrForDistance);
   ArrayFree(AtrPeriod);
   ArrayFree(PercentageOfAtrToUs);
   ArrayFree(CloseOnOppositeFB);
   ArrayFree(CloseOnOppositeHGI);
   ArrayFree(CloseOnOppositeMA);
   ArrayFree(CloseOnOppositeChaos);
   ArrayFree(OnlyCloseWhenSuperSlopeAgrees);
   ArrayFree(OnlyCloseWhenPeakyAgrees);
   ArrayFree(OnlyCloseWhenBothSuperSlopeAndPeakyAgrees);   

   //Own Time Frame
   ArrayFree(OTFPeakyMarketDirection);
   ArrayFree(OTFSsColour);
   ArrayFree(OTFChaosStatus);
   ArrayFree(OTFChaosD1);
   ArrayFree(OTFChaosD2);
   ArrayFree(OTFChaosD3);
   ArrayFree(OTFChaosD4);
   ArrayFree(OTFChaosD5);
   ArrayFree(OTFTmsStatus);
   ArrayFree(OTFTmsD1);
   ArrayFree(OTFTmsD2);
   ArrayFree(OTFTmsD3);
   ArrayFree(OTFTmsD4);
   ArrayFree(OTFTmsD5);
   ArrayFree(OTFTmsD6);
   ArrayFree(OTFFbStatus);
   ArrayFree(OTFHgiStatus);
   ArrayFree(OTFMaTrend);
   ArrayFree(OTFRangingDirection);

}//End void OnDeinit(const int reason)


//+------------------------------------------------------------------+
//| Chart event function                                             |
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
         int tf=(int)StringToInteger(result[3]);
         
         OpenChart(pair,tf);
         return;
      }
      
      else if(StringFind(sparam,"OAM-CLOSE")>=0)
      {
         ObjectSetInteger(0,sparam,OBJPROP_STATE,0);
         
         CloseCharts();
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
   ChartApplyTemplate(newchartid,ChartTemplate);
   ChartSetString(newchartid,CHART_COMMENT,"This chart may be closed from the EA panel"); 
   
}//End void OpenChart(string pair,int tf)
 
void CloseCharts()
{
   //If chart is already open, bring it to top
   long nextchart=ChartFirst();
   do
   {
      if(ChartGetString(nextchart,CHART_COMMENT)=="This chart may be closed from the EA panel")
         ChartClose(nextchart);
   }
   while((nextchart=ChartNext(nextchart))!=-1);
   
}//End void OpenChart(string pair,int tf)
 
 
void PopulateTheArrays()
{

   //Copies the user inputs into arrays to make function programming easier.

   //Calculate the number of time frames to be traded.
   int tf = 0;
   if (TradeTF1)
      tf++;
   if (TradeTF2)
      tf++;
   if (TradeTF3)
      tf++;
   if (TradeTF4)
      tf++;
      
   
   //Size the arrays. I have not bothered to initialise them as they will all have a relevant value.
   ArrayResize(TimeFrames, tf);
   ArrayResize(TradeBuffers, tf);
   ArrayResize(CloseStopOrderOnOppositePK, tf);
   ArrayResize(CloseStopOrderOnOppositeSS, tf);
   ArrayResize(MagicNumbers, tf);
   ArrayResize(TradeComments, tf);
   ArrayResize(TakeProfits, tf);
   ArrayResize(UseAverageRangeTakeProfit, tf);
   ArrayResize(AverageRangeTakeProfitTimeFrame, tf);
   ArrayResize(AverageRangeTakeProfitPeriod, tf);
   ArrayResize(AverageRangeTakeProfitPipsShift, tf);
   ArrayResize(StopLosses, tf);
   ArrayResize(UseAverageRangeStopLoss, tf);
   ArrayResize(AverageRangeStopLossTimeFrame, tf);
   ArrayResize(AverageRangeStopLossPeriod, tf);
   ArrayResize(AverageRangeStopLossPipsShift, tf);
   ArrayResize(PositiveSwapOnly, tf);
   ArrayResize(TradeLots, tf);
   ArrayResize(TradeLotsPerDollop, tf);
   ArrayResize(TradeSizeOfDollop, tf);
   ArrayResize(TradeUseBalance, tf);
   ArrayResize(TradeUseEquity, tf);
   ArrayResize(SsBarTime, NoOfPairs);
   ArrayInitialize(SsBarTime, 0);
   ArrayResize(ImmediateMarketTrades, tf);
   ArrayResize(UseRecovery, tf);
   ArrayResize(TradesToConstituteRecovery, tf);
   ArrayResize(RecoveryProfitPips, tf);
   ArrayResize(RecoveryProfitCash, tf);
   ArrayResize(TradeAsBasket, tf);
   ArrayResize(TradeBasketCashTarget, tf);
   ArrayResize(TradeBasketCashPercentageTarget, tf);
   ArrayResize(TradeBasketCashUseDollopMultiplier, tf);
   ArrayResize(TradeBasketProfitTarget, tf);
   ArrayResize(UseBreakEven, tf);
   ArrayResize(BreakEvenPips, tf);
   ArrayResize(BreakEvenProfitPips, tf);
   ArrayResize(UseJumpingStop, tf);
   ArrayResize(JumpingStopPips, tf);
   ArrayResize(JumpAfterBreakEvenOnly, tf);
   ArrayResize(PKBarTime, NoOfPairs);//Changed by CHS
   ArrayInitialize(PKBarTime, 0);//Changed by CHS
   ArrayResize(SsBarTime, NoOfPairs);//Changed by CHS
   ArrayInitialize(SsBarTime, 0);//Changed by CHS
   ArrayResize(FBBarTime, NoOfPairs);//Changed by CHS
   ArrayInitialize(FBBarTime, 0);//Changed by CHS
   ArrayResize(MaBarTime, NoOfPairs);//Changed by CHS
   ArrayInitialize(MaBarTime, 0);//Changed by CHS
   ArrayResize(HGIBarTime, NoOfPairs);//Changed by CHS
   ArrayInitialize(HGIBarTime, 0);//Changed by CHS
   ArrayResize(RanBarTime, NoOfPairs);//Changed by CHS
   ArrayInitialize(RanBarTime, 0);//Changed by CHS
   

    //Take every trade signal
   ArrayResize(TradeEverySignal, tf);
   ArrayResize(MaxSignalsToFollow, tf);
   ArrayResize(MinTradeDistanceSingleTimeframePips, tf);
   ArrayResize(UsePercentageOfAtrForDistance, tf);
   ArrayResize(AtrPeriod, tf);
   ArrayResize(PercentageOfAtrToUs, tf);
   ArrayResize(CloseOnOppositeFB, tf);
   ArrayResize(CloseOnOppositeHGI, tf);
   ArrayResize(CloseOnOppositeMA, tf);
   ArrayResize(CloseOnOppositeChaos, tf);
   ArrayResize(CloseOnOppositeTMS, tf);
   ArrayResize(OnlyCloseWhenSuperSlopeAgrees, tf);
   ArrayResize(OnlyCloseWhenPeakyAgrees, tf);
   ArrayResize(OnlyCloseWhenBothSuperSlopeAndPeakyAgrees, tf);     

   //Own Time Frame
   ArrayResize(OTFPeakyMarketDirection, NoOfPairs);
   ArrayResize(OTFSsColour, NoOfPairs);
   ArrayResize(OTFChaosStatus, NoOfPairs);
   ArrayResize(OTFChaosD1, NoOfPairs);
   ArrayResize(OTFChaosD2, NoOfPairs);
   ArrayResize(OTFChaosD3, NoOfPairs);
   ArrayResize(OTFChaosD4, NoOfPairs);
   ArrayResize(OTFChaosD5, NoOfPairs);
   ArrayResize(OTFTmsStatus, NoOfPairs);
   ArrayResize(OTFTmsD1, NoOfPairs);
   ArrayResize(OTFTmsD2, NoOfPairs);
   ArrayResize(OTFTmsD3, NoOfPairs);
   ArrayResize(OTFTmsD4, NoOfPairs);
   ArrayResize(OTFTmsD5, NoOfPairs);
   ArrayResize(OTFTmsD6, NoOfPairs);
   ArrayResize(OTFFbStatus, NoOfPairs);
   ArrayResize(OTFHgiStatus, NoOfPairs);
   ArrayResize(OTFMaTrend, NoOfPairs);
   ArrayResize(OTFRangingDirection, NoOfPairs);
   ArrayResize(NewsStatus, NoOfPairs);

   int tfTotal = 0;//The number of time frames being traded.
   //Trade1
   if (TradeTF1)
   {
      TimeFrames[tfTotal] = Trade1TimeFrame;
      TradeBuffers[tfTotal] = Trade1BufferPips;
      CloseStopOrderOnOppositePK[tfTotal] = Trade1CloseStopOrderOnOppositePK;
      CloseStopOrderOnOppositeSS[tfTotal] = Trade1CloseStopOrderOnOppositeSS;
      MagicNumbers[tfTotal] = Trade1MagicNumber;
      TradeComments[tfTotal] =  TradeCommentPrefix + "-" + Trade1TradeComment;
      TakeProfits[tfTotal] = Trade1TakeProfitPips;
      UseAverageRangeTakeProfit[tfTotal] = Trade1UseAverageRangeTakeProfit;
      AverageRangeTakeProfitTimeFrame[tfTotal] = Trade1AverageRangeTakeProfitTimeFrame;
      AverageRangeTakeProfitPeriod[tfTotal] = Trade1AverageRangeTakeProfitPeriod;
      AverageRangeTakeProfitPipsShift[tfTotal] = Trade1AverageRangeTakeProfitPipsShift;
      StopLosses[tfTotal] = Trade1StopLossPips;
      UseAverageRangeStopLoss[tfTotal] = Trade1UseAverageRangeStopLoss;
      AverageRangeStopLossTimeFrame[tfTotal] = Trade1AverageRangeStopLossTimeFrame;
      AverageRangeStopLossPeriod[tfTotal] = Trade1AverageRangeStopLossPeriod;
      AverageRangeStopLossPipsShift[tfTotal] = Trade1AverageRangeStopLossPipsShift;
      PositiveSwapOnly[tfTotal] = Trade1PositiveSwapTradesOnly;
      TradeLots[tfTotal] = Trade1Lot;
      TradeLotsPerDollop[tfTotal] = Trade1LotsPerDollopOfCash;
      TradeSizeOfDollop[tfTotal] = Trade1SizeOfDollop;
      TradeUseBalance[tfTotal] = Trade1UseBalance;
      TradeUseEquity[tfTotal] = Trade1UseEquity;
      ImmediateMarketTrades[tfTotal] = Trade1ImmediateMarketOrder;
      UseRecovery[tfTotal] = Trade1UseRecovery;
      TradesToConstituteRecovery[tfTotal] = Trade1TradesToConstituteRecovery;
      RecoveryProfitPips[tfTotal] = Trade1RecoveryProfitPips;
      RecoveryProfitCash[tfTotal] = Trade1RecoveryProfitCash;
      TradeAsBasket[tfTotal] = Trade1AsBasket;
      TradeBasketCashTarget[tfTotal] = Trade1BasketCashTarget;
      TradeBasketCashPercentageTarget[tfTotal] = Trade1BasketCashPercentageTarget;
      TradeBasketCashUseDollopMultiplier[tfTotal] = Trade1BasketCashUseDollopMultiplier;
      TradeBasketProfitTarget[tfTotal] = Trade1BasketProfitTarget;
      UseBreakEven[tfTotal] = Trade1UseBreakEven;
      BreakEvenPips[tfTotal] = Trade1BreakEvenPips;
      BreakEvenProfitPips[tfTotal] = Trade1BreakEvenProfitPips;
      UseJumpingStop[tfTotal] = Trade1UseJumpingStop;
      JumpingStopPips[tfTotal] = Trade1JumpingStopPips;
      JumpAfterBreakEvenOnly[tfTotal] = Trade1JumpAfterBreakevenOnly;

      //Take every trade signal
      TradeEverySignal[tfTotal] = Trade1TradeEverySignal;
      MaxSignalsToFollow[tfTotal] = Trade1MaxSignalsToFollow;
      MinTradeDistanceSingleTimeframePips[tfTotal] = Trade1MinTradeDistanceSingleTimeframePips;
      UsePercentageOfAtrForDistance[tfTotal] = Trade1UsePercentageOfAtrForDistance;
      AtrPeriod[tfTotal] = Trade1AtrPeriod;
      PercentageOfAtrToUs[tfTotal] = Trade1PercentageOfAtrToUse;
      CloseOnOppositeFB[tfTotal] = Trade1CloseOnOppositeFB;
      CloseOnOppositeHGI[tfTotal] = Trade1CloseOnOppositeHGI;
      CloseOnOppositeMA[tfTotal] = Trade1CloseOnOppositeMA;
      CloseOnOppositeChaos[tfTotal] = Trade1CloseOnOppositeChaos;
      CloseOnOppositeTMS[tfTotal] = Trade1CloseOnOppositeTMS;
      OnlyCloseWhenSuperSlopeAgrees[tfTotal] = Trade1OnlyCloseWhenSuperSlopeAgrees;
      OnlyCloseWhenPeakyAgrees[tfTotal] = Trade1OnlyCloseWhenPeakyAgrees;
      OnlyCloseWhenBothSuperSlopeAndPeakyAgrees[tfTotal] = Trade1OnlyCloseWhenBothSuperSlopeAndPeakyAgrees;

            
      tfTotal++;
   }//if (TradeTF1)
   


   if (TradeTF2)
   {
      TimeFrames[tfTotal] = Trade2TimeFrame;
      TradeBuffers[tfTotal] = Trade2BufferPips;
      CloseStopOrderOnOppositePK[tfTotal] = Trade2CloseStopOrderOnOppositePK;
      CloseStopOrderOnOppositeSS[tfTotal] = Trade2CloseStopOrderOnOppositeSS;
      MagicNumbers[tfTotal] = Trade2MagicNumber;
      TradeComments[tfTotal] = TradeCommentPrefix + "-" + Trade2TradeComment;
      TakeProfits[tfTotal] = Trade2TakeProfitPips;
      UseAverageRangeTakeProfit[tfTotal] = Trade2UseAverageRangeTakeProfit;
      AverageRangeTakeProfitTimeFrame[tfTotal] = Trade2AverageRangeTakeProfitTimeFrame;
      AverageRangeTakeProfitPeriod[tfTotal] = Trade2AverageRangeTakeProfitPeriod;
      AverageRangeTakeProfitPipsShift[tfTotal] = Trade2AverageRangeTakeProfitPipsShift;
      StopLosses[tfTotal] = Trade2StopLossPips;
      UseAverageRangeStopLoss[tfTotal] = Trade2UseAverageRangeStopLoss;
      AverageRangeStopLossTimeFrame[tfTotal] = Trade2AverageRangeStopLossTimeFrame;
      AverageRangeStopLossPeriod[tfTotal] = Trade2AverageRangeStopLossPeriod;
      AverageRangeStopLossPipsShift[tfTotal] = Trade2AverageRangeStopLossPipsShift;
      PositiveSwapOnly[tfTotal] = Trade2PositiveSwapTradesOnly;
      TradeLots[tfTotal] = Trade2Lot;
      TradeLotsPerDollop[tfTotal] = Trade2LotsPerDollopOfCash;
      TradeSizeOfDollop[tfTotal] = Trade2SizeOfDollop;
      TradeUseBalance[tfTotal] = Trade2UseBalance;
      TradeUseEquity[tfTotal] = Trade2UseEquity;
      ImmediateMarketTrades[tfTotal] = Trade2ImmediateMarketOrder;
      UseRecovery[tfTotal] = Trade2UseRecovery;
      TradesToConstituteRecovery[tfTotal] = Trade2TradesToConstituteRecovery;
      RecoveryProfitPips[tfTotal] = Trade2RecoveryProfitPips;
      RecoveryProfitCash[tfTotal] = Trade2RecoveryProfitCash;
      TradeAsBasket[tfTotal] = Trade2AsBasket;
      TradeBasketCashTarget[tfTotal] = Trade2BasketCashTarget;
      TradeBasketCashPercentageTarget[tfTotal] = Trade2BasketCashPercentageTarget;
      TradeBasketCashUseDollopMultiplier[tfTotal] = Trade2BasketCashUseDollopMultiplier;
      TradeBasketProfitTarget[tfTotal] = Trade2BasketProfitTarget;
      UseBreakEven[tfTotal] = Trade2UseBreakEven;
      BreakEvenPips[tfTotal] = Trade2BreakEvenPips;
      BreakEvenProfitPips[tfTotal] = Trade2BreakEvenProfitPips;
      UseJumpingStop[tfTotal] = Trade2UseJumpingStop;
      JumpingStopPips[tfTotal] = Trade2JumpingStopPips;
      JumpAfterBreakEvenOnly[tfTotal] = Trade2JumpAfterBreakevenOnly;

      //Take every trade signal
      TradeEverySignal[tfTotal] = Trade2TradeEverySignal;
      MaxSignalsToFollow[tfTotal] = Trade2MaxSignalsToFollow;
      MinTradeDistanceSingleTimeframePips[tfTotal] = Trade2MinTradeDistanceSingleTimeframePips;
      UsePercentageOfAtrForDistance[tfTotal] = Trade2UsePercentageOfAtrForDistance;
      AtrPeriod[tfTotal] = Trade2AtrPeriod;
      PercentageOfAtrToUs[tfTotal] = Trade2PercentageOfAtrToUse;
      CloseOnOppositeFB[tfTotal] = Trade2CloseOnOppositeFB;
      CloseOnOppositeHGI[tfTotal] = Trade2CloseOnOppositeHGI;
      CloseOnOppositeMA[tfTotal] = Trade2CloseOnOppositeMA;
      CloseOnOppositeChaos[tfTotal] = Trade2CloseOnOppositeChaos;
      CloseOnOppositeTMS[tfTotal] = Trade2CloseOnOppositeTMS;
      OnlyCloseWhenSuperSlopeAgrees[tfTotal] = Trade2OnlyCloseWhenSuperSlopeAgrees;
      OnlyCloseWhenPeakyAgrees[tfTotal] = Trade2OnlyCloseWhenPeakyAgrees;
      OnlyCloseWhenBothSuperSlopeAndPeakyAgrees[tfTotal] = Trade2OnlyCloseWhenBothSuperSlopeAndPeakyAgrees;

      tfTotal++;
   }//if (TradeTF2)
   
   //Trade3
   if (TradeTF3)
   {
      TimeFrames[tfTotal] = Trade3TimeFrame;
      TradeBuffers[tfTotal] = Trade3BufferPips;
      CloseStopOrderOnOppositePK[tfTotal] = Trade3CloseStopOrderOnOppositePK;
      CloseStopOrderOnOppositeSS[tfTotal] = Trade3CloseStopOrderOnOppositeSS;
      MagicNumbers[tfTotal] = Trade3MagicNumber;
      TradeComments[tfTotal] =  TradeCommentPrefix + "-" + Trade3TradeComment;
      TakeProfits[tfTotal] = Trade3TakeProfitPips;
      UseAverageRangeTakeProfit[tfTotal] = Trade3UseAverageRangeTakeProfit;
      AverageRangeTakeProfitTimeFrame[tfTotal] = Trade3AverageRangeTakeProfitTimeFrame;
      AverageRangeTakeProfitPeriod[tfTotal] = Trade3AverageRangeTakeProfitPeriod;
      AverageRangeTakeProfitPipsShift[tfTotal] = Trade3AverageRangeTakeProfitPipsShift;
      StopLosses[tfTotal] = Trade3StopLossPips;
      UseAverageRangeStopLoss[tfTotal] = Trade3UseAverageRangeStopLoss;
      AverageRangeStopLossTimeFrame[tfTotal] = Trade3AverageRangeStopLossTimeFrame;
      AverageRangeStopLossPeriod[tfTotal] = Trade3AverageRangeStopLossPeriod;
      AverageRangeStopLossPipsShift[tfTotal] = Trade3AverageRangeStopLossPipsShift;
      PositiveSwapOnly[tfTotal] = Trade3PositiveSwapTradesOnly;
      TradeLots[tfTotal] = Trade3Lot;
      TradeLotsPerDollop[tfTotal] = Trade3LotsPerDollopOfCash;
      TradeSizeOfDollop[tfTotal] = Trade3SizeOfDollop;
      TradeUseBalance[tfTotal] = Trade3UseBalance;
      TradeUseEquity[tfTotal] = Trade3UseEquity;
      ImmediateMarketTrades[tfTotal] = Trade3ImmediateMarketOrder;
      UseRecovery[tfTotal] = Trade3UseRecovery;
      TradesToConstituteRecovery[tfTotal] = Trade3TradesToConstituteRecovery;
      RecoveryProfitPips[tfTotal] = Trade3RecoveryProfitPips;
      RecoveryProfitCash[tfTotal] = Trade3RecoveryProfitCash;
      TradeAsBasket[tfTotal] = Trade3AsBasket;
      TradeBasketCashTarget[tfTotal] = Trade3BasketCashTarget;
      TradeBasketCashPercentageTarget[tfTotal] = Trade3BasketCashPercentageTarget;
      TradeBasketCashUseDollopMultiplier[tfTotal] = Trade3BasketCashUseDollopMultiplier;
      TradeBasketProfitTarget[tfTotal] = Trade3BasketProfitTarget;
      UseBreakEven[tfTotal] = Trade3UseBreakEven;
      BreakEvenPips[tfTotal] = Trade3BreakEvenPips;
      BreakEvenProfitPips[tfTotal] = Trade3BreakEvenProfitPips;
      UseJumpingStop[tfTotal] = Trade3UseJumpingStop;
      JumpingStopPips[tfTotal] = Trade3JumpingStopPips;
      JumpAfterBreakEvenOnly[tfTotal] = Trade3JumpAfterBreakevenOnly;

      //Take every trade signal
      TradeEverySignal[tfTotal] = Trade3TradeEverySignal;
      MaxSignalsToFollow[tfTotal] = Trade3MaxSignalsToFollow;
      MinTradeDistanceSingleTimeframePips[tfTotal] = Trade3MinTradeDistanceSingleTimeframePips;
      UsePercentageOfAtrForDistance[tfTotal] = Trade3UsePercentageOfAtrForDistance;
      AtrPeriod[tfTotal] = Trade3AtrPeriod;
      PercentageOfAtrToUs[tfTotal] = Trade3PercentageOfAtrToUse;
      CloseOnOppositeFB[tfTotal] = Trade3CloseOnOppositeFB;
      CloseOnOppositeHGI[tfTotal] = Trade3CloseOnOppositeHGI;
      CloseOnOppositeMA[tfTotal] = Trade3CloseOnOppositeMA;
      CloseOnOppositeChaos[tfTotal] = Trade3CloseOnOppositeChaos;
      CloseOnOppositeTMS[tfTotal] = Trade3CloseOnOppositeTMS;
      OnlyCloseWhenSuperSlopeAgrees[tfTotal] = Trade3OnlyCloseWhenSuperSlopeAgrees;
      OnlyCloseWhenPeakyAgrees[tfTotal] = Trade3OnlyCloseWhenPeakyAgrees;
      OnlyCloseWhenBothSuperSlopeAndPeakyAgrees[tfTotal] = Trade3OnlyCloseWhenBothSuperSlopeAndPeakyAgrees;

      tfTotal++;
   }//if (TradeTF3)
   
   //Trade4
   if (TradeTF4)
   {
      TimeFrames[tfTotal] = Trade4TimeFrame;
      TradeBuffers[tfTotal] = Trade4BufferPips;
      CloseStopOrderOnOppositePK[tfTotal] = Trade4CloseStopOrderOnOppositePK;
      CloseStopOrderOnOppositeSS[tfTotal] = Trade4CloseStopOrderOnOppositeSS;
      MagicNumbers[tfTotal] = Trade4MagicNumber;
      TradeComments[tfTotal] =  TradeCommentPrefix + "-" + Trade4TradeComment;
      TakeProfits[tfTotal] = Trade4TakeProfitPips;
      UseAverageRangeTakeProfit[tfTotal] = Trade4UseAverageRangeTakeProfit;
      AverageRangeTakeProfitTimeFrame[tfTotal] = Trade4AverageRangeTakeProfitTimeFrame;
      AverageRangeTakeProfitPeriod[tfTotal] = Trade4AverageRangeTakeProfitPeriod;
      AverageRangeTakeProfitPipsShift[tfTotal] = Trade4AverageRangeTakeProfitPipsShift;
      StopLosses[tfTotal] = Trade4StopLossPips;
      UseAverageRangeStopLoss[tfTotal] = Trade4UseAverageRangeStopLoss;
      AverageRangeStopLossTimeFrame[tfTotal] = Trade4AverageRangeStopLossTimeFrame;
      AverageRangeStopLossPeriod[tfTotal] = Trade4AverageRangeStopLossPeriod;
      AverageRangeStopLossPipsShift[tfTotal] = Trade4AverageRangeStopLossPipsShift;
      PositiveSwapOnly[tfTotal] = Trade4PositiveSwapTradesOnly;
      TradeLots[tfTotal] = Trade4Lot;
      TradeLotsPerDollop[tfTotal] = Trade4LotsPerDollopOfCash;
      TradeSizeOfDollop[tfTotal] = Trade4SizeOfDollop;
      TradeUseBalance[tfTotal] = Trade4UseBalance;
      TradeUseEquity[tfTotal] = Trade4UseEquity;
      ImmediateMarketTrades[tfTotal] = Trade4ImmediateMarketOrder;
      UseRecovery[tfTotal] = Trade4UseRecovery;
      TradesToConstituteRecovery[tfTotal] = Trade4TradesToConstituteRecovery;
      RecoveryProfitPips[tfTotal] = Trade4RecoveryProfitPips;
      RecoveryProfitCash[tfTotal] = Trade4RecoveryProfitCash;
      TradeAsBasket[tfTotal] = Trade4AsBasket;
      TradeBasketCashTarget[tfTotal] = Trade4BasketCashTarget;
      TradeBasketCashPercentageTarget[tfTotal] = Trade4BasketCashPercentageTarget;
      TradeBasketCashUseDollopMultiplier[tfTotal] = Trade4BasketCashUseDollopMultiplier;
      TradeBasketProfitTarget[tfTotal] = Trade4BasketProfitTarget;
      UseBreakEven[tfTotal] = Trade4UseBreakEven;
      BreakEvenPips[tfTotal] = Trade4BreakEvenPips;
      BreakEvenProfitPips[tfTotal] = Trade4BreakEvenProfitPips;
      UseJumpingStop[tfTotal] = Trade4UseJumpingStop;
      JumpingStopPips[tfTotal] = Trade4JumpingStopPips;
      JumpAfterBreakEvenOnly[tfTotal] = Trade4JumpAfterBreakevenOnly;

      //Take every trade signal
      TradeEverySignal[tfTotal] = Trade4TradeEverySignal;
      MaxSignalsToFollow[tfTotal] = Trade4MaxSignalsToFollow;
      MinTradeDistanceSingleTimeframePips[tfTotal] = Trade4MinTradeDistanceSingleTimeframePips;
      UsePercentageOfAtrForDistance[tfTotal] = Trade4UsePercentageOfAtrForDistance;
      AtrPeriod[tfTotal] = Trade4AtrPeriod;
      PercentageOfAtrToUs[tfTotal] = Trade4PercentageOfAtrToUse;
      CloseOnOppositeFB[tfTotal] = Trade4CloseOnOppositeFB;
      CloseOnOppositeHGI[tfTotal] = Trade4CloseOnOppositeHGI;
      CloseOnOppositeMA[tfTotal] = Trade4CloseOnOppositeMA;
      CloseOnOppositeChaos[tfTotal] = Trade4CloseOnOppositeChaos;
      CloseOnOppositeTMS[tfTotal] = Trade4CloseOnOppositeTMS;
      OnlyCloseWhenSuperSlopeAgrees[tfTotal] = Trade4OnlyCloseWhenSuperSlopeAgrees;
      OnlyCloseWhenPeakyAgrees[tfTotal] = Trade4OnlyCloseWhenPeakyAgrees;
      OnlyCloseWhenBothSuperSlopeAndPeakyAgrees[tfTotal] = Trade4OnlyCloseWhenBothSuperSlopeAndPeakyAgrees;

      tfTotal++;
   }//if (TradeTF4)
   
   //I do not know of any way of resizing a 2 dimensional array, so store
   //each bar open time in an array of the number of pairs being traded * the no of time frames.
   ArrayResize(TradingBarTime, NoOfPairs * tfTotal);
   ArrayInitialize(TradingBarTime, 0);

   //FBStatus
   ArrayResize(FbStatus, NoOfPairs);
   for (int cc = 0; cc < NoOfPairs; cc++)
   {
      for (int pairsIndex = 0; pairsIndex < tfTotal; pairsIndex++)
      {
         FbStatus[cc][pairsIndex] = fbnoarrow;
      }//for (int pairsIndex = 0; pairsIndex <= tfTotal; pairsIndex++)      
   }//for (int cc = 0; cc < NoOfPairs; cc++)

   //ChaosStatus
   ArrayResize(ChaosStatus, NoOfPairs);
   for (int cc = 0; cc < NoOfPairs; cc++)
   {
      for (int pairsIndex = 0; pairsIndex < tfTotal; pairsIndex++)
      {
         ChaosStatus[cc][pairsIndex] = chaosno;
      }//for (int pairsIndex = 0; pairsIndex <= tfTotal; pairsIndex++)      
   }//for (int cc = 0; cc < NoOfPairs; cc++)

   //ChaosD1
   ArrayResize(ChaosD1, NoOfPairs);
   for (int cc = 0; cc < NoOfPairs; cc++)
   {
      for (int pairsIndex = 0; pairsIndex < tfTotal; pairsIndex++)
      {
         ChaosD1[cc][pairsIndex] = chaosno;
      }//for (int pairsIndex = 0; pairsIndex <= tfTotal; pairsIndex++)      
   }//for (int cc = 0; cc < NoOfPairs; cc++)

   //ChaosD2
   ArrayResize(ChaosD2, NoOfPairs);
   for (int cc = 0; cc < NoOfPairs; cc++)
   {
      for (int pairsIndex = 0; pairsIndex < tfTotal; pairsIndex++)
      {
         ChaosD2[cc][pairsIndex] = chaosno;
      }//for (int pairsIndex = 0; pairsIndex <= tfTotal; pairsIndex++)      
   }//for (int cc = 0; cc < NoOfPairs; cc++)

   //ChaosD3
   ArrayResize(ChaosD3, NoOfPairs);
   for (int cc = 0; cc < NoOfPairs; cc++)
   {
      for (int pairsIndex = 0; pairsIndex < tfTotal; pairsIndex++)
      {
         ChaosD3[cc][pairsIndex] = chaosno;
      }//for (int pairsIndex = 0; pairsIndex <= tfTotal; pairsIndex++)      
   }//for (int cc = 0; cc < NoOfPairs; cc++)

   //ChaosD4
   ArrayResize(ChaosD4, NoOfPairs);
   for (int cc = 0; cc < NoOfPairs; cc++)
   {
      for (int pairsIndex = 0; pairsIndex < tfTotal; pairsIndex++)
      {
         ChaosD4[cc][pairsIndex] = chaosno;
      }//for (int pairsIndex = 0; pairsIndex <= tfTotal; pairsIndex++)      
   }//for (int cc = 0; cc < NoOfPairs; cc++)

   //ChaosD5
   ArrayResize(ChaosD5, NoOfPairs);
   for (int cc = 0; cc < NoOfPairs; cc++)
   {
      for (int pairsIndex = 0; pairsIndex < tfTotal; pairsIndex++)
      {
         ChaosD5[cc][pairsIndex] = chaosno;
      }//for (int pairsIndex = 0; pairsIndex <= tfTotal; pairsIndex++)      
   }//for (int cc = 0; cc < NoOfPairs; cc++)

   //TmsStatus
   ArrayResize(TmsStatus, NoOfPairs);
   for (int cc = 0; cc < NoOfPairs; cc++)
   {
      for (int pairsIndex = 0; pairsIndex < tfTotal; pairsIndex++)
      {
         TmsStatus[cc][pairsIndex] = tmsno;
      }//for (int pairsIndex = 0; pairsIndex <= tfTotal; pairsIndex++)      
   }//for (int cc = 0; cc < NoOfPairs; cc++)

   //TmsD1
   ArrayResize(TmsD1, NoOfPairs);
   for (int cc = 0; cc < NoOfPairs; cc++)
   {
      for (int pairsIndex = 0; pairsIndex < tfTotal; pairsIndex++)
      {
         TmsD1[cc][pairsIndex] = tmsno;
      }//for (int pairsIndex = 0; pairsIndex <= tfTotal; pairsIndex++)      
   }//for (int cc = 0; cc < NoOfPairs; cc++)

   //TmsD2
   ArrayResize(TmsD2, NoOfPairs);
   for (int cc = 0; cc < NoOfPairs; cc++)
   {
      for (int pairsIndex = 0; pairsIndex < tfTotal; pairsIndex++)
      {
         TmsD2[cc][pairsIndex] = tmsno;
      }//for (int pairsIndex = 0; pairsIndex <= tfTotal; pairsIndex++)      
   }//for (int cc = 0; cc < NoOfPairs; cc++)

   //TmsD3
   ArrayResize(TmsD3, NoOfPairs);
   for (int cc = 0; cc < NoOfPairs; cc++)
   {
      for (int pairsIndex = 0; pairsIndex < tfTotal; pairsIndex++)
      {
         TmsD3[cc][pairsIndex] = tmsno;
      }//for (int pairsIndex = 0; pairsIndex <= tfTotal; pairsIndex++)      
   }//for (int cc = 0; cc < NoOfPairs; cc++)

   //TmsD4
   ArrayResize(TmsD4, NoOfPairs);
   for (int cc = 0; cc < NoOfPairs; cc++)
   {
      for (int pairsIndex = 0; pairsIndex < tfTotal; pairsIndex++)
      {
         TmsD4[cc][pairsIndex] = tmsno;
      }//for (int pairsIndex = 0; pairsIndex <= tfTotal; pairsIndex++)      
   }//for (int cc = 0; cc < NoOfPairs; cc++)

   //TmsD5
   ArrayResize(TmsD5, NoOfPairs);
   for (int cc = 0; cc < NoOfPairs; cc++)
   {
      for (int pairsIndex = 0; pairsIndex < tfTotal; pairsIndex++)
      {
         TmsD5[cc][pairsIndex] = tmsno;
      }//for (int pairsIndex = 0; pairsIndex <= tfTotal; pairsIndex++)      
   }//for (int cc = 0; cc < NoOfPairs; cc++)

   //TmsD6
   ArrayResize(TmsD6, NoOfPairs);
   for (int cc = 0; cc < NoOfPairs; cc++)
   {
      for (int pairsIndex = 0; pairsIndex < tfTotal; pairsIndex++)
      {
         TmsD6[cc][pairsIndex] = tmsno;
      }//for (int pairsIndex = 0; pairsIndex <= tfTotal; pairsIndex++)      
   }//for (int cc = 0; cc < NoOfPairs; cc++)

   //MaTrend
   ArrayResize(MaTrend, NoOfPairs);
   for (int cc = 0; cc < NoOfPairs; cc++)
   {
      for (int pairsIndex = 0; pairsIndex < tfTotal; pairsIndex++)
      {
         MaTrend[cc][pairsIndex] = manotrend;//CHS Amendment
      }//for (int pairsIndex = 0; pairsIndex <= tfTotal; pairsIndex++)      
   }//for (int cc = 0; cc < NoOfPairs; cc++)

   //HgiStatus
   ArrayResize(HgiStatus, NoOfPairs);
   for (int cc = 0; cc < NoOfPairs; cc++)
   {
      for (int pairsIndex = 0; pairsIndex < tfTotal; pairsIndex++)
      {
         HgiStatus[cc][pairsIndex] = hginoarrow;//CHS Amendment
      }//for (int pairsIndex = 0; pairsIndex <= tfTotal; pairsIndex++)      
   }//for (int cc = 0; cc < NoOfPairs; cc++)

   //PeakyMarketDirection
   ArrayResize(PeakyMarketDirection, NoOfPairs);
   for (int cc = 0; cc < NoOfPairs; cc++)
   {
      for (int pairsIndex = 0; pairsIndex < tfTotal; pairsIndex++)
      {
         PeakyMarketDirection[cc][pairsIndex] = peakynodirection;//CHS Amendment
      }//for (int pairsIndex = 0; pairsIndex <= tfTotal; pairsIndex++)      
   }//for (int cc = 0; cc < NoOfPairs; cc++)

   //SsColour
   ArrayResize(SsColour, NoOfPairs);
   for (int cc = 0; cc < NoOfPairs; cc++)
   {
      for (int pairsIndex = 0; pairsIndex < tfTotal; pairsIndex++)
      {
         SsColour[cc][pairsIndex] = white;//CHS Amendment
      }//for (int pairsIndex = 0; pairsIndex <= tfTotal; pairsIndex++)      
   }//for (int cc = 0; cc < NoOfPairs; cc++)


   //Tradeability
   ArrayResize(Tradeability, NoOfPairs);
   for (int cc = 0; cc < NoOfPairs; cc++)
   {
      for (int pairsIndex = 0; pairsIndex < tfTotal; pairsIndex++)
      {
         Tradeability[cc][pairsIndex] = tradable;
      }//for (int pairsIndex = 0; pairsIndex <= tfTotal; pairsIndex++)      
   }//for (int cc = 0; cc < NoOfPairs; cc++)

      
   //Safety adapted from my shells
   ArrayResize(TimeToStartTrading, NoOfPairs);//Time to start trading
   ArrayInitialize(TimeToStartTrading, 0);//Time to start trading

   //Spread filter.
   ArrayResize(RunningTotalOfSpreads, NoOfPairs);
   ArrayInitialize(RunningTotalOfSpreads, 0);
   ArrayResize(AverageSpread, NoOfPairs);
   ArrayInitialize(AverageSpread, 0);

}//void PopulateTheArrays()


void ExtractPairs()
{
   // Cleanup first
   InputString=PairsToTrade;
   CleanUpInputString();
   
   // Extract the number of paraaters passed by the user
   CalculatePairsPassed();
   
   //Cater for a symbol suffix
   string AddChar = StringSubstr(Symbol(),6,4);
   
   // Resize the arrays appropriately
   ArrayResize(TradePair, NoOfPairs);
   

   
   int Index = 0;//For searching InputString
   int LastIndex = 0;//Points the the most recent Index
   
   for (int cc = 0; cc < NoOfPairs; cc ++)
   {
      Index = StringFind(InputString, ",",LastIndex);
      if (Index > -1)
      {
         TradePair[cc] = StringSubstr(InputString, LastIndex,Index-LastIndex);
         TradePair[cc] = StringTrimLeft(TradePair[cc]);
         TradePair[cc] = StringTrimRight(TradePair[cc]);
         TradePair[cc] = StringConcatenate(TradePair[cc], AddChar);

         LastIndex = Index+1;
           
      }//if (Index > -1)            
   }//for (int cc; cc<NoOfPairs; cc ++)

}//End void ExtractPairs()

void CleanUpInputString()
{
   // Does any tidying up of the user inputs
   
   //Remove unwanted spaces
   InputString = StringTrimLeft(InputString);
   InputString = StringTrimRight(InputString);

   //Add final comma if ommitted by user
   if (StringSubstr(InputString, StringLen(InputString)-1) != ",") 
      InputString = StringConcatenate(InputString,",");
      
   
}//void CleanUpInputString

void CalculatePairsPassed()
{
   // Calculates the numbers of paramaters passed in LongMagicNumber and TradeComment.
   
   int Index = 0;//For searching NoTradePairs
   int LastIndex = 0;//Points the the most recent Index
   NoOfPairs = 0;
   
   while(Index > -1)
   {
      Index = StringFind(InputString, ",",LastIndex);
      if (Index > -1)
      {
         NoOfPairs ++;
         LastIndex = Index+1;            
      }//if (Index > -1)
   }//while(int cc > -1)
   
}//End void CalculatePairsPassed()

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

string GetTimeFrameAsString(int tf)
{

   //Convert the time frame into a crapT4 style display
   if (tf == PERIOD_M1)
      return(" M1 ");
   if (tf == PERIOD_M5)
      return(" M5 ");
   if (tf == PERIOD_M15)
      return(" M15 ");
   if (tf == PERIOD_M30)
      return(" M30 ");
   if (tf == PERIOD_H1)
      return(" H1 ");
   if (tf == PERIOD_H4)
      return(" H4 ");
   if (tf == PERIOD_D1)
      return(" D1 ");
   if (tf == PERIOD_W1)
      return(" W1 ");
   if (tf == PERIOD_MN1)
      return(" MN1 ");

   //Default
   return("");
   
}//string GetTimeFrameAsString(int tf)


void DisplayUserFeedback()
{
   string text = "";
   int cc = 0;
   
 
//   ************************* added for OBJ_LABEL
   DisplayCount = 1;
   removeAllObjects();
//   *************************

 
   ScreenMessage = "";
   //ScreenMessage = StringConcatenate(ScreenMessage,Gap + NL);
   SM(NL);
   
   SM("Updates for this EA are to be found at http://www.stevehopwoodforex.com"+NL);
   SM("Feeling generous? Help keep the coder going with a small Paypal donation to pianodoodler@hotmail.com"+NL);
   SM("Broker time = "+TimeToStr(TimeCurrent(),TIME_DATE|TIME_SECONDS)+": Local time = "+TimeToStr(TimeLocal(),TIME_DATE|TIME_SECONDS)+NL);
   SM(version+NL);

   if(MarginMessage!="") 
      SM(MarginMessage+NL);

   //Trading hours
   if(!TradeTimeOk)
   {
      SM(NL);
      SM("----------OUTSIDE TRADING HOURS. Will continue to monitor opent trades.----------"+NL+NL);
   }//if (!TradeTimeOk)
   if(tradingHoursDisplay!="") SM("Trading hours: "+tradingHoursDisplay+NL);
   else SM("24 hour trading: "+NL);

   //Profit targets
   text = "";
   text = "Total cash profit so far today = " + DoubleToStr(ProfitToday, 2) + "    ";
   if (!CloseEnough(DailyProfitTarget, 0) )
      text = text + "Daily profit target = " + DoubleToStr(DailyProfitTarget, 2) + "    ";
   if (!CloseEnough(WeeklyProfitTarget, 0) )
      text = text + "Weekly profit target = " + DoubleToStr(WeeklyProfitTarget, 2);
   if (text != "")
      SM(text + NL);
   if (TradingDoneForTheDay)
      if (!TradingDoneForTheWeek)
         SM("I have reached my daily profit target and will not start any more cycles today." + NL);      
   if (TradingDoneForTheWeek)
      SM("I have reached my weekly profit target and will not start any more cycles this week." + NL);      

   if (TradingPairs >= MaxPairsAllowed)
      SM("You are at your maximum pairs allowed to trade on this account. I shall not initiate any new trading cycles.");
   
      if (AllTradesBelongToBasket)
      SM("I am looking for the opportunity to close all trades on the platform at your chosen profit target. Upl is currently "
          + DoubleToStr(EntirePositionCashUpl, 2) + NL);
   
   if (!ShowChartFeedback)
      return;
   
   SM(NL);

   if (SymbolTradesBelongToBasket)
      SM("Symbol Basket Target set at: " + (string)SymbolBasketProfitTarget + NL);
   if (AllTradesBelongToBasket)
      SM("All Basket Target set at: " + (string)AllBasketProfitTarget + NL);


   DisplayMatrix();
   
   Comment(ScreenMessage);
   
}//End void DisplayUserFeedback()


void DisplayMatrix()
{
   int TextXPos=0;
   int TextYPos=DisplayY+DisplayCount*(int)(fontSise*1.5)+(int)(fontSise*3);
   
   int TPLength=(int)(fontSise*5.50);
   int RFLength=(int)(fontSise*3.50);
   int TRLength=(int)(fontSise*3.50);
   int PKLength=(int)(fontSise*3.50);
   int SSLength=(int)(fontSise*3.50);
   int MALength=(int)(fontSise*3.50);
   int FBLength=(int)(fontSise*3.50);
   int HGLength=(int)(fontSise*3.50);
   int SWLength=(int)(fontSise*3.50);
   int SPLength=(int)(fontSise*6.50);
   int NFLength=(int)(fontSise*3.50);
   int CHLength=(int)(fontSise*2.00);
   int TMLength=(int)(fontSise*2.00);
   
   
   //Display Headers
   
   TextXPos=DisplayX;
   DisplayTextLabel("Close all",TextXPos,TextYPos,ANCHOR_LEFT_UPPER,"CLOSE");
   DisplayTextLabel("subcharts",TextXPos,TextYPos+(int)(fontSise*1.5),ANCHOR_LEFT_UPPER,"CLOSE");
   
   TextXPos+=TPLength;
   TextXPos+=fontSise*2;
      
      
   if (UseRangingFilter)
   {
      DisplayTextLabel("RF",TextXPos,TextYPos+(int)(fontSise*1.5));
      TextXPos+=RFLength;
   }
   if (UsePeakyOnOwnTimeFrame)
   {
      DisplayTextLabel("PK",TextXPos,TextYPos+(int)(fontSise*1.5));
      TextXPos+=PKLength;
   }
   if (UseSuperSlopeOnOwnTimeFrame)
   {
      DisplayTextLabel("SS",TextXPos,TextYPos+(int)(fontSise*1.5));
      TextXPos+=SSLength;
   }
   if (UseMaOnOwnTimeFrame)
   {
      DisplayTextLabel("MA",TextXPos,TextYPos+(int)(fontSise*1.5));
      TextXPos+=MALength;
   }
   if (UseFBOnOwnTimeFrame)
   {
      DisplayTextLabel("FB",TextXPos,TextYPos+(int)(fontSise*1.5));
      TextXPos+=FBLength;
   }
   if (UseHGIOnOwnTimeFrame)
   {
      DisplayTextLabel("HG",TextXPos,TextYPos+(int)(fontSise*1.5));
      TextXPos+=HGLength;
   }
    if (UseChaosOnOwnTimeFrame)
    {
         DisplayTextLabel("CH",TextXPos,TextYPos+(int)(fontSise*1.5));
         TextXPos+=CHLength;
		if (ShowChaosDimensions)
		{
			DisplayTextLabel("D1",TextXPos,TextYPos+(int)(fontSise*1.5));
			TextXPos+=CHLength;
			DisplayTextLabel("D2",TextXPos,TextYPos+(int)(fontSise*1.5));
			TextXPos+=CHLength;
			DisplayTextLabel("D3",TextXPos,TextYPos+(int)(fontSise*1.5));
			TextXPos+=CHLength;
			DisplayTextLabel("D4",TextXPos,TextYPos+(int)(fontSise*1.5));
			TextXPos+=CHLength;
			DisplayTextLabel("D5",TextXPos,TextYPos+(int)(fontSise*1.5));
			TextXPos+=CHLength;
		}
	}
    if (UseTMSOnOwnTimeFrame)
    {
         DisplayTextLabel("TMS",TextXPos,TextYPos+(int)(fontSise*1.5));
         TextXPos+=TMLength;
		if (ShowTMSDimensions)
		{
			DisplayTextLabel("D1",TextXPos,TextYPos+(int)(fontSise*1.5));
			TextXPos+=TMLength;
			DisplayTextLabel("D2",TextXPos,TextYPos+(int)(fontSise*1.5));
			TextXPos+=TMLength;
			DisplayTextLabel("D3",TextXPos,TextYPos+(int)(fontSise*1.5));
			TextXPos+=TMLength;
			DisplayTextLabel("D4",TextXPos,TextYPos+(int)(fontSise*1.5));
			TextXPos+=TMLength;
//			DisplayTextLabel("D5",TextXPos,TextYPos+(int)(fontSise*1.5));
//			TextXPos+=TMLength;
//			DisplayTextLabel("D6",TextXPos,TextYPos+(int)(fontSise*1.5));
//			TextXPos+=TMLength;
		}
	}
   if (UseNewsFilter)
   {
      DisplayTextLabel("NF",TextXPos,TextYPos+(int)(fontSise*1.5));
      TextXPos+=NFLength;
   }
   
   for (int dd = 0; dd < ArraySize(TimeFrames); dd++)
   {
      TextXPos+=fontSise*2;
      string tf = StringTrimLeft(GetTimeFrameAsString(TimeFrames[dd]));
      DisplayTextLabel(tf+"->",TextXPos,TextYPos);

      if (MinTradeDistanceSingleTimeframePips[dd]>0)
      {
         DisplayTextLabel("MD",TextXPos,TextYPos+(int)(fontSise*1.5));
         TextXPos+=TRLength;
      }
      if (UsePeakyOnTradingTimeFrame)
      {
         DisplayTextLabel("PK",TextXPos,TextYPos+(int)(fontSise*1.5));
         TextXPos+=PKLength;
      }
      if (UseSuperSlopeOnTradingTimeFrame)
      {
         DisplayTextLabel("SS",TextXPos,TextYPos+(int)(fontSise*1.5));
         TextXPos+=SSLength;
      }
      if (UseMaOnTradingTimeFrame)
      {
         DisplayTextLabel("MA",TextXPos,TextYPos+(int)(fontSise*1.5));
         TextXPos+=MALength;
      }
      if (UseFBOnTradingTimeFrame)
      {
         DisplayTextLabel("FB",TextXPos,TextYPos+(int)(fontSise*1.5));
         TextXPos+=FBLength;
      }
    if (UseChaosOnTradingTimeFrame)
    {
         DisplayTextLabel("CH",TextXPos,TextYPos+(int)(fontSise*1.5));
         TextXPos+=CHLength;
		if (ShowChaosDimensions)
		{
			DisplayTextLabel("D1",TextXPos,TextYPos+(int)(fontSise*1.5));
			TextXPos+=CHLength;
			DisplayTextLabel("D2",TextXPos,TextYPos+(int)(fontSise*1.5));
			TextXPos+=CHLength;
			DisplayTextLabel("D3",TextXPos,TextYPos+(int)(fontSise*1.5));
			TextXPos+=CHLength;
			DisplayTextLabel("D4",TextXPos,TextYPos+(int)(fontSise*1.5));
			TextXPos+=CHLength;
			DisplayTextLabel("D5",TextXPos,TextYPos+(int)(fontSise*1.5));
			TextXPos+=CHLength;
		}
	}
    if (UseTMSOnTradingTimeFrame)
    {
         DisplayTextLabel("TM",TextXPos,TextYPos+(int)(fontSise*1.5));
         TextXPos+=TMLength;
		if (ShowTMSDimensions)
		{
			DisplayTextLabel("D1",TextXPos,TextYPos+(int)(fontSise*1.5));
			TextXPos+=TMLength;
			DisplayTextLabel("D2",TextXPos,TextYPos+(int)(fontSise*1.5));
			TextXPos+=TMLength;
			DisplayTextLabel("D3",TextXPos,TextYPos+(int)(fontSise*1.5));
			TextXPos+=TMLength;
			DisplayTextLabel("D4",TextXPos,TextYPos+(int)(fontSise*1.5));
			TextXPos+=TMLength;
//			DisplayTextLabel("D5",TextXPos,TextYPos+(int)(fontSise*1.5));
//			TextXPos+=TMLength;
//			DisplayTextLabel("D6",TextXPos,TextYPos+(int)(fontSise*1.5));
//			TextXPos+=TMLength;
		}
	}
      if (UseHGIOnTradingTimeFrame)
      {
         DisplayTextLabel("HG",TextXPos,TextYPos+(int)(fontSise*1.5));
         TextXPos+=HGLength;
      }
   }//for (int dd = 0; dd < ArraySize(TimeFrames); dd++)
   
   TextXPos+=fontSise*6;
   DisplayTextLabel(" Long",TextXPos,TextYPos,ANCHOR_RIGHT_UPPER);
   DisplayTextLabel("Swap",TextXPos,TextYPos+(int)(fontSise*1.5),ANCHOR_RIGHT_UPPER);
   TextXPos+=SWLength;
   DisplayTextLabel(" Short",TextXPos,TextYPos,ANCHOR_RIGHT_UPPER);
   DisplayTextLabel("Swap",TextXPos,TextYPos+(int)(fontSise*1.5),ANCHOR_RIGHT_UPPER);
   TextXPos+=SWLength;
   
   TextXPos+=fontSise*3;
   DisplayTextLabel("Actual",TextXPos,TextYPos,ANCHOR_RIGHT_UPPER);
   DisplayTextLabel("Spread",TextXPos,TextYPos+(int)(fontSise*1.5),ANCHOR_RIGHT_UPPER);
   TextXPos+=SPLength;
   DisplayTextLabel("Average",TextXPos,TextYPos,ANCHOR_RIGHT_UPPER);
   DisplayTextLabel("Spread",TextXPos,TextYPos+(int)(fontSise*1.5),ANCHOR_RIGHT_UPPER);

   TextYPos+=3*(int)(fontSise*1.5);
   
   //Display trade pairs 
        
   for (int cc = 0; cc <= ArraySize(TradePair) - 1; cc++)
   {
      TextXPos=DisplayX;
      GetBasics(TradePair[cc]);
      DisplayTextLabel(TradePair[cc],TextXPos,TextYPos);
      TextXPos+=TPLength;

      TextXPos+=fontSise*2;
      
      if (UseRangingFilter)
      {
         DisplayTextLabel(OTFRangingDirection[cc],TextXPos,TextYPos);
         TextXPos+=RFLength;
      }
      if (UsePeakyOnOwnTimeFrame)
      {
         DisplayTextLabel(OTFPeakyMarketDirection[cc],TextXPos,TextYPos);
         TextXPos+=PKLength;
      }
      if (UseSuperSlopeOnOwnTimeFrame)
      {
         DisplayTextLabel(OTFSsColour[cc],TextXPos,TextYPos);
         TextXPos+=SSLength;
      }
      if (UseMaOnOwnTimeFrame)
      {
         DisplayTextLabel(OTFMaTrend[cc],TextXPos,TextYPos);
         TextXPos+=MALength;
      }
      if (UseFBOnOwnTimeFrame)
      {
         DisplayTextLabel(OTFFbStatus[cc],TextXPos,TextYPos);
         TextXPos+=FBLength;
      }
      if (UseHGIOnOwnTimeFrame)
      {
         DisplayTextLabel(OTFHgiStatus[cc],TextXPos,TextYPos);
         TextXPos+=HGLength;
      }
         if (UseChaosOnOwnTimeFrame)
         {
            DisplayTextLabel(OTFChaosStatus[cc],TextXPos,TextYPos);
            TextXPos+=CHLength;
			   if (ShowChaosDimensions)
			   {
				DisplayTextLabel(OTFChaosD1[cc],TextXPos,TextYPos);
				TextXPos+=CHLength;
				DisplayTextLabel(OTFChaosD2[cc],TextXPos,TextYPos);
				TextXPos+=CHLength;
				DisplayTextLabel(OTFChaosD3[cc],TextXPos,TextYPos);
				TextXPos+=CHLength;
				DisplayTextLabel(OTFChaosD4[cc],TextXPos,TextYPos);
				TextXPos+=CHLength;
				DisplayTextLabel(OTFChaosD5[cc],TextXPos,TextYPos);
				TextXPos+=CHLength;
			   }
         }
         if (UseTMSOnOwnTimeFrame)
         {
            DisplayTextLabel(OTFTmsStatus[cc],TextXPos,TextYPos);
            TextXPos+=TMLength;
			   if (ShowTMSDimensions)
			   {
				DisplayTextLabel(OTFTmsD1[cc],TextXPos,TextYPos);
				TextXPos+=TMLength;
				DisplayTextLabel(OTFTmsD2[cc],TextXPos,TextYPos);
				TextXPos+=TMLength;
				DisplayTextLabel(OTFTmsD3[cc],TextXPos,TextYPos);
				TextXPos+=TMLength;
				DisplayTextLabel(OTFTmsD4[cc],TextXPos,TextYPos);
				TextXPos+=TMLength;
//				DisplayTextLabel(OTFTmsD5[cc],TextXPos,TextYPos);
//				TextXPos+=TMLength;
//				DisplayTextLabel(OTFTmsD6[cc],TextXPos,TextYPos);
//				TextXPos+=TMLength;
			   }
         }
	  
      if (UseNewsFilter)
      {
         DisplayTextLabel(NewsStatus[cc],TextXPos,TextYPos);
         TextXPos+=NFLength;
      }
      
      for (int dd = 0; dd < ArraySize(TimeFrames); dd++)
      {
         TextXPos+=fontSise*2;
         
         if (MinTradeDistanceSingleTimeframePips[dd]>0)
         {
            DisplayTextLabel(Tradeability[cc][dd],TextXPos,TextYPos,ANCHOR_LEFT_UPPER,TradePair[cc],TimeFrames[dd]);
            TextXPos+=TRLength;
         }
         if (UsePeakyOnTradingTimeFrame)
         {
            DisplayTextLabel(PeakyMarketDirection[cc][dd],TextXPos,TextYPos,ANCHOR_LEFT_UPPER,TradePair[cc],TimeFrames[dd]);
            TextXPos+=PKLength;
         }
         if (UseSuperSlopeOnTradingTimeFrame)
         {
            DisplayTextLabel(SsColour[cc][dd],TextXPos,TextYPos,ANCHOR_LEFT_UPPER,TradePair[cc],TimeFrames[dd]);
            TextXPos+=SSLength;
         }
         if (UseMaOnTradingTimeFrame)
         {
            DisplayTextLabel(MaTrend[cc][dd],TextXPos,TextYPos,ANCHOR_LEFT_UPPER,TradePair[cc],TimeFrames[dd]);
            TextXPos+=MALength;
         }
         if (UseFBOnTradingTimeFrame)
         {
            DisplayTextLabel(FbStatus[cc][dd],TextXPos,TextYPos,ANCHOR_LEFT_UPPER,TradePair[cc],TimeFrames[dd]);
            TextXPos+=FBLength;
         }
         if (UseChaosOnTradingTimeFrame)
         {
            DisplayTextLabel(ChaosStatus[cc][dd],TextXPos,TextYPos,ANCHOR_LEFT_UPPER,TradePair[cc],TimeFrames[dd]);
            TextXPos+=CHLength;
			   if (ShowChaosDimensions)
			   {
				DisplayTextLabel(ChaosD1[cc][dd],TextXPos,TextYPos,ANCHOR_LEFT_UPPER,TradePair[cc],TimeFrames[dd]);
				TextXPos+=CHLength;
				DisplayTextLabel(ChaosD2[cc][dd],TextXPos,TextYPos,ANCHOR_LEFT_UPPER,TradePair[cc],TimeFrames[dd]);
				TextXPos+=CHLength;
				DisplayTextLabel(ChaosD3[cc][dd],TextXPos,TextYPos,ANCHOR_LEFT_UPPER,TradePair[cc],TimeFrames[dd]);
				TextXPos+=CHLength;
				DisplayTextLabel(ChaosD4[cc][dd],TextXPos,TextYPos,ANCHOR_LEFT_UPPER,TradePair[cc],TimeFrames[dd]);
				TextXPos+=CHLength;
				DisplayTextLabel(ChaosD5[cc][dd],TextXPos,TextYPos,ANCHOR_LEFT_UPPER,TradePair[cc],TimeFrames[dd]);
				TextXPos+=CHLength;
			   }
         }
         if (UseTMSOnTradingTimeFrame)
         {
            DisplayTextLabel(TmsStatus[cc][dd],TextXPos,TextYPos,ANCHOR_LEFT_UPPER,TradePair[cc],TimeFrames[dd]);
            TextXPos+=TMLength;
			   if (ShowTMSDimensions)
			   {
				DisplayTextLabel(TmsD1[cc][dd],TextXPos,TextYPos,ANCHOR_LEFT_UPPER,TradePair[cc],TimeFrames[dd]);
				TextXPos+=TMLength;
				DisplayTextLabel(TmsD2[cc][dd],TextXPos,TextYPos,ANCHOR_LEFT_UPPER,TradePair[cc],TimeFrames[dd]);
				TextXPos+=TMLength;
				DisplayTextLabel(TmsD3[cc][dd],TextXPos,TextYPos,ANCHOR_LEFT_UPPER,TradePair[cc],TimeFrames[dd]);
				TextXPos+=TMLength;
				DisplayTextLabel(TmsD4[cc][dd],TextXPos,TextYPos,ANCHOR_LEFT_UPPER,TradePair[cc],TimeFrames[dd]);
				TextXPos+=TMLength;
//				DisplayTextLabel(TmsD5[cc][dd],TextXPos,TextYPos,ANCHOR_LEFT_UPPER,TradePair[cc],TimeFrames[dd]);
//				TextXPos+=TMLength;
//				DisplayTextLabel(TmsD6[cc][dd],TextXPos,TextYPos,ANCHOR_LEFT_UPPER,TradePair[cc],TimeFrames[dd]);
//				TextXPos+=TMLength;
			   }
         }
         if (UseHGIOnTradingTimeFrame)
         {
            DisplayTextLabel(HgiStatus[cc][dd],TextXPos,TextYPos,ANCHOR_LEFT_UPPER,TradePair[cc],TimeFrames[dd]);
            TextXPos+=HGLength;
         }
      }//for (int dd = 0; dd < ArraySize(TimeFrames); dd++)

      TextXPos+=fontSise*5;
      DisplayTextLabel(DoubleToStr(longSwap, 2),TextXPos,TextYPos,ANCHOR_RIGHT_UPPER);
      TextXPos+=SWLength;
      DisplayTextLabel(DoubleToStr(shortSwap, 2),TextXPos,TextYPos,ANCHOR_RIGHT_UPPER);
      TextXPos+=SWLength;
      
      TextXPos+=fontSise*3;
      DisplayTextLabel(DoubleToStr(spread, 1) + " pips",TextXPos,TextYPos,ANCHOR_RIGHT_UPPER);
      TextXPos+=SPLength;
      DisplayTextLabel(DoubleToStr(AverageSpread[cc], 1) + " pips",TextXPos,TextYPos,ANCHOR_RIGHT_UPPER);
      TextXPos+=SPLength;
      
      TextYPos+=(int)(fontSise*LineSpacing);
   }//for (cc = 0; cc <= ArraySize(TradePair) -1; cc++)

   //Display Footer
   
   TextXPos=DisplayX;


   for (int dd = 0; dd < ArraySize(TimeFrames); dd++)
   {
      if (TradeAsBasket[dd])
      DisplayTextLabel("BasketTP "+ GetTimeFrameAsString(TimeFrames[dd]) +": " + (string)TradeBasketProfitTarget[dd],TextXPos,TextYPos);

      if (MinTradeDistanceSingleTimeframePips[dd]>0) TextXPos+=TRLength;
      if (UsePeakyOnTradingTimeFrame) TextXPos+=PKLength;
      if (UseSuperSlopeOnTradingTimeFrame) TextXPos+=SSLength;
      if (UseMaOnTradingTimeFrame) TextXPos+=MALength;
      if (UseFBOnTradingTimeFrame) TextXPos+=FBLength;
      if (UseChaosOnTradingTimeFrame) TextXPos+=CHLength;
		if (ShowChaosDimensions)
		{
			TextXPos+=CHLength;
			TextXPos+=CHLength;
			TextXPos+=CHLength;
			TextXPos+=CHLength;
			TextXPos+=CHLength;
		}
      if (UseTMSOnTradingTimeFrame) TextXPos+=TMLength;
		if (ShowTMSDimensions)
		{
			TextXPos+=TMLength;
			TextXPos+=TMLength;
			TextXPos+=TMLength;
			TextXPos+=TMLength;
//			TextXPos+=TMLength;
//			TextXPos+=TMLength;
		}
      if (UseHGIOnTradingTimeFrame)  TextXPos+=HGLength;
   }//for (int dd = 0; dd < ArraySize(TimeFrames); dd++)


  
}//End void DisplayMatrix()


void DisplayTextLabel(string text, int xpos, int ypos, ENUM_ANCHOR_POINT anchor=ANCHOR_LEFT_UPPER, string pair="", int tf=0)
{
   color UPColor=Lime;
   color DNColor=Red;
   color NOColor=Gray;
   color TRColor=White;
   color CBColor=Cyan; 
   
   color scol=colour;
   
   if (text=="Long"||text=="Blue"||text=="Up arrow"||text=="Up wave"||text=="Up rad ar"||text=="Up trend") scol=UPColor;
   else if (text=="Short"||text=="Red"||text=="Dn arrow"||text=="Dn wave"||text=="Dn rad ar"||text=="Dn trend"||text=="News") scol=DNColor;
   else if (text=="None"||text=="White"||text=="No signal"||text=="No trend"||text=="Range"||text=="Too near"||text=="No news")scol=NOColor;
   else if (text=="Trend"||text=="Tradable") scol=TRColor;
   else if (text=="Close all"||text=="subcharts") scol=CBColor;

   if (text=="Long"||text=="Blue"||text=="Up arrow"||text=="Up") text="á";
   else if (text=="Short"||text=="Red"||text=="Dn arrow"||text=="Down") text="â";
   else if (text=="Up wave"||text=="Dn wave"||text=="Yellow range wave") text="h";
   else if (text=="Tradable long"||text=="Tradable short"||text=="Tradable") text="ü";
   else if (text=="No signal"||text=="White"||text=="Not tradable"||text=="Too near")text="û";

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
//   ************************* added for OBJ_LABEL
void removeAllObjects()
{
   for(int i = ObjectsTotal() - 1; i >= 0; i--)
   if (StringFind(ObjectName(i),"OAM-",0) > -1) 
      ObjectDelete(ObjectName(i));
}//End void removeAllObjects()
//   ************************* added for OBJ_LABEL


void GetHighestAndLowestClose(string symbol, int tf, int cc)
{

   HighestHigh = iHighest(symbol, tf, MODE_HIGH, CandleRange, 1);
   LowestLow = iLowest(symbol, tf, MODE_LOW, CandleRange, 1);

   //Read the highest and lowest Close prices
   HighestHighValue = iClose(symbol, tf, HighestHigh);
   LowestLowValue = iClose(symbol, tf, LowestLow);

}//End  of void GetHighestAndLowestClose(string symbol, int tf)

void CountOpenTrades(string symbol, int magic, int index)
{
   //Some of these may be redundant.
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
   PendingTradesTotal = 0;
   TicketNo=-1;OpenTrades=0;
   LatestTradeTime=0; EarliestTradeTime=TimeCurrent();//More specific times are in each individual section
   LatestTradeTicketNo=-1; EarliestTradeTicketNo=-1;
   PipsUpl=0;//For keeping track of the pips PipsUpl of multi-trade/hedged positions
   CashUpl=0;//For keeping track of the cash PipsUpl of multi-trade/hedged positions
   
   //FIFO ticket resize
   ArrayResize(FifoTicket, 0);

   //Recovery
   ArrayResize(BuyTickets, 0);
   ArrayInitialize(BuyTickets, 0);
   ArrayResize(SellTickets, 0);
   ArrayInitialize(SellTickets, 0);
   
   BuysInRecovery = false; SellsInRecovery = false;
   bool BuyLoser = false, SellLoser = false;//For working out if the position is in Recovery.
      
   
   //All trades on the platform belong to the same basket
   EntirePositionCashUpl = 0;

   
   int type;//Saves the OrderType() for consulatation later in the function
   int as = 0;
   
   if (OrdersTotal() == 0) return;
   
   //Iterating backwards through the orders list caters more easily for closed trades than iterating forwards
   for (int cc = OrdersTotal() - 1; cc >= 0; cc--)
   {
      bool TradeWasClosed = false;//See 'check for possible trade closure'

      //Ensure the trade is still open
      if (!OrderSelect(cc, SELECT_BY_POS, MODE_TRADES) ) continue;
      
      EntirePositionCashUpl+= OrderProfit() + OrderSwap() + OrderCommission();
      
      //Ensure the EA 'owns' this trade
      if (OrderSymbol() != symbol) continue;
      if (OrderMagicNumber() != magic) continue;
      
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
      
      
      //Store the latest trade sent. Most of my EA's only need this final ticket number as either they are single trade
      //bots or the last trade in the sequence is the important one. Adapt this code for your own use.
      if (TicketNo  == -1) TicketNo = OrderTicket();
      
      //Store ticket numbers for FIFO
      ArrayResize(FifoTicket, OpenTrades + 1);
      FifoTicket[OpenTrades] = OrderTicket();
      
      OpenTrades++;
      
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
         
         //Buys
         if (OrderType() == OP_BUY)
         {
            //Recovery
            ArrayResize(BuyTickets, MarketBuysCount + 1);
            BuyTickets[MarketBuysCount] = OrderTicket();
            //In case the position needs Recovery
            if ( (OrderProfit() + OrderSwap() + OrderCommission()) < 0 )
               BuyLoser = true;

            BuyOpen = true;
            BuyTicketNo = OrderTicket();
            MarketBuysCount++;
            BuyPipsUpl+= pips;
            BuyCashUpl+= (OrderProfit() + OrderSwap() + OrderCommission()); 
            
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
            //Recovery
            ArrayResize(SellTickets, MarketSellsCount + 1);
            SellTickets[MarketSellsCount] = OrderTicket();
            //In case the position needs Recovery
            if ( (OrderProfit() + OrderSwap() + OrderCommission()) < 0 )
               SellLoser = true;

            SellOpen = true;
            SellTicketNo = OrderTicket();
            MarketSellsCount++;
            SellPipsUpl+= pips;
            SellCashUpl+= (OrderProfit() + OrderSwap() + OrderCommission()); 
            
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
         PendingTradesTotal++;
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
      
      
      
      
      
      //if (CloseEnough(OrderStopLoss(), 0) && !CloseEnough(StopLoss, 0)) InsertStopLoss(OrderTicket());
      //if (CloseEnough(OrderTakeProfit(), 0) && !CloseEnough(TakeProfit, 0)) InsertTakeProfit(OrderTicket() );
      
      
      TradeWasClosed = LookForTradeClosure(OrderTicket() );
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
         TradeManagementModule(OrderTicket(), index );
      }//if (OrderProfit() > 0) 
      
               
      
   }//for (int cc = OrdersTotal() - 1; cc <= 0; c`c--)
   
   //Sort ticket numbers for FIFO
   if (ArraySize(FifoTicket) > 0)
      ArraySort(FifoTicket, WHOLE_ARRAY, 0, MODE_DESCEND);
      
   //Are we in Recovery?
   if (UseRecovery[index] )
   {
      if (MarketBuysCount >= TradesToConstituteRecovery[index])//Minimum trades to constitute Recovery
         if (BuyLoser)//One of them must be a loser or we do not need Recovery
            BuysInRecovery = true;
            
      if (MarketSellsCount >= TradesToConstituteRecovery[index])//Minimum trades to constitute Recovery
         if (SellLoser)//One of them must be a loser or we do not need Recovery
            SellsInRecovery = true;
            
   }//if (UseRecovery[index] )
   

}//End void CountOpenTrades(string symbol, int magic, int index)

int ExtractIndexFromTradeComment(string symbol, string comment)
{

   //Return the the time frame index from the order comment passed by LookForTradeClosure()
   
   if (comment ==  TradeCommentPrefix + "-" + Trade1TradeComment)
      return(0);
      
   if (comment ==  TradeCommentPrefix + "-" + Trade2TradeComment)
      return(1);
      
   if (comment ==  TradeCommentPrefix + "-" + Trade3TradeComment)
      return(2);
      
   if (comment ==  TradeCommentPrefix + "-" + Trade4TradeComment)
      return(3);
      
   //User has buggered up the order comment, so drive him nuts with an alert.
   Alert(symbol, ". You have buggered up your trade comments so PoS cannot work properly. Read the damn user guide and stop being an asshole. Cretins fail when trading Forex.");
   return(5);//Impossible value

}//End int ExtractIndexFromTradeComment(string symbol, string comment)


int ExtractTradePairIndex(string symbol, int tf)
{
   
   //Extract the trade pair index
   int cc = 0;
   for (cc = 0; cc < ArraySize(TradePair); cc++)
   {
      if (symbol == TradePair[cc])
         break;
   }//for (cc = 0; cc < ArraySize(TradePair); cc++)
   
   
   return(cc);

}//End int ExtractTradePairIndex(string symbol, int tf)


bool LookForTradeClosure(int ticket)
{
   //Close the trade if the close conditions are met.
   //Called from within CountOpenTrades(). Returns true if a close is needed and succeeds, so that COT can increment cc,
   //else returns false
   
   if (!BetterOrderSelect(ticket, SELECT_BY_TICKET, MODE_TRADES) ) 
      return(true);
   if (BetterOrderSelect(ticket, SELECT_BY_TICKET, MODE_TRADES) )
      if (OrderCloseTime() > 0)
          return(true);
   
   bool CloseThisTrade = false;
   
   //We need to know which time frame this trade belongs to
   int cc = ExtractIndexFromTradeComment(OrderSymbol(), OrderComment() );


   //Opposite direction HGI
   int pairIndex = 0;
   if (CloseOnOppositeFB[cc] || CloseOnOppositeHGI[cc] || CloseOnOppositeMA[cc] || CloseOnNews || CloseOnOppositeChaos[cc] || CloseOnOppositeTMS[cc])
      pairIndex = ExtractTradePairIndex(OrderSymbol(), cc);

//   CountOpenTrades(OrderSymbol(), MagicNumbers[cc], cc);
         
            
   ///////////////////////////////////////////////////////////////////////////////////////////////////////////
//   if (OrderType() == OP_BUYSTOP)
//   {
   if (OrderType() == OP_BUY || OrderType() == OP_BUYSTOP)
   {
      //TP
      if (bid >= OrderTakeProfit() ) 
         if (!CloseEnough(OrderTakeProfit(), 0) ) 
            CloseThisTrade = true;
      //SL
      if (bid <= OrderStopLoss() )
       if (!CloseEnough(OrderStopLoss(), 0) ) 
         CloseThisTrade = true;

      //Opposite direction PK
      if (OrderType() == OP_BUYSTOP)
         if (BuyStopsCount < 2)
            if (UsePeakyOnTradingTimeFrame || UsePeakyOnOwnTimeFrame)
               if (CloseStopOrderOnOppositePK[cc])
                  if (PeakyMarketDirection[pairIndex][cc] == peakyshortdirection)
                  {
                     Alert(OrderSymbol(), " ", OrderComment(), " Opposite PK ", OrderSymbol(), " ", OrderComment(), " BUYSTOP trade should have closed.");
                     CloseThisTrade = true;
                  }

      //Opposite direction SS
      if (OrderType() == OP_BUYSTOP)
         if (BuyStopsCount < 2)
            if (UseSuperSlopeOnTradingTimeFrame || UseSuperSlopeOnOwnTimeFrame)
               if (CloseStopOrderOnOppositeSS[cc])
                  if (SsColour[pairIndex][cc] == red || SsColour[pairIndex][cc] == white)
                  {
                     Alert(OrderSymbol(), " ", OrderComment(), " Opposite SS ", OrderSymbol(), " ", OrderComment(), " BUYSTOP trade should have closed.");
                     CloseThisTrade = true;
                  }

      //Opposite direction FB
      if (CloseOnOppositeFB[cc])
         if (!OnlyCloseWhenSuperSlopeAgrees[cc] || SsColour[pairIndex][cc] == red)
            if (!OnlyCloseWhenPeakyAgrees[cc] || PeakyMarketDirection[pairIndex][cc] == peakyshortdirection)
               if (!OnlyCloseWhenBothSuperSlopeAndPeakyAgrees[cc] || (SsColour[pairIndex][cc] == red && PeakyMarketDirection[pairIndex][cc] == peakyshortdirection) )
                  if (FbStatus[pairIndex][cc] == fbdownarrow)
                  {
                     Alert(OrderSymbol(), " ", OrderComment(), " Opposite FB ", OrderSymbol(), " ", OrderComment(), " BUY trades should have closed.");
                     CloseThisTrade = true;
                  }

      //Opposite direction MA
      if (CloseOnOppositeMA[cc])
         if (!OnlyCloseWhenSuperSlopeAgrees[cc] || SsColour[pairIndex][cc] == red)
            if (!OnlyCloseWhenPeakyAgrees[cc] || PeakyMarketDirection[pairIndex][cc] == peakyshortdirection)
               if (!OnlyCloseWhenBothSuperSlopeAndPeakyAgrees[cc] || (SsColour[pairIndex][cc] == red && PeakyMarketDirection[pairIndex][cc] == peakyshortdirection) )
                  if (MaTrend[pairIndex][cc] == maDown)
                  {
                     Alert(OrderSymbol(), " ", OrderComment(), " Opposite MA ", OrderSymbol(), " ", OrderComment(), " BUY trades should have closed.");
                     CloseThisTrade = true;
                  }

      //Opposite direction HGI
      if (CloseOnOppositeHGI[cc])
         if (!OnlyCloseWhenSuperSlopeAgrees[cc] || SsColour[pairIndex][cc] == red)
            if (!OnlyCloseWhenPeakyAgrees[cc] || PeakyMarketDirection[pairIndex][cc] == peakyshortdirection)
               if (!OnlyCloseWhenBothSuperSlopeAndPeakyAgrees[cc] || (SsColour[pairIndex][cc] == red && PeakyMarketDirection[pairIndex][cc] == peakyshortdirection) )
                  if ((TrendTradingAllowed && HgiStatus[pairIndex][cc] == hgidownarrow) ||
                      (BlueWaveTradingAllowed && HgiStatus[pairIndex][cc] == hgidownwave) ||
                      (RadTradingAllowed && HgiStatus[pairIndex][cc] == hgidownradarrow) )
                  {
                     Alert(OrderSymbol(), " ", OrderComment(), " Opposite HGI ", OrderSymbol(), " ", OrderComment(), " BUY trades should have closed.");
                     CloseThisTrade = true;
                  }
      //Opposite direction Chaos
      if (CloseOnOppositeChaos[cc])
         if (!OnlyCloseWhenSuperSlopeAgrees[cc] || SsColour[pairIndex][cc] == red)
            if (!OnlyCloseWhenPeakyAgrees[cc] || PeakyMarketDirection[pairIndex][cc] == peakyshortdirection)
               if (!OnlyCloseWhenBothSuperSlopeAndPeakyAgrees[cc] || (SsColour[pairIndex][cc] == red && PeakyMarketDirection[pairIndex][cc] == peakyshortdirection) )
                  if (ChaosStatus[pairIndex][cc] == chaosdn)
         {
            Alert(OrderSymbol(), " ", OrderComment(), " Opposite Chaos ", OrderSymbol(), " ", OrderComment(), " BUY trades should have closed.");
            CloseThisTrade = true;
         }

      //Opposite direction Tms
      if (CloseOnOppositeTMS[cc])
         if (!OnlyCloseWhenSuperSlopeAgrees[cc] || SsColour[pairIndex][cc] == red)
            if (!OnlyCloseWhenPeakyAgrees[cc] || PeakyMarketDirection[pairIndex][cc] == peakyshortdirection)
               if (!OnlyCloseWhenBothSuperSlopeAndPeakyAgrees[cc] || (SsColour[pairIndex][cc] == red && PeakyMarketDirection[pairIndex][cc] == peakyshortdirection) )
                  if (TmsStatus[pairIndex][cc] == tmsdn)
         {
            Alert(OrderSymbol(), " ", OrderComment(), " Opposite TMS ", OrderSymbol(), " ", OrderComment(), " BUY trades should have closed.");
            CloseThisTrade = true;
         }

      //Close on news
         if (CloseOnNews)
         {
               int numGVs = GlobalVariablesTotal();
               for (int n=0; n<numGVs; n++)
               {
                  string globalvarname = GlobalVariableName(n);
                  if (StringFind(globalvarname,"NEWS", 0) > -1)
                  {
                     string newsline = globalvarname;
                     const ushort comma = StringGetChar(",",0);
                     StringSplit( newsline, comma, newsarray);
                     int timetillnews = StrToInteger(newsarray[3]) - (int) TimeLocal();
                     if (StringFind(OrderSymbol(),newsarray[1], 0) > -1)
                     {
                        if (CloseOnHighImpactNews && StringFind(newsarray[2],"High", 0) > -1) 
                        {
                           if (timetillnews!=0 && timetillnews < CloseSecondsBeforeNews)
                           {
                              Alert(OrderSymbol(), " ", OrderComment(), "incoming " + newsarray[1] + " High Impact News. ", OrderSymbol(), " ", OrderComment(), " BUY trades should have closed.");
                              CloseThisTrade = true;
                           }
                        if (CloseOnMediumImpactNews && StringFind(newsarray[2],"Medium", 0) > -1) 
                           if (timetillnews!=0 && timetillnews < CloseSecondsBeforeNews)
                           {
                              Alert(OrderSymbol(), " ", OrderComment(), "incoming " + newsarray[1] + " Medium Impact News. ", OrderSymbol(), " ", OrderComment(), " BUY trades should have closed.");
                              CloseThisTrade = true;
                           }
                        if (CloseOnLowImpactNews && StringFind(newsarray[2],"Low", 0) > -1)
                           if (timetillnews!=0 && timetillnews < CloseSecondsBeforeNews)
                           {
                              Alert(OrderSymbol(), " ", OrderComment(), "incoming " + newsarray[1] + " Low Impact News. ", OrderSymbol(), " ", OrderComment(), " BUY trades should have closed.");
                              CloseThisTrade = true;
                           }
                        }
                     }
                  }//if (StringFind(globalvarname,"NEWS", 0) > -1) {
               }// for
            }//if (CloseOnNews)

   }//if (OrderType() == OP_BUY || OrderType() == OP_BUYSTOP)
   
   
   ///////////////////////////////////////////////////////////////////////////////////////////////////////////
   if (OrderType() == OP_SELL || OrderType() == OP_SELLSTOP)
   {
      //TP
      if (ask <= OrderTakeProfit() )
         if (!CloseEnough(OrderTakeProfit(), 0) ) 
            CloseThisTrade = true;
      //SL
      if (ask >= OrderStopLoss() ) 
         if (!CloseEnough(OrderStopLoss(), 0) ) 
            CloseThisTrade = true;

      //Opposite direction PK
      if (OrderType() == OP_SELLSTOP)
         if (SellStopsCount < 2)
            if (UsePeakyOnTradingTimeFrame || UsePeakyOnOwnTimeFrame)
               if (CloseStopOrderOnOppositePK[cc])
                  if (PeakyMarketDirection[pairIndex][cc] == peakylongdirection)
                  {
                     Alert(OrderSymbol(), " ", OrderComment(), " Opposite PK ", OrderSymbol(), " ", OrderComment(), " SELLSTOP trade should have closed.");
                     CloseThisTrade = true;
                  }

      //Opposite direction SS
      if (OrderType() == OP_SELLSTOP)
         if (SellStopsCount < 2)
            if (UseSuperSlopeOnTradingTimeFrame || UseSuperSlopeOnOwnTimeFrame)
               if (CloseStopOrderOnOppositeSS[cc])
                  if (SsColour[pairIndex][cc] == blue || SsColour[pairIndex][cc] == white)
                  {
                     Alert(OrderSymbol(), " ", OrderComment(), " Opposite SS ", OrderSymbol(), " ", OrderComment(), " SELLSTOP trade should have closed.");
                     CloseThisTrade = true;
                  }

      //Opposite direction FB
      if (CloseOnOppositeFB[cc])
         if (!OnlyCloseWhenSuperSlopeAgrees[cc] || SsColour[pairIndex][cc] == blue)
            if (!OnlyCloseWhenPeakyAgrees[cc] || PeakyMarketDirection[pairIndex][cc] == peakylongdirection)
               if (!OnlyCloseWhenBothSuperSlopeAndPeakyAgrees[cc] || (SsColour[pairIndex][cc] == blue && PeakyMarketDirection[pairIndex][cc] == peakylongdirection) )
                  if (FbStatus[pairIndex][cc] == fbuparrow)
                      {
                        Alert(OrderSymbol(), " ", OrderComment(), " Opposite FB ", OrderSymbol(), " ", OrderComment(), " SELL trades should have closed.");
                        CloseThisTrade = true;
                      }     

      //Opposite direction MA
      if (CloseOnOppositeMA[cc])
         if (!OnlyCloseWhenSuperSlopeAgrees[cc] || SsColour[pairIndex][cc] == blue)
            if (!OnlyCloseWhenPeakyAgrees[cc] || PeakyMarketDirection[pairIndex][cc] == peakylongdirection)
               if (!OnlyCloseWhenBothSuperSlopeAndPeakyAgrees[cc] || (SsColour[pairIndex][cc] == blue && PeakyMarketDirection[pairIndex][cc] == peakylongdirection) )
                  if (MaTrend[pairIndex][cc] == maUp)
                      {
                        Alert(OrderSymbol(), " ", OrderComment(), " Opposite MA ", OrderSymbol(), " ", OrderComment(), " SELL trades should have closed.");
                        CloseThisTrade = true;
                      }     

      //Opposite direction HGI
      if (CloseOnOppositeHGI[cc])
         if (!OnlyCloseWhenSuperSlopeAgrees[cc] || SsColour[pairIndex][cc] == blue)
            if (!OnlyCloseWhenPeakyAgrees[cc] || PeakyMarketDirection[pairIndex][cc] == peakylongdirection)
              if (!OnlyCloseWhenBothSuperSlopeAndPeakyAgrees[cc] || (SsColour[pairIndex][cc] == blue && PeakyMarketDirection[pairIndex][cc] == peakylongdirection) )
                  if ((TrendTradingAllowed && HgiStatus[pairIndex][cc] == hgiuparrow) ||
                      (BlueWaveTradingAllowed && HgiStatus[pairIndex][cc] == hgiupwave) ||
                      (RadTradingAllowed && HgiStatus[pairIndex][cc] == hgiupradarrow) )
                      {
                        Alert(OrderSymbol(), " ", OrderComment(), " Opposite HGI ", OrderSymbol(), " ", OrderComment(), " SELL trades should have closed.");
                        CloseThisTrade = true;
                      }     

      //Opposite direction Chaos
      if (CloseOnOppositeChaos[cc])
         if (!OnlyCloseWhenSuperSlopeAgrees[cc] || SsColour[pairIndex][cc] == blue)
            if (!OnlyCloseWhenPeakyAgrees[cc] || PeakyMarketDirection[pairIndex][cc] == peakylongdirection)
               if (!OnlyCloseWhenBothSuperSlopeAndPeakyAgrees[cc] || (SsColour[pairIndex][cc] == blue && PeakyMarketDirection[pairIndex][cc] == peakylongdirection) )
                  if (ChaosStatus[pairIndex][cc] == chaosup)
                  {
                     Alert(OrderSymbol(), " ", OrderComment(), " Opposite Chaos ", OrderSymbol(), " ", OrderComment(), " SELL trades should have closed.");
                     CloseThisTrade = true;
                  }

      //Opposite direction TMS
      if (CloseOnOppositeTMS[cc])
         if (!OnlyCloseWhenSuperSlopeAgrees[cc] || SsColour[pairIndex][cc] == blue)
            if (!OnlyCloseWhenPeakyAgrees[cc] || PeakyMarketDirection[pairIndex][cc] == peakylongdirection)
               if (!OnlyCloseWhenBothSuperSlopeAndPeakyAgrees[cc] || (SsColour[pairIndex][cc] == blue && PeakyMarketDirection[pairIndex][cc] == peakylongdirection) )
                  if (TmsStatus[pairIndex][cc] == tmsup)
                  {
                  Alert(OrderSymbol(), " ", OrderComment(), " Opposite TMS ", OrderSymbol(), " ", OrderComment(), " SELL trades should have closed.");
                  CloseThisTrade = true;
                  }

      //Close on news
         if (CloseOnNews)
         {
            int numGVs = GlobalVariablesTotal();
            for (int n=0; n<numGVs; n++)
            {
               int timetillnews=0;
               string globalvarname = GlobalVariableName(n);
               if (StringFind(globalvarname,"NEWS", 0) > -1)
               {
                  string newsline = globalvarname;
                  const ushort comma = StringGetChar(",",0);
                  StringSplit( newsline, comma, newsarray);
                  timetillnews = StrToInteger(newsarray[3]) - (int) TimeLocal();
                  if (StringFind(OrderSymbol(),newsarray[1], 0) > -1)
                  {
                     if (CloseOnHighImpactNews && StringFind(newsarray[2],"High", 0) > -1)
                     {
                        if (timetillnews!=0 && timetillnews < CloseSecondsBeforeNews)
                        {
                           Alert(OrderSymbol(), " ", OrderComment(), " incoming " + newsarray[1] + " High Impact News. ", OrderSymbol(), " ", OrderComment(), " SELL trades should have closed.");
                           CloseThisTrade = true;
                        }
                     }
                     if (CloseOnMediumImpactNews && StringFind(newsarray[2],"Medium", 0) > -1) 
                     {
                        if (timetillnews!=0 && timetillnews < CloseSecondsBeforeNews)
                        {
                           Alert(OrderSymbol(), " ", OrderComment(), " incoming " + newsarray[1] + " Medium Impact News. ", OrderSymbol(), " ", OrderComment(), " SELL trades should have closed.");
                           CloseThisTrade = true;
                        }
                     }
                     if (CloseOnLowImpactNews && StringFind(newsarray[2],"Low", 0) > -1) 
                     {   
                        if (timetillnews!=0 && timetillnews < CloseSecondsBeforeNews)
                        {
                           Alert(OrderSymbol(), " ", OrderComment(), " incoming " + newsarray[1] + " Low Impact News. ", OrderSymbol(), " ", OrderComment(), " SELL trades should have closed.");
                           CloseThisTrade = true;
                        }
                     }
                  }
               }
            }
         }//if (CloseOnNews)
      
   }//if (OrderType() == OP_SELL || OrderType() == OP_SELLSTOP)
   
   ///////////////////////////////////////////////////////////////////////////////////////////////////////////
   if (CloseThisTrade)
   {
      bool result = false;
      
      if (OrderType() < 2)//Market orders
         result = CloseOrder(ticket, __FUNCTION__,  OrderLots(), ocm);
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

////////////////////////////////////////////////////////////////////////////////////////

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

bool MarginCheck()
{

   EnoughMargin = true;//For user display
   MarginMessage = "";
   
   if (AccountMargin() > 0)
   {
      
      double ml = NormalizeDouble(AccountEquity() / AccountMargin() * 100, 2);
      if (ml < MinimumMarginPercent)
      {
         MarginMessage = StringConcatenate("There is insufficient margin percent to allow trading. ", DoubleToStr(ml, 2), "%");
         return(false);
      }//if (ml < FkMinimumMarginPercent)
   }//if (UseForexKiwi && AccountMargin() > 0)
   
  
   //Got this far, so there is sufficient margin for trading
   return(true);
}//End bool MarginCheck()


//Changed by TS
bool DistanceOK(string symbol,int magic,double price,double distance)
{
   for (int cc=0; cc<OrdersTotal(); cc++)
   {
      //Ensure the trade is still open
      if (!OrderSelect(cc, SELECT_BY_POS, MODE_TRADES)) 
         continue;
      
      //Ensure the EA 'owns' this trade
      if (OrderSymbol()!=symbol) 
         continue;
      
      if (OrderMagicNumber()==magic && MathAbs(price-OrderOpenPrice())<distance)
         return false;
      
      if (OrderMagicNumber()!=magic && MathAbs(price-OrderOpenPrice())<MinTradeDistanceAcrossTimeframesPips/factor)
         return false;
   }
   
   return(true);
   
}//End bool DistanceOK(double distance)


void LookForTradingOpportunities(string symbol, int cc)
{
   int type = 0;//The OrderType() to send to SendSingleTrade()
   bool SendTrade = false;//Will be 'true' if there is a trade to be sent.
   double SendLots = Lot;
   bool result = false;
   double price = 0;//Stop order price.
   bool SendLong = false, SendShort = false;//Set to 'true' if there is a trade to send.
   double stop = 0, take = 0;//Stop loss and take profit.
   double targetHigh = 0, targetLow = 0;//For the hilo of market trades open   

                
   if (BuySignal)
      if (TradeLong)
         SendLong = true;
      
   if (SellSignal)
      if (TradeShort)
         SendShort = true;   
   
   //A check that we are not already at our pairs limit and we are not already trading this pair on another time frame. Abort the trade if so.
   //We want trading on different time frames if we are already trading a pair, hence the AreWeAlreadyTradingThisPair(string symbol) function.
   if (SendLong || SendShort)
      if (OrdersTotal() > 0)
      {
         CountCurrentlyTradingPairs();
         if (TradingPairs >= MaxPairsAllowed && !AreWeAlreadyTradingThisPair(symbol))
            return;   
      }//if (OrdersTotal() > 0)
      
      
   
   //Set up a buy trade.
   if (SendLong)
   {
      //Stop orders
      price = NormalizeDouble(ask + (TradeBuffers[cc] / factor), digits);//Stop order price
      if(UsePriceChecks && !CheckOrderOpenPrice(symbol, TimeFrames[cc], OP_BUYSTOP, price, false))//if check fails, calculate closest valid open price
         //price = NormalizeDouble(ask+(1/factor), digits);//Stop order price
         return;
      type = OP_BUYSTOP;
      //Immediate market orders
      if (ImmediateMarketTrades[cc] )
      {
         price = ask;
         type = OP_BUY;
      }//if (ImmediateMarketTrades[cc] )
      
      stop = CalculateStopLoss(OP_BUY, price, symbol, cc);
      take = CalculateTakeProfit(OP_BUY, price, symbol, cc);
      SendTrade = true;

   }//if (SendLong)


   //Set up a sell trade.
   if (SendShort)
   {
      //Stop orders
      price = NormalizeDouble(bid - (TradeBuffers[cc] / factor), digits);//Stop order price
      if(UsePriceChecks && !CheckOrderOpenPrice(symbol, TimeFrames[cc], OP_SELLSTOP, price, false))//if check fails, calculate closest valid open price
         //price = NormalizeDouble(bid-(1/factor), digits);//Stop order price 
         return;
      type = OP_SELLSTOP;
      //Immediate market orders
      if (ImmediateMarketTrades[cc] )
      {
         price = bid;
         type = OP_SELL;
      }//if (ImmediateMarketTrades[cc] )
      
      stop = CalculateStopLoss(OP_SELL, price, symbol, cc);
      take = CalculateTakeProfit(OP_SELL, price, symbol, cc);
      SendTrade = true;

   }//if (SendShort)

   
   //Send the trade
   //Changed by TS
   if (SendTrade && DistanceOK(symbol,MagicNumbers[cc],price,DistanceBetweenTrades))
   {
      result = SendSingleTrade(symbol, type, TradeComments[cc], SendLots, price, stop, take, MagicNumbers[cc]);

      //Safety adapted from my shells
      //Time to start trading
      int tfIndex = ExtractIndexFromTradeComment(symbol, TradeComments[cc]);
      int pairsIndex = ExtractTradePairIndex(symbol, tfIndex);
      if (result)
      {
            if (TakeSnapshots)
            {
               DisplayUserFeedback();
               TakeChartSnapshot(TicketNo, tfIndex, " open");
            }//if (TakeSnapshots)
            if (EmailTradeNotification) SendMail("Trade sent ", symbol + IntegerToString(type) + "trade at " + TimeToStr(TimeCurrent(), TIME_DATE|TIME_MINUTES));
            if (AlertPush) AlertNow(WindowExpertName() + " " + symbol + " " + IntegerToString(type) + " " + DoubleToStr(price, Digits) );
         TimeToStartTrading[pairsIndex][tfIndex] = TimeCurrent() + (PostTradeAttemptWaitSeconds);
      }//if (result)
         
      //Safety adapted from my shells
      if (!result)
         TimeToStartTrading[pairsIndex][tfIndex] = 0;//Force a retry at the next OnTimer//Time to start trading

      //Avoid duplicate trading
      if (result)
         AlreadyTradedThisPrice = true;
         
   }//if (SendTrade)
   
}//End void LookForTradingOpportunities(string symbol, int cc)

void AlertNow(string sAlertMsg)
{

   if(AlertPush)
   {
      if(IsTesting()) Print("Message to Push: ",TimeToStr(Time[0],TIME_DATE|TIME_SECONDS)+" "+sAlertMsg);
      SendNotification(StringConcatenate(TimeToStr(Time[0],TIME_DATE|TIME_SECONDS)," "+sAlertMsg));
   }//if (AlertPush) 
   return;
}//End void AlertNow(string sAlertMsg) 

bool CheckOrderOpenPrice(string mySymbol, int myTimeFrame, int type, double price, bool modify)
{
//Added by Gary to deal with error 130. Cheers Gary.

   string myTF=GetTimeFrameAsString(myTimeFrame);
   string strF;
   int    stopsLevel=(int)SymbolInfoInteger(mySymbol,SYMBOL_TRADE_STOPS_LEVEL);   
   bool   check=false;
//--- check the order type
   switch(type)
     {
      //--- Buy operation
      case  0: //ORDER_TYPE_BUY:
        {
         //--- check the open price
         if(!modify) check=(price==ask); //can't modify buy
         
         if(PrintFailedChecks && !check)
           {
            strF=StringFormat("%%s %%s  For order %%s   Open Price=%%.%df must be equal to %%.%df",digits,digits);
            PrintFormat(strF,mySymbol,myTF,"Buy",price,ask);
           }
         //--- return the result of checking
         return(check);
        }
      //--- Sell operation
      case  1: //ORDER_TYPE_SELL:
        {
         //--- check the open price
         if(!modify) check=(price==bid); //can't modify sell
         
         if(PrintFailedChecks && !check)
           {
            strF=StringFormat("%%s %%s  For order %%s   Open Price=%%.%df must be equal to %%.%df",digits,digits);
            PrintFormat(strF,mySymbol,myTF,"Sell",price,bid);
           }
         //--- return the result of checking
         return(check);
        }
      break;
      //--- BuyLimit pending order
      case  2: //ORDER_TYPE_BUY_LIMIT:
        {
         //--- check the open price
         if(modify) check=(ask-price>=stopsLevel/factor);
         else       check=(price<ask);
         
         if(PrintFailedChecks && !check)
           {
            if(modify)
              {
               strF=StringFormat("%%s %%s  For order %%s   Open Price=%%.%df must be less than %%.%df and (Price-Ask=%%.%df >= STOPS_LEVEL=%%.%df)",digits,digits,digits,digits);
               PrintFormat(strF,mySymbol,myTF,"BuyLimit",price,ask-(stopsLevel/factor),ask-price,stopsLevel/factor);
               }
             else
               {
                strF=StringFormat("%%s %%s  For order %%s   Open Price=%%.%df must be less than %%.%df",digits,digits);
                PrintFormat(strF,mySymbol,myTF,"BuyLimit",price,ask);
               }
           }
         //--- return the result of checking
         return(check);
        }
      //--- SellLimit pending order
      case  3: //ORDER_TYPE_SELL_LIMIT:
        {
         //--- check the open price
         if(modify) check=(price-bid>=stopsLevel/factor);
         else       check=(price>bid);
         
         if(PrintFailedChecks && !check)
           {
            if(modify)
              {
               strF=StringFormat("%%s %%s  For order %%s   Open Price=%%.%df must be greater than %%.%df and (Price-Bid=%%.%df  >=  STOPS_LEVEL=%%.%df)",digits,digits,digits,digits);
               PrintFormat(strF,mySymbol,myTF,"SellLimit",price,bid+(stopsLevel/factor),price-bid,stopsLevel/factor);
              }
            else
              {
               strF=StringFormat("%%s %%s  For order %%s   Open Price=%%.%df must be greater than %%.%df",digits,digits);
               PrintFormat(strF,mySymbol,myTF,"SellLimit",price,bid);
              }
           }
         //--- return the result of checking
         return(check);
        }
      break;
      //--- BuyStop pending order
      case  4: //ORDER_TYPE_BUY_STOP:
        {
         //--- check the open price
         if(modify) check=(price-ask>=stopsLevel/factor);
         else       check=(price>ask);
         
         if(PrintFailedChecks && !check)
           {
            if(modify)
              {
               strF=StringFormat("%%s %%s  For order %%s   Open Price=%%.%df must be greater than %%.%df and (Price-Ask=%%.%df  >=  STOPS_LEVEL=%%.%df)",digits,digits,digits,digits);
               PrintFormat(strF,mySymbol,myTF,"BuyStop",price,ask+(stopsLevel/factor),price-ask,stopsLevel/factor);
               }
             else
               {
                strF=StringFormat("%%s %%s  For order %%s   Open Price=%%.%df must be greater than %%.%df",digits,digits);
                PrintFormat(strF,mySymbol,myTF,"BuyStop",price,ask);
               }
            }
         //--- return the result of checking
         return(check);
        }
      //--- SellStop pending order
      case  5: //ORDER_TYPE_SELL_STOP:
        {
         //--- check the open price
         if(modify) check=(bid-price>=stopsLevel/factor);
         else       check=(price<bid);
         
         if(PrintFailedChecks && !check)
           {
            if(modify)
              {
               strF=StringFormat("%%s %%s  For order %%s   Open Price=%%.%df must be less than %%.%df and (Bid-Price=%%.%df  >=  STOPS_LEVEL=%%.%df)",digits,digits,digits,digits);
               PrintFormat(strF,mySymbol,myTF,"SellStop",price,bid-(stopsLevel/factor),bid-price,stopsLevel/factor);
               }
             else
               {
                strF=StringFormat("%%s %%s  For order %%s   Open Price=%%.%df must be less than %%.%df",digits,digits);
                PrintFormat(strF,mySymbol,myTF,"SellStop",price,bid);
               }
          }
         //--- return the result of checking
         return(check);
        }
      break;
     }
//---
   return false;
}//CheckOrderOpenPrice()

double CalculateRangeHigh(string symbol, int timeframe, int cc)
{
   int        i,ii,iii,x=0,xx=0,ShiftBar;
   double     Hi,Lo;
   double     RangeAvg, RangeHigh, RangeLow;
   double     ARg,Range; 
   ShiftBar   = iBarShift(symbol,timeframe,iTime(symbol,timeframe,0));
   if (timeframe > 1440) ShiftBar = 0;
   Hi         = iHigh (symbol,timeframe,ShiftBar);
   Lo         = iLow  (symbol,timeframe,ShiftBar); 
   Range      = ((Hi - Lo)/Point)/factor; 
   
   if (timeframe <= 1440)
   {
      ARg = 0; for(i=1; i<=AverageRangeTakeProfitPeriod[cc]; i++)
      {
         if (TimeDayOfWeek(iTime(symbol,timeframe,i))!=0) {
         ARg = ARg + iHigh(symbol,timeframe,i)- iLow(symbol,timeframe,i);}
         else {x=x+1;}
      }
      for(ii=i+1; ii<i+x+1; ii++) 
      {
         if (TimeDayOfWeek(iTime(symbol,timeframe,ii))!=0) {       
            ARg = ARg + iHigh(symbol,timeframe,ii)- iLow(symbol,timeframe,ii);}
         else {xx=xx+1;}       
      }      
      for(iii=ii+1; iii<ii+xx+1; iii++) 
      {
         ARg = ARg + iHigh(symbol,timeframe,iii)- iLow(symbol,timeframe,iii);
      }                     
   }
   else
   {
      ARg = 0; for(i=1; i<=AverageRangeTakeProfitPeriod[cc]; i++)
      {
         ARg = ARg + iHigh(symbol,timeframe,i)- iLow(symbol,timeframe,i);
      }
   }  

      RangeAvg = NormalizeDouble(ARg/AverageRangeTakeProfitPeriod[cc],4);                
      RangeHigh =  RangeAvg + iLow(symbol,timeframe,ShiftBar);
      RangeLow  = -RangeAvg + iHigh(symbol,timeframe,ShiftBar);
      if (Hi - Lo > RangeAvg)
         {            
            if ((MarketInfo(symbol,MODE_BID)) >= Hi - (Hi-Lo)/2) {RangeHigh = Lo + RangeAvg; RangeLow  = Lo;}
            else {RangeHigh  = Hi; RangeLow = Hi - RangeAvg;}
         }
   return(RangeHigh);
}

double CalculateRangeLow(string symbol, int timeframe, int cc)
{
   int        i,ii,iii,x=0,xx=0,ShiftBar;
   double     Hi,Lo;
   double     RangeAvg, RangeHigh, RangeLow;
   double     ARg,Range; 
   ShiftBar   = iBarShift(symbol,timeframe,iTime(symbol,timeframe,0));
   if (timeframe > 1440) ShiftBar = 0;
   Hi         = iHigh (symbol,timeframe,ShiftBar);
   Lo         = iLow  (symbol,timeframe,ShiftBar); 
   Range      = ((Hi - Lo)/Point)/factor; 
   
   if (timeframe <= 1440)
   {
      ARg = 0; for(i=1; i<=AverageRangeTakeProfitPeriod[cc]; i++)
      {
         if (TimeDayOfWeek(iTime(symbol,timeframe,i))!=0) {
         ARg = ARg + iHigh(symbol,timeframe,i)- iLow(symbol,timeframe,i);}
         else {x=x+1;}
      }
      for(ii=i+1; ii<i+x+1; ii++) 
      {
         if (TimeDayOfWeek(iTime(symbol,timeframe,ii))!=0) {       
            ARg = ARg + iHigh(symbol,timeframe,ii)- iLow(symbol,timeframe,ii);}
         else {xx=xx+1;}       
      }      
      for(iii=ii+1; iii<ii+xx+1; iii++) 
      {
         ARg = ARg + iHigh(symbol,timeframe,iii)- iLow(symbol,timeframe,iii);
      }                     
   }
   else
   {
      ARg = 0; for(i=1; i<=AverageRangeTakeProfitPeriod[cc]; i++)
      {
         ARg = ARg + iHigh(symbol,timeframe,i)- iLow(symbol,timeframe,i);
      }
   }  
      RangeAvg = NormalizeDouble(ARg/AverageRangeTakeProfitPeriod[cc],4);                
      RangeHigh =  RangeAvg + iLow(symbol,timeframe,ShiftBar);
      RangeLow  = -RangeAvg + iHigh(symbol,timeframe,ShiftBar);
      if (Hi - Lo > RangeAvg)
      {            
         if ((MarketInfo(symbol,MODE_BID)) >= Hi - (Hi-Lo)/2){ RangeHigh = Lo + RangeAvg; RangeLow  = Lo;}
         else {RangeHigh  = Hi; RangeLow = Hi - RangeAvg;}
      }
   return(RangeLow);
}

double CalculateTakeProfit(int type, double price, string symbol, int cc)
{
   //Returns the stop loss for use in LookForTradingOpps and InsertMissingStopLoss
   double take = 0;//Take profit to return.
   double takeprofit = TakeProfits[cc];
   double RangeHigh;
   double RangeLow;

   if (type == OP_BUY)
   {
      if (UseAverageRangeTakeProfit[cc])
      {
         RangeHigh = CalculateRangeHigh(symbol, AverageRangeTakeProfitTimeFrame[cc], cc);
         if (!CloseEnough(RangeHigh, 0) )
         { 
            take = NormalizeDouble(RangeHigh + (AverageRangeTakeProfitPipsShift[cc] / factor),digits);
         } 
      } 
      else
      {
         if (!CloseEnough(takeprofit, 0) )
         {
           take = NormalizeDouble(price + (takeprofit / factor),digits);
         }//if (!CloseEnough(takeprofit, 0) )
      }
   }//if (type == OP_BUY)
   
   if (type == OP_SELL)
   {
      if (UseAverageRangeTakeProfit[cc])
      {
         RangeLow = CalculateRangeLow(symbol, AverageRangeTakeProfitTimeFrame[cc], cc);
         if (!CloseEnough(RangeLow, 0) )
         {
            take = NormalizeDouble(RangeLow + (AverageRangeTakeProfitPipsShift[cc] / factor),digits);
         }
      }
      else
      {
         if (!CloseEnough(takeprofit, 0) )
         {
            take = NormalizeDouble(price - (takeprofit / factor),digits);
         }//if (!CloseEnough(takeprofit, 0) )
      }
   }//if (type == OP_SELL)
   
   return(take);
   
}//End double CalculateTakeProfit(int type)

double CalculateStopLoss(int type, double price, string symbol, int cc)
{
   //Returns the stop loss for use in LookForTradingOpps and InsertMissingStopLoss
   double stop = 0;
   double stoploss = StopLosses[cc];//'Hard' stop loss.
   double RangeHigh;
   double RangeLow;
   
   if (type == OP_BUY)
   {
      if (UseAverageRangeStopLoss[cc])
      {
         RangeLow = CalculateRangeLow(symbol, AverageRangeStopLossTimeFrame[cc], cc);
         if (!CloseEnough(RangeLow, 0) )
         { 
            stop = NormalizeDouble(RangeLow + (AverageRangeStopLossPipsShift[cc] / factor),digits);
         } 
      } 
      else
      {
         if (!CloseEnough(stoploss, 0) ) 
         {
            stop = NormalizeDouble(price - (stoploss / factor),digits);
         }//if (!CloseEnough(StopLoss, 0) )       
      }   
   }//if (type == OP_BUY)      
   
   if (type == OP_SELL)
   {
      if (UseAverageRangeTakeProfit[cc])
      {
         RangeHigh = CalculateRangeHigh(symbol, AverageRangeStopLossTimeFrame[cc], cc);
         if (!CloseEnough(RangeHigh, 0) )
         {
            stop = NormalizeDouble(RangeHigh + (AverageRangeStopLossPipsShift[cc] / factor),digits);
         }
      }
      else
      {

         if (!CloseEnough(stoploss, 0) ) 
         {
            stop = NormalizeDouble(price + (stoploss / factor),digits);
         }//if (!CloseEnough(StopLoss, 0) )
      }
   }//if (type == OP_SELL)   
   
   return(stop);
   
}//End double CalculateStopLoss(int type)

void CalculateLotAsAmountPerCashDollops()
{

   double lotstep = MarketInfo(Symbol(), MODE_LOTSTEP);
   int decimal = 0;
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

bool SendSingleTrade(string symbol,int type,string comment,double lotsize,double price,double stop,double take, int magic)
{

   int ticket = -1;


   
   datetime expiry=0;
   //if (SendPendingTrades) expiry = TimeCurrent() + (PendingExpiryMinutes * 60);

   //RetryCount is declared as 10 in the Trading variables section at the top of this file
   for(int cc=0; cc<RetryCount; cc++)
     {
      //for (int d = 0; (d < RetryCount) && IsTradeContextBusy(); d++) Sleep(100);

      while(IsTradeContextBusy()) Sleep(100);//Put here so that excess slippage will cancel the trade if the ea has to wait for some time.
      
      ticket=OrderSend(symbol,type,lotsize,price,0,stop,take,comment,magic,expiry,clrNONE);

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
         Alert(symbol," ",WindowExpertName()," ",stype," order send failed with error(",err,"): ",ErrorDescription(err), " TF = ", comment, ": bid = " 
               + DoubleToStr(bid, digits) + "  Price = " + DoubleToStr(price, digits));
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
         Alert(symbol," sent trade not in your trade history yet. Turn off this ea NOW.");
        }//if (!TradeReturnedFromCriminal)
     }//while (!TradeReturnedFromCriminal)

   //Got this far, so trade send succeeded
   return(true);

}//End bool SendSingleTrade(int type, string comment, double lotsize, double price, double stop, double take)
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+

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
         Print("Did not find #" + IntegerToString(ticket) + " in history, sleeping, then doing retry #" + IntegerToString(cnt));
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
      Print("Never found #" + IntegerToString(ticket) + " in history! crap!");
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

bool DoesOrderExist(string symbol, int type, double price, int pairsIndex)
{

   //Checks that there is not already a stop order in place before sending a gap filling trade.
   
   if (OrdersTotal() == 0)
      return(false);
   if (OpenTrades == 0)
      return(false);
   
   
   for (int cc = OrdersTotal() - 1; cc >= 0; cc--)
   {
      if (!OrderSelect(cc, SELECT_BY_POS) ) continue;
      if (OrderSymbol() != symbol ) continue;
      if (OrderMagicNumber() != MagicNumbers[pairsIndex]) continue;
      if (OrderType() != type) continue;
      if (!CloseEnough(OrderOpenPrice(), price) ) continue;
      if (OrderComment() != TradeComments[pairsIndex] ) continue;
      
      //Got to here, so we have found a trade
      return(true);

   }//for (int cc = OrdersTotal() - 1; cc >= 0; cc--)
   
   
   //Got this far, so no trade found
   return(false);   

}//End bool DoesOrderExist(int type, double price, int cc)

void FillGapsWithStopOrders(string symbol, int pairsIndex)
{

   //Fill in the gaps between the market price and the most recent trade
   //when the market is above the PH or below the PL.
   
   bool result = true;
   double price = 0;
   double SendLots = Lot;
   double stop = 0, take = 0;
   
   //Sell stops
   if (LatestTradeTicketNo > -1)   
      if (BetterOrderSelect(LatestTradeTicketNo, SELECT_BY_TICKET, MODE_TRADES))
         if (OrderType() == OP_SELL || OrderType() == OP_SELLSTOP)
            if (bid - OrderOpenPrice() >= (MarketDistance / factor) )
            {
               price = NormalizeDouble(OrderOpenPrice() + (MarketDistance / factor) / 2, digits);
               if(UsePriceChecks && !CheckOrderOpenPrice(symbol, TimeFrames[pairsIndex], OP_SELLSTOP, price, false))//if check fails, calculate closest valid open price
                  //price = NormalizeDouble(bid-(1/factor), digits);
                  return;
               take = OrderTakeProfit();//New stop orders have the same take profit as the oldest market trade
               if (!DoesOrderExist(OrderSymbol(), OP_SELLSTOP, price, pairsIndex))
               {
                  //DoesOrderExist() leaves the wrong trade selected, so reselect
                  if (!BetterOrderSelect(LatestTradeTicketNo, SELECT_BY_TICKET, MODE_TRADES))
                     return;

                  stop = CalculateStopLoss(OP_SELL, price, symbol, pairsIndex);
                  
                  result = SendSingleTrade(OrderSymbol(), OP_SELLSTOP, TradeComments[pairsIndex], SendLots, price, stop, take, MagicNumbers[pairsIndex]);
               }//if (!DoesOrderExist(OrderSymbol(), OP_SELLSTOP, price, pairsIndex))
               
            }//if (bid - OrderOpenPrice() >= (MarketDistance / factor) )

   //Buy stops
   if (LatestTradeTicketNo > -1)   
      if (BetterOrderSelect(LatestTradeTicketNo, SELECT_BY_TICKET, MODE_TRADES))
         if (OrderType() == OP_BUY|| OrderType() == OP_BUYSTOP)
            if (OrderOpenPrice() - bid >= (MarketDistance / factor) )
            {
               price = NormalizeDouble(OrderOpenPrice() - (MarketDistance / factor) / 2, digits);
               if(UsePriceChecks && !CheckOrderOpenPrice(symbol, TimeFrames[pairsIndex], OP_BUYSTOP, price, false))//if check fails, calculate closest valid open price
                  //price = NormalizeDouble(ask+(1/factor), digits);
                  return;
               take = OrderTakeProfit();//New stop orders have the same take profit as the oldest market trade
               if (!DoesOrderExist(OrderSymbol(), OP_BUYSTOP, price, pairsIndex))
               {
                  //DoesOrderExist() leaves the wrong trade selected, so reselect
                  if (!BetterOrderSelect(LatestTradeTicketNo, SELECT_BY_TICKET, MODE_TRADES))
                     return;

                  stop = CalculateStopLoss(OP_BUY, price, symbol, pairsIndex);
                  
                  result = SendSingleTrade(OrderSymbol(), OP_BUYSTOP, TradeComments[pairsIndex], SendLots, price, stop, take, MagicNumbers[pairsIndex]);
               }//if (!DoesTradeExist(OP_BUYSTOP, price))
               
            }//if (OrderOpenPrice() - bid >= (MarketDistance / factor) )
      

}//End void FillGapWithStopOrders(int cc)

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

void CheckPricesAreStillValid(string symbol, int cc)
{
//Code modifications to avoid error 130 added by Gary. Cheers Gary.

   //Examine pending trades and adjust the price if the peak has moved by 1 pip or more.
   if (!BetterOrderSelect(LatestTradeTicketNo, SELECT_BY_TICKET, MODE_TRADES) )
      return;
   
   double price = 0, newPrice = 0;
   bool modify = false;
   double stop = 0, take = 0;
      
   //A buy stop will be above the lowest trade line
   if (OrderType() == OP_BUYSTOP)
   {
      price = OrderOpenPrice();
      if (price - (bid + (TradeBuffers[cc] / factor)) > (1 / factor) )//Only check the price when it has moved by one full pip
      {
         modify = true;
         newPrice = bid + (TradeBuffers[cc] / factor);
         
         //don't modify unless stop order will move south   
         if(newPrice >= OrderOpenPrice()) return;
         
         //if check fails, calculate closest valid open price
         if(UsePriceChecks && !CheckOrderOpenPrice(symbol, TimeFrames[cc], OP_BUYSTOP, newPrice, true))
            //newPrice = NormalizeDouble(ask+(StopsLevel/factor)+(1/factor), digits);
            return; //don't modify unless we have a valid price
         
         stop = CalculateStopLoss(OP_BUY, newPrice, symbol, cc);
         take = CalculateTakeProfit(OP_BUY, newPrice, symbol, cc);
      }//if (price - (bid + (TradeBuffers[cc] / factor)) > (1 / factor) )
   }//if (OrderType() == OP_BUYSTOP)
         
   //A sell stop will be below the highest trade line
   if (OrderType() == OP_SELLSTOP)
   {
      price = OrderOpenPrice();
      if (bid - (price + (TradeBuffers[cc] / factor) )  > (1 / factor) )//Only check the price when it has moved by one full pip
      {
         modify = true;
         newPrice = bid - (TradeBuffers[cc] / factor);
         
         //don't modify unless stop order will move north
         if(newPrice <= OrderOpenPrice()) return; 
         
         //if check fails, calculate closest valid open price
         if(UsePriceChecks && !CheckOrderOpenPrice(symbol, TimeFrames[cc], OP_SELLSTOP, newPrice, true))  
            //newPrice = NormalizeDouble(bid-(StopsLevel/factor)-(1/factor), digits);
            return; //don't modify unless we have a valid price
         
         stop = CalculateStopLoss(OP_SELL, newPrice,symbol, cc);
         take = CalculateTakeProfit(OP_SELL, newPrice, symbol, cc);
      }//if (bid - (price + (TradeBuffers[cc] / factor)) > (1 / factor) )
   }//if (OrderType() == OP_SELLSTOP)
         
   if (!modify)
      return;
      
   bool result = ModifyOrder(OrderTicket(), newPrice, stop, take, OrderExpiration(), clrNONE, __FUNCTION__, oop);

}//void CheckPricesAreStillValid(int cc)

bool ModifyOrder(int ticket, double price, double stop, double take, datetime expiry, color col, string function, string reason)
{
   //Multi-purpose order modify function
   
   bool result=false, checkPassed=false;
   
   //check if 'OrderModify()' will actually modify the order
   if (OrderModifyCheck(ticket, price, stop, take))
   {
      result = OrderModify(ticket, price, stop, take, expiry, col);
      checkPassed=true; 
   }//if (OrderModifyCheck(ticket, price, stop, take))

   //Actions when trade close succeeds
   if (result)
   {
      return(true);
   }//if (result)
   
   //Actions when trade close fails & check passed
   if (!result && checkPassed)
      ReportError(function, reason);

   //Got this far, so modify failed
   return(false);
   
}// End bool ModifyOrder()

bool OrderModifyCheck(int ticket, double price, double sl, double tp)
{
//--- https://www.mql5.com/en/articles/2555

//--- select order by ticket
   if(OrderSelect(ticket,SELECT_BY_TICKET))
     {
      //--- point size and name of the symbol, for which a pending order was placed
      string symbol=OrderSymbol();
      double myPoint=SymbolInfoDouble(symbol,SYMBOL_POINT);
      //--- check if there are changes in the Open price
      bool PriceOpenChanged=true;
      int type=OrderType();
      if(!(type==OP_BUY || type==OP_SELL))
        {
         PriceOpenChanged=(MathAbs(OrderOpenPrice()-price)>myPoint);
        }
      //--- check if there are changes in the StopLoss level
      bool StopLossChanged=(MathAbs(OrderStopLoss()-sl)>myPoint);
      //--- check if there are changes in the Takeprofit level
      bool TakeProfitChanged=(MathAbs(OrderTakeProfit()-sl)>tp);
      //--- if there are any changes in levels
      if(PriceOpenChanged || StopLossChanged || TakeProfitChanged)
         return(true);  // order can be modified      
      //--- there are no changes in the Open, StopLoss and Takeprofit levels
      /*
      else
      //--- notify about the error
         PrintFormat("Order #%d already has levels of Open=%.5f SL=.5f TP=%.5f",
                     ticket,OrderOpenPrice(),OrderStopLoss(),OrderTakeProfit());
      */
     }
//--- came to the end, no changes for the order
   return(false);       // no point in modifying 
}//OrderModifyCheck(int ticket, double price, double sl, double tp)

//Treating each individual symbol as a basket across all time frames.
//Added by orisb. Thanks Brenden
void CloseAllSymbolTrades(string symbol, int magic)
{
   ForceTradeClosure= false;
   if (OrdersTotal() == 0) return;
   
   bool result = false;
   for (int cc = OrdersTotal() - 1; cc >= 0; cc--)
   {
     if (!BetterOrderSelect(cc, SELECT_BY_POS, MODE_TRADES) ) continue;
     if (OrderMagicNumber() != magic) continue;
     if (OrderSymbol() != symbol ) continue;         
            
     while(IsTradeContextBusy()) Sleep(100);
     if (OrderType() < 2)
     {
        result = OrderClose(OrderTicket(), OrderLots(), OrderClosePrice(), 1000, CLR_NONE);
        if (!result) ForceTradeClosure= true;
     }//if (OrderType() < 2)
        
     if (OrderType() > 1) 
     {
        result = OrderDelete(OrderTicket(), clrNONE);               
        if (!result) ForceTradeClosure= true;
     }//if (OrderType() > 1)             
   }//for (int cc = OrdersTotal() - 1; cc >= 0; cc--)
}//End void CloseAllSymbolTrades(string symbol, int magic)     

void CloseAllTrades(string symbol, int type, int magic)
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
         if (OrderMagicNumber() != magic && type != AllTrades) continue;
         if (OrderSymbol() != symbol ) continue;
         if (OrderType() != type && type != AllTrades) continue;
            
         
         while(IsTradeContextBusy()) Sleep(100);
         if (OrderType() < 2)
         {
            result = OrderClose(OrderTicket(), OrderLots(), OrderClosePrice(), 1000, CLR_NONE);
            if (result) 
            {
               FifoTicket[cc] = -1;
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
                  FifoTicket[cc] = -1;
                  OpenTrades--;
               }//(result) 
            if (!result) ForceTradeClosure= true;
            }//if (OrderType() > 1) 
            
      }//for (int cc = ArraySize(FifoTicket) - 1; cc >= 0; cc--)
   }//for (int pass = 0; pass <= 1; pass++)

}//End void CloseAllTrades(string symbol, int type, int magic)

void NuclearOption()
{

   ForceTradeClosure= false;
   
   if (OrdersTotal() == 0) return;
   
   //Put all the order tickets into an array for our friends in the US
   int Tickets[];
   int as = 0;
   for (int cc = OrdersTotal() - 1; cc >= 0; cc--)
   {
      if (!BetterOrderSelect(cc, SELECT_BY_POS, MODE_TRADES))
         continue;
         
      ArrayResize(Tickets, as + 1);
      Tickets[as] = OrderTicket();
      as++;
   }//for (int cc = OrdersTotal() - 1; cc >= 0; cc--)
   if (as == 0)
      return;//Just in case
   ArraySort(Tickets, WHOLE_ARRAY, 0, MODE_DESCEND);   
   
   for (int cc = ArraySize(Tickets) - 1; cc >= 0; cc--)
   {
      if (!BetterOrderSelect(Tickets[cc], SELECT_BY_TICKET, MODE_TRADES) ) continue;
         
      while(IsTradeContextBusy()) Sleep(100);
      bool result = false;

      if (OrderType() < 2)
      {
         result = OrderClose(OrderTicket(), OrderLots(), OrderClosePrice(), 1000, CLR_NONE);
         if (result) 
         {
            Tickets[cc] = -1;
            OpenTrades--;
         }//(result) 
         
         if (!result) ForceTradeClosure= true;
      }//if (OrderType() < 2)
      
      if (OrderType() > 1) 
      {
         result = OrderDelete(OrderTicket(), clrNONE);
         if (result) 
         {
            Tickets[cc] = -1;
            OpenTrades--;
         }//(result) 
         if (!result) ForceTradeClosure= true;
      }//if (OrderType() > 1) 
      
   }//for (int cc = ArraySize(Tickets) - 1; cc >= 0; cc--)

}//End void NuclearOption


bool HaveWeReachedGlobalBasketTP()
{
   double lotstep = MarketInfo(Symbol(), MODE_LOTSTEP);
   int decimal = 0;
   if (CloseEnough(lotstep, 0.1) )
      decimal = 1;
   if (CloseEnough(lotstep, 0.01) )
      decimal = 2;
      
   double maxlot = MarketInfo(Symbol(), MODE_MAXLOT);
   double minlot = MarketInfo(Symbol(), MODE_MINLOT);
   double DoshDollop = AccountInfoDouble(ACCOUNT_BALANCE); 
   
   if (UseEquity)
      DoshDollop = AccountInfoDouble(ACCOUNT_EQUITY); 

   AllBasketProfitTarget = AllBasketCashTakeProfit;

   //Calculate the dynamic tp
   if (!CloseEnough(AllBasketCashPercentageTarget, 0) )
      AllBasketProfitTarget = (AccountBalance() * AllBasketCashPercentageTarget) / 100;

   if (AllBasketCashUseDollopMultiplier)
      AllBasketProfitTarget = NormalizeDouble((DoshDollop / SizeOfDollop) * LotsPerDollopOfCash * 100 * AllBasketProfitTarget, decimal);
      
   if (EntirePositionCashUpl >= AllBasketProfitTarget)
      return (true);
         
   //Not reached the target
   return(false);
   
}//bool HaveWeReachedGlobalBasketTP()

void CountCurrentlyTradingPairs()
{
   //Calculate how many pairs have open trades

   ArrayResize(PairsWithOpenTrades, 0);
   int as = 0;//PairsWithOpenTrades Array size
   TradingPairs = 0;//Running total of pairs with trades open.
   
  
   //Iterate through the trades open on the platform
   for (int cc = OrdersTotal() - 1; cc >= 0; cc--)
   {
      bool found = false;
      if (BetterOrderSelect(cc, SELECT_BY_POS, MODE_TRADES) )
      {
         //Iterate through PairsWithOpenTrades to find a matching symbol to the currently selected OrderSymbol()
         for (int pairsIndex = 0; pairsIndex < ArraySize(PairsWithOpenTrades); pairsIndex++)
         {
            if (PairsWithOpenTrades[pairsIndex] == OrderSymbol())
            {
               found = true;
               break;
            }//if (PairsWithOpenTrades[pairsIndex] == OrderSymbol())
         }//for (int pairsIndex = 0; pairsIndex < ArraySize(PairsWithOpenTrades); pairsIndex++)
      }//if (BetterOrderSelect(cc, SELECT_BY_POS, MODE_TRADES) )
      
      //Continue to the next iteration if OrderSymbol() is already stored in the PairsWithOpenTrades array
      if (found)
         continue;
         
      //Not found in the array, so store the symbol
      ArrayResize(PairsWithOpenTrades, as + 1);
      PairsWithOpenTrades[as] = OrderSymbol();
      TradingPairs++;//Running total of pairs with trades open.
      as++;   
      
   }//for (int cc = OrdersTotal() - 1; cc >= 0; cc--)
   


}//End void CountCurrentlyTradingPairs()

bool AreWeAlreadyTradingThisPair(string symbol)
{

   //Returns true if this pair is already being traded on any time frame, else returns false.
   
   if (TradingPairs == 0) //Calculated in void CountCurrentlyTradingPairs()
      return(false);
      
   //Iterate through PairsWithOpenTrades[] to lok for a pair matching symbol
   for (int cc = 0; cc < ArraySize(PairsWithOpenTrades); cc++)
   {
      if (PairsWithOpenTrades[cc] == symbol)
         return(true);//Found one
   }//for (int cc = 0; cc < ArraySize(PairsWithOpenTrades); cc++)
      
   
   
   //Got this far, so not trading this pair
   return(false);

}//End bool AreWeAlreadyTradingThisPair(string symbol)

double GetSuperSlope(string symbol, int tf, int maperiod, int atrperiod, int pShift )
{
   double dblTma, dblPrev;
   int shiftWithoutSunday = pShift;
   if ( BrokerHasSundayCandles && PERIOD_CURRENT == PERIOD_D1 )
   {
      if ( TimeDayOfWeek( iTime( symbol, PERIOD_D1, pShift ) ) == 0  ) shiftWithoutSunday++;
   }   

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


//Using hgi_lib Function commented out
/*
double GetHGI(string symbol, int tf, int buffer, int shift)
{

   //return(iCustom(symbol, tf, HGI_Name, 0, false, false, false, false, false, false, false, buffer, shift) );
   return(iCustom(symbol, tf, HGI_Name, true, buffer,shift));
   
}//double GetHGI()
*/


double GetFlyingBuddha(string symbol, int tf, int ffp, int ffam, int ffpr, int fsp, int fsam, int fspr, int buffer, int shift)
{

   //Code by Baluda. Thanks very much Paul.
   
   double fastMA = iMA( symbol, tf, ffp, 0, ffam, ffpr, shift );
   double slowMA = iMA( symbol, tf, fsp, 0, fsam, fspr, shift );
   double high = iHigh( symbol, tf, shift );
   double low  = iLow( symbol, tf, shift );

   double result = EMPTY_VALUE;
      
   //-- long signal
   if ( buffer == 2 && high < MathMin( fastMA, slowMA ) ) result = low;
     
   //-- short signal
   if ( buffer == 3 && low > MathMax( fastMA, slowMA ) ) result = high;
   
   return ( result );

}//End double GetFlyingBuddha()

int GetPeriod(int period)
{int periodres;
 switch(period)
  {
   case 1: periodres=1;break;
   case 2: periodres=5;break;
   case 3: periodres=15;break;
   case 4: periodres=30;break;
   case 5: periodres=60;break;
   case 6: periodres=240;break;
   case 7: periodres=1440;break;
   case 8: periodres=10080;break;
   default: periodres=1;break;
  }
return(periodres);
} 

double GetAtr(string symbol, int tf, int period, int shift)
{
   //Returns the value of atr
   
   return(iATR(symbol, tf, period, shift) );   

}//End double GetAtr()

bool HaveWeHitRecoveryTarget(string symbol, int type, int index)
{
   //Calculate the Recovery target and close the trades if the target price is reached.
   
   int cc = 0;
   RecoveryTargetPrice = 0;
   RecoveryTargetCash = 0;
   
   if (type == OP_BUY)
   {
      //Add together the price of all the market trades
      for (cc = 0; cc < ArraySize(BuyTickets); cc++)
      {
         if (!BetterOrderSelect(BuyTickets[cc], SELECT_BY_TICKET, MODE_TRADES) )
            continue;//Just in case
         
         if (!CloseEnough(RecoveryProfitPips[index], 0) )
            RecoveryTargetPrice+= OrderOpenPrice();//Pips recovery
         
         if (!CloseEnough(RecoveryProfitCash[index], 0) )
            RecoveryTargetCash+= (OrderProfit() + OrderSwap() + OrderCommission() );//For cash recovery
      
      }//for (cc = 0; cc < ArraySize(BuyTickets); cc++)
      
      //Divide this figure by the ticket array size to arrivc at the breakeven price
      if (!CloseEnough(RecoveryProfitPips[index], 0) )
      {
         RecoveryTargetPrice/= ArraySize(BuyTickets);
         RecoveryTargetPrice+= (RecoveryProfitPips[index] / factor);
      }//if (!CloseEnough(RecoveryProfitPips[index], 0) )
         
      //Has the market reached this target?
      //Pips recovery
      if (!CloseEnough(RecoveryTargetPrice, 0) )
         if (bid >= RecoveryTargetPrice)
            return(true);
   
   }//if (type == OP_BUY)

   if (type == OP_SELL)
   {
      //Add together the price of all the market trades
      for (cc = 0; cc < ArraySize(SellTickets); cc++)
      {
         if (!BetterOrderSelect(SellTickets[cc], SELECT_BY_TICKET, MODE_TRADES) )
            continue;//Just in case
         
         if (!CloseEnough(RecoveryProfitPips[index], 0) )
            RecoveryTargetPrice+= OrderOpenPrice();//Pips recovery
         
         if (!CloseEnough(RecoveryProfitCash[index], 0) )
            RecoveryTargetCash+= (OrderProfit() + OrderSwap() + OrderCommission() );//For cash recovery
      }//for (cc = 0; cc < ArraySize(BuyTickets); cc++)
      
      //Divide this figure by the ticket array size to arrivc at the breakeven price
      if (!CloseEnough(RecoveryProfitPips[index], 0) )
      {
         RecoveryTargetPrice/= ArraySize(SellTickets);
         RecoveryTargetPrice-= (RecoveryProfitPips[index] / factor);
      }//if (!CloseEnough(RecoveryProfitPips[index], 0) )
     
      //Has the market reached this target?
      //Pips recovery
      if (!CloseEnough(RecoveryTargetPrice, 0) )
         if (ask <= RecoveryTargetPrice)//Should ths be ask instead of bid?
            return(true);
      
   }//if (type == OP_SELL)
   

   //Cash target
   if (!CloseEnough(RecoveryTargetCash, 0) )
      if (RecoveryTargetCash >= RecoveryProfitCash[index])
         return(true);

   //Got this far, so no closure
   return(false);

}//bool HaveWeHitRecoveryTarget(string symbol, int type)

bool HaveWeHitBasketTarget(int cc)
{
   //Tests for multiple market trades hitting their basket target.
   //Returns true if so, else returns false.

   double lotstep = MarketInfo(Symbol(), MODE_LOTSTEP);
   int decimal = 0;
   if (CloseEnough(lotstep, 0.1) )
      decimal = 1;
   if (CloseEnough(lotstep, 0.01) )
      decimal = 2;
      
   double maxlot = MarketInfo(Symbol(), MODE_MAXLOT);
   double minlot = MarketInfo(Symbol(), MODE_MINLOT);
   double DoshDollop = AccountInfoDouble(ACCOUNT_BALANCE); 
   
   if (UseEquity)
      DoshDollop = AccountInfoDouble(ACCOUNT_EQUITY); 
   
   TradeBasketProfitTarget[cc] = TradeBasketCashTarget[cc];
   
   //Calculate BasketProfitTarget as a percentage of the account balance
   if (!CloseEnough(TradeBasketCashPercentageTarget[cc], 0))
      TradeBasketProfitTarget[cc] = (AccountBalance() * TradeBasketCashPercentageTarget[cc] ) / 100;
 
   if (TradeBasketCashUseDollopMultiplier[cc])
      TradeBasketProfitTarget[cc] = NormalizeDouble((DoshDollop / SizeOfDollop) * LotsPerDollopOfCash * 100 * TradeBasketProfitTarget[cc], decimal);
 
   if (CashUpl >= TradeBasketProfitTarget[cc])
      return(true);   


   //Got this far, so target not hit
   return(false);

}//End bool HaveWeHitBasketTarget(int cc)

////////////////////////////////////////////////////////////////////////////////////////////
//START OF INDIVIDUAL TRADE MANAGEMENT MODULE
void ReportError(string function, string message)
{
   //All purpose sl mod error reporter. Called when a sl mod fails
   
   int err=GetLastError();
   if (err == 1) return;//That bloody 'error but no error' report is a nuisance
   
      
   Alert(WindowExpertName(), " ", OrderTicket(), " ", function, message, err,": ",ErrorDescription(err));
   Print(WindowExpertName(), " ", OrderTicket(), " ", function, message, err,": ",ErrorDescription(err));
   
}//void ReportError()

void BreakEvenStopLoss(int ticket, int cc)
{
 
   // Move stop loss to breakeven
   
   if (!BetterOrderSelect(ticket, SELECT_BY_TICKET, MODE_TRADES))
      return;//Order has closed, so nothing to do.    
 
   //I have copied this from MuptiPurposeTradeManage Updated, so set
   //up some local variables to save having to edit those already in place.
   double BreakEven = BreakEvenPips[cc];
   double BreakEvenProfit = BreakEvenProfitPips[cc];
 
   //No need to continue if already at BE
   if (OrderType() == OP_BUY)
      if (OrderStopLoss() >= OrderOpenPrice() )
         return;
         
   if (OrderType() == OP_SELL)
      if (!CloseEnough(OrderStopLoss(), 0) )//Sell stops need this extra conditional to cater for no stop loss trades
         if (OrderStopLoss() <= OrderOpenPrice() )
            return;
             
 
   int err = 0;
   bool modify = false;
   double stop = 0;
   
  //Can we move the stop loss to breakeven?        
   if (OrderType()==OP_BUY)
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
            stop = OrderOpenPrice() - (BreakEvenProfit / factor);
         }//if (OrderStopLoss()>OrderOpenPrice())
         
   //Modify the order stop loss if BE has been achieved
   if (modify)
   {
      bool result = ModifyOrder(OrderTicket(), OrderOpenPrice(), stop, OrderTakeProfit(),
                                OrderExpiration(), clrNONE, __FUNCTION__, slm);
     
   }//if (modify)
   
 
}//End void BreakEvenStopLoss(int ticket, int cc)
 
 
 
void JumpingStopLoss(int ticket, int cc)
{
   // Jump stop loss by pips intervals chosen by user.
   // Also carry out partial closure if the user requires this
 
 
   if (!BetterOrderSelect(ticket, SELECT_BY_TICKET, MODE_TRADES))
      return;//Order has closed, so nothing to do.    
 
   //I have copied this from MuptiPurposeTradeManage Updated, so set
   //up some local variables to save having to edit those already in place.
   bool JumpAfterBreakevenOnly = JumpAfterBreakEvenOnly[cc];
   double JumpingStop = JumpingStopPips[cc];
   double BreakEven = BreakEvenPips[cc];
   double BreakEvenProfit = BreakEvenProfitPips[cc];
 
   
   // Abort the routine if JumpAfterBreakevenOnly is set to true and be stop is not yet set
   if (JumpAfterBreakevenOnly)
   {
      if (OrderType()==OP_BUY)
         if(OrderStopLoss() < OrderOpenPrice() )
            return;
   
      if (OrderType()==OP_SELL)
         if(OrderStopLoss() > OrderOpenPrice() || CloseEnough(OrderStopLoss(), 0) )
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
         if (bid >= OrderOpenPrice() + (BreakEven / factor))
         {
            stop = OrderOpenPrice() + (BreakEvenProfit / factor);
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
            }// if (bid>= stop + (BreakEvenProfit / factor) && stop>= OrderOpenPrice())      
     
   
   }//if (OrderType()==OP_BUY)
   
   if (OrderType()==OP_SELL)
   {
      // First check if stop needs setting to breakeven
      if (CloseEnough(stop, 0) || stop > OrderOpenPrice())
      {
         if (bid <= OrderOpenPrice() - (BreakEvenProfit / factor))
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
            }// if (bid>= stop + (BreakEvenProfit / factor) && stop>= OrderOpenPrice())      
       
   }//if (OrderType()==OP_SELL)
 
   //Modify the order stop loss if a jump has been achieved
   if (modify)
   {
      result = ModifyOrder(OrderTicket(), OrderOpenPrice(), stop, OrderTakeProfit(),
                                OrderExpiration(), clrNONE, __FUNCTION__, slm);
  }//if (modify)
 
 
} //End void JumpingStopLoss(int ticket, int cc) 

void TradeManagementModule(int ticket, int cc)
{

   //Break even
   if (UseBreakEven[cc])
      BreakEvenStopLoss(ticket, cc);
      
   
   //Jumping stop loss
   if (UseJumpingStop[cc])
      JumpingStopLoss(ticket, cc);
   
}//End void TradeManagementModule(int ticket, int cc)


//END OF INDIVIDUAL TRADE MANAGEMENT MODULE
////////////////////////////////////////////////////////////////////////////////////////////

//Spread filter
bool SpreadOk(int cc)
{

   //Calculate the max allowable spread
   double target = AverageSpread[cc] * MultiplierToDetectStopHunt;
   if (CloseEnough(target, 0) )
      return(true);//Just in case.
      
   if (spread >= target)//Too wide
      return(false);

   //Got this far, so spread is ok.
   return(true);
   
}//End bool SpreadOk(int cc)

//Spread filter
void ReCalculateAverageSpread(string symbol, int cc, int counter)
{
   //Keep a running total of the spread for each pair, the periodically
   //re-calculate the average.
   RunningTotalOfSpreads[cc] += spread;
   
   //Do we need a recalc
   if (counter >= 100)
   {
      AverageSpread[cc] = RunningTotalOfSpreads[cc] / counter;
      SpreadGvName = symbol + " average spread";
      GlobalVariableSet(SpreadGvName, AverageSpread[cc]);      
      RunningTotalOfSpreads[cc] = 0;
   }//if (counter >= 100)


}//End void ReCalculateAverageSpread(string symbol, int cc, int counter)


//Treating each individual symbol as a basket across all time frames.
//Added by orisb. Thanks Brenden
bool HaveWeReachedSymbolBasketTP()
{
   //Close all trades on the platform if a full basket tp is hit.
   double lotstep = MarketInfo(Symbol(), MODE_LOTSTEP);
   int decimal = 0;
   if (CloseEnough(lotstep, 0.1) )
      decimal = 1;
   if (CloseEnough(lotstep, 0.01) )
      decimal = 2;
      
   double maxlot = MarketInfo(Symbol(), MODE_MAXLOT);
   double minlot = MarketInfo(Symbol(), MODE_MINLOT);
   double DoshDollop = AccountInfoDouble(ACCOUNT_BALANCE); 
   
   if (UseEquity)
      DoshDollop = AccountInfoDouble(ACCOUNT_EQUITY); 

   SymbolBasketProfitTarget = SymbolBasketCashTakeProfit;
   
   //Calculate the dynamic tp
   if (!CloseEnough(SymbolBasketCashPercentageTarget, 0) )
      SymbolBasketProfitTarget = (AccountBalance() * SymbolBasketCashPercentageTarget) / 100;

   if (SymbolBasketCashUseDollopMultiplier)
      SymbolBasketProfitTarget = NormalizeDouble((DoshDollop / SizeOfDollop) * LotsPerDollopOfCash * 100 * SymbolBasketProfitTarget, decimal);
      
   if (SymbolPositionCashUpl >= SymbolBasketProfitTarget)
      return (true);
         
   //Not reached the target
   return(false);
   
}//bool HaveWeReachedSymbolBasketTP()

//Profit targets
double AccumulatedProfit(int tf)
{
   bool OnlyClosedOrders=False;
   datetime starttime = iTime(Symbol(), tf, 0);//Define a starting time based on the passed parameter
   double profit = 0; //initialize the profit to calculate
   
   //Iterate through the orders in History and calculate the accumulated profit/loss.
   for (int cc = OrdersHistoryTotal() -1; cc >= 0; cc--)
   {      
      if(BetterOrderSelect(cc, SELECT_BY_POS, MODE_HISTORY) )
         if(OrderCloseTime() >= starttime)
            if (OrderType() < 2)//We are only interested in market trades
               profit += (OrderProfit() + OrderSwap() + OrderCommission() );
   }//for (int cc = OrdersHistoryTotal() -1; cc >= 0; cc--)
   
   
   return(profit);
}//End double AccumulatedProfit(int tf)

bool HaveWeReachedOurTarget(int tf)
{

   //Returns true if the profit target for the passed time frame is reached,
   //else returns false.
   
   double profit = 0;
   
   //Daily
   if (tf == PERIOD_D1)
   {
      DailyProfitTarget = DailyCashProfitTarget;//'Hard' cash profit target.
      //Profit target as a percentage of the account balance
      if (!CloseEnough(DailyPercentOfBalanceProfitTarget, 0) )
         DailyProfitTarget = (AccountBalance() * DailyPercentOfBalanceProfitTarget) / 100;
      
      //Is this feature disabled?
      if (CloseEnough(DailyProfitTarget, 0) )
         return(false);
      
      //Get the accumulated profit for the passed time frame.
      profit = AccumulatedProfit(PERIOD_D1);
      //Have we hit our target?
      if (profit >= DailyProfitTarget)
         return(true);
         
   }//if (tf == PERIOD_D1)
   
   //Weekly
   if (tf == PERIOD_W1)
   {
      WeeklyProfitTarget = WeeklyCashProfitTarget;//'Hard' cash profit target.
      //Profit target as a percentage of the account balance
      if (!CloseEnough(WeeklyPercentOfBalanceProfitTarget, 0) )
         WeeklyProfitTarget = (AccountBalance() * WeeklyPercentOfBalanceProfitTarget) / 100;
      
      //Is this feature disabled?
      if (CloseEnough(WeeklyProfitTarget, 0) )
         return(false);
      
      //Get the accumulated profit for the passed time frame.
      profit = AccumulatedProfit(PERIOD_W1);
      //Have we hit our target?
      if (profit >= WeeklyProfitTarget)
         return(true);
         
   }//if (tf == PERIOD_W1)
   
   
   //Got this far, so profit target not reached.
   return(false);

}//End bool HaveWeReachedOurTarget(int tf)

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
//Trading hours
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


//Trading hours
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

//Trading hours
string StringSubstrOld(string x,int a,int b=-1) 
{
   if(a<0) a=0; // Stop odd behaviour
   if(b<=0) b=-1; // new MQL4 EOL flag
   return StringSubstr(x,a,b);
}


void TakeChartSnapshot(int ticket, int tf, string oc)
{
string pair;
   //Takes a snapshot of the chart after a trade open or close. Files are stored in the MQL4/Files folder
   //of the platform.
   
   //--- Prepare a text to show on the chart and a file name.
   //oc is either " open" or " close"
   string name="ChartScreenShot " + string(ticket) + oc + ".gif";
   if(OrderSelect(ticket,SELECT_BY_TICKET))
      pair=OrderSymbol();

   OpenChart(pair,tf);
   Sleep(10000);
   //--- Save the chart screenshot in a file in the terminal_directory\MQL4\Files\
   
   if(ChartScreenShot(0,name, PictureWidth, PictureHeight, ALIGN_RIGHT))
      Alert("Screen snapshot taken ",name);
   //---

}//void TakeChartSnapshot()


//+------------------------------------------------------------------+
//| Timer function                                                   |
//+------------------------------------------------------------------+
void OnTimer()
{
   
   if (!IsTradeAllowed() )
   {
      Comment("                          THIS EXPERT HAS LIVE TRADING DISABLED");
      return;
   }//if (!IsTradeAllowed() )
   
   /////////////////////////////////////////////////////////////
   //Profit targets
   static datetime OldDayBarTime = 0, OldWeekBarTime = 0;//Keep track of time.
   if (OldDayBarTime != iTime(Symbol(), PERIOD_D1, 0) )//Should we reset the timer?
   {
      OldDayBarTime = iTime(Symbol(), PERIOD_D1, 0);
      TradingDoneForTheDay = false;//New day, so start trading.
   }//if (OldDayBarTime != iTime(Symbol(), PERIOD_D1, 0) )
   
   if (OldWeekBarTime != iTime(Symbol(), PERIOD_W1, 0) )//Should we reset the timer?
   {
      OldWeekBarTime = iTime(Symbol(), PERIOD_W1, 0);
      TradingDoneForTheWeek = false;//New day, so start trading.
   }//if (OldWeekBarTime != iTime(Symbol(), PERIOD_W1, 0) )
   
   //Is the daily target reached?
   if (HaveWeReachedOurTarget(PERIOD_D1) )
      TradingDoneForTheDay = true;
   if (HaveWeReachedOurTarget(PERIOD_W1) )
      TradingDoneForTheWeek = true;

   //Calculate the profit made so far today
   ProfitToday = AccumulatedProfit(PERIOD_D1);
   
   /////////////////////////////////////////////////////////////
   
   //Safety adapted from my shells
   //An index to keep track of where we are in the TimeToStartTrading array.
   TradingTimeCounter = 0;
 
   //The user can treat every trade open on the platform as part of a basket with a cash take profit.
   //Initialising this to zero in CountOpenTrades() would cause incorrect calculations, so do so here instead.
   EntirePositionCashUpl=0;
   
   //An index to keep track of where we are in the TradingBarTime array.
   int TradingBarCounter = 0;
   
   //Spread filter
   static int counter = 0;
      

   //Iterate around the pairs being traded.
   for (int pairsIndex = 0; pairsIndex < ArraySize(TradePair); pairsIndex++)
   {

      //Avoid duplicate trading
      AlreadyTradedThisPrice = false;//Free the pair for trading
      
      //Rollover. Do absolutely nothing during rollover.
      if (DisablePoSDuringRollover)
      {
         RolloverInProgress = false;
         if (AreWeAtRollover())
         {
            RolloverInProgress = true;
            DisplayUserFeedback();
            return;
         }//if (AreWeAtRollover)
      }//if (DisablePoSDuringRollover)

      string symbol = TradePair[pairsIndex];//Cuts down a lot of typing and matches the calls to the functions.
      GetBasics(symbol);//bid, Ask etc
      
      //Treating each individual symbol as a basket across all time frames.
      //Added by orisb. Thanks Brenden
      SymbolPositionCashUpl=0;
      SymbolMarketTrades=0;
      SymbolMagicNumberCount=0;
      ArrayResize(SymbolMagicNumber, 0);
      ArrayInitialize(SymbolMagicNumber, 0);
      
      
      //Spread filter
      //Running total of spreads and periodic recalculate. Calculating every 100 OnTimer() events for now.)
      ReCalculateAverageSpread(symbol, pairsIndex, counter);
      if (!SpreadOk(pairsIndex) )//Spread is too wide, so do not want the EA doing anything.579
      {
         //Update the TimeToStartTrading array counter.
         TradingTimeCounter+= ArraySize(TimeFrames);
         continue;
      }//if (!SpreadOk(pairsIndex) )

                            
      if (UsePeakyOnOwnTimeFrame)
         if (PKBarTime[pairsIndex] != iTime(symbol, OwnPeakyTimeFrame, 0))//Changed by CHS
         {
            //Get the bar shift of the peaks
            int currentPeakHighBar = iHighest(symbol, OwnPeakyTimeFrame, MODE_CLOSE, NoOfBars, 1);
            int currentPeakLowBar = iLowest(symbol, OwnPeakyTimeFrame, MODE_CLOSE, NoOfBars, 1);
         
            //Read the peak prices
            PeakHigh = iClose(symbol, OwnPeakyTimeFrame, currentPeakHighBar);
            PeakLow = iClose(symbol, OwnPeakyTimeFrame, currentPeakLowBar);

            OTFPeakyMarketDirection[pairsIndex] = otfpeakynodirection;               
            //Calculate the market direction.
            //Short
            if (currentPeakHighBar < currentPeakLowBar)
               OTFPeakyMarketDirection[pairsIndex] = otfpeakyshortdirection;
            else   
               OTFPeakyMarketDirection[pairsIndex] = otfpeakylongdirection;
         }//if (UsePeakyOnOwnTimeFrame)


      if (UseSuperSlopeOnOwnTimeFrame)
         if (SsBarTime[pairsIndex] != iTime(symbol, OwnSuperSlopeTimeFrame, 0))//Changed by CHS
         {
            SsTtfCurr1Val = GetSuperSlope(symbol, OwnSuperSlopeTimeFrame, SsTradingSlopeMAPeriod,SsTradingSlopeATRPeriod,1);

            //Changed by tomele
            //Set the colours
            OTFSsColour[pairsIndex] = otfwhite;
            if (SsTtfCurr1Val > 0)  //buy
               if (SsTtfCurr1Val - SsTradingDifferenceThreshold/2 > 0) //blue
                  OTFSsColour[pairsIndex] = otfblue;

            if (SsTtfCurr1Val < 0)  //sell
               if (SsTtfCurr1Val + SsTradingDifferenceThreshold/2 < 0) //red
                  OTFSsColour[pairsIndex] = otfred;
         }//if (UseSuperSlopeOnOwnTimeFrame)

            if (UseTMSOnOwnTimeFrame)
            {
               int signal_period=OwnTMSTimeFrame;
//               int signal_period=TimeFrames[tfIndex];
               TdiGreen = iCustom(symbol, signal_period, "TDI Red Green", 13, 0, 34, 2, 0, 7, 0,  4, 0);
               PrevTdiGreen = iCustom(symbol, signal_period, "TDI Red Green", 13, 0, 34, 2, 0, 7, 0,  4, 1);
               TdiRed = iCustom(symbol, signal_period, "TDI Red Green", 13, 0, 34, 2, 0, 7, 0,  5, 0);
               SmaVal = iMA(symbol, signal_period, 5, 1, MODE_SMA, PRICE_TYPICAL, 0);
               StochVal = iStochastic(symbol, signal_period, 8,3,3,0,0,0,0);
               PrevStochVal = iStochastic(symbol, signal_period, 8,3,3,0,0,0,1);
               AskVal = MarketInfo(symbol,MODE_ASK);
               BidVal = MarketInfo(symbol,MODE_BID);
               double OP0 =  iOpen(symbol, signal_period, 0);
               double OP1 =  iOpen(symbol, signal_period, 1);
               double CL0 =  iClose(symbol, signal_period, 0);
               OTFTmsStatus[pairsIndex]=otftmsno;
               OTFTmsD1[pairsIndex]=otftmsno;
               OTFTmsD2[pairsIndex]=otftmsno;
               OTFTmsD3[pairsIndex]=otftmsno;
               OTFTmsD4[pairsIndex]=(string)(int)TdiRed;;
               OTFTmsD5[pairsIndex]=otftmsno;
               OTFTmsD6[pairsIndex]=(string)(int)TdiRed;

               //up
               if (TdiGreen > TdiRed && PrevTdiGreen < TdiRed) OTFTmsD1[pairsIndex]=otftmsup;
               if (StochVal > StochLow && PrevStochVal < StochVal) OTFTmsD2[pairsIndex]=otftmsup;
               if (CL0 > SmaVal) OTFTmsD3[pairsIndex]=otftmsup;
               if (TdiRed < TDiLow) OTFTmsD4[pairsIndex]=otftmsup;
               if (AskVal >= OP0) OTFTmsD5[pairsIndex]=otftmsup;
               if (TdiRed < TDiLow) OTFTmsD6[pairsIndex]=otftmsup;

               //dn
               if (TdiGreen < TdiRed && PrevTdiGreen > TdiRed) OTFTmsD1[pairsIndex]=otftmsdn;
               if (StochVal > StochHigh && PrevStochVal > StochVal) OTFTmsD2[pairsIndex]=otftmsdn;
               if (CL0 < SmaVal) OTFTmsD3[pairsIndex]=otftmsdn;
               if (TdiRed > TDiHigh) OTFTmsD4[pairsIndex]=otftmsdn;
               if (BidVal <= OP0) OTFTmsD5[pairsIndex]=otftmsdn;
               if (TdiRed > TDiHigh) OTFTmsD6[pairsIndex]=otftmsdn;

               if
               (
               (TdiGreen > TdiRed && PrevTdiGreen < TdiRed)
               &&
               (StochVal > StochLow && PrevStochVal < StochVal)
               &&
               (CL0 > SmaVal)
               &&
               (TdiRed < TDiLow)
               &&
               (CL0 > SmaVal)
               &&
               (TdiRed < TDiLow)
               )
               OTFTmsStatus[pairsIndex]=otftmsup;

               if
               (
               (TdiGreen < TdiRed && PrevTdiGreen > TdiRed)
               &&
               (StochVal > StochHigh && PrevStochVal > StochVal)
               &&
               (CL0 < SmaVal)
               &&
               (TdiRed > TDiHigh)
               &&
               (CL0 < SmaVal)
               &&
               (TdiRed > TDiHigh)
               )
               OTFTmsStatus[pairsIndex]=otftmsdn;
            }

        if (UseChaosOnOwnTimeFrame)
            {
               OTFChaosStatus[pairsIndex] = otfchaosno;
//               int signal_period=GetPeriod(s_signal_period);
               int signal_period=OwnChaosTimeFrame;
//               upfractal=iFractals(symbol,signal_period, MODE_UPPER, 2);
//               dwfractal=iFractals(symbol,signal_period, MODE_LOWER, 2);
               upfractal=iCustom(symbol,signal_period,"FractalsMod",0,0);
               dwfractal=iCustom(symbol,signal_period,"FractalsMod",1,0);


               double Teeth = iAlligator(symbol, signal_period, JawPeriod, JawShift, TeethPeriod, TeethShift, 
                           LipsPeriod, LipsShift, AlligatorMethod, AlligatorPrice, 
                           MODE_GATORTEETH, 1);

               double AO1 =  iAO(symbol, signal_period, 1);
               double AO2 =  iAO(symbol, signal_period, 2);
               double AO3 =  iAO(symbol, signal_period, 3);

               double AC1 =  iAC(symbol, signal_period, 1);
               double AC2 =  iAC(symbol, signal_period, 2);
               double AC3 =  iAC(symbol, signal_period, 3);
               double AC4 =  iAC(symbol, signal_period, 4);
               double AC5 =  iAC(symbol, signal_period, 5);

               double CL1 =  iClose(symbol, signal_period, 1);
               double CL2 =  iClose(symbol, signal_period, 2);
           
					OTFChaosD1[pairsIndex] = otfchaosno;
					OTFChaosD2[pairsIndex] = otfchaosno;
					OTFChaosD3[pairsIndex] = otfchaosno;
					OTFChaosD4[pairsIndex] = otfchaosno;
					OTFChaosD5[pairsIndex] = otfchaosno;
           //UP
					//1
					if (dwfractal!=0 && dwfractal<upfractal && dwfractal<Teeth)// down fractal under the teeth
						OTFChaosD1[pairsIndex] = otfchaosup;
					//2
					if((AO1>0 && AO2<0) || // upward crossover of zero line
						(AO1>AO2 && AO2>0 && AO3>AO2)) // saucer above the zero line
						OTFChaosD2[pairsIndex] = otfchaosup;
					//3
					if((AC1>AC2 && AC1>0 && AC2>AC3) || //(buy) ÀÑ 2 bars up
						(AC1>AC2 && AC3<0 && AC2>AC3 && AC3>AC4)) //(buy) ÀÑ 3 bars up (3rd below the zero line)
						OTFChaosD3[pairsIndex] = otfchaosup;
					//4
					if(AO1>AO2 && AO2>AO3 && AC1>AC2 && AC2>AC3 && CL1>CL2)
						OTFChaosD4[pairsIndex] = otfchaosup;
					//5
					if(CL1>Teeth) // last close above the Teeth
						OTFChaosD5[pairsIndex] = otfchaosup;
          //DOWN
					//1
					if (upfractal!=0 && upfractal>dwfractal && upfractal>Teeth)// up fractal above the teeth
						OTFChaosD1[pairsIndex] = otfchaosdn;
					//2
   				if((AO1<0 && AO2>0) || // downward crossover of zero line
						(AO1<AO2 && AO2<0 && AO3<AO2)) // saucer below the zero line
						OTFChaosD2[pairsIndex] = otfchaosdn;
					//3
					if((AC1<AC2 && AC1<0 && AC2<AC3) || //(sell) ÀÑ 2 bars down
						(AC1<AC2 && AC3>0 && AC2<AC3 && AC3>AC4)) //(sell) ÀÑ 3 bars down (3rd above the zero line)
						OTFChaosD3[pairsIndex] = otfchaosdn;
					//4
					if(AO1<AO2 && AO2<AO3 && AC1<AC2 && AC2<AC3 && CL1<CL2)
						OTFChaosD4[pairsIndex] = otfchaosdn;
					//5
					if(CL1<Teeth) // last close under the Teeth
						OTFChaosD5[pairsIndex] = otfchaosdn;
           //UP
               if(
                  (dwfractal!=0 && dwfractal<upfractal && dwfractal<Teeth) // down fractal under the teeth
                  &&
                  ((AO1>0 && AO2<0) || // upward crossover of zero line
						(AO1>AO2 && AO2>0 && AO3>AO2)) // saucer above the zero line &&
						&&
                  ((AC1>AC2 && AC1>0 && AC2>AC3) || //(buy) ÀÑ 2 bars up
						(AC1>AC2 && AC3<0 && AC2>AC3 && AC3>AC4)) //(buy) ÀÑ 3 bars up (3rd below the zero line)
                  &&
                  (AO1>AO2 && AO2>AO3 && AC1>AC2 && AC2>AC3 && CL1>CL2)
                  &&
                  (CL1>Teeth) // last close above the Teeth
                 )
               OTFChaosStatus[pairsIndex] = otfchaosup;
          //DOWN
               if (
                  (upfractal!=0 && upfractal>dwfractal && upfractal>Teeth)// up fractal above the teeth
                  &&
                  ((AO1<0 && AO2>0) || // downward crossover of zero line
						(AO1<AO2 && AO2<0 && AO3<AO2)) // saucer below the zero line
                  &&
                  ((AC1<AC2 && AC1<0 && AC2<AC3) || //(sell) ÀÑ 2 bars down
						(AC1<AC2 && AC3>0 && AC2<AC3 && AC3>AC4)) //(sell) ÀÑ 3 bars down (3rd above the zero line)
                  &&
                  (AO1<AO2 && AO2<AO3 && AC1<AC2 && AC2<AC3 && CL1<CL2)
                  &&
                  (CL1<Teeth)
                  )
               OTFChaosStatus[pairsIndex] = otfchaosdn;

            }//if (UseChaosOnOwnTimeFrame)

		 
		 
      if (UseFBOnOwnTimeFrame)
         if (FBBarTime[pairsIndex] != iTime(symbol, OwnFBTimeFrame, 0))//Changed by CHS
         {
            OTFFbStatus[pairsIndex] = otffbnoarrow;
            //Buffer 2 holds blue up arrow
            double Fbval = GetFlyingBuddha(symbol, OwnFBTimeFrame, FbFastPeriod, FbFastAvgMode, FbFastPrice, 
                                         FbSlowPeriod, FbSlowAvgMode, FbSlowPrice, 2, 1);
            if (!CloseEnough(Fbval, EMPTY_VALUE) )
               OTFFbStatus[pairsIndex] = otffbuparrow;
            
            if (OTFFbStatus[pairsIndex] == otffbnoarrow)
            {
               //Buffer 3 holds red down arrow
               Fbval = GetFlyingBuddha(symbol, OwnFBTimeFrame, FbFastPeriod, FbFastAvgMode, FbFastPrice, 
                                     FbSlowPeriod, FbSlowAvgMode, FbSlowPrice, 3, 1);
               if (!CloseEnough(Fbval, EMPTY_VALUE) )
                  OTFFbStatus[pairsIndex] = otffbdownarrow;
                  
            }//if (FbStatus[pairsIndex][tfIndex] == fbnoarrow)
         }//if (UseFBOnOwnTimeFrame)

      if (UseMaOnOwnTimeFrame)
         if (MaBarTime[pairsIndex] != iTime(symbol, OwnMaTimeFrame, 0))//Changed by CHS
         {
            OTFMaTrend[pairsIndex] = otfmanotrend;//Default            
         
            MaVal1 = iMA(symbol,OwnMaTimeFrame,MaTrendPeriodLow,0,MODE_EMA,PRICE_CLOSE,1);            
            MaVal2 = iMA(symbol,OwnMaTimeFrame,MaTrendPeriodHigh,0,MODE_EMA,PRICE_CLOSE,1);

               if(MaVal1 > MaVal2)
               {
                  OTFMaTrend[pairsIndex] = otfmaUp;
               }

               if(MaVal1 < MaVal2)
               {
                  OTFMaTrend[pairsIndex] = otfmaDown;
               }
         }//if (UseMaOnOwnTimeFrame)


      if (UseHGIOnOwnTimeFrame)
         if (HGIBarTime[pairsIndex] != iTime(symbol, OwnHGITimeFrame, 0))//Changed by CHS
         {
            //Using hgi_lib
            SIGNAL signal = 0;
            SLOPE  slope  = 0;

            //Loop back through candles
            for (int lookback = 0; lookback <= OwnHGITimeFrameCandlesLookBack; lookback++)
            {
               //The HGI library functionality was added by tomele. Many thanks Thomas.
               signal = getHGISignal(symbol, OwnHGITimeFrame, lookback+1);//This library function looks for arrows.
               slope  = getHGISlope (symbol, OwnHGITimeFrame, lookback+1);//This library function looks for wavy lines.
   
               OTFHgiStatus[pairsIndex] = otfhginoarrow;
               if (signal==TRENDUP)
               {
                  if (TrendTradingAllowed)
                     OTFHgiStatus[pairsIndex] = otfhgiuparrow;
               }
               else 
               if (signal==TRENDDN)
               {
                  if (TrendTradingAllowed)
                     OTFHgiStatus[pairsIndex] = otfhgidownarrow;//Amended by CHS
                  break;
               }
               else 
               if (slope==TRENDBELOW)
               {
                  if (BlueWaveTradingAllowed)
                     OTFHgiStatus[pairsIndex] = otfhgiupwave;
               }
               else 
               if (slope==TRENDABOVE)
               {
                  if (BlueWaveTradingAllowed)
                     OTFHgiStatus[pairsIndex] = otfhgidownwave;
               }
               else
               if (signal==RADUP)
               {
                  if (RadTradingAllowed)
                     OTFHgiStatus[pairsIndex] = otfhgiupradarrow;//Amended by CHS
               }
               else 
               if (signal==RADDN)
               {
                  if (RadTradingAllowed)
                     OTFHgiStatus[pairsIndex] = otfhgidownradarrow;//Amended by CHS
               }
               
               //Found last signal, so dont look back further
               if (OTFHgiStatus[pairsIndex] != otfhginoarrow)
                  break;

            }   
         }//if (UseHGIOnOwnTimeFrame)


      //We need to check if there is sufficient movement on a currency pair
      if (UseRangingFilter)
      {
         if (RanBarTime[pairsIndex] != iTime(symbol, RangingTimeFrame, 0))//Changed by CHS
         {
            GetHighestAndLowestClose(symbol, RangingTimeFrame, pairsIndex);
   
            if(HighestHighValue - LowestLowValue <= RangeNoTradePips/factor)
            {
               OTFRangingDirection[pairsIndex] = otfnodirection;
            }

            if(HighestHighValue - LowestLowValue > RangeNoTradePips/factor)
            {
               OTFRangingDirection[pairsIndex] = otfbothdirection;
            }
         }
      }//if (UseRangingFilter)

      if (UseNewsFilter)
      {
         NewsStatus[pairsIndex] = nonews;
         int numGVs = GlobalVariablesTotal();
         for (int n=0; n<numGVs; n++)
         {
            string globalvarname = GlobalVariableName(n);
            if (StringFind(globalvarname,"NEWS", 0) > -1) {
               string newsline = globalvarname;
               const ushort comma = StringGetChar(",",0);
               StringSplit( newsline, comma, newsarray);
               int timetillnews = StrToInteger(newsarray[3]) - (int) TimeLocal();
               if (timetillnews < 0) {GlobalVariableDel(globalvarname); continue;}
               if (StringFind(symbol,newsarray[1], 0) > -1)
                  if (FilterOnHighImpactNews && StringFind(newsarray[2],"High", 0) > -1) 
                     if (timetillnews < StopTradingSecondsBeforeHighImpact)
                      NewsStatus[pairsIndex] = yesnews;
               if (StringFind(symbol,newsarray[1], 0) > -1)
                  if (FilterOnMediumImpactNews && StringFind(newsarray[2],"Medium", 0) > -1)
                     if (timetillnews < StopTradingSecondsBeforeMediumImpact)
                      NewsStatus[pairsIndex] = yesnews;
               if (StringFind(symbol,newsarray[1], 0) > -1)
                  if (FilterOnLowImpactNews && StringFind(newsarray[2],"Low", 0) > -1)
                     if (timetillnews < StopTradingSecondsBeforeLowImpact)
                      NewsStatus[pairsIndex] = yesnews;
             }
         }
      }//if (UseNewsFilter)


      //Iterate through the time frames chosen by the user.
      for (int tfIndex = 0; tfIndex < ArraySize(TimeFrames); tfIndex++)
      {

        //We need to know positions before and after trade signals - DXH
         //Build a picture of the trade position.
         CountOpenTrades(symbol, MagicNumbers[tfIndex], tfIndex);
         
         BuySignal = false;
         SellSignal = false;

         if (TradingBarTime[TradingBarCounter] != iTime(symbol, TimeFrames[tfIndex], 0) )
         {   

            BuySignal = false;
            SellSignal = false;

            if (UsePeakyOnTradingTimeFrame)
            {
               //Get the bar shift of the peaks
               int currentPeakHighBar = iHighest(symbol, TimeFrames[tfIndex], MODE_CLOSE, NoOfBars, 1);
               int currentPeakLowBar = iLowest(symbol, TimeFrames[tfIndex], MODE_CLOSE, NoOfBars, 1);
            
               //Read the peak prices
               PeakHigh = iClose(symbol, TimeFrames[tfIndex], currentPeakHighBar);
               PeakLow = iClose(symbol, TimeFrames[tfIndex], currentPeakLowBar);

               PeakyMarketDirection[pairsIndex][tfIndex] = peakynodirection;               
               //Calculate the market direction.
               //Short
               if (currentPeakHighBar < currentPeakLowBar)
                  PeakyMarketDirection[pairsIndex][tfIndex] = peakyshortdirection;
               else   
                  PeakyMarketDirection[pairsIndex][tfIndex] = peakylongdirection;
            }//if (UsePeakyOnTradingTimeFrame)


            //Read superslope at the open of a new bar
            if (UseSuperSlopeOnTradingTimeFrame)
            {
               SsTtfCurr1Val = GetSuperSlope(symbol, TimeFrames[tfIndex], SsTradingSlopeMAPeriod,SsTradingSlopeATRPeriod,1);

                  //Changed by tomele
                  //Set the colours
                  SsColour[pairsIndex][tfIndex] = white;
                  if (SsTtfCurr1Val > 0)  //buy
                     if (SsTtfCurr1Val - SsTradingDifferenceThreshold/2 > 0) //blue
                        SsColour[pairsIndex][tfIndex] = blue;
   
                  if (SsTtfCurr1Val < 0)  //sell
                     if (SsTtfCurr1Val + SsTradingDifferenceThreshold/2 < 0) //red
                        SsColour[pairsIndex][tfIndex] = red;
            }//if (UseSuperSlopeOnTradingTimeFrame)

            if (UseTMSOnTradingTimeFrame)
            {
//               symbol=Symbol();
//               int signal_period=OwnChaosTimeFrame;
               int signal_period=TimeFrames[tfIndex];
               TdiGreen = iCustom(symbol, signal_period, "TDI Red Green", 13, 0, 34, 2, 0, 7, 0,  4, 0);
               PrevTdiGreen = iCustom(symbol, signal_period, "TDI Red Green", 13, 0, 34, 2, 0, 7, 0,  4, 1);
               TdiRed = iCustom(symbol, signal_period, "TDI Red Green", 13, 0, 34, 2, 0, 7, 0,  5, 0);
               SmaVal = iMA(symbol, signal_period, 5, 1, MODE_SMA, PRICE_TYPICAL, 0);
               StochVal = iStochastic(symbol, signal_period, 8,3,3,0,0,0,0);
               PrevStochVal = iStochastic(symbol, signal_period, 8,3,3,0,0,0,1);
               AskVal = MarketInfo(symbol,MODE_ASK);
               BidVal = MarketInfo(symbol,MODE_BID);
               double OP0 =  iOpen(symbol, signal_period, 0);
               double OP1 =  iOpen(symbol, signal_period, 1);
               double CL0 =  iClose(symbol, signal_period, 0);
               TmsStatus[pairsIndex][tfIndex]=tmsno;
               TmsD1[pairsIndex][tfIndex]=tmsno;
               TmsD2[pairsIndex][tfIndex]=tmsno;
               TmsD3[pairsIndex][tfIndex]=tmsno;
               TmsD4[pairsIndex][tfIndex]=(string)(int)TdiRed;;
               TmsD5[pairsIndex][tfIndex]=tmsno;
               TmsD6[pairsIndex][tfIndex]=(string)(int)TdiRed;

               //up
               if (TdiGreen > TdiRed && PrevTdiGreen < TdiRed) TmsD1[pairsIndex][tfIndex]=tmsup;
               if (StochVal > StochLow && PrevStochVal < StochVal) TmsD2[pairsIndex][tfIndex]=tmsup;
               if (CL0 > SmaVal) TmsD3[pairsIndex][tfIndex]=tmsup;
               if (TdiRed < TDiLow) TmsD4[pairsIndex][tfIndex]=tmsup;
               if (AskVal >= OP0) TmsD5[pairsIndex][tfIndex]=tmsup;
               if (TdiRed < TDiLow) TmsD6[pairsIndex][tfIndex]=tmsup;

               //dn
               if (TdiGreen < TdiRed && PrevTdiGreen > TdiRed) TmsD1[pairsIndex][tfIndex]=tmsdn;
               if (StochVal > StochHigh && PrevStochVal > StochVal) TmsD2[pairsIndex][tfIndex]=tmsdn;
               if (CL0 < SmaVal) TmsD3[pairsIndex][tfIndex]=tmsdn;
               if (TdiRed > TDiHigh) TmsD4[pairsIndex][tfIndex]=tmsdn;
               if (BidVal <= OP0) TmsD5[pairsIndex][tfIndex]=tmsdn;
               if (TdiRed > TDiHigh) TmsD6[pairsIndex][tfIndex]=tmsdn;

               if
               (
               (TdiGreen > TdiRed && PrevTdiGreen < TdiRed)
               &&
               (StochVal > StochLow && PrevStochVal < StochVal)
               &&
               (CL0 > SmaVal)
               &&
               (TdiRed < TDiLow)
               &&
               (CL0 > SmaVal)
               &&
               (TdiRed < TDiLow)
               )
               TmsStatus[pairsIndex][tfIndex]=tmsup;

               if
               (
               (TdiGreen < TdiRed && PrevTdiGreen > TdiRed)
               &&
               (StochVal > StochHigh && PrevStochVal > StochVal)
               &&
               (CL0 < SmaVal)
               &&
               (TdiRed > TDiHigh)
               &&
               (CL0 < SmaVal)
               &&
               (TdiRed > TDiHigh)
               )
               TmsStatus[pairsIndex][tfIndex]=tmsdn;
            }

/*
               //buy
               //Green/red cross
               if (TdiGreen < TdiRed) return(false);//Green below red
               if (TdiGreen > TdiRed && PrevTdiGreen > TdiRed) return(false);//No cross
               //Green angle
               if(PrevTdiGreen = TdiGreen) return(false);
               //Current candle must be green
               if (Ask <= Open[0] ) return(false);
               //Prev candle must close above sma
               if (Close[1] < SmaVal) return(false);

               //sell
               //Green/red cross
               if (TdiGreen > TdiRed) return(false);//Green above red
               if (TdiGreen < TdiRed && PrevTdiGreen < TdiRed) return(false);//No cross
               //Green angle
               if(PrevTdiGreen <= TdiGreen) return(false);
               //Current candle must be green
               if (Bid >= Open[0] ) return(false);
               //Prev candle must close below sma
               if (Close[1] > SmaVal) return(false);
*/   







            if (UseChaosOnTradingTimeFrame)
            {
               ChaosStatus[pairsIndex][tfIndex] = chaosno;
//               int signal_period=GetPeriod(s_signal_period);
               int signal_period=TimeFrames[tfIndex];
//               upfractal=iFractals(symbol,signal_period, MODE_UPPER, 2);
//               dwfractal=iFractals(symbol,signal_period, MODE_LOWER, 2);
               upfractal=iCustom(symbol,signal_period,"FractalsMod",0,0);
               dwfractal=iCustom(symbol,signal_period,"FractalsMod",1,0);


               double Teeth = iAlligator(symbol, signal_period, JawPeriod, JawShift, TeethPeriod, TeethShift, 
                           LipsPeriod, LipsShift, AlligatorMethod, AlligatorPrice, 
                           MODE_GATORTEETH, 1);

               double AO1 =  iAO(symbol, signal_period, 1);
               double AO2 =  iAO(symbol, signal_period, 2);
               double AO3 =  iAO(symbol, signal_period, 3);

               double AC1 =  iAC(symbol, signal_period, 1);
               double AC2 =  iAC(symbol, signal_period, 2);
               double AC3 =  iAC(symbol, signal_period, 3);
               double AC4 =  iAC(symbol, signal_period, 4);
               double AC5 =  iAC(symbol, signal_period, 5);

               double CL1 =  iClose(symbol, signal_period, 1);
               double CL2 =  iClose(symbol, signal_period, 2);
           
					ChaosD1[pairsIndex][tfIndex] = chaosno;
					ChaosD2[pairsIndex][tfIndex] = chaosno;
					ChaosD3[pairsIndex][tfIndex] = chaosno;
					ChaosD4[pairsIndex][tfIndex] = chaosno;
					ChaosD5[pairsIndex][tfIndex] = chaosno;
           //UP
					//1
					if (dwfractal!=0 && dwfractal<upfractal && dwfractal<Teeth)// down fractal under the teeth
						ChaosD1[pairsIndex][tfIndex] = chaosup;
					//2
					if((AO1>0 && AO2<0) || // upward crossover of zero line
						(AO1>AO2 && AO2>0 && AO3>AO2)) // saucer above the zero line
						ChaosD2[pairsIndex][tfIndex] = chaosup;
					//3
					if((AC1>AC2 && AC1>0 && AC2>AC3) || //(buy) ÀÑ 2 bars up
						(AC1>AC2 && AC3<0 && AC2>AC3 && AC3>AC4)) //(buy) ÀÑ 3 bars up (3rd below the zero line)
						ChaosD3[pairsIndex][tfIndex] = chaosup;
					//4
					if(AO1>AO2 && AO2>AO3 && AC1>AC2 && AC2>AC3 && CL1>CL2)
						ChaosD4[pairsIndex][tfIndex] = chaosup;
					//5
					if(CL1>Teeth) // last close above the Teeth
						ChaosD5[pairsIndex][tfIndex] = chaosup;
          //DOWN
					//1
					if (upfractal!=0 && upfractal>dwfractal && upfractal>Teeth)// up fractal above the teeth
						ChaosD1[pairsIndex][tfIndex] = chaosdn;
					//2
   				if((AO1<0 && AO2>0) || // downward crossover of zero line
						(AO1<AO2 && AO2<0 && AO3<AO2)) // saucer below the zero line
						ChaosD2[pairsIndex][tfIndex] = chaosdn;
					//3
					if((AC1<AC2 && AC1<0 && AC2<AC3) || //(sell) ÀÑ 2 bars down
						(AC1<AC2 && AC3>0 && AC2<AC3 && AC3>AC4)) //(sell) ÀÑ 3 bars down (3rd above the zero line)
						ChaosD3[pairsIndex][tfIndex] = chaosdn;
					//4
					if(AO1<AO2 && AO2<AO3 && AC1<AC2 && AC2<AC3 && CL1<CL2)
						ChaosD4[pairsIndex][tfIndex] = chaosdn;
					//5
					if(CL1<Teeth) // last close under the Teeth
						ChaosD5[pairsIndex][tfIndex] = chaosdn;
           //UP
               if(
                  (dwfractal!=0 && dwfractal<upfractal && dwfractal<Teeth) // down fractal under the teeth
                  &&
                  ((AO1>0 && AO2<0) || // upward crossover of zero line
						(AO1>AO2 && AO2>0 && AO3>AO2)) // saucer above the zero line &&
						&&
                  ((AC1>AC2 && AC1>0 && AC2>AC3) || //(buy) ÀÑ 2 bars up
						(AC1>AC2 && AC3<0 && AC2>AC3 && AC3>AC4)) //(buy) ÀÑ 3 bars up (3rd below the zero line)
                  &&
                  (AO1>AO2 && AO2>AO3 && AC1>AC2 && AC2>AC3 && CL1>CL2)
                  &&
                  (CL1>Teeth) // last close above the Teeth
                 )
               ChaosStatus[pairsIndex][tfIndex] = chaosup;
          //DOWN
               if (
                  (upfractal!=0 && upfractal>dwfractal && upfractal>Teeth)// up fractal above the teeth
                  &&
                  ((AO1<0 && AO2>0) || // downward crossover of zero line
						(AO1<AO2 && AO2<0 && AO3<AO2)) // saucer below the zero line
                  &&
                  ((AC1<AC2 && AC1<0 && AC2<AC3) || //(sell) ÀÑ 2 bars down
						(AC1<AC2 && AC3>0 && AC2<AC3 && AC3>AC4)) //(sell) ÀÑ 3 bars down (3rd above the zero line)
                  &&
                  (AO1<AO2 && AO2<AO3 && AC1<AC2 && AC2<AC3 && CL1<CL2)
                  &&
                  (CL1<Teeth)
                  )
               ChaosStatus[pairsIndex][tfIndex] = chaosdn;

/*               
               if(
                  (ChaosD1[pairsIndex][tfIndex] == chaosd1no) &&
                  (ChaosD2[pairsIndex][tfIndex] == chaosd2up) &&
                  (ChaosD3[pairsIndex][tfIndex] == chaosd3up) &&
                  (ChaosD4[pairsIndex][tfIndex] == chaosd4up) &&
                  (ChaosD5[pairsIndex][tfIndex] == chaosd5up) 
                 )
               ChaosStatus[pairsIndex][tfIndex] = chaosuparrow;

               if (
                  (ChaosD1[pairsIndex][tfIndex] == chaosd1up) &&
                  (ChaosD2[pairsIndex][tfIndex] == chaosd2dn) &&
                  (ChaosD3[pairsIndex][tfIndex] == chaosd3dn) &&
                  (ChaosD4[pairsIndex][tfIndex] == chaosd4dn) &&
                  (ChaosD5[pairsIndex][tfIndex] == chaosd5dn)
                  )
               ChaosStatus[pairsIndex][tfIndex] = chaosdownarrow;
*/
            }//if (UseChaosOnTradingTimeFrame)

            if (UseFBOnTradingTimeFrame)
            {
               FbStatus[pairsIndex][tfIndex] = fbnoarrow;
               //Buffer 2 holds blue up arrow
               double Fbval = GetFlyingBuddha(symbol, TimeFrames[tfIndex], FbFastPeriod, FbFastAvgMode, FbFastPrice, 
                                            FbSlowPeriod, FbSlowAvgMode, FbSlowPrice, 2, 1);
               if (!CloseEnough(Fbval, EMPTY_VALUE) )
                  FbStatus[pairsIndex][tfIndex] = fbuparrow;
               
               if (FbStatus[pairsIndex][tfIndex] == fbnoarrow)
               {
                  //Buffer 3 holds red down arrow
                  Fbval = GetFlyingBuddha(symbol, TimeFrames[tfIndex], FbFastPeriod, FbFastAvgMode, FbFastPrice, 
                                        FbSlowPeriod, FbSlowAvgMode, FbSlowPrice, 3, 1);
                  if (!CloseEnough(Fbval, EMPTY_VALUE) )
                     FbStatus[pairsIndex][tfIndex] = fbdownarrow;

               }
            }//if (UseFBOnTradingTimeFrame)


            if (UseMaOnTradingTimeFrame)
            {
               MaTrend[pairsIndex][tfIndex] = manotrend;//Default            
            
               MaVal1 = iMA(symbol,TimeFrames[tfIndex],MaTrendPeriodLow,0,MODE_EMA,PRICE_CLOSE,1);            
               MaVal2 = iMA(symbol,TimeFrames[tfIndex],MaTrendPeriodHigh,0,MODE_EMA,PRICE_CLOSE,1);

                  if(MaVal1 > MaVal2)
                  {
                     MaTrend[pairsIndex][tfIndex] = maUp;
                  }

                  if(MaVal1 < MaVal2)
                  {
                     MaTrend[pairsIndex][tfIndex] = maDown;
                  }
            }//if (UseMaOnTradingTimeFrame)
     

            if (UseHGIOnTradingTimeFrame)
            {
               //Using hgi_lib
               SIGNAL signal = 0;
               SLOPE  slope  = 0;
   
               //The HGI library functionality was added by tomele. Many thanks Thomas.
               signal = getHGISignal(symbol, TimeFrames[tfIndex], 1);//This library function looks for arrows.
               slope  = getHGISlope (symbol, TimeFrames[tfIndex], 1);//This library function looks for wavy lines.
   
               HgiStatus[pairsIndex][tfIndex] = hginoarrow;
               if (signal==TRENDUP)
               {
                  if (TrendTradingAllowed)
                  HgiStatus[pairsIndex][tfIndex] = hgiuparrow;
               }
               else 
               if (signal==TRENDDN)
               {
                  if (TrendTradingAllowed)
                     HgiStatus[pairsIndex][tfIndex] = hgidownarrow;//Amended by CHS
               }
               else 
               if (slope==TRENDBELOW)
               {
                  if (BlueWaveTradingAllowed)
                     HgiStatus[pairsIndex][tfIndex] = hgiupwave;
               }
               else 
               if (slope==TRENDABOVE)
               {
                  if (BlueWaveTradingAllowed)
                     HgiStatus[pairsIndex][tfIndex] = hgidownwave;
               }
               else
               if (signal==RADUP)
               {
                  if (RadTradingAllowed)
                  HgiStatus[pairsIndex][tfIndex] = hgiupradarrow;//Amended by CHS
               }
               else 
               if (signal==RADDN)
               {
                  if (RadTradingAllowed)
                     HgiStatus[pairsIndex][tfIndex] = hgidownradarrow;//Amended by CHS
               }
            }//if (UseHGIOnTradingTimeFrame)
                  
            //Do we have a trade signal?
            
            //Buy
            if (!UseRangingFilter || OTFRangingDirection[pairsIndex] == otfbothdirection)//CHS new Amendment
               if (!UsePeakyOnOwnTimeFrame ||  OTFPeakyMarketDirection[pairsIndex] == otfpeakylongdirection)
                  if (!UseSuperSlopeOnOwnTimeFrame || OTFSsColour[pairsIndex] == otfblue)
                     if (!UseChaosOnOwnTimeFrame || OTFChaosStatus[pairsIndex] == otfchaosup)
                     if (!UseTMSOnOwnTimeFrame || OTFTmsStatus[pairsIndex] == otftmsup)
                     if (!UseFBOnOwnTimeFrame || OTFFbStatus[pairsIndex] == otffbuparrow)
                        if (!UseMaOnOwnTimeFrame || OTFMaTrend[pairsIndex] == otfmaUp)
                           if (!UseHGIOnOwnTimeFrame || OTFHgiStatus[pairsIndex] == otfhgiuparrow || OTFHgiStatus[pairsIndex] == otfhgiupwave || OTFHgiStatus[pairsIndex] == hgiupradarrow)
                              if (!PositiveSwapOnly[tfIndex] || longSwap >= 0)
                                 if (!UsePeakyOnTradingTimeFrame ||  PeakyMarketDirection[pairsIndex][tfIndex] == peakylongdirection)
                                    if (!UseSuperSlopeOnTradingTimeFrame || SsColour[pairsIndex][tfIndex] == blue)
                                       if (!UseFBOnTradingTimeFrame || FbStatus[pairsIndex][tfIndex] == fbuparrow)
                                          if (!UseMaOnTradingTimeFrame || MaTrend[pairsIndex][tfIndex] == maUp)
                                             if (!UseHGIOnTradingTimeFrame || HgiStatus[pairsIndex][tfIndex] == hgiuparrow || HgiStatus[pairsIndex][tfIndex] == hgiupwave || HgiStatus[pairsIndex][tfIndex] == hgiupradarrow)
                                                if (!UseNewsFilter || NewsStatus[pairsIndex] == nonews)
											                  if (!UseChaosOnTradingTimeFrame || ChaosStatus[pairsIndex][tfIndex] == chaosup)
											                     if (!UseTMSOnTradingTimeFrame || TmsStatus[pairsIndex][tfIndex] == tmsup)
                                                      BuySignal = true;
         
            
            //Sell
            if (!UseRangingFilter || OTFRangingDirection[pairsIndex] == otfbothdirection)//CHS new Amendment
               if (!UsePeakyOnOwnTimeFrame ||  OTFPeakyMarketDirection[pairsIndex] == otfpeakyshortdirection)
                  if (!UseSuperSlopeOnOwnTimeFrame || OTFSsColour[pairsIndex] == otfred)
                     if (!UseChaosOnOwnTimeFrame || OTFChaosStatus[pairsIndex] == otfchaosdn)
                     if (!UseTMSOnOwnTimeFrame || OTFChaosStatus[pairsIndex] == otftmsdn)
                     if (!UseFBOnOwnTimeFrame || OTFFbStatus[pairsIndex] == otffbdownarrow)
                        if (!UseMaOnOwnTimeFrame || OTFMaTrend[pairsIndex] == otfmaDown)
                           if (!UseHGIOnOwnTimeFrame || OTFHgiStatus[pairsIndex] == otfhgidownarrow || OTFHgiStatus[pairsIndex] == otfhgidownwave || OTFHgiStatus[pairsIndex] == otfhgidownradarrow)
                              if (!PositiveSwapOnly[tfIndex] || shortSwap >= 0)
                                 if (!UsePeakyOnTradingTimeFrame ||  PeakyMarketDirection[pairsIndex][tfIndex] == peakyshortdirection)
                                    if (!UseSuperSlopeOnTradingTimeFrame || SsColour[pairsIndex][tfIndex] == red)
                                       if (!UseFBOnTradingTimeFrame || FbStatus[pairsIndex][tfIndex] == fbdownarrow)
                                          if (!UseMaOnTradingTimeFrame || MaTrend[pairsIndex][tfIndex] == maDown)
                                             if (!UseHGIOnTradingTimeFrame || HgiStatus[pairsIndex][tfIndex] == hgidownarrow || HgiStatus[pairsIndex][tfIndex] == hgidownwave || HgiStatus[pairsIndex][tfIndex] == hgidownradarrow)
                                                if (!UseNewsFilter || NewsStatus[pairsIndex] == nonews)
                                                   if (!UseChaosOnTradingTimeFrame || ChaosStatus[pairsIndex][tfIndex] == chaosdn)
                                                   if (!UseTMSOnTradingTimeFrame || TmsStatus[pairsIndex][tfIndex] == tmsdn)
                                                      SellSignal = true;
   
            TradingBarTime[TradingBarCounter] = iTime(symbol, TimeFrames[tfIndex], 0);
         
         }//if (TradingBarTime[TradingBarCounter] != iTime(symbol, TimeFrames[tfIndex], 0) )

         TradingBarCounter++;
         
         //Build a picture of the trade position.
         CountOpenTrades(symbol, MagicNumbers[tfIndex], tfIndex);
         
         //Update the trading bar time 

         //Take every trade signal
         DistanceBetweenTrades = MinTradeDistanceSingleTimeframePips[tfIndex] / factor;                     
         //Calculate MinimumDistanceBetweenSignals if using atr
         if (TradeEverySignal[tfIndex])
            if (UsePercentageOfAtrForDistance[tfIndex])
            {
               AtrVal = GetAtr(symbol, TimeFrames[tfIndex], AtrPeriod[tfIndex], 1);
               AtrVal*= (PercentageOfAtrToUs[tfIndex] / 100);
               if (AtrVal > DistanceBetweenTrades)
                  DistanceBetweenTrades = AtrVal;
            }//if (UsePercentageOfAtrForDistance)
               
         //Changed by TS
         //We need to check that the trade is far enough away from other trades
         Tradeability[pairsIndex][tfIndex]=tradable;
         if (!DistanceOK(symbol,MagicNumbers[tfIndex],ask,DistanceBetweenTrades))
            Tradeability[pairsIndex][tfIndex]=untradable;

         //Opposite direction signal trade closure
         BuyCloseSignal = false;
         SellCloseSignal = false;
         
         if (BuySignal)
            SellCloseSignal = true;
            
         if (SellSignal)
            BuyCloseSignal = true;   
         
         ////////////////////////////////////////////////////////////////////////////////////
         //Treating each individual symbol as a basket across all time frames.
         //Added by orisb. Thanks Brenden
         if (SymbolTradesBelongToBasket)
            if (MarketTradesTotal > 0)          
            {
                  SymbolMagicNumberCount++;
                  ArrayResize(SymbolMagicNumber, SymbolMagicNumberCount);
                  SymbolMagicNumber[SymbolMagicNumberCount-1] = MagicNumbers[tfIndex];       
                  SymbolMarketTrades += MarketTradesTotal;
                  SymbolPositionCashUpl += CashUpl;       
            }//if (MarketTradesTotal > 0)   
         ////////////////////////////////////////////////////////////////////////////////////
         
         //Check for individual time frame basket closure.
           if (TradeAsBasket[tfIndex] )
             if (HaveWeHitBasketTarget(tfIndex) )
               if (MarketTradesTotal > 1)
               {
                  Alert(symbol, " ", TradeComments[tfIndex], " basket profit target reached. All ", symbol, " ", TradeComments[tfIndex], " trades should have closed.");
                  CloseAllTrades(symbol, AllTrades, MagicNumbers[tfIndex]);
                  if (ForceTradeClosure)//In case a trade close/delete failed
                  {
                     CloseAllTrades(symbol, AllTrades, MagicNumbers[tfIndex]);
                     if (ForceTradeClosure)
                     {
                        CloseAllTrades(symbol, AllTrades, MagicNumbers[tfIndex]);
                        if (ForceTradeClosure)
                        {
                           CloseAllTrades(symbol, AllTrades, MagicNumbers[tfIndex]);
                           if (ForceTradeClosure)
                           {
                              Alert(symbol, " Magic number ", IntegerToString(MagicNumbers[tfIndex]), " Recovery profit target hit but trades failed to close.");
                           }//if (ForceTradeClosure)                        
                        }//if (ForceTradeClosure)                     
                     }//if (ForceTradeClosure)         
                  }//if (ForceTradeClosure)      
                  
                  continue;//No need to continue with this iteration.
               }//if (HaveWeHitBasketTarget(tfIndex) )
            
         //Check for hitting our Recovery target
         if (UseRecovery[tfIndex] )
         {
            if (BuysInRecovery)
               if (HaveWeHitRecoveryTarget(symbol, OP_BUY, tfIndex) )
               {
                  Alert(symbol, " ", TradeComments[tfIndex], " buy trades Recovery target reached. All ", symbol, " ", TradeComments[tfIndex], " buy trades should have closed.");
                  CloseAllTrades(symbol, OP_BUY, MagicNumbers[tfIndex]);
                  if (ForceTradeClosure)//In case a trade close/delete failed
                  {
                     CloseAllTrades(symbol, OP_BUY, MagicNumbers[tfIndex]);
                     if (ForceTradeClosure)
                     {
                        CloseAllTrades(symbol, OP_BUY, MagicNumbers[tfIndex]);
                        if (ForceTradeClosure)
                        {
                           CloseAllTrades(symbol, OP_BUY, MagicNumbers[tfIndex]);
                           if (ForceTradeClosure)
                           {
                              Alert(symbol, " Magic number ", IntegerToString(MagicNumbers[tfIndex]), " Order comment ", TradeComments[tfIndex], " sell trades Recovery profit target hit but trades failed to close.");
                           }//if (ForceTradeClosure)                        
                        }//if (ForceTradeClosure)                     
                     }//if (ForceTradeClosure)         
                  }//if (ForceTradeClosure)      

                  //Re-build a picture of the trade position.
                  CountOpenTrades(symbol, MagicNumbers[tfIndex], tfIndex);
                  
                  continue;//No need to continue with this iteration.
               }//if (HaveWeHitRecoveryTarget() )
               
            if (SellsInRecovery)
               if (HaveWeHitRecoveryTarget(symbol, OP_SELL, tfIndex) )
               {
                  Alert(symbol, " ", TradeComments[tfIndex], " sell trades Recovery target reached. All ", symbol, " ", TradeComments[tfIndex], " sell trades should have closed.");
                  CloseAllTrades(symbol, OP_SELL, MagicNumbers[tfIndex]);
                  if (ForceTradeClosure)//In case a trade close/delete failed
                  {
                     CloseAllTrades(symbol, OP_SELL, MagicNumbers[tfIndex]);
                     if (ForceTradeClosure)
                     {
                        CloseAllTrades(symbol, OP_SELL, MagicNumbers[tfIndex]);
                        if (ForceTradeClosure)
                        {
                           CloseAllTrades(symbol, OP_SELL, MagicNumbers[tfIndex]);
                           if (ForceTradeClosure)
                           {
                              Alert(symbol, " Magic number ", IntegerToString(MagicNumbers[tfIndex]), " Order comment ", TradeComments[tfIndex], " buy trades Recovery profit target hit but trades failed to close.");
                           }//if (ForceTradeClosure)                        
                        }//if (ForceTradeClosure)                     
                     }//if (ForceTradeClosure)         
                  }//if (ForceTradeClosure)      
                  
                  //Re-build a picture of the trade position.
                  CountOpenTrades(symbol, MagicNumbers[tfIndex], tfIndex);

                  continue;//No need to continue with this iteration.
               }//if (HaveWeHitRecoveryTarget() )
                              
         }//if (UseRecovery[tfIndex] )

         //PoS knows what trades are open, so move their opening prices
         //in line with the market forming new peaks.
         if (PendingTradesTotal >= 1)
            if (MarketTradesTotal == 0)
               CheckPricesAreStillValid(TradePair[pairsIndex], tfIndex);

         
         
         //Lot sizing. Hard lot size
         Lot = TradeLots[tfIndex];
         //Dynamic lot sizing based on account size
         if (!CloseEnough(TradeLotsPerDollop[tfIndex], 0))
         {
         	LotsPerDollopOfCash = TradeLotsPerDollop[tfIndex];
         	SizeOfDollop = TradeSizeOfDollop[tfIndex];
         	UseBalance = TradeUseBalance[tfIndex];
         	UseEquity = TradeUseEquity[tfIndex];
         	CalculateLotAsAmountPerCashDollops();
         }//if (!CloseEnough(TradeLotsPerDollop[tfIndex], 0))		

         /*
           Filling gaps when a stop order fills then the market reverses,
           leaving the market trade a long way behind. The idea is to send
           new stop orders at regular intervals. These will fill when the 
           bloody market finally pulls itself together and travels in the
           direction of the trades. The open market trades will then be
           treated as a basket and we can close out at a pre-determined
           profit.*/
         if (FollowAdverseMarketWithStopOrders)
            if (OpenTrades < MaxTradesAllowedPerTimeFrame)
               if (MarketTradesTotal > 0)
                  FillGapsWithStopOrders(TradePair[pairsIndex], tfIndex);  

         
         //Trading hours
         TradeTimeOk = CheckTradingTimes();


         //Trading. Look for the initial trade on this time frame.
         if (TradeTimeOk)//Trading hours
            if (MarginCheck())
               if (OpenTrades == 0 || (TradeEverySignal[tfIndex] && OpenTrades < MaxSignalsToFollow[tfIndex]) )//Take every trade signal
                  if (!TradingDoneForTheDay)//Profit targets
                     if (!TradingDoneForTheWeek)//Profit targets
                        if (!AlreadyTradedThisPrice)//Avoid duplicate trading
                           //Safety adapted from my shells
                           if (TimeCurrent() >= TimeToStartTrading[pairsIndex][tfIndex])//Time to start trading
                           {
                              LookForTradingOpportunities(symbol, tfIndex);
                           }//if (TimeCurrent() >= TimeToStartTrading[pairsIndex][tfIndex])
                     
         //Safety adapted from my shells
         //Update the TimeToStartTrading array counter.
         TradingTimeCounter++;
      
      }//for (int tfIndex = 0; tfIndex < ArraySize(TimeFrames); cc++)
      
      ////////////////////////////////////////////////////////////////////////////////////
      //Treating each individual symbol as a basket across all time frames.
      //Added by orisb. Thanks Brenden
      if (SymbolTradesBelongToBasket)
         if (HaveWeReachedSymbolBasketTP())
            if (SymbolMarketTrades >= SymbolMinTradesOpenForBasket) 
               if (SymbolPositionCashUpl > 0)
               {
                  Alert("Symbol profit target reached. All " + symbol + " trades should have closed.");            
                  for (int symbols = ArraySize(SymbolMagicNumber)-1; symbols >= 0; symbols--)
                  {
                      CloseAllSymbolTrades(symbol, SymbolMagicNumber[symbols]);  
                      //Attempt to force closure if there was a failure.
                      if (ForceTradeClosure)
                      {
                        int tries = 0;
                        while (ForceTradeClosure)
                        {
                           CloseAllSymbolTrades(symbol, SymbolMagicNumber[symbols]);
                           tries++;
                           if (tries >= 3)
                              ForceTradeClosure = false;//In case of accidental endless loops.
                        }//while (ForceTradeClosure)                              
                      }//if (ForceTradeClosure)                            
                  }//for (int symbols = ArraySize(SymbolMagicNumber)-1; symbols >= 0; symbols--)
              }
      ////////////////////////////////////////////////////////////////////////////////////
   
   }//for (int pairsIndex = 0; pairsIndex < ArraySize(TradePair); pairsIndex++)
   
   //Spread filter
   counter++;
   if (counter >= 100)
      counter = 0;
   
   //Have we reached a whole platform basket target?
   if (AllTradesBelongToBasket)
   {
      if (HaveWeReachedGlobalBasketTP() )
      {
         Alert("Global profit target reached. All trades should have closed.");
         NuclearOption();
         //All trades must be closed, so keep banging away until they are.
         if (ForceTradeClosure)
         {
            while (ForceTradeClosure)
            {
               NuclearOption();
               if (ForceTradeClosure)
                  Sleep(5000);//5 seconds
            }//while (ForceTradeClosure)
            
         }//if (ForceTradeClosure)
         
      }//if (HaveWeReachedGlobalBasketTP() )
      
   
   }//if (AllTradesBelongToBasket)
      

   DisplayUserFeedback();
   
}//End void OnTimer()

//+------------------------------------------------------------------+
