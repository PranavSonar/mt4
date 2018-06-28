
//+-------------------------------------------------------------------+
//|                              Holy Graily Bob 'n Grid Experimental |
//|                                    Copyright 2012, Steve Hopwood  |
//|                              http://www.hopwood3.freeserve.co.uk  |
//+-------------------------------------------------------------------+

#define  version "Version 2d"

#property copyright "Copyright 2012, Steve Hopwood"
#property link      "http://www.hopwood3.freeserve.co.uk"
#include <WinUser32.mqh>
#include <stdlib.mqh>
#define  NL    "\n"
#define  up "Up"
#define  down "Down"
#define  crossing ": Crossing"
#define  ranging "Ranging"
#define  none "None"
#define  both "Both"
#define  buy "Buy"
#define  sell "Sell"

#define  million 1000000;
#define ordercomment "HGB 'n G" //MJB

//Define the FifoBuy/SellTicket fields
#define  TradeOpenTime 0
#define  TradeTicket 1
#define  TradeProfitCash 2 //Cash profit
#define  TradeProfitPips 3 //Pips profit

//Define the GridBuy/SellTicket fields
#define  TradeOpenPrice 0
//#define  TradeTicket 1 /// can use the one above.


//Semafor status
#define  nosemafor " No signal found on previous candle"
#define  highsemafor " High signal found on previous candle"
#define  lowsemafor " Low signal found on previous candle"
#define  highsemafornow " High signal emerging on current candle"
#define  lowsemafornow " Low signal emerging on current candle"

//HGI signal status
#define  hginosignal ": No trade signal"
#define  hgibuysignal ": Buy signal"
#define  hgisellsignal ": Sell signal"


//Trend Arrow constants
#define  Trendnoarrow " No trend arrow "
#define  Trenduparrow " Big green up Trend arrow "
#define  Trenddownarrow " Big red down Trend arrow "

//Rad Arrow constants
#define  Radnoarrow " No RAD arrow "
#define  Raduparrow " Small up RAD arrow "
#define  Raddownarrow " Small down RAD arrow "


//Wavy line constants
#define  Wavenone " No wave "
#define  Waverange " Yellow Range wave "
#define  Wavebuytrend " Blue wave buy trend"
#define  Waveselltrend " Blue wave sell trend"

//Currency status
#define  upaccelerating "Up, and accelerating"
#define  updecelerating "Up, but slowing"
#define  downaccelerating "Down, and accelerating"
#define  downdecelerating "Down, but slowing"

//Pending trade price line
#define  pendingpriceline "Pending price line"
//Hidden sl and tp lines. If used, the bot will close trades on a touch/break of these lines.
//Each line is named with its appropriate prefix and the ticket number of the relevant trade
#define  TpPrefix "Tp"
#define  SlPrefix "Sl"

//RSI TMA Slope constants
#define  pinhigh "Pin high"
#define  pinlow "Pin low"
#define  pinnone "No pin"

//Slope constants
#define  buyonly "Buy Only. "
#define  sellonly "Sell Only. "
#define  buyhold "Buy and hold. "
#define  sellhold "Sell and hold. "
#define  rising   ": Angle is rising. "
#define  falling   ": Angle is falling. "
#define  unchanged   ": Angle is unchanged. "

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

//Enumeration for the type of grid being sent. 
//Rene taught me how to define my own enum.
//FXCoder taught me how to present them as inputs. 
//Thanks guys.
enum GridStrategyType
{
   Hedged_Stop_Orders_Only,
   Non_Hedged_Stop_Orders_Only,
   Stop_And_Limit_Orders
};

enum PendingOrdersAvailable
{
   Buy_Limit,
   Sell_Limit,
   Buy_Stop,
   Sell_Stop
};//enum PendingOrdersAvailable


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

extern string  hgi="---- HGI Inputs ----"; 
extern string  HGI_Name="HGI_v16.05";
extern int     HgiReadDelaySeconds=60;//cpu saver. Read the indi every minute by default
extern int     FridayStopTradingHour=14;//Ignore signals at and after this time on Friday.
                                        //Local time input. >23 to disable.
extern int     SaturdayStopTradingHour=24;//For those in Upside Down Land.  
extern bool    TradeSundayCandle=false;
extern bool    TradeMondayCandle=true;
extern int     MondayStartHour=8;//24h local time     
extern bool    TradeTuesdayCandle=true;
extern bool    TradeWednesdayCandle=true;
extern bool    TradeThursdayCandle=true;//Thursday tends to be a reversal day, so avoid it.                               
extern bool    TradeFridayCandle=true;
extern bool    TradeSaturdayCandle=true;
////////////////////////////////////////////////////////////////////////////////////////
datetime        NextReadTime=0;//Time the indi will next be read
////////////////////////////////////////////////////////////////////////////////////////

extern string  gen="----General inputs----";
/*
Note to coders about TradingTimeFrame. Be consistent in your calls to indicators etc and always use TradingTimeFrame i.e.
double v = iCustom(Symbol(), TradingTimeFrame, ....................)
This allows the user to change time frames without disturbing the ea. There is a line of code in OnInit(), just above the call
to DisplayUserFeedback() that forces the EA to wait until the open of a new TradingTimeFrame candle; you might want to comment
this out during your EA development.
*/
extern ENUM_TIMEFRAMES TradingTimeFrame=PERIOD_H4;//Defaults to current chart
extern bool    EveryTickMode=true;
extern double  Lot=0.01;
double  RiskPercent = 0;//Set to zero to disable and use Lot
//Lot size by x lots per y of equity or balance. Default 0.01 lots per $1000 of equity
extern double  LotsPerDollopOfCash=0.01;//Over rides Lot. Zero input to cancel.
extern double  SizeOfDollop=1000;
extern bool    UseBalance=false;
extern bool    UseEquity=true;
extern bool    StopTrading=false;
bool    TradeLong=true;
bool    TradeShort=true;
extern int     TakeProfitPips=0;
extern int     StopLossPips=0;
extern int     MagicNumber=0;
extern bool    IsGlobalPrimeOrECNCriminal=false;
extern double  MaxSlippagePips=5;
//We need more safety to combat the cretins at Crapperquotes managing to break Matt's OR code occasionally.
//EA will make no further attempt to trade for PostTradeAttemptWaitMinutes minutes, whether OR detects a receipt return or not.
extern int     PostTradeAttemptWaitSeconds=180;//Defaults to 3 minutes
////////////////////////////////////////////////////////////////////////////////////////
datetime       TimeToStartTrading=0;//Re-start calling LookForTradingOpportunities() at this time.
double         TakeProfit, StopLoss;
datetime       OldBarsTime;
double         dPriceFloor = 0, dPriceCeiling = 0;//Next x0 numbers
double         PriceCeiling100 = 0, PriceFloor100 = 0;// Next 'big' numbers
string         TradingTimeFrameDisplay="";
//For FIFO
int            FifoTicket[];//Array to store trade ticket numbers in FIFO mode, to cater for
                            //US citizens and to make iterating through the trade closure loop 
                            //quicker.
double         FifoBuyTicket[][4];
double         FifoSellTicket[][4];

double         GridOrderBuyTickets[][2]; // number of lines will be equal to MarketBuysOpen - 1
double         GridOrderSellTickets[][2];
//An array to store ticket numbers of trades that need closing, should an offsetting OrderClose fail
double         ForceCloseTickets[];
////////////////////////////////////////////////////////////////////////////////////////

extern string  sep11c="================================================================";
extern string  tts="======== Trading styles ========";
extern bool    TrendTradingAllowed=true;
extern string  TrendTradeComment="HGBnG Trend";
extern bool    RadTradingAllowed=true;
extern string  RadTradeComment="HGBnG Rad";
extern bool    WaveTradingAllowed=true;
extern string  WaveTradeComment="HGBnG Blue Wave";
extern bool    CloseOnYellowRangeWave=false;
extern bool    OnlyCloseProfitablePositions=true;
extern bool    ReplaceWavyWinnersGrid=true;
extern bool    DeleteAndReplaceWavyLosersGrid=true;
////////////////////////////////////////////////////////////////////////////////////////
//Trading variables
string         TrendArrowStatus="";//One of the arrow status constants at the top of this file
string         RadArrowStatus="";//One of the arrow status constants at the top of this file
string         WaveStatus="";//One of the wave status constants at the top of this file
string         TradeCommentRIV=ordercomment; // Updated In ReadIndicatorValues //MJB
string         TradeCommentCOT=ordercomment; // Updated In CountOpenTrades     //MJB
////////////////////////////////////////////////////////////////////////////////////////

extern string  sep1="================================================================";
extern string  gri="---- Grid inputs ----";
input GridStrategyType GridType=Hedged_Stop_Orders_Only;
extern bool    SendImmediateMarketTrade=false;//Send a market trade as soon as there is a signal
extern int     GridSize=5;//x orders above market and x below.
extern int     DistanceBetweenTradesPips=0;
extern bool    CloseOnOppositeSignal=true;
extern string  sol="-- Specific Hedged Stop only inputs --";
extern bool    ReplaceOppositeSignalWinnersGrid=true;
extern bool    DeleteAndReplaceOppositeSignalLosersGrid=true;
extern bool    OnlyCloseProfitableOppositePositions=true;
extern string  so2="-- Specific Stop and Limit inputs --";
extern bool    MultiTradeInOppositeDirection=false;
extern int     NoOfOppositeTrades=5;//Ignored if !MultiTradeInOppositeDirection
extern int     DistanceBetweenOppositeTradesPips=10;
extern int     OppositeTakeProfitPips=9;
////////////////////////////////////////////////////////////////////////////////////////
double         OppositeTakeProfit=0;
double         DistanceBetweenOppositeTrades=0;
double         DistanceBetweenTrades=0;
int            GridTradesTotal=0;//Total of market, stop and limit trades
int            PendingTradesTotal=0;//Total of stop and limit trades
int            MarketTradesTotal=0;//Total of open market trades
bool           GridSent=false;//true if CountOpenTrades finds a trade
string         HgiSignalStatus="";
bool           Hedged=true;//Set to true if there are both market buys and sells open,
                            //to prevent closure on an opposite direction signal. Initialised
                            //as true to avoid closure first time around CountOpenTrades
//These two variables are set in OnInit according to the user's GridStrategyType input
//bool           GridType == Hedged_Stop_Orders_Only=false;//Buy stops above the market, sell stops below.
//bool           GridType == Stop_And_Limit_Orders=true;//Buy stops above and limits below for a buy. Vice versa
                                       //for a sell 
////////////////////////////////////////////////////////////////////////////////////////

extern string  sep1i="================================================================";
extern string  off="---- Offsetting ----";
extern bool    UseOffsetting=true;//Simple offset and double-sided complex offset
extern bool    AllowComplexSingleSidedOffsets=true;//Allow complex single-sided offset. Not allowed if UseOffsetting = false
extern int     MinOpenTradesToStartOffset=4;//Only use offsetting if there are at least this number of trades in the group

extern string  sep1a="================================================================";
extern string  hed="---- Hedging ----";
extern int     HedgeProfitPips=30;//Pips profit target at which to close a hedged position.
                                  //Zero value to disable
extern bool    OnlyCloseInCashProfit=true;//Hedged position can be pips positive but cash negative.
extern int     HedgeProfitCash=30;//Cash profit target at which to close a hedged position.
                                  //Zero value to disable                                  
////////////////////////////////////////////////////////////////////////////////////////
double         HedgeProfit=0;
double         HedgeLotSize=0;//Holds the lot size of an open market order so hgb knows the lot size to send when hedging
////////////////////////////////////////////////////////////////////////////////////////

extern string  sep1b="================================================================";
extern string  atri="---- ATR inputs ----";
extern string  grz="-- Grid size --";
extern bool    UseAtrForGrid=true;
extern ENUM_TIMEFRAMES GridAtrTimeFrame=PERIOD_D1;
extern int     GridAtrPeriod=20;
extern double  GridAtrMultiplier=1;
extern string  tpa="-- Take Profit --";
extern bool    UseAtrForTakeProfit=true;
extern ENUM_TIMEFRAMES TpAtrTimeFrame=PERIOD_D1;
extern int     TpAtrPeriod=20;
extern double  TpAtrMultiplier=1.5;
extern string  sla="-- Stop Loss --";
extern bool    UseAtrForStopLoss=false;
extern ENUM_TIMEFRAMES SlAtrTimeFrame=PERIOD_D1;
extern int     SlAtrPeriod=20;
extern double  SlAtrMultiplier=1;
/////////////////////////////////////////////////////////////////////////////////////////////
double         GridAtrVal=0;
double         TpAtrVal=0;
double         SlAtrVal=0;
/////////////////////////////////////////////////////////////////////////////////////////////

extern string  sep1d="================================================================";
extern string  sem="---- 3 Semafor Inputs ----";
extern bool    CloseTradesOnRelevantSemafor=true;//This is the close of the previous candle.
extern bool    CloseImmediatelySemaforAppears=false;
extern int     SemaforRetracePips=10;//Close when the market has retraced from the semafor by this number of pips. Value is a guess.
extern bool    CloseOnlyInPositivePips=true;//Only close a group of trades if the pips upl is positive
extern bool    ReplaceWinnersGrid=true;//Open a new grid in case the market resumes its move
extern bool    ReplaceWinnersWithLimitGrid=true;//Open a new limit orders grid to catch the retrace
extern bool    AddStopOrdersToLimitGrid=true;//Then add a grid of stop orders at the end of the limit grid in case
                                             //the retrace becomes a full reversal.
extern bool    DeleteAndReplaceLosersGrid=true;//Losing hedged trades will be a long way away, so delete
                                                //outstanding stop orders and replace them closer to the market.
double  Period1=5; 
double  Period2=13; 
extern double  Period3=34; 
string  Dev_Step_1="1,3";
string  Dev_Step_2="8,5";
string  Dev_Step_3="13,8";
/////////////////////////////////////////////////////////////////////////////////////////////
string         SemStatus="";
double         SemaforRetrace=0;
/////////////////////////////////////////////////////////////////////////////////////////////

extern string  sep1f="================================================================";
extern string  tmai="---- tnavi's moving averages ----";
extern bool    UseTnaviMA=false;
int     tMaShift=0;
extern ENUM_TIMEFRAMES TnaviTimeFrame=PERIOD_CURRENT;
extern ENUM_MA_METHOD tMaMethod= MODE_LWMA;
extern ENUM_APPLIED_PRICE tMaAppliedPrice=PRICE_CLOSE;
extern int     tFastMaPeriod1=40;
extern int     tFastMaPeriod2=60;
extern int     tSlowMaPeriod1=90;
extern int     tSlowMaPeriod2=120;
////////////////////////////////////////////////////////////////////////////////////////
double         tFMaVal1=0, tFMaVal2=0;//Faster moving averages
double         tSMaVal1=0, tSMaVal2=0;//Slower moving averages
string         tMaTrend;//up, down or crossing constants
////////////////////////////////////////////////////////////////////////////////////////

extern string  sep1g="================================================================";
extern string  bmai="---- Bob's double moving average ----";
extern bool    UseBobMA=true;
int     bMaShift=0;
extern ENUM_TIMEFRAMES BobTimeFrame=PERIOD_H4;
extern ENUM_MA_METHOD bMaMethod= MODE_LWMA;
extern ENUM_APPLIED_PRICE bMaAppliedPrice=PRICE_OPEN;
extern int     bFastMaPeriod=60;
extern int     bSlowMaPeriod=240;
////////////////////////////////////////////////////////////////////////////////////////
double         bFMaVal=0;//Faster moving averages
double         bSMaVal=0;//Slower moving averages
string         bMaTrend;//up, down or crossing constants
////////////////////////////////////////////////////////////////////////////////////////

extern string  sep1h="================================================================";
extern string  smai="---- Single moving average ----";
extern bool    UseSingleMA=false;
int     sMaShift=0;
extern ENUM_TIMEFRAMES SingleMaTimeFrame=PERIOD_H4;
extern ENUM_MA_METHOD sMaMethod= MODE_EMA;
extern ENUM_APPLIED_PRICE sMaAppliedPrice=PRICE_CLOSE;
extern int     sMaPeriod=34;
////////////////////////////////////////////////////////////////////////////////////////
double         sMaVal=0;//Faster moving averages
string         sMaTrend;//up, down or crossing constants
////////////////////////////////////////////////////////////////////////////////////////


extern string  sep1c="================================================================";
extern string  pen="---- Send a pending grid ----";
extern bool    SendGrid=false;
input PendingOrdersAvailable PendingOrderType=OP_BUY;//The default disallows trade send as ea will only send stop/limit orders
extern double  GridStartPrice=0;//Default of 0 means the Bid. >0 will attempt to send the grid at that price.
/////////////////////////////////////////////////////////////////////////////////////////////
bool           RemoveExpert=false;
/////////////////////////////////////////////////////////////////////////////////////////////

extern string  sep5="================================================================";
extern string	CSS_Input="----CCS inputs----";
extern bool    UseCSS=true;
extern int     maxBars           = 100;
extern ENUM_TIMEFRAMES CssTf=PERIOD_D1;
// extern bool    ignoreFuture      = true;
string         CurrNames[8]  = { "USD", "EUR", "GBP", "CHF", "JPY", "AUD", "CAD", "NZD" };
////////////////////////////////////////////////////////////////////////////////////////
string         Curr1, Curr2;//First and second currency in the pair
int            CurrIndex1, CurrIndex2;//Index of the currencies that form the pair to point to the correct one in currencyNames
double         CurrVal1[3], CurrVal2[3];//Hold the values of the two currencies, alloing me to look back in time to see if the currency is rising or falling.
string         CurrDirection1, CurrDirection2;//One of the Currency ststus constants
////////////////////////////////////////////////////////////////////////////////////////

extern string  sep1e="================================================================";
extern string  sfs="----SafetyFeature----";
//Safety feature. Sometimes an unexpected concatenation of inputs choice and logic error can cause rapid opening-closing of trades. Use the next input in combination with TooClose() 
//to abort the trade if the porevious one closed within the time limit.
extern int     MinMinutesBetweenTradeOpenClose=0;
extern int     MinMinutesBetweenTrades=1;
////////////////////////////////////////////////////////////////////////////////////////
bool           SafetyViolation;//For chart display
bool           RobotSuspended=false;
////////////////////////////////////////////////////////////////////////////////////////

extern string  sep2="================================================================";
//Hidden tp/sl inputs.
extern string  hts="----Stealth stop loss and take profit inputs----";
extern int     PipsHiddenFromCriminal=0;//Added to the 'hard' sl and tp and used for closure calculations
////////////////////////////////////////////////////////////////////////////////////////
double         HiddenStopLoss, HiddenTakeProfit;
double         HiddenPips=0;//Added to the 'hard' sl and tp and used for closure calculations
////////////////////////////////////////////////////////////////////////////////////////

extern string  sep7="================================================================";
//CheckTradingTimes. Baluda has provided all the code for this. Mny thanks Paul; you are a star.
extern string	trh				= "----Trading hours----";
extern string	tr1				= "tradingHours is a comma delimited list";
extern string  tr1a            = "of start and stop times.";
extern string	tr2				= "Prefix start with '+', stop with '-'";
extern string  tr2a            = "Use 24H format, local time.";
extern string	tr3				= "Example: '+07.00,-10.30,+14.15,-16.00'";
extern string	tr3a			= "Do not leave spaces";
extern string	tr4				= "Blank input means 24 hour trading.";
extern string	tradingHours="";
////////////////////////////////////////////////////////////////////////////////////////
double	      TradeTimeOn[];
double	      TradeTimeOff[];
// trading hours variables
int 	         tradeHours[];
string         tradingHoursDisplay;//tradingHours is reduced to "" on initTradingHours, so this variable saves it for screen display.
bool           TradeTimeOk;
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
double         LongSwap, ShortSwap;
////////////////////////////////////////////////////////////////////////////////////////

extern string  sep10="================================================================";
extern string  amc="----Available Margin checks----";
extern string  sco="Scoobs";
extern bool    UseScoobsMarginCheck=false;
extern string  fk="ForexKiwi";
extern bool    UseForexKiwi=true;
extern int     FkMinimumMarginPercent=800;
extern string  sep10a="-- Insufficient margin action --";
//When there is insufficient margin for trading, allow deletion of pending
//orders when there are no market trades.
extern bool    DeletePendingOrders=true;
////////////////////////////////////////////////////////////////////////////////////////
bool           EnoughMargin;
string         MarginMessage="";
////////////////////////////////////////////////////////////////////////////////////////

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


extern string  sep13="================================================================";
extern string  tmm="----Trade management module----";
//Breakeven has to be enabled for JS and TS to work.
extern string  BE="Break even settings";
extern bool    BreakEven=false;
extern int     BreakEvenTargetPips=100;
extern int     BreakEvenTargetProfit=20;
extern bool    PartCloseEnabled=false;
extern double  PartClosePercent=50;//Percentage of the trade lots to close
////////////////////////////////////////////////////////////////////////////////////////
double         BreakEvenPips, BreakEvenProfit;
bool           TradeHasPartClosed=false;
////////////////////////////////////////////////////////////////////////////////////////

extern string  sep14="================================================================";
extern string  JSL="Jumping stop loss settings";
extern bool    JumpingStop=false;
extern int     JumpingStopTargetPips=50;
extern bool    AddBEP=true;
////////////////////////////////////////////////////////////////////////////////////////
double         JumpingStopPips;
////////////////////////////////////////////////////////////////////////////////////////

extern string  sep15="================================================================";
extern string  cts="----Candlestick jumping stop----";
extern bool    UseCandlestickTrailingStop=false;
extern int     CstTimeFrame=0;//Defaults to current chart
extern int     CstTrailCandles=1;//Defaults to previous candle
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

//Enhanced screen feedback display code provided by Paul Batchelor (lifesys). Thanks Paul; this is fantastic.
extern string  se52  ="================================================================";
extern string  oad               ="----Odds and ends----";
extern bool    ShowChartFeedback=true;
extern int     ChartRefreshDelaySeconds=3;
extern int     DisplayGapSize    = 30; // if using Comments
// ****************************** added to make screen Text more readable
extern bool    DisplayAsText     = true;  // replaces Comment() with OBJ_LABEL text
extern bool    KeepTextOnTop     = true;//Disable the chart in foreground CrapTx setting so the candles do not obscure the text
extern int     DisplayX          = 100;
extern int     DisplayY          = 0;
extern int     fontSise          = 10;
extern string  fontName          = "Arial";
extern color   colour            = Yellow;
extern double  spacingtweek      = 0.6; // adjustment to reform lines for different font size
////////////////////////////////////////////////////////////////////////////////////////
int            DisplayCount;
string         Gap,ScreenMessage;
datetime       DisplayNow = 0;   
////////////////////////////////////////////////////////////////////////////////////////
//  *****************************

extern string  sep11b="================================================================";
extern string  cmdb="---- Command buttons ----";
extern int     ButtonHeight=50;
extern int     ButtonWidth=150;
extern ENUM_BASE_CORNER ButtonCorner=CORNER_LEFT_UPPER; // Chart corner for anchoring
extern string           ButtonFont="Arial";             // Font
extern int              ButtonFontSize=14;              // Font size
extern color            ButtonColor=clrBlack;           // Text color
extern color            ButtonBackColor=C'236,233,216'; // Background color
extern color            ButtonBorderColor=clrNONE;      // Border color
extern int              Button_X=800;                   //X axis
extern int              Button_Y=50;                    //Y axis
////////////////////////////////////////////////////////////////////////////////////////
string         CloseAllName="CloseAllButton";            // Close market orders and delete pendings
string         CloseMarketOrdersName="CloseAllMarketOrders"; //Market trades only
string         CloseMarketBuysName="CloseAllMarketBuys"; //Market buy trades only
string         CloseMarketSellssName="CloseAllMarketSells"; //Market sell trades only
string         DeleteAllPendingsName="DeleteAllPendingTrades"; //All pendings
string         DeleteBuyStops="DeleteBuyStops"; //Buy stops only
string         DeleteSellStops="DeleteSellStops"; //Sell stops only
string         DeleteBuyLimits="DeleteBuyLimits"; //Buy limits only
string         DeleteSellLimits="DeleteSellLimits"; //Sell limits only
string         SendFullGrid="Send_FullGrid"; //Send a grid of buy and sell stops
string         SendBuyStops="SendBuyStops"; //Send a grid of buy stops
string         SendSellStops="SendSellStops"; //Send a grid of sell stops
string         SendBuyLimits="SendBuyLimits"; //Send a grid of buy Limits
string         SendSellLimits="SendSellLimits"; //Send a grid of sell Limits
string         PauseTrading="Pause_Trading"; //Stops fresh trades being sent. Management continues
string         ResumeTrading="Resume_Trading"; //Restart trading
bool           ButtonBack=false;               // Background object
bool           ButtonSelection=false;          // Highlight to move
bool           ButtonHidden=false;             // Hidden in the object list
long           ButtonZOrder=0;                 // Priority for mouse click
bool           ButtonState=false;              // Pressed/Released

bool           TradingPaused=false;
////////////////////////////////////////////////////////////////////////////////////////

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
string         GvName="";//Holds the signal type.
int            OriginalSignal=-1;//OP_BUY or OP_SELL
////////////////////////////////////////////////////////////////////////////////////////


//Calculating the factor needed to turn pip values into their correct points value to accommodate different Digit size.
//Thanks to Lifesys for providing this code. Coders, you need to briefly turn of Wrap and turn on a mono-spaced font to view this properly and see how easy it is to make changes.
string         pipFactor[]  = {"JPY","XAG","SILVER","BRENT","WTI","XAU","GOLD","SP500","S&P","UK100","WS30","DAX30","DJ30","NAS100","CAC400"};
double         pipFactors[] = { 100,  100,  100,     100,    100,  10,   10,    10,     10,   1,      1,     1,      1,     1,       1};
double         factor;//For pips/points stuff. Set up in int init()
////////////////////////////////////////////////////////////////////////////////////////


//Matt's O-R stuff
int 	         O_R_Setting_max_retries 	= 10;
double 	      O_R_Setting_sleep_time 		= 4.0; /* seconds */
double 	      O_R_Setting_sleep_max 		= 15.0; /* seconds */
int            RetryCount = 10;//Will make this number of attempts to get around the trade context busy error.

//Running total of trades
int            LossTrades, WinTrades;
double         OverallProfit;

//Misc
int            OldBars;
string         PipDescription=" pips";
bool           ForceTradeClosure;
int            TurnOff=0;//For turning off functions without removing their code



void DisplayUserFeedback()
{

   if (IsTesting() && !IsVisualMode()) return;

   //cpu saving
   static datetime CurrentTime = 0;
   DisplayNow = 0;
   if (TimeCurrent() < DisplayNow )
      return;
   CurrentTime = TimeCurrent();
   DisplayNow = CurrentTime + ChartRefreshDelaySeconds;

 
//   ************************* added for OBJ_LABEL
   DisplayCount = 1;
   removeAllObjects();
//   *************************

 
   ScreenMessage = "";
   //ScreenMessage = StringConcatenate(ScreenMessage,Gap + NL);
   SM(NL);
   if (SafetyViolation) SM("*************** CANNOT TRADE YET. TOO SOON AFTER CLOSE OF PREVIOUS TRADE***************" + NL);
   
   if (TradingPaused)
      SM("*************** TRADING IS PAUSED. MANAGEMENT CONTINUES. ***************"+NL);
    
   
   SM("Updates for this EA are to be found at http://www.stevehopwoodforex.com" + NL);
   SM("Feeling generous? Help keep the coder going with a small Paypal donation to pianodoodler@hotmail.com" + NL);
   SM("Broker time = " + TimeToStr(TimeCurrent(), TIME_DATE|TIME_SECONDS) + ": Local time = " + TimeToStr(TimeLocal(), TIME_DATE|TIME_SECONDS) + NL );
   SM(version + NL);
   
   
   if (!ShowChartFeedback)
   {
      Comment(ScreenMessage);
      return;
   }//if (!ShowChartFeedback)
   
   
   /*
   //Code for time to bar-end display donated by Baluda. Cheers Paul.
   SM( TimeToString( iTime(Symbol(), TradingTimeFrame, 0) + TradingTimeFrame * 60 - CurTime(), TIME_MINUTES|TIME_SECONDS ) 
   + " left to bar end" + NL );
   */
   if (!TradeTimeOk)
   {
      SM(NL);
      SM("----------OUTSIDE TRADING HOURS. Will continue to monitor open trades.----------" + NL + NL);
   }//if (!TradeTimeOk)

   SM(NL);
   if (GridType == Hedged_Stop_Orders_Only)
      SM("Trading the Hedged_Stop_Orders_Only hedging system." + NL);
   if (GridType == Non_Hedged_Stop_Orders_Only)
      SM("Trading the Non_Hedged_Stop_Orders_Only system." + NL);
   if (GridType == Stop_And_Limit_Orders)
      SM("Trading the Stop_And_Limit_Orders system." + NL);
   SM("HGI_Name = " + HGI_Name + NL);
   SM("Next indi read time: " + TimeToStr(NextReadTime, TIME_SECONDS) +NL);
   if (TrendTradingAllowed)
      SM("Trend arrow status:" + TrendArrowStatus + NL);
   if (RadTradingAllowed)
      SM("RAD arrow status: " + RadArrowStatus + NL);
   if (WaveTradingAllowed)
      SM("Wavy line status:" + WaveStatus + NL);
   SM("HGI signal status" + HgiSignalStatus + NL);
   if (UseTnaviMA)
   {
      SM("tnavi Moving averages:" + NL);
      SM("        Fast: " + DoubleToStr(tFMaVal1, Digits) + ": " +  DoubleToStr(tFMaVal2, Digits) + NL);
      SM("        Slow: " + DoubleToStr(tSMaVal1, Digits) + ": " +  DoubleToStr(tSMaVal2, Digits) + NL);
      SM("Trend is" + tMaTrend + NL);
   }//if (UseTnaviMA)
      
   if (UseBobMA)
   {
      SM("Bob Moving averages:" + NL);
      SM("        Fast: " + DoubleToStr(bFMaVal, Digits) + NL);
      SM("        Slow: " + DoubleToStr(bSMaVal, Digits) + NL);
      SM("Trend is" + bMaTrend + NL);
   }//if (UseBobMA)
      
   if (UseSingleMA)
   {
      SM("Single Moving averages:" + NL);
      SM("        MA value: " + DoubleToStr(sMaVal, Digits) + NL);
      SM("Trend is" + sMaTrend + NL);
   }//if (UseSingleMA)
      
   if(UseAtrForGrid)
   {
      SM("ATR for the grid size = "+DoubleToString(GridAtrVal,0)+" pips"+NL);
   }//if (UseAtrForGrid)

   SM("Distance between trades = "+DistanceBetweenTrades+" pips"+NL);
   
   if (CloseTradesOnRelevantSemafor || CloseImmediatelySemaforAppears)
      SM("Semafor status: " + SemStatus + NL);
   
   if (UseCSS)
   {
      SM(Curr1 + " = " + DoubleToStr(CurrVal1[2], 2) + "  "  + DoubleToStr(CurrVal1[1], 2) + ": Direction is " + CurrDirection1 + NL);
      SM(Curr2 + " = " + DoubleToStr(CurrVal2[2], 2) + "  "  + DoubleToStr(CurrVal2[1], 2) + ": Direction is " + CurrDirection2 + NL);
   }//if (UseCSS)

   SM(NL);     
   SM("Pending trades open =" + IntegerToString(PendingTradesTotal) + NL);
   string text = "Market trades open = ";
   if (Hedged)
   {
      text = "Hedged position. Market trades open = ";
   }
   SM(text + IntegerToString(MarketTradesTotal) + ": Pips UPL = " + DoubleToStr(PipsUpl, 0)
   +  ": Cash UPL = " + DoubleToStr(CashUpl, 2) + NL);
   if (BuyOpen)
      SM("Buy trades = " + IntegerToString(MarketBuysCount)
         + ": Pips upl = " + IntegerToString(BuyPipsUpl)
         + ": Cash upl = " + DoubleToStr(BuyCashUpl, 2)
         + NL);
   if (SellOpen)
      SM("Sell trades = " + IntegerToString(MarketSellsCount)
         + ": Pips upl = " + IntegerToString(SellPipsUpl)
         + ": Cash upl = " + DoubleToStr(SellCashUpl,2)
         + NL);
   
   
   SM(NL);     
   SM("Trading time frame: " + TradingTimeFrameDisplay + NL);
   if (TradeLong) SM("Taking long trades" + NL);
   if (TradeShort) SM("Taking short trades" + NL);
   if (!TradeLong && !TradeShort) SM("Both TradeLong and TradeShort are set to false" + NL);
   SM("Lot size: " + DoubleToStr(Lot, 2) + " (Criminal's minimum lot size: " + DoubleToStr(MarketInfo(Symbol(), MODE_MINLOT) , 2)+ ")" + NL);
   if (!CloseEnough(TakeProfit, 0)) SM("Take profit: " + DoubleToStr(TakeProfit, 0) + PipDescription +  NL);
   if (!CloseEnough(StopLoss, 0)) SM("Stop loss: " + DoubleToStr(StopLoss, 0) + PipDescription +  NL);
   SM("Magic number: " + MagicNumber + NL);
   if (IsGlobalPrimeOrECNCriminal) SM("IsGlobalPrimeOrECNCriminal = true" + NL);
   else SM("IsGlobalPrimeOrECNCriminal = false" + NL);
   double spread = (Ask - Bid) * factor;   
   SM("Average Spread = " + DoubleToStr(AverageSpread, 1) + ": Spread = " + DoubleToStr(spread, 1) + ": Widest since loading = " + DoubleToStr(BiggestSpread, 1) + NL);
   SM("Long swap " + DoubleToStr(LongSwap, 2) + ": ShortSwap " + DoubleToStr(ShortSwap, 2) + NL);
   SM(NL);
   
   //Trading hours
   if (tradingHoursDisplay != "") SM("Trading hours: " + tradingHoursDisplay + NL);
   else SM("24 hour trading: " + NL);
   
   if (MarginMessage != "") SM(MarginMessage + NL);


   //Running total of trades
   SM(Gap + NL);
   SM("Results for this trading day as measured by your broker. Wins: " + WinTrades + ": Losses " + LossTrades + ": P/L " + DoubleToStr(OverallProfit, 2) + NL);
   
      
   SM(NL);
   
   if (BreakEven)
   {
      SM("Breakeven is set to " + DoubleToStr(BreakEvenPips, 0) + PipDescription + ": BreakEvenProfit = " + DoubleToStr(BreakEvenProfit, 0) + PipDescription);
      SM(NL);
      if (PartCloseEnabled)
      {
         double CloseLots = NormalizeLots(Symbol(),Lot * (PartClosePercent / 100));
         SM("Part-close is enabled at " + DoubleToStr(PartClosePercent, 2) + "% (" + DoubleToStr(CloseLots, 2) + " lots to close)" + NL);
      }//if (PartCloseEnabled)      
   }//if (BreakEven)

   if (UseCandlestickTrailingStop)
   {
      SM("Using candlestick trailing stop" + NL);      
   }//if (UseCandlestickTrailingStop)
   
   if (JumpingStop)
   {
      SM("Jumping stop is set to " + DoubleToStr(JumpingStopPips, 0) + PipDescription);
      SM(NL);  
   }//if (JumpingStop)
   

   if (TrailingStop)
   {
      SM("Trailing stop is set to " + DoubleToStr(TrailingStopPips, 0) + PipDescription);
      SM(NL);  
   }//if (TrailingStop)
   
   
   
   Comment(ScreenMessage);


}//void DisplayUserFeedback()

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
   string lab_str = "OAM-" + DisplayCount;   
   int ofset = 0;
   string textpart[5];
   for (int cc = 0; cc < 5; cc++) 
   {
      textpart[cc] = StringSubstr(text,cc*63,64);
      if (StringLen(textpart[cc]) ==0) continue;
      ofset = cc * 63 * fontSise * spacingtweek;
      lab_str = lab_str + cc;
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

//////////////////////////////////////////////////////////////////////////////////////////////////////
//Price ceiling and floor module. Code generously provided by Elixe. Thanks Elixe

double priceFloor(double price, int pipfloor)
{
   if (pipfloor != 1 && pipfloor != 10 && pipfloor != 100 && pipfloor != 1000 && pipfloor != 10000) return price;
   
   // will handle the 2/4 digits broker if there are still any. Will obviously not work for CFDs as the digits can be "exotic"
   int pipMultiplier = 1;
   if (Digits == 3 || Digits == 5) pipMultiplier = 10;
   
   // Divide te price by point value, resulting in a integer of our price (eg : 1.69532 will return 169532)
   double pricetoInt = price / Point;
   
   // Get the remainder of the division of our pricetoInt by the pipfloor requested (eg : 169532 mod 100 = 32)
   double priceMod = MathMod(pricetoInt, pipfloor*pipMultiplier);

   // substract that remainder of our priceToInt, we get a floored integer (eg : 169500);
   double flooredPriceInt = pricetoInt - priceMod;
   
   // convert back our flooredPriceInt to a usable price (eg: 169500 will return 1.69500)
   double flooredPrice = flooredPriceInt * Point;
   
   return(NormalizeDouble(flooredPrice, Digits));
}

double priceCeiling(double price, int pipfloor)
{
   // not commenting the whole process again
   if (pipfloor != 1 && pipfloor != 10 && pipfloor != 100 && pipfloor != 1000 && pipfloor != 10000) return price;
   
   int pipMultiplier = 1;
   if (Digits == 3 || Digits == 5) pipMultiplier = 10;
   
   double pricetoInt = price / Point;
   double priceMod = MathMod(pricetoInt, pipfloor*pipMultiplier);
   
   // but just this piece, we are adding our pipfloor request to the already floored price, that will return the ceiling :)
   double ceiledPriceInt = (pricetoInt - priceMod) + (pipfloor*pipMultiplier);
   
   double ceiledPrice = ceiledPriceInt * Point;
   
   return(NormalizeDouble(ceiledPrice, Digits));
}

//End price ceiling and floor module
//////////////////////////////////////////////////////////////////////////////////////////////////////

//+------------------------------------------------------------------+
//| expert initialization function                                   |
//+------------------------------------------------------------------+
int OnInit()
{
//----

   
   //Mindless dimwit check
   if (!indiExists( HGI_Name ))
   {
      Alert(" Read the fucking user guide properly this time, you demented lazy and stupid dimwit.");
      Alert("The required indicator " + HGI_Name + " does not exist on your platform. I am removing myself from your chart.");
      ExpertRemove();
      return(0);
   }//if (! indiExists( "wanker" ))
   
   ///////////////////////////////////////////////////////////////////////////
   //Enforce some essential default values if GridType == Hedged_Stop_Orders_Only=true
   if (GridType == Hedged_Stop_Orders_Only)
   {
      UseAtrForStopLoss = false;
      StopLossPips = 0;
   }//if (GridType == Hedged_Stop_Orders_Only)
   
   ///////////////////////////////////////////////////////////////////////////
   

   //~ Set up the pips factor. tp and sl etc.
   //~ The EA uses doubles and assume the value of the integer user inputs. This: 
   //~    1) minimises the danger of the inputs becoming corrupted by restarts; 
   //~    2) the integer inputs cannot be divided by factor - doing so results in zero.
   
   factor = PFactor(Symbol());
   StopLoss = StopLossPips;
   TakeProfit = TakeProfitPips;
   BreakEvenPips = BreakEvenTargetPips;
   BreakEvenProfit = BreakEvenTargetProfit;
   JumpingStopPips = JumpingStopTargetPips;
   TrailingStopPips = TrailingStopTargetPips;
   HiddenPips = PipsHiddenFromCriminal;
   DistanceBetweenTrades = DistanceBetweenTradesPips;
   HedgeProfit = HedgeProfitPips;
   SemaforRetrace = SemaforRetracePips;
   DistanceBetweenOppositeTrades = DistanceBetweenOppositeTradesPips;
   OppositeTakeProfit = OppositeTakeProfitPips;

   //Find the latest trade signal type after a restart
   GvName = WindowExpertName() + " " + Symbol();
   if (GlobalVariableCheck(GvName))
      OriginalSignal = GlobalVariableGet(GvName);
   
   while (IsConnected()==false)
   {
      Comment("Waiting for MT4 connection...");
      Sleep(1000);
   }//while (IsConnected()==false)

   //Lot size and part-close idiot check for the cretins. Code provided by phil_trade. Many thanks, Philippe.
   //adjust Min_lot
   if (CloseEnough(RiskPercent, 0) )
      if(Lot<MarketInfo(Symbol(),MODE_MINLOT))
      {
         Alert(Symbol()+" Lot was adjusted to Minlot = "+DoubleToStr(MarketInfo(Symbol(),MODE_MINLOT),Digits));
         Lot=MarketInfo(Symbol(),MODE_MINLOT);
      }//if (Lot < MarketInfo(Symbol(), MODE_MINLOT)) 
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

   //Jumping/trailing stops need breakeven set before they work properly
   if ((JumpingStop || TrailingStop) && !BreakEven) 
   {
      BreakEven = true;
      if (JumpingStop) BreakEvenPips = JumpingStopPips;
      if (TrailingStop) BreakEvenPips = TrailingStopPips;
   }//if (JumpingStop || TrailingStop) 
   
   Gap="";
   if (DisplayGapSize >0)
   {
      for (int cc=0; cc< DisplayGapSize; cc++)
      {
         Gap = StringConcatenate(Gap, " ");
      }   
   }//if (DisplayGapSize >0)
   
   //Reset CriminIsECN if crim is IBFX and the punter does not know or, like me, keeps on forgetting
   string name = TerminalCompany();
   int ispart = -1;
   ispart = StringFind(name, "Global Prime", 0);
   if (ispart > -1) IsGlobalPrimeOrECNCriminal = true;   
   
   //Set up the trading hours
   tradingHoursDisplay = tradingHours;//For display
   initTradingHours();//Sets up the trading hours array

   // Initialize libCSS
   if (UseCSS)
      libCSSinit();


   if (TrendTradeComment == "") TrendTradeComment="HGBnG Trend";
   if (RadTradeComment == "") RadTradeComment="HGBnG Rad";
   if (WaveTradeComment == "") WaveTradeComment="HGBnG Blue Wave";
   
   OldBars = Bars;
   TicketNo = -1;
   ReadIndicatorValues();//For initial display in case user has turned of constant re-display
   //Reset variables where user is not using ATR
   if (!UseAtrForGrid)
      DistanceBetweenTrades = DistanceBetweenTradesPips;
   if (!UseAtrForTakeProfit)
      TakeProfit = TakeProfitPips;   
   if (!UseAtrForStopLoss)
      StopLoss = StopLossPips;   
   GetSwap(Symbol());//This will need editing/removing in a multi-pair ea.
   TradeDirectionBySwap();
   TooClose();
   CountOpenTrades();
   OldOpenTrades = OpenTrades;
   TradeTimeOk = CheckTradingTimes();   
   
   //I will not allow the safety feature to be disabled.
   if (PostTradeAttemptWaitSeconds == 0)
      PostTradeAttemptWaitSeconds = 60;
   
   if (!IsTesting() )
   {   
      //The apread global variable
      SpreadGvName = Symbol() + " average spread";
      AverageSpread = GlobalVariableGet(SpreadGvName);//If no gv, then the value will be left at zero.
   }//if (!IsTesting() )
   
   
   //Chart display
   if (DisplayAsText)
      if (KeepTextOnTop)
         ChartForegroundSet(false,0);// change chart to background

   //Ensure that an ea depending on Close[1] for its values does not immediately fire a trade.
   if (!EveryTickMode) OldBarsTime = iTime(Symbol(), TradingTimeFrame, 0);

   //Lot size based on account size
   if (!CloseEnough(LotsPerDollopOfCash, 0))
      CalculateLotAsAmountPerCashDollops();

   //Force a pending grid order send
   if (SendGrid)
   {
      int type = PendingOrderType + 2;//enum starts at 0, so we need to add 2 to make the order a stop or limit
      int retno = MessageBox("Please confirm that you want to send a pending trade grid", "Confirm grid sending", MB_YESNOCANCEL);
            
      if (retno == IDYES)
      {
         double price = NormalizeDouble(Bid + (DistanceBetweenTrades / factor), Digits);//Defaults to buy stop/sell limit
         if (type == 2 || type == 5)//Buy limit sell stop
            price = NormalizeDouble(Bid - (DistanceBetweenTrades / factor), Digits);
         if (!CloseEnough(GridStartPrice, 0))
            price = GridStartPrice;
         if (type == 2 || type == 4)
            SendBuyGrid(Symbol(), type, price, Lot, ordercomment);
         else
            SendSellGrid(Symbol(), type, price, Lot, ordercomment);
         RemoveExpert = true;
         Alert(Symbol() + ": I have removed myself from the chart.");
         ExpertRemove();
         return(0);               
      }//if (retno == IDYES) 
   }//if (SendGrid)

   DrawButtons();
   
   //Time frame display
   TradingTimeFrameDisplay = GetTimeFrameDisplay(TradingTimeFrame);
  
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
   
   ObjectsDeleteAll(0, OBJ_BUTTON);
   
//----
   return;
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

bool SendSingleTrade(string symbol, int type, string comment, double lotsize, double price, double stop, double take)
{
   //pah (Paul) contributed the code to get around the trade context busy error. Many thanks, Paul.
   
   double slippage = MaxSlippagePips * MathPow(10, Digits) / PFactor(Symbol());
   int ticket = -1;

   
   
   color col = Red;
   if (type == OP_BUY || type == OP_BUYSTOP || type == OP_BUYLIMIT) col = Green;
   
   datetime expiry = 0;
   //if (SendPendingTrades) expiry = TimeCurrent() + (PendingExpiryMinutes * 60);

   //RetryCount is declared as 10 in the Trading variables section at the top of this file
   for (int cc = 0; cc < RetryCount; cc++)
   {
      //for (int d = 0; (d < RetryCount) && IsTradeContextBusy(); d++) Sleep(100);

      RefreshRates();
      if (type == OP_BUY) price = MarketInfo(symbol, MODE_ASK);
      if (type == OP_SELL) price = MarketInfo(symbol, MODE_BID);
      
      while(IsTradeContextBusy()) Sleep(100);//Put here so that excess slippage will cancel the trade if the ea has to wait for some time.
      
      if (!IsGlobalPrimeOrECNCriminal)
         ticket = OrderSend(symbol,type, lotsize, price, slippage, stop, take, comment, MagicNumber, expiry, col);
   
   
      //Is a 2 stage criminal
      if (IsGlobalPrimeOrECNCriminal)
      {
         ticket = OrderSend(symbol, type, lotsize, price, slippage, 0, 0, comment, MagicNumber, expiry, col);
         if (ticket > -1)
         {
	           ModifyOrderTpSl(ticket, stop, take);
         }//if (ticket > 0)}
      }//if (IsGlobalPrimeOrECNCriminal)
      
      if (ticket > -1) break;//Exit the trade send loop
      if (cc == RetryCount - 1) return(false);
   
      //Error trapping for both
      if (ticket < 0)
      {
         string stype;
         if (type == OP_BUY) stype = "OP_BUY";
         if (type == OP_SELL) stype = "OP_SELL";
         if (type == OP_BUYLIMIT) stype = "OP_BUYLIMIT";
         if (type == OP_SELLLIMIT) stype = "OP_SELLLIMIT";
         if (type == OP_BUYSTOP) stype = "OP_BUYSTOP";
         if (type == OP_SELLSTOP) stype = "OP_SELLSTOP";
         int err=GetLastError();
         Alert(symbol, " ", WindowExpertName(), " ", stype," order send failed with error(",err,"): ",ErrorDescription(err));
         Print(symbol, " ", WindowExpertName(), " ", stype," order send failed with error(",err,"): ",ErrorDescription(err));
         return(false);
      }//if (ticket < 0)  
   }//for (int cc = 0; cc < RetryCount; cc++);
   
   
   TicketNo = ticket;
   //Make sure the trade has appeared in the platform's history to avoid duplicate trades.
   //My mod of Matt's code attempts to overcome the bastard crim's attempts to overcome Matt's code.
   bool TradeReturnedFromCriminal = false;
   while (!TradeReturnedFromCriminal)
   {
      TradeReturnedFromCriminal = O_R_CheckForHistory(ticket);
      if (!TradeReturnedFromCriminal)
      {
         Alert(Symbol(), " sent trade not in your trade history yet. Turn of this ea NOW.");
      }//if (!TradeReturnedFromCriminal)
   }//while (!TradeReturnedFromCriminal)
   
   //Got this far, so trade send succeeded
   return(true);
   
}//End bool SendSingleTrade(int type, string comment, double lotsize, double price, double stop, double take)

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
   if (!IsTesting() )
   {
      double spread = (Ask - Bid) * factor;
      if (spread > AverageSpread * MultiplierToDetectStopHunt) return(false);
   }//if (!IsTesting() )
   
   //Friday/Saturday/Sunday/Monday stuff
   if (!SundayMondayFridayStuff())
      return(false);
         
   
   //An individual currency can only be traded twice, so check for this
   CanTradeThisPair = true;
   if (OnlyTradeCurrencyTwice && OpenTrades == 0)
   {
      IsThisPairTradable();      
   }//if (OnlyTradeCurrencyTwice)
   if (!CanTradeThisPair) return(false);
   
   //Swap filter
   if (OpenTrades == 0) TradeDirectionBySwap();
   
   //Order close time safety feature
   if (TooClose()) return(false);

   return(true);


}//End bool IsTradingAllowed()

////////////////////////////////////////////////////////////////////////////////////////
//Balance/swap filters module
void TradeDirectionBySwap()
{

   //Sets TradeLong & TradeShort according to the positive/negative swap it attracts

   //Swap is read in init() and start()


   if (CadPairsPositiveOnly)
   {
      if (StringSubstrOld(Symbol(), 0, 3) == "CAD" || StringSubstrOld(Symbol(), 0, 3) == "cad" || StringSubstrOld(Symbol(), 3, 3) == "CAD" || StringSubstrOld(Symbol(), 3, 3) == "cad" )      
      {
         if (LongSwap > 0) TradeLong = true;
         else TradeLong = false;
         if (ShortSwap > 0) TradeShort = true;
         else TradeShort = false;         
      }//if (StringSubstrOld()      
   }//if (CadPairsPositiveOnly)
   
   if (AudPairsPositiveOnly)
   {
      if (StringSubstrOld(Symbol(), 0, 3) == "AUD" || StringSubstrOld(Symbol(), 0, 3) == "aud" || StringSubstrOld(Symbol(), 3, 3) == "AUD" || StringSubstrOld(Symbol(), 3, 3) == "aud" )      
      {
         if (LongSwap > 0) TradeLong = true;
         else TradeLong = false;
         if (ShortSwap > 0) TradeShort = true;
         else TradeShort = false;         
      }//if (StringSubstrOld()      
   }//if (AudPairsPositiveOnly)
   
   
   if (NzdPairsPositiveOnly)
   {
      if (StringSubstrOld(Symbol(), 0, 3) == "NZD" || StringSubstrOld(Symbol(), 0, 3) == "nzd" || StringSubstrOld(Symbol(), 3, 3) == "NZD" || StringSubstrOld(Symbol(), 3, 3) == "nzd" )      
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

bool IsThisPairTradable()
{
   //Checks to see if either of the currencies in the pair is already being traded twice.
   //If not, then return true to show that the pair can be traded, else return false
   
   string c1 = StringSubstrOld(Symbol(), 0, 3);//First currency in the pair
   string c2 = StringSubstrOld(Symbol(), 3, 3);//Second currency in the pair
   int c1open = 0, c2open = 0;
   CanTradeThisPair = true;
   for (int cc = OrdersTotal() - 1; cc >= 0; cc--)
   {
      if (!OrderSelect(cc, SELECT_BY_POS) ) continue;
      if (OrderSymbol() != Symbol() ) continue;
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

bool BalancedPair(int type)
{

   //Only allow an individual currency to trade if it is a balanced trade
   //e.g. UJ Buy open, so only allow Sell xxxJPY.
   //The passed parameter is the proposed trade, so an existing one must balance that

   //This code courtesy of Zeljko (zkucera) who has my grateful appreciation.
   
   string BuyCcy1, SellCcy1, BuyCcy2, SellCcy2;

   if (type == OP_BUY || type == OP_BUYSTOP)
   {
      BuyCcy1 = StringSubstrOld(Symbol(), 0, 3);
      SellCcy1 = StringSubstrOld(Symbol(), 3, 3);
   }//if (type == OP_BUY || type == OP_BUYSTOP)
   else
   {
      BuyCcy1 = StringSubstrOld(Symbol(), 3, 3);
      SellCcy1 = StringSubstrOld(Symbol(), 0, 3);
   }//else

   for (int cc = OrdersTotal() - 1; cc >= 0; cc--)
   {
      if (!OrderSelect(cc, SELECT_BY_POS)) continue;
      if (OrderSymbol() == Symbol()) continue;
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



//End Balance/swap filters module
////////////////////////////////////////////////////////////////////////////////////////
double CalculateLotSize(double price1, double price2)
{
   //Calculate the lot size by risk. Code kindly supplied by jmw1970. Nice one jmw.
   
   if (price1 == 0 || price2 == 0) return(Lot);//Just in case
   
   double FreeMargin = AccountFreeMargin();
   double TickValue = MarketInfo(Symbol(),MODE_TICKVALUE) ;
   double LotStep = MarketInfo(Symbol(),MODE_LOTSTEP);


   double SLPts = MathAbs(price1 - price2);
   //SLPts/= Point;//No idea why *= factor does not work here, but it doesn't
   SLPts = int(SLPts * factor * 10);//Code from Radar. Thanks Radar; much appreciated
   
   double Exposure = SLPts * TickValue; // Exposure based on 1 full lot

   double AllowedExposure = (FreeMargin * RiskPercent) / 100;
   
   int TotalSteps = ((AllowedExposure / Exposure) / LotStep);
   double LotSize = TotalSteps * LotStep;

   double MinLots = MarketInfo(Symbol(), MODE_MINLOT);
   double MaxLots = MarketInfo(Symbol(), MODE_MAXLOT);
   
   if (LotSize < MinLots) LotSize = MinLots;
   if (LotSize > MaxLots) LotSize = MaxLots;
   return(LotSize);

}//double CalculateLotSize(double price1, double price1)

double CalculateStopLoss(int type, double price)
{
   //Returns the stop loss for use in LookForTradingOpps and InsertMissingStopLoss
   double stop;

   RefreshRates();
   
   double StopLevel = MarketInfo(Symbol(), MODE_STOPLEVEL) + MarketInfo(Symbol(), MODE_SPREAD);
   double spread = (Ask - Bid) * factor;

   
   if (type == OP_BUY)
   {
      if (!CloseEnough(StopLoss, 0) ) 
      {
         if (StopLoss < StopLevel) 
            if (StopLossPips > 0)
               StopLoss = StopLevel;
         stop = price - (StopLoss / factor);
         HiddenStopLoss = stop;
      }//if (!CloseEnough(StopLoss, 0) ) 

      if (HiddenPips > 0 && stop > 0) stop = NormalizeDouble(stop - (HiddenPips / factor), Digits);
   }//if (type == OP_BUY)
   
   if (type == OP_SELL)
   {
      if (!CloseEnough(StopLoss, 0) ) 
      {
         if (StopLoss < StopLevel) 
            if (StopLossPips > 0)
               StopLoss = StopLevel;
         stop = price + (StopLoss / factor);
         HiddenStopLoss = stop;         
      }//if (!CloseEnough(StopLoss, 0) ) 
      
      if (HiddenPips > 0 && stop > 0) stop = NormalizeDouble(stop + (HiddenPips / factor), Digits);

   }//if (type == OP_SELL)
   
   return(stop);
   
}//End double CalculateStopLoss(int type)

double CalculateTakeProfit(int type, double price)
{
   //Returns the stop loss for use in LookForTradingOpps and InsertMissingStopLoss
   double take;

   RefreshRates();
   
   double StopLevel = MarketInfo(Symbol(), MODE_STOPLEVEL) + MarketInfo(Symbol(), MODE_SPREAD);
   double spread = (Ask - Bid) * factor;

   
   if (type == OP_BUY)
   {
      if (!CloseEnough(TakeProfit, 0) )
      {
         if (TakeProfit < StopLevel) 
            if (TakeProfitPips > 0)   
               TakeProfit = StopLevel;
         take = price + (TakeProfit / factor);
         HiddenTakeProfit = take;
      }//if (!CloseEnough(TakeProfit, 0) )

               
      if (HiddenPips > 0 && take > 0) take = NormalizeDouble(take + (HiddenPips / factor), Digits);

   }//if (type == OP_BUY)
   
   if (type == OP_SELL)
   {
      if (!CloseEnough(TakeProfit, 0) )
      {
         if (TakeProfit < StopLevel) 
            if (TakeProfitPips > 0)   
               TakeProfit = StopLevel;
         take = price - (TakeProfit / factor);
         HiddenTakeProfit = take;         
      }//if (!CloseEnough(TakeProfit, 0) )
      
      
      if (HiddenPips > 0 && take > 0) take = NormalizeDouble(take - (HiddenPips / factor), Digits);

   }//if (type == OP_SELL)
   
   return(take);
   
}//End double CalculateTakeProfit(int type)

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
   if(BuySignal)
      SendLong=true;

//Usual filters
   if(SendLong)
     {
      //Extra trade filters
      if(!TradeLong) return;

      //tnavi's 4 moving averages filter
      if(UseTnaviMA)
         if(tMaTrend!=up)
            return;

      //Bob's double moving averages filter
      if(UseBobMA)
         if(bMaTrend!=up)
            return;

      //Single moving average
      if(UseSingleMA)
         if(sMaTrend!=up)
            return;

      //CSS.         
      if (UseCSS)
      {
         //We are buying the first in the pair ans selling the second, so ensure they are moving in the correct direction and on the right side of 0
         if (CurrDirection1 == downaccelerating || CurrDirection1 == downdecelerating) return;
         if (CurrDirection2 == upaccelerating || CurrDirection2 == updecelerating) return;
      }//if (UseCSS)
      

      if(UseZeljko && !BalancedPair(OP_BUY) ) return;

      //Change of market state - explanation at the end of start()
      //if (OldAsk <= some_condition) SendLong = false;   
     }//if (SendLong)

/////////////////////////////////////////////////////////////////////////////////////

   if(!SendLong)
     {
      //Short trade
      //Specific system filters
      if(SellSignal)
         SendShort=true;

      if(SendShort)
        {

         //Extra trade filters
         if(!TradeShort) return;

         //Other filters

         //tnavi's 4 moving averages filter
         if(UseTnaviMA)
            if(tMaTrend!=down)
               return;

         //Bob's double moving averages filter
         if(UseBobMA)
            if(bMaTrend!=down)
               return;

         //Single moving average
         if(UseSingleMA)
            if(sMaTrend!=down)
               return;

         //CSS.         
         if (UseCSS)
         {
            //We are selling the first in the pair ans buying the second, so ensure they are moving in the correct direction and on the right side of 0        
            if (CurrDirection1 == upaccelerating || CurrDirection1 == updecelerating) return;
            if (CurrDirection2 == downaccelerating || CurrDirection2 == downdecelerating) return;
         }//if (UseCSS)

         if(UseZeljko && !BalancedPair(OP_SELL) ) return;

         //Change of market state - explanation at the end of start()
         //if (OldBid += some_condition) SendShort = false;   
        }//if (SendShort)

     }//if (!SendLong)

////////////////////////////////////////////////////////////////////////////////////////

//No need to continue if there are no orders to be sent
   if(!SendLong)
      if(!SendShort)
         return;

//Long 
   if(SendLong)
   {

      //Immediate market order
      if (SendImmediateMarketTrade)
      {
         stop = CalculateStopLoss(OP_BUY, Ask);
         take = CalculateTakeProfit(OP_BUY, Ask);
         SendSingleTrade(Symbol(), OP_BUY, TradeCommentRIV, SendLots, Ask, stop, take);
      }//if (SendImmediateMarketTrade)
      

      //Send the buy stop grid above Ask
      price=NormalizeDouble(Ask+(DistanceBetweenTrades/factor),Digits);
      type=OP_BUYSTOP;
      stop = CalculateStopLoss(OP_BUY, price);
      take = CalculateTakeProfit(OP_BUY, price);

      //Lot size calculated by risk
      if(RiskPercent>0) SendLots=CalculateLotSize(price,NormalizeDouble(stop+(HiddenPips/factor),Digits));
      
      SendBuyGrid(Symbol(),type,NormalizeDouble(Ask+(DistanceBetweenTrades/factor),Digits),SendLots,TradeCommentRIV); //MJB

                                                                                                                      //Now the lower half of the grid.
      //Sell stops
      if(GridType==Hedged_Stop_Orders_Only)
         SendSellGrid(Symbol(),OP_SELLSTOP,NormalizeDouble(Bid -(DistanceBetweenTrades/factor),Digits),SendLots,TradeCommentRIV); //MJB

      //Limit
      if(GridType==Stop_And_Limit_Orders)
      {
         SendBuyGrid(Symbol(),OP_BUYLIMIT,NormalizeDouble(Ask -(DistanceBetweenTrades/factor),Digits),SendLots,TradeCommentRIV); //MJB
         if (MultiTradeInOppositeDirection)
            SendOppSellGrid(Symbol(),OP_SELLSTOP,NormalizeDouble(Bid -(DistanceBetweenOppositeTrades/factor),Digits),SendLots,TradeCommentRIV); //MJB         
      }//if(GridType==Stop_And_Limit_Orders)
      
      CountOpenTrades();
   }//if (SendLong)

//Short
   if(SendShort)
   {

      //Immediate market order
      if (SendImmediateMarketTrade)
      {
         stop = CalculateStopLoss(OP_SELL, Bid);
         take = CalculateTakeProfit(OP_SELL, Bid);
         SendSingleTrade(Symbol(), OP_SELL, TradeCommentRIV, SendLots, Bid, stop, take);
      }//if (SendImmediateMarketTrade)
      

      //Send the sell stop grid below Bid
      type=OP_SELLSTOP;
      price=NormalizeDouble(Bid -(DistanceBetweenTrades/factor),Digits);//Change this to whatever the price needs to be         
      stop = CalculateStopLoss(OP_SELL, price);
      take = CalculateTakeProfit(OP_SELL, price);

      //Lot size calculated by risk
      if(RiskPercent>0) SendLots=CalculateLotSize(price,NormalizeDouble(stop+(HiddenPips/factor),Digits));

      SendSellGrid(Symbol(),type,NormalizeDouble(Bid -(DistanceBetweenTrades/factor),Digits),SendLots,TradeCommentRIV); //MJB

                                                                                                                        //Now the upper half of the grid.
      //Buy stops
      if(GridType==Hedged_Stop_Orders_Only)
         SendBuyGrid(Symbol(),OP_BUYSTOP,NormalizeDouble(Ask+(DistanceBetweenTrades/factor),Digits),SendLots,TradeCommentRIV); //MJB

      //Limit
      if(GridType==Stop_And_Limit_Orders)
      {
         SendSellGrid(Symbol(),OP_SELLLIMIT,NormalizeDouble(Bid+(DistanceBetweenTrades/factor),Digits),SendLots,TradeCommentRIV); //MJB
         if (MultiTradeInOppositeDirection)
            SendOppBuyGrid(Symbol(),OP_BUYSTOP,NormalizeDouble(Ask+(DistanceBetweenOppositeTrades/factor),Digits),SendLots,TradeCommentRIV); //MJB
      }//if(GridType==Stop_And_Limit_Orders)
      
      CountOpenTrades();

   }//if (SendShort)

//Safety feature
   TimeToStartTrading=TimeCurrent()+PostTradeAttemptWaitSeconds;

}//void LookForTradingOpportunities()

bool DoesTradeExist(int type,double price)
{

   if(OrdersTotal()==0)
      return(false);
   if(OpenTrades==0)
      return(false);


   for(int cc=OrdersTotal()-1; cc>=0; cc--)
     {
      if(!OrderSelect(cc,SELECT_BY_POS)) continue;
      if(OrderSymbol()!=Symbol()) continue;
      if(OrderMagicNumber()!=MagicNumber) continue;
      if(OrderType()!=type) continue;
      if(!CloseEnough(OrderOpenPrice(),price)) continue;

      //Got to here, so we have found a trade
      return(true);

     }//for (int cc = OrdersTotal() - 1; cc >= 0; cc--)

//Got this far, so no trade found
   return(false);

}//End bool DoesTradeExist(int type, double price)

void SendBuyGrid(string symbol,int type,double price,double lot,string comment) //MJB
{
//Send a grid of stop orders using the passed parameters
   double stop = 0;
   double take = 0;
   bool result = false;

//For minimum distance market to stop level
   double spread=(Ask-Bid);
   double StopLevel=MarketInfo(Symbol(),MODE_STOPLEVEL)+spread;

   int tries=0;//To break out of an infinite loop

   for(int cc=0; cc<GridSize; cc++)
     {
      tries++;
      if(tries>=100)
         break;

      //Check the trade has not already been sent
      if(DoesTradeExist(type,price))
        {
         //Increment the price for the next pending
         if(type==OP_BUYSTOP)
            price=NormalizeDouble(price+(DistanceBetweenTrades/factor),Digits);
         else
            price=NormalizeDouble(price -(DistanceBetweenTrades/factor),Digits);

         continue;
        }//if (DoesTradeExist(OP_BUYSTOP, price))

      stop = CalculateStopLoss(OP_BUY, price);
      take = CalculateTakeProfit(OP_BUY, price);

      if(!IsExpertEnabled())
        {
         Comment("                          EXPERTS DISABLED");
         return;
        }//if (!IsExpertEnabled() )

      result=true;
      //TradeComment is defined either in ReadIndicatorValues,
      //and subsequently in CountOpenTrades()
      result=SendSingleTrade(Symbol(),type,comment,lot,price,stop,take); //MJB

      //Each trade in the grid must be sent, so deal with failures
      if(!result)
        {
         int err=GetLastError();
         if(err==132)//Market is closed
            return;
         Alert("Buy stop: Lots ",lot,": Price ",price,": Ask ",Ask);
         Sleep(5000);
         cc--;
         continue;//Do not want price incrementing
        }//if (!result)

      //Increment the price for the next pending
      if(type==OP_BUYSTOP)
         price=NormalizeDouble(price+(DistanceBetweenTrades/factor),Digits);
      else
         price=NormalizeDouble(price -(DistanceBetweenTrades/factor),Digits);
      Sleep(500);

     }//for (int cc = 0; cc < GridSize; cc++)

//Set up the global variable with the signal type
   GlobalVariableSet(GvName,OP_BUY);
   OriginalSignal=OP_BUY;

}//End void SendBuyGrid(string symbol, double price, double lot)
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void SendSellGrid(string symbol,int type,double price,double lot,string comment) //MJB
{
//Send a grid of stop orders using the passed parameters
   double stop = 0;
   double take = 0;
   bool result = false;

//For minimum distance market to stop level
   double spread=(Ask-Bid);
   double StopLevel=MarketInfo(Symbol(),MODE_STOPLEVEL)+spread;

   int tries=0;//To break out of an infinite loop

   for(int cc=0; cc<GridSize; cc++)
     {
      tries++;
      if(tries>=100)
         break;

      //Check the trade has not already been sent
      if(DoesTradeExist(type,price))
        {
         //Increment the price for the next pending
         if(type==OP_SELLLIMIT)
            price=NormalizeDouble(price+(DistanceBetweenTrades/factor),Digits);
         else
            price=NormalizeDouble(price -(DistanceBetweenTrades/factor),Digits);

         continue;
        }//if (DoesTradeExist(OP_SELLSTOP, price))

      stop = CalculateStopLoss(OP_SELL, price);
      take = CalculateTakeProfit(OP_SELL, price);

      if(!IsExpertEnabled())
        {
         Comment("                          EXPERTS DISABLED");
         return;
        }//if (!IsExpertEnabled() )

      result=true;
      //TradeComment is defined either in ReadIndicatorValues,
      //and subsequently in CountOpenTrades()
      result=SendSingleTrade(Symbol(),type,comment,lot,price,stop,take); //MJB

      //Each trade in the grid must be sent, so deal with failures
      if(!result)
        {
         int err=GetLastError();
         if(err==132)//Market is closed
            return;
         Alert("Sell stop: Lots ",lot,": Price ",price,": Bid ",Bid);Sleep(5000);
         cc--;
         continue;//Do not want price incrementing
        }//if (!result)

      //Increment the price for the next pending
      if(type==OP_SELLLIMIT)
         price=NormalizeDouble(price+(DistanceBetweenTrades/factor),Digits);
      else
         price=NormalizeDouble(price -(DistanceBetweenTrades/factor),Digits);

      Sleep(500);

     }//for (int cc = 0; cc < GridSize; cc++)

//Set up the global variable with the signal type
   GlobalVariableSet(GvName,OP_SELL);
   OriginalSignal=OP_SELL;

}//End void SendSellGrid(string symbol, double price, double lot)

void SendOppBuyGrid(string symbol,int type,double price,double lot,string comment) //MJB
{
//Send a grid of stop orders using the passed parameters
   double stop = 0;
   double take = 0;
   bool result = false;


   int tries=0;//To break out of an infinite loop

   for(int cc=0; cc<NoOfOppositeTrades; cc++)
     {
      tries++;
      if(tries>=100)
         break;

      //Check the trade has not already been sent
      if(DoesTradeExist(type,price))
        {
         //Increment the price for the next pending
         if(type==OP_BUYSTOP)
            price=NormalizeDouble(price+(DistanceBetweenOppositeTrades/factor),Digits);
         else
            price=NormalizeDouble(price -(DistanceBetweenOppositeTrades/factor),Digits);

         continue;
        }//if (DoesTradeExist(OP_BUYSTOP, price))

      stop = 0;
      take = NormalizeDouble(price + (OppositeTakeProfitPips / factor), Digits);

      if(!IsExpertEnabled())
        {
         Comment("                          EXPERTS DISABLED");
         return;
        }//if (!IsExpertEnabled() )

      result=true;
      //TradeComment is defined either in ReadIndicatorValues,
      //and subsequently in CountOpenTrades()
      result=SendSingleTrade(Symbol(),type,comment,lot,price,stop,take); //MJB

      //Each trade in the grid must be sent, so deal with failures
      if(!result)
        {
         int err=GetLastError();
         if(err==132)//Market is closed
            return;
         Alert("Buy stop: Lots ",lot,": Price ",price,": Ask ",Ask);
         Sleep(5000);
         cc--;
         continue;//Do not want price incrementing
        }//if (!result)

      //Increment the price for the next pending
      if(type==OP_BUYSTOP)
         price=NormalizeDouble(price+(DistanceBetweenOppositeTrades/factor),Digits);
      else
         price=NormalizeDouble(price -(DistanceBetweenOppositeTrades/factor),Digits);
      Sleep(500);

     }//for (int cc = 0; cc < NoOfOppositeTrades; cc++)



}//End void SendOppBuyGrid(string symbol, double price, double lot)
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void SendOppSellGrid(string symbol,int type,double price,double lot,string comment) //MJB
{
//Send a grid of stop orders using the passed parameters
   double stop = 0;
   double take = 0;
   bool result = false;

   int tries=0;//To break out of an infinite loop

   for(int cc=0; cc<NoOfOppositeTrades; cc++)
     {
      tries++;
      if(tries>=100)
         break;

      //Check the trade has not already been sent
      if(DoesTradeExist(type,price))
        {
         //Increment the price for the next pending
         if(type==OP_SELLLIMIT)
            price=NormalizeDouble(price+(DistanceBetweenOppositeTrades/factor),Digits);
         else
            price=NormalizeDouble(price -(DistanceBetweenOppositeTrades/factor),Digits);

         continue;
        }//if (DoesTradeExist(OP_SELLSTOP, price))

      stop = 0;
      take = NormalizeDouble(price - (OppositeTakeProfitPips / factor), Digits);

      if(!IsExpertEnabled())
        {
         Comment("                          EXPERTS DISABLED");
         return;
        }//if (!IsExpertEnabled() )

      result=true;
      //TradeComment is defined either in ReadIndicatorValues,
      //and subsequently in CountOpenTrades()
      result=SendSingleTrade(Symbol(),type,comment,lot,price,stop,take); //MJB

      //Each trade in the grid must be sent, so deal with failures
      if(!result)
        {
         int err=GetLastError();
         if(err==132)//Market is closed
            return;
         Alert("Sell stop: Lots ",lot,": Price ",price,": Bid ",Bid);Sleep(5000);
         cc--;
         continue;//Do not want price incrementing
        }//if (!result)

      //Increment the price for the next pending
      if(type==OP_SELLLIMIT)
         price=NormalizeDouble(price+(DistanceBetweenOppositeTrades/factor),Digits);
      else
         price=NormalizeDouble(price -(DistanceBetweenOppositeTrades/factor),Digits);

      Sleep(500);

     }//for (int cc = 0; cc < NoOfOppositeTrades; cc++)


}//End void SendOppSellGrid(string symbol, double price, double lot)


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
   
   return(false);
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
         //Safety feature. Sometimes an unexpected concatenation of inputs choice and logic error can cause rapid opening-closing of trades. Detect a closed trade and check that is was not a rogue.
         if (OldOpenTrades != OpenTrades)
         {
            if (IsClosedTradeRogue() )
            {
               RobotSuspended = true;
               return;
            }//if (IsClosedTradeRogue() )      
         }//if (OldOpenTrades != OpenTrades)
         if (ForceTradeClosure) return;//Emergency measure to force a retry at the next tick
         
         OldOpenTrades = OpenTrades;
         
         Sleep(1000);

      }//while (spread >= TargetSpread)      
   }//if (spread >= TargetSpread)
}//End void CheckForSpreadWidening()

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


void GetAverageSpread()
{

//   ************************* added for OBJ_LABEL
   DisplayCount = 1;
   removeAllObjects();
//   *************************
 
   static double SpreadTotal = 0;
   AverageSpread = 0;
   
   //Add spread to total and keep track of the ticks
   double Spread = (Ask - Bid) * factor;
   SpreadTotal+= Spread;
   CountedTicks++;
   
   //All ticks counted?
   if (CountedTicks >= TicksToCount)
   {
      AverageSpread = NormalizeDouble(SpreadTotal / TicksToCount, 1);
      //Save the average for restarts.
      GlobalVariableSet(SpreadGvName, AverageSpread);
      RunInSpreadDetectionMode = false;
   }//if (CountedTicks >= TicksToCount)
   
   
   
}//void GetAverageSpread()


double GetHGI(string symbol, int tf, int buffer, int shift)
{

   //return(iCustom(symbol, tf, HGI_Name, 0, false, false, false, false, false, false, false, buffer, shift) );
   return(iCustom(symbol, tf, HGI_Name, true, buffer, shift));
   
}//double GetHGI()

bool indiExists( string indiName ) 
{

   //Returns true if a custom indi exists in the user's indi folder, else false
   bool exists = false;
   
   ResetLastError();
   double value = iCustom( Symbol(), Period(), indiName, 0, 0 );
   if ( GetLastError() == 0 ) exists = true;
   
   return(exists);

}//End bool indiExists( string indiName ) 

double GetAtr(string symbol, int tf, int period, int shift)
{
   //Returns the value of atr
   
   return(iATR(symbol, tf, period, shift) );   

}//End double GetAtr()

double GetSemaphor(string symbol, int tf, double p1, double p2, double p3, string d1,
                   string d2, string d3, int buffer, int shift)
{

   return(iCustom(symbol, tf, "3 Level", p1, p2, p3, d1, d2, d3, buffer, shift) );

}//double GetSemaphor(string symbol, int tf, double p1, double p2, double p3, string d1

double GetMa(string symbol, int tf, int period, int mashift, int method, int ap, int shift)
{
   return(iMA(symbol, tf, period, mashift, method, ap, shift) );
}//End double GetMa(int tf, int period, int mashift, int method, int ap, int shift)

void SplitSymbol()
{
   Curr1 = StringSubstrOld(Symbol(), 0, 3);
   Curr2 = StringSubstrOld(Symbol(), 3, 3);
   
   //Calculate the index to pass to CSS
   int cc;
   for (cc = 0; cc < ArraySize(CurrNames); cc++)
   {
      if (Curr1 == CurrNames[cc])
      {
         CurrIndex1 = cc;
         break;
      }//if (Curr1 == CurrNames[cc])
   }//for (cc = 0; cc < ArraySize(CurrNames); cc++)
   
   for (cc = 0; cc < ArraySize(CurrNames); cc++)
   {
      if (Curr2 == CurrNames[cc])
      {
         CurrIndex2 = cc;
         break;
      }//if (Curr1 == CurrNames[cc])
   }//for (cc = 0; cc < ArraySize(CurrNames); cc++)

}//End void SplitSymbol()

double GetCSS(double index, int shift)
{

   // return(iCustom(NULL, 0, "10.5 CSS 4H 1.0.8 modified for automation", autoSymbols, symbolsToWeigh, maxBars, addSundayToMonday, timeFrame, ignoreFuture, index, shift));
   
   // Initialize
   double myCSS[];
   // Call libary
   // Do not care about multiple calls, libCCS caches its values internally
   libCSSgetCSS( myCSS, CssTf, shift, true );
   
   int currencyIndex = NormalizeDouble( index, 0 );
   
   return ( myCSS[currencyIndex] );

}//End double GetCSS(int index, int shift)

void ReadIndicatorValues()
{

   int cc=0;
   double val=0;

//Declare a shift for use with indicators.
   int shift=0;
   if(!EveryTickMode)
     {
      shift=1;
     }//if (!EveryTickMode)

///////////////////////////////////////////////////////////////////////
//HGI
   static datetime OldReadBarTime=0;
   if(EveryTickMode)
      OldReadBarTime=0;

////////////////////////////////////////
//shift = 2;
////////////////////////////////////////



   //MA
   //Read once a minute
   static datetime OldMaBarTime=0;
   if(OldMaBarTime!=iTime(Symbol(),PERIOD_M1,0))
     {

      //tnavi's four moving average filter.
      //Trend is up then both fast ma's > both slow ma's.
      //Vice versa for down trend.
      //Ranging market if the ma's are mixed up.
      //Relationship to the market is not relevant, so we can buy when the market is below
      //the ma's and sell above.
      if(UseTnaviMA)
        {
         OldMaBarTime=iTime(Symbol(),PERIOD_M1,0);

         tFMaVal1 = GetMa(Symbol(), TnaviTimeFrame, tFastMaPeriod1, 0, tMaMethod, tMaAppliedPrice, 0);
         tFMaVal2 = GetMa(Symbol(), TnaviTimeFrame, tFastMaPeriod2, 0, tMaMethod, tMaAppliedPrice, 0);
         tSMaVal1 = GetMa(Symbol(), TnaviTimeFrame, tSlowMaPeriod1, 0, tMaMethod, tMaAppliedPrice, 0);
         tSMaVal2 = GetMa(Symbol(), TnaviTimeFrame, tSlowMaPeriod2, 0, tMaMethod, tMaAppliedPrice, 0);

         //Define the status
         tMaTrend=crossing;//Default
         TradeLong=false;
         TradeShort=false;

         //Uptrend. Both faster ma's must be > both slower ma's
         if(tFMaVal1>tSMaVal1)
            if(tFMaVal2>tSMaVal1)
               if(tFMaVal1>tSMaVal2)
                  if(tFMaVal2>tSMaVal2)
                    {
                     tMaTrend=up;
                     TradeLong=true;
                    }//if (tFMaVal2 > tSMaVal2)

         //Downtrend. Both faster ma's must be < both slower ma's
         if(tFMaVal1<tSMaVal1)
            if(tFMaVal2<tSMaVal1)
               if(tFMaVal1<tSMaVal2)
                  if(tFMaVal2<tSMaVal2)
                    {
                     tMaTrend=down;
                     TradeShort=true;
                    }//if (tFMaVal2 < tSMaVal2)

        }//if (UseTnaviMA)       

/*
      BNob's moving average filter.
      This is H4, 60 and 240 period ema applied to the close.
      Buy when market is > both moving averages.
      Sell when market is < both moving averages.
      Market is in between = the pair is ranging.
      The relationship between the two ma's is not relevant.      
      */
      if(UseBobMA)
        {
         bFMaVal = GetMa(Symbol(), BobTimeFrame, bFastMaPeriod, 0, bMaMethod, bMaAppliedPrice, 0);
         bSMaVal = GetMa(Symbol(), BobTimeFrame, bSlowMaPeriod, 0, bMaMethod, bMaAppliedPrice, 0);

         //Define the status
         bMaTrend=ranging;//Default
         TradeLong=false;
         TradeShort=false;

         //Uptrend. Market must be above both ma's
         if(Bid>bFMaVal)
            if(Bid>bSMaVal)
              {
               bMaTrend=up;
               TradeLong=true;
              }//if (Bid > bSMaVal)

         //Downtrend. Market must be below both ma's
         if(Bid<bFMaVal)
            if(Bid<bSMaVal)
              {
               bMaTrend=down;
               TradeShort=true;
              }//if (Bid < bSMaVal)

        }//if (UseBobMA)

      //Single moving average filter
      if(UseSingleMA)
        {
         sMaVal=GetMa(Symbol(),SingleMaTimeFrame,sMaPeriod,0,sMaMethod,sMaAppliedPrice,0);

         //Define the status
         sMaTrend=ranging;//Default
         TradeLong=false;
         TradeShort=false;

         //Uptrend. Market must be above the ma
         if(Bid>sMaVal)
           {
            sMaTrend=up;
            TradeLong=true;
           }//if (Bid > bSMaVal)

         //Downtrend. Market must be below te ma
         if(Bid<sMaVal)
           {
            sMaTrend=down;
            TradeShort=true;
           }//if (Bid < bSMaVal)

        }//if (UseSingleMA)

     }//if (OldMaBarTime != iTime(Symbol(), PERIOD_M1, 0) )

//SemStatus = "No open trades, so not reading the 3 level indi to lower the pressure on the cpu";
//semafor
   if(CloseTradesOnRelevantSemafor)
     {
      static datetime OldSemTime=0;

      if(OldSemTime!=iTime(Symbol(),TradingTimeFrame,0))
        {
         OldSemTime=iTime(Symbol(),TradingTimeFrame,0);

         SemStatus=nosemafor;

         //Buffer 5 holds a high signal
         val=GetSemaphor(Symbol(),TradingTimeFrame,Period1,Period2,Period3,
                         Dev_Step_1,Dev_Step_2,Dev_Step_3,
                         5,1);
         if(!CloseEnough(val,0))
           {
            SemStatus=highsemafor;
           }//if (!CloseEnough(TtfSemVal, 0))

         //Buffer 4 holds a low signal
         val=GetSemaphor(Symbol(),TradingTimeFrame,Period1,Period2,Period3,
                         Dev_Step_1,Dev_Step_2,Dev_Step_3,
                         4,1);
         if(!CloseEnough(val,0))
           {
            SemStatus=lowsemafor;
           }//if (!CloseEnough(TtfSemVal, 0))

        }//if (OldHtfTime != iTime(Symbol(), TradingTimeFrame, 0) )

     }//if (CloseTradesOnRelevantSemafor)

//Closing immediately a candle appears
   if(CloseImmediatelySemaforAppears)
     {
      if(BuyOpen || SellOpen)//We only need this if there are open trades
        {
         static datetime OldM1SemTime=0;
         //Read the indi every minute
         if(OldM1SemTime!=iTime(Symbol(),PERIOD_M1,0))
           {
            OldM1SemTime=iTime(Symbol(),PERIOD_M1,0);

            //Buffer 5 holds a high signal
            val=GetSemaphor(Symbol(),TradingTimeFrame,Period1,Period2,Period3,
                            Dev_Step_1,Dev_Step_2,Dev_Step_3,
                            5,0);
            if(!CloseEnough(val,0))
              {
               SemStatus=highsemafornow;
              }//if (!CloseEnough(TtfSemVal, 0))

            //Buffer 4 holds a low signal
            val=GetSemaphor(Symbol(),TradingTimeFrame,Period1,Period2,Period3,
                            Dev_Step_1,Dev_Step_2,Dev_Step_3,
                            4,0);
            if(!CloseEnough(val,0))
              {
               SemStatus=lowsemafornow;
              }//if (!CloseEnough(TtfSemVal, 0))

           }//if (OldM1SemTime != iTime(Symbol(), TradingTimeFrame, 0))

        }//if (BuyOpen || SellOpen)
     }//if (CloseImmediatelySemaforAppears)

//////////////////////////////////////////////////////////////////////////////////

   if(OldReadBarTime!=iTime(Symbol(),TradingTimeFrame,0))
     {
      OldReadBarTime=iTime(Symbol(),TradingTimeFrame,0);

      static datetime OldBarHgiReadTime=0;
      static bool IsNewHgiBar=false;

      //Forces the EA to read HGI at the opening of a new candle even if HgiReadDelaySeconds haven't expired
      if(OldBarHgiReadTime!=iTime(Symbol(),TradingTimeFrame,0))
        {
         OldBarHgiReadTime=iTime(Symbol(),TradingTimeFrame,0);
         IsNewHgiBar=true;
        }
      else
         IsNewHgiBar=false;

      if(TimeCurrent()>=NextReadTime || IsNewHgiBar)
        {
         TrendArrowStatus=Trendnoarrow;
         WaveStatus=Wavenone;
         RadArrowStatus=Radnoarrow;
         HgiSignalStatus=hginosignal;
         NextReadTime=TimeCurrent()+HgiReadDelaySeconds;

         //Look for trend arrows
         if(TrendTradingAllowed)
           {
            //Buffer 0 holds a buy trend arrow - large green up
            val=GetHGI(Symbol(),TradingTimeFrame,0,shift);
            if(!CloseEnough(val,EMPTY_VALUE))
              {
               TrendArrowStatus=Trenduparrow;
               TradeCommentRIV=TrendTradeComment; //MJB
              }//if (!CloseEnough(val 0) )         
            else
              {
               //Buffer 1 hods a sell trend arrrow - large red down
               val=GetHGI(Symbol(),TradingTimeFrame,1,shift);
               if(!CloseEnough(val,EMPTY_VALUE))
                 {
                  TrendArrowStatus=Trenddownarrow;
                  TradeCommentRIV=TrendTradeComment; //MJB
                 }//if (!CloseEnough(val 0) 
              }//else
           }//if (TrendTradingAllowed)

         //Look for Rad arrows
         if(RadTradingAllowed)
           {
            //Buffer 4 holds a buy rad arrow - small diagonal green up
            val=GetHGI(Symbol(),TradingTimeFrame,4,shift);
            if(!CloseEnough(val,EMPTY_VALUE))
              {
               RadArrowStatus=Raduparrow;
               TradeCommentRIV=RadTradeComment; //MJb
              }//if (!CloseEnough(val 0) )  

            //Buffer 5 holds a sell rad arrow - small diagonal red down
            val=GetHGI(Symbol(),TradingTimeFrame,5,shift);
            if(!CloseEnough(val,EMPTY_VALUE))
              {
               RadArrowStatus=Raddownarrow;
               TradeCommentRIV=RadTradeComment; //MJB
              }//if (!CloseEnough(val 0) )  
           }//if (RadTradingAllowed)

         //Look for blue waves
         if(WaveTradingAllowed)
           {
            //Buffer 7 holds a wavy trend - blue squiggle
            val=GetHGI(Symbol(),TradingTimeFrame,7,shift);
            if(!CloseEnough(val,EMPTY_VALUE))
              {
               if(Bid>val)
                  WaveStatus=Wavebuytrend;
               else
                  WaveStatus=Waveselltrend;

               TradeCommentRIV=WaveTradeComment; //MJB   
              }//if (!CloseEnough(val 0) )  
           }//if (WaveTradingAllowed)

         //Look for a yellow range squggle.
         //Buffer 6 holds a wavy range - yellow squiggle
         val=GetHGI(Symbol(),TradingTimeFrame,6,shift);

         if(!CloseEnough(val,EMPTY_VALUE))
           {
            WaveStatus=Waverange;
           }//if (!CloseEnough(val 0) )           

         /////////////////////////////////////////////////////////////////////////////////////
         //Do we have a trade signal
         BuySignal=false;
         SellSignal=false;

         if(TrendTradingAllowed)
           {
            if(TrendArrowStatus==Trenduparrow)
               if((!CloseTradesOnRelevantSemafor && !CloseImmediatelySemaforAppears) || (SemStatus!=highsemafor && SemStatus!=highsemafornow))
                  BuySignal=true;

            if(TrendArrowStatus==Trenddownarrow)
               if((!CloseTradesOnRelevantSemafor && !CloseImmediatelySemaforAppears) || (SemStatus!=lowsemafor && SemStatus!=lowsemafornow))
                  SellSignal=true;

            if(BuySignal || SellSignal)
               TradeCommentRIV=TrendTradeComment; //MJB

           }//if (TrendTradingAllowed)


         //Small diagonal rad arrows
         if(!BuySignal)
            if(!SellSignal)
               if(RadTradingAllowed)
                 {
                  if(RadArrowStatus==Raduparrow)
                     if((!CloseTradesOnRelevantSemafor && !CloseImmediatelySemaforAppears) || SemStatus!=highsemafor)
                        BuySignal=true;

                  if(RadArrowStatus==Raddownarrow)
                     if((!CloseTradesOnRelevantSemafor && !CloseImmediatelySemaforAppears) || SemStatus!=lowsemafor)
                        SellSignal=true;

                  if(BuySignal || SellSignal)
                     TradeCommentRIV=RadTradeComment; //MJB

                 }//if (RadTradingAllowed)

         if(!BuySignal)
            if(!SellSignal)         
               if(WaveTradingAllowed)
               {
                  if(WaveStatus==Wavebuytrend)
                     if((!CloseTradesOnRelevantSemafor && !CloseImmediatelySemaforAppears) || (SemStatus!=highsemafor && SemStatus!=highsemafornow))
                        BuySignal=true;
      
                  if(WaveStatus==Waveselltrend)
                     if((!CloseTradesOnRelevantSemafor && !CloseImmediatelySemaforAppears) || (SemStatus!=lowsemafor && SemStatus!=lowsemafornow))
                        SellSignal=true;
      
                  if(BuySignal || SellSignal)
                     TradeCommentRIV=WaveTradeComment; //MJB
      
               }//if (WaveTradingAllowed)

   //CCS
   if (UseCSS)
   {
      static datetime OldCssBarsTime, OldShiftedBarTime;
      int TimeFrame = 1;
      if (EveryTickMode) 
      {

      }//if (EveryTickMode) 
      
      shift=0;
      if (!EveryTickMode) 
      {
         shift = 1;
         TimeFrame = CssTf;
      }//if (!EveryTickMode) 
      
      if (OldCssBarsTime != iTime(NULL, TimeFrame, 0) )
      {
         OldCssBarsTime = iTime(NULL, TimeFrame, 0);
         SplitSymbol();//Split the Symbol into its constituent currencies. Also finds their index for passing to CSS
         CurrVal1[1] = GetCSS(CurrIndex1, shift);
         CurrVal2[1] = GetCSS(CurrIndex2, shift);
         if (OldShiftedBarTime != iTime(NULL, TimeFrame, shift + 1) )
         {
            OldShiftedBarTime = iTime(NULL, TimeFrame, shift + 1);
            CurrVal1[2] = GetCSS(CurrIndex1, shift + 1);
            CurrVal2[2] = GetCSS(CurrIndex2, shift + 1);         
         }//if (OldShiftedBarTime != iTime(NULL, TimeFrame, shift + 1) )         
      
         //Define direction
         //Currency 1
         if (CurrVal1[1] > 0 && CurrVal1[1] > CurrVal1[2])  CurrDirection1 = upaccelerating;
         if (CurrVal1[1] > 0 && CurrVal1[1] <= CurrVal1[2])  CurrDirection1 = updecelerating;
         
         if (CurrVal1[1] < 0 && CurrVal1[1] < CurrVal1[2])  CurrDirection1 = downaccelerating;
         if (CurrVal1[1] < 0 && CurrVal1[1] >= CurrVal1[2])  CurrDirection1 = downdecelerating;
         
         //Currency 2
         if (CurrVal2[1] > 0 && CurrVal2[1] > CurrVal2[2])  CurrDirection2 = upaccelerating;
         if (CurrVal2[1] > 0 && CurrVal2[1] <= CurrVal2[2])  CurrDirection2 = updecelerating;
         
         if (CurrVal2[1] < 0 && CurrVal2[1] < CurrVal2[2])  CurrDirection2 = downaccelerating;
         if (CurrVal2[1] < 0 && CurrVal2[1] >= CurrVal2[2])  CurrDirection2 = downdecelerating;
      
      }//if (OldCssBarsTime != iTime(NULL, PERIOD_M1, 0) )
      
      
   }//if (UseCSS)

         //Close trades on an opposite direction signal
         BuyCloseSignal=false;
         SellCloseSignal=false;

         if(BuySignal)
           {
            HgiSignalStatus=hgibuysignal;
            if(CloseOnOppositeSignal)//HGI
               SellCloseSignal=true;

           }//if (BuySignal)

         if(SellSignal)
           {
            HgiSignalStatus=hgisellsignal;
            if(CloseOnOppositeSignal)//HGI
               BuyCloseSignal=true;

           }//if (SellSignal)

         //Close on a wavy line.
         if(WaveStatus==Waverange)
           {
            //We want to close everything
            BuyCloseSignal=true;
            SellCloseSignal=true;
           }//if (WaveStatus == Waverange)

         /////////////////////////////////////////////////////////////////////////////////////

        }//if (TimeCurrent() >= NextReadTime)

     }//if (OldReadBarTime != iTime(Symbol(), TradingTimeFrame, 0) )

///////////////////////////////////////////////////////////////////////
//ATR

//For grid size
   if(UseAtrForGrid)
     {
      static datetime OldGridReadTime=0;
      if(OldGridReadTime!=iTime(Symbol(),GridAtrTimeFrame,0))
        {
         OldGridReadTime=iTime(Symbol(),GridAtrTimeFrame,0);
         GridAtrVal = GetAtr(Symbol(), GridAtrTimeFrame, GridAtrPeriod, 1);
         GridAtrVal*= factor;
         GridAtrVal = NormalizeDouble(GridAtrVal * GridAtrMultiplier, 0);
         DistanceBetweenTrades=NormalizeDouble(GridAtrVal/GridSize,0);
        }//if (OldGridReadTime != iTime(Symbol(), GridAtrTimeFrame, 0) ) 
     }//if (UseAtrForGrid)

//For stop loss
   if(UseAtrForStopLoss)
     {
      SlAtrVal=GridAtrVal*SlAtrMultiplier;//Same time frame
                                          //Different tf
      if(SlAtrTimeFrame!=GridAtrTimeFrame)
        {
         static datetime OldSlReadTime=0;
         if(OldSlReadTime!=iTime(Symbol(),SlAtrTimeFrame,0))
           {
            OldSlReadTime=iTime(Symbol(),SlAtrTimeFrame,0);
            SlAtrVal = GetAtr(Symbol(), SlAtrTimeFrame, SlAtrPeriod, 1);
            SlAtrVal*= factor;
            SlAtrVal = NormalizeDouble(SlAtrVal * SlAtrMultiplier, 0);
           }//if (OldSlReadTime != iTime(Symbol(), SlAtrTimeFrame, 0) )         
        }//if (SlAtrTimeFrame != SlAtrTimeFrame)   
      StopLoss=SlAtrVal;
     }//if (UseAtrForStopLoss)

//For take profit
   if(UseAtrForTakeProfit)
     {
      TpAtrVal=GridAtrVal*TpAtrMultiplier;//Same time frame
                                          //Different tf
      if(TpAtrTimeFrame!=GridAtrTimeFrame)
        {
         static datetime OldTpReadTime=0;
         if(OldTpReadTime!=iTime(Symbol(),TpAtrTimeFrame,0))
           {
            OldTpReadTime=iTime(Symbol(),TpAtrTimeFrame,0);
            TpAtrVal = GetAtr(Symbol(), TpAtrTimeFrame, TpAtrPeriod, 1);
            TpAtrVal*= factor;
            TpAtrVal = NormalizeDouble(TpAtrVal * TpAtrMultiplier, 0);
           }//if (OldTpReadTime != iTime(Symbol(), TpAtrTimeFrame, 0) )         
        }//if (TpAtrTimeFrame != TpAtrTimeFrame)   
      TakeProfit=TpAtrVal;
     }//if (UseAtrForTakeProfit)




///////////////////////////////////////////////////////////////////////





}//void ReadIndicatorValues()

//End Indicator module
////////////////////////////////////////////////////////////////////////////////////////

bool  LookForTradeClosure(int ticket)
{
   //Close the trade if the close conditions are met.
   //Called from within CountOpenTrades(). Returns true if a close is needed and succeeds, so that COT can increment cc,
   //else returns false
   
   if (!OrderSelect(ticket, SELECT_BY_TICKET) ) return(true);
   if (OrderSelect(ticket, SELECT_BY_TICKET) && OrderCloseTime() > 0) return(true);
   
   bool CloseThisTrade = false;
   
   string LineName = TpPrefix + DoubleToStr(ticket, 0);
   //Work with the lines on the chart that represent the hidden tp/sl
   double take = ObjectGet(LineName, OBJPROP_PRICE1);
   if (CloseEnough(take, 0) ) take = OrderTakeProfit();
   LineName = SlPrefix + DoubleToStr(ticket, 0);
   double stop = ObjectGet(LineName, OBJPROP_PRICE1);
   if (CloseEnough(stop, 0) ) stop = OrderStopLoss();
         
   ///////////////////////////////////////////////////////////////////////////////////////////////////////////
   if (!CloseThisTrade)
   {
      if (OrderType() == OP_BUY)
      {
         //TP
         if (Bid >= take && !CloseEnough(take, 0) && !CloseEnough(take, OrderTakeProfit()) ) CloseThisTrade = true;
         //SL
         if (Bid <= stop && !CloseEnough(stop, 0)  && !CloseEnough(stop, OrderStopLoss())) CloseThisTrade = true;
      
      }//if (OrderType() == OP_BUY)
      
      
      ///////////////////////////////////////////////////////////////////////////////////////////////////////////
      if (OrderType() == OP_SELL)
      {
         //TP
         if (Bid <= take && !CloseEnough(take, 0) && !CloseEnough(take, OrderTakeProfit()) ) CloseThisTrade = true;
         //SL
         if (Bid >= stop && !CloseEnough(stop, 0)  && !CloseEnough(stop, OrderStopLoss())) CloseThisTrade = true;
   
      }//if (OrderType() == OP_SELL)
   }//if (!CloseThisTrade)
      
   ///////////////////////////////////////////////////////////////////////////////////////////////////////////
   if (CloseThisTrade)
   {
       bool result = true;
       if (OrderType() < 2)
         result = CloseOrder(ticket);
       else
         result = OrderDelete(ticket);
           
      //Actions when trade close succeeds
      if (result)
      {
         DeletePendingPriceLines();
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

void CloseAllTrades(int type)
{
   ForceTradeClosure= false;
   
   if (OrdersTotal() == 0) return;
   
   bool result = false;
   
      
   for (int cc = ArraySize(FifoTicket) - 1; cc >= 0; cc--)
   {
      if (!OrderSelect(FifoTicket[cc], SELECT_BY_TICKET, MODE_TRADES) ) continue;
      if (OrderMagicNumber() != MagicNumber) continue;
      if (OrderSymbol() != Symbol() ) continue;
      if (OrderType() != type) continue;
      
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
      
   }//for (int cc = ArraySize(FifoTicket) - 1; cc >= 0; cc--)

   
}//End void CloseAllTrades()

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

/*
void CountOpenTrades()
{
   //Not all these will be needed. Which ones are depends on the individual EA.
   OpenTrades = 0;
   TicketNo = -1;
   BuyStopTicketNo = -1;
   BuyLimitTicketNo = -1;
   SellStopTicketNo = -1;
   SellLimitTicketNo = -1;
   BuyTicketNo = -1;
   SellTicketNo = -1;
   BuyOpen = false;
   SellOpen = false;
   BuyStopOpen = false;
   SellStopOpen = false;
   BuyLimitOpen = false;
   SellLimitOpen = false;
   GridTradesTotal = 0;
   GridSent = false;
   PendingTradesTotal = 0;
   MarketTradesTotal = 0;
   MarketBuys = 0;
   MarketSells = 0;
   PendingBuyStop=0;
   PendingSellStop=0;
   PendingBuyLimit=0;
   PendingSellLimit=0;
   
   //Variables to spot and store the most recent trade prices
   MostRecentBuyPrice = 0;
   MostRecentSellPrice = 0;
   datetime LatestBuyOpenTime = 0;
   datetime LatestSellOpenTime = 0;
   LatestTradeTime = 0;
   EarliestTradeTime = TimeCurrent();
   
   
   //FIFO ticket resize
   ArrayResize(FifoTicket, 0);
   
   //For hedging, so ea knows whether tp/sl need removing
   TpSet = false;
   SlSet = false;
   HedgeLotSize=0;
   
   
   int type;//Saves the OrderType() for consulatation later in the function
   
   PipsUpl = 0;//Unrealised profit and loss for hedging/recovery basket closure decisions
   CashUpl = 0;
   MarketBuys=0;
   MarketSells=0;
   BuyPipsUpl=0;
   SellPipsUpl=0;
   BuyCashUpl=0;
   SellCashUpl=0;
   
   if (OrdersTotal() == 0) return;
   
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
      
      //All conditions passed, so carry on
      type = OrderType();//Store the order type
      
      //Does the trade have sl/tp
      if (!CloseEnough(OrderTakeProfit(), 0) )
         TpSet = true;
      if (!CloseEnough(OrderStopLoss(), 0) )
         SlSet = true;
        
      
      //Trades totals
      GridSent = true;
      GridTradesTotal++;
      OpenTrades++;
      if (OrderType() > 1)
         PendingTradesTotal++;
      else
         MarketTradesTotal++;
         
      //Store the latest trade sent. Most of my EA's only need this final ticket number as either they are single trade
      //bots or the last trade in the sequence is the important one. Adapt this code for your own use.
      if (TicketNo  == -1) TicketNo = OrderTicket();

      //Store ticket numbers for FIFO
      ArrayResize(FifoTicket, OpenTrades + 1);
      FifoTicket[OpenTrades] = OrderTicket();
      
      //The time of the most recent pending order
      if (OrderType() > 1)
         if (OrderOpenTime() > LatestTradeTime)
            LatestTradeTime = OrderOpenTime();
      //Time of the furthest back in time trade
      if (OrderOpenTime() < EarliestTradeTime)
         EarliestTradeTime = OrderOpenTime();
         
      //PipsUpl might not be needed. Depends on the individual EA
      CashUpl+= (OrderProfit() + OrderSwap() + OrderCommission()); 
      //The next block of code calculates the pips upl of an open trade. 
      double pips = 0;
      if (OrderType() < 2)
      {
         pips = CalculateTradeProfitInPips(OrderType());
         PipsUpl+= pips;
         HedgeLotSize = OrderLots();
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
      
      //These might need extra coding if both stop and limit orders are used
      if (OrderType() == OP_BUYSTOP) 
      {
         BuyStopOpen = true; 
         BuyStopTicketNo = OrderTicket();
         PendingBuyStop++;
      }//if (OrderType() == OP_BUYSTOP) 
      
      if (OrderType() == OP_BUYLIMIT) 
      {
         BuyLimitOpen = true; 
         BuyLimitTicketNo = OrderTicket(); 
         PendingBuyLimit++;
      }//if (OrderType() == OP_BUYLIMIT) 
      
      if (OrderType() == OP_SELLSTOP) 
      {
         SellStopOpen = true; 
         SellStopTicketNo = OrderTicket();
         PendingSellStop++;
      }//if (OrderType() == OP_SELLSTOP) 
      
      if (OrderType() == OP_SELLLIMIT) 
      {
         SellLimitOpen = true; 
         SellLimitTicketNo = OrderTicket();
         PendingSellLimit++;
      }//if (OrderType() == OP_SELLLIMIT) 
      
      
      //Add missing tp/sl in case rapidly moving markets prevent their addition - ECN
      if (!Hedged)
      {
         if (CloseEnough(OrderStopLoss(), 0) )
            if (!CloseEnough(StopLoss, 0)) 
               InsertStopLoss(OrderTicket());
         if (CloseEnough(OrderTakeProfit(), 0) )
            if (!CloseEnough(TakeProfit, 0) ) 
               InsertTakeProfit(OrderTicket() );
      }//if (!Hedged)
      
      //Replace missing tp and sl lines
      if (HiddenPips > 0) ReplaceMissingSlTpLines();
      
      if (!Hedged)
         TradeWasClosed = LookForTradeClosure(OrderTicket() );
      if (TradeWasClosed) 
      {
         if (type == OP_BUY) BuyOpen = false;//Will be reset if subsequent trades are buys that are not closed
         if (type == OP_SELL) SellOpen = false;//Will be reset if subsequent trades are sells that are not closed
         cc++;
         continue;
      }//if (TradeWasClosed) 
         
      //Profitable trade management
      if (!Hedged)
         if (OrderProfit() > 0) 
         {
            TradeManagementModule(OrderTicket());
         }//if (OrderProfit() > 0) 
               
      //Trade types and half-close, and adjust sl/tp in case slippage has caused them to be inaccurate when the trade was sent.
      if (OrderType() == OP_BUY) 
      {
         BuyOpen = true;
         BuyTicketNo = OrderTicket();
         if (OrderOpenTime() > LatestBuyOpenTime)
         {
            LatestBuyOpenTime = OrderOpenTime();
            MostRecentBuyPrice = OrderOpenPrice();
         }//if (OrderOpenTime() > LatestBuyOpenTime)         
      }//if (OrderType() == OP_BUY) 
      
      if (OrderType() == OP_SELL) 
      {
         SellOpen = true;
         SellTicketNo = OrderTicket();
         if (OrderOpenTime() > LatestSellOpenTime)
         {
            LatestSellOpenTime = OrderOpenTime();
            MostRecentSellPrice = OrderOpenPrice();
         }//if (OrderOpenTime() > LatestBuyOpenTime)         
      }//if (OrderType() == OP_SELL) 
      
   }//for (int cc = OrdersTotal() - 1; cc <= 0; c`c--)
   
   //Sort ticket numbers for FIFO
   if (OpenTrades > 0)
      ArraySort(FifoTicket, WHOLE_ARRAY, 0, MODE_DESCEND);
   
   //Is the position hedged?
   Hedged = false;
   if (BuyOpen)
      if (SellOpen)
         Hedged=true;

   //Remove stop losses and take profits
   if (Hedged)
   {
      if (TpSet)
         RemoveTakeProfits();
      if (SlSet)
         RemoveStopLosses();
   }//if (Hegded)
   
         
}//End void CountOpenTrades();
*/

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

   //For hedging, so ea knows whether tp/sl need removing
   TpSet = false;
   SlSet = false;
   HedgeLotSize=0;
   
   GridTradesTotal = 0;
   GridSent = false;
   PendingTradesTotal = 0;
   MarketTradesTotal = 0;

   TradeCommentCOT=ordercomment; //MJB

   
   //FIFO ticket resize
   ArrayResize(FifoTicket, 0);
   ArrayResize(FifoTicket, 0);
   ArrayResize(FifoBuyTicket, 0);
   ArrayResize(FifoSellTicket, 0);
   ArrayInitialize(FifoBuyTicket, 0);
   ArrayInitialize(FifoSellTicket, 0);
   
   //Grid order array - provided by Bruster
   ArrayResize(GridOrderBuyTickets, 0);
   ArrayInitialize(GridOrderBuyTickets, 0);
   ArrayResize(GridOrderSellTickets, 0);
   ArrayInitialize(GridOrderSellTickets, 0);
      
   
   int type;//Saves the OrderType() for consulatation later in the function
   
   
   if (OrdersTotal() == 0) return;
   
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
      
      //All conditions passed, so carry on
      
      //The time of the most recent pending order
      if (OrderType() > 1)
         if (OrderOpenTime() > LatestTradeTime)
            LatestTradeTime = OrderOpenTime();
      //Time of the furthest back in time trade
      if (OrderOpenTime() < EarliestTradeTime)
         EarliestTradeTime = OrderOpenTime();

      
      //Trades totals
      GridSent = true;
      GridTradesTotal++;
      OpenTrades++;
      if (OrderType() > 1)
         PendingTradesTotal++;
      
      HedgeLotSize = OrderLots();
      
      type = OrderType();//Store the order type
      
      if (!CloseEnough(OrderTakeProfit(), 0) )
         TpSet = true;
      if (!CloseEnough(OrderStopLoss(), 0) )
         SlSet = true;

      TradeCommentCOT=OrderComment();//For sending with grid trades //MJB

      
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
         
         //Buys
         if (OrderType() == OP_BUY)
         {
            ArrayResize(GridOrderBuyTickets, MarketBuysCount + 1);
            GridOrderBuyTickets[MarketBuysCount][TradeOpenPrice] = OrderOpenPrice();  //can be sorted by price
            GridOrderBuyTickets[MarketBuysCount][TradeTicket] = OrderTicket();
            
            ArrayResize(FifoBuyTicket, MarketBuysCount + 1);
            FifoBuyTicket[MarketBuysCount][TradeOpenTime] = OrderOpenTime();
            FifoBuyTicket[MarketBuysCount][TradeTicket] = OrderTicket();
            FifoBuyTicket[MarketBuysCount][TradeProfitCash] = OrderProfit() + OrderSwap() + OrderCommission();
            FifoBuyTicket[MarketBuysCount][TradeProfitPips] += pips;
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
            ArrayResize(GridOrderSellTickets, MarketSellsCount + 1);
            GridOrderSellTickets[MarketSellsCount][TradeOpenPrice] = OrderOpenPrice();  //can be sorted by price
            GridOrderSellTickets[MarketSellsCount][TradeTicket] = OrderTicket();

            ArrayResize(FifoSellTicket, MarketSellsCount + 1);
            FifoSellTicket[MarketSellsCount][TradeOpenTime] = OrderOpenTime();
            FifoSellTicket[MarketSellsCount][TradeTicket] = OrderTicket();
            FifoSellTicket[MarketSellsCount][TradeProfitCash] = OrderProfit() + OrderSwap() + OrderCommission();
            FifoSellTicket[MarketSellsCount][TradeProfitPips] += pips;
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
      
      
      
      
      //Add missing tp/sl in case rapidly moving markets prevent their addition - ECN
      if (!Hedged)
      {
         if (CloseEnough(OrderStopLoss(), 0) && !CloseEnough(StopLoss, 0)) InsertStopLoss(OrderTicket());
         if (CloseEnough(OrderTakeProfit(), 0) && !CloseEnough(TakeProfit, 0)) InsertTakeProfit(OrderTicket() );
      }//if (!Hedged)

      //Replace missing tp and sl lines
      if (HiddenPips > 0) ReplaceMissingSlTpLines();
      
      if (!Hedged)
      {
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
            TradeManagementModule(OrderTicket() );
         }//if (OrderProfit() > 0) 
      }//if (!Hedged)
         
               
      
   }//for (int cc = OrdersTotal() - 1; cc <= 0; c`c--)
   
   //Sort ticket numbers for FIFO
   if (ArraySize(FifoTicket) > 0)
      ArraySort(FifoTicket, WHOLE_ARRAY, 0, MODE_DESCEND);
   if (ArraySize(FifoBuyTicket) > 0)
      ArraySort(FifoBuyTicket, WHOLE_ARRAY, 0, MODE_DESCEND);
   if (ArraySize(FifoSellTicket) > 0)
      ArraySort(FifoSellTicket, WHOLE_ARRAY, 0, MODE_DESCEND);
      
   //Is the position hedged?
   Hedged = false;
   if (BuyOpen)
      if (SellOpen)
         Hedged=true;

   //Remove stop losses and take profits
   if (Hedged)
   {
      if (TpSet)
         RemoveTakeProfits();
      if (SlSet)
         RemoveStopLosses();
   }//if (Hegded)
    
}//End void CountOpenTrades();

void RemoveTakeProfits()
{

   for (int cc = OrdersTotal() - 1; cc >= 0; cc--)
   {
      if (!OrderSelect(cc, SELECT_BY_POS) ) continue;
      if (OrderSymbol() != Symbol() ) continue;
      if (OrderMagicNumber() != MagicNumber) continue;

      if (!CloseEnough(OrderTakeProfit(), 0) )
         ModifyOrder(OrderTicket(), OrderOpenPrice(), OrderStopLoss(), 0, 
                     OrderExpiration(), clrNONE, __FUNCTION__, tpm);
      
      
  
   }//for (int cc = OrdersTotal() - 1; cc >= 0; cc--)

}//void RemoveTakeProfits()

void RemoveStopLosses()
{

   for (int cc = OrdersTotal() - 1; cc >= 0; cc--)
   {
      if (!OrderSelect(cc, SELECT_BY_POS) ) continue;
      if (OrderSymbol() != Symbol() ) continue;
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
   
   if (!OrderSelect(ticket, SELECT_BY_TICKET)) return;
   if (OrderCloseTime() > 0) return;//Somehow, we are examining a closed trade
   if (OrderStopLoss() > 0) return;//Function called unnecessarily.
   
   while(IsTradeContextBusy()) Sleep(100);
   
   double stop;
   
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

void InsertTakeProfit(int ticket)
{
   //Inserts a TP if the ECN crim managed to swindle the original trade out of the modification at trade send time
   //Called from CountOpenTrades() if TakeProfit > 0 && OrderTakeProfit() == 0.
   
   if (!OrderSelect(ticket, SELECT_BY_TICKET)) return;
   if (OrderCloseTime() > 0) return;//Somehow, we are examining a closed trade
   if (!CloseEnough(OrderTakeProfit(), 0) ) return;//Function called unnecessarily.
   
   while(IsTradeContextBusy()) Sleep(100);
   
   double take;
   
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




////////////////////////////////////////////////////////////////////////////////////////
//Pending trade price lines module.
//Doubles up by providing missing lines for the stealth stuff
void DrawPendingPriceLines()
{
   //This function will work for a full pending-trade EA.
   //The pending tp/sl can be used for hiding the stops in a market-trading ea
   
   /*
   ObjectDelete(pendingpriceline);
   ObjectCreate(pendingpriceline, OBJ_HLINE, 0, TimeCurrent(), PendingPrice);
   if (PendingBuy) ObjectSet(pendingpriceline, OBJPROP_COLOR, Green);
   if (PendingSell) ObjectSet(pendingpriceline, OBJPROP_COLOR, Red);
   ObjectSet(pendingpriceline, OBJPROP_WIDTH, 1);
   ObjectSet(pendingpriceline, OBJPROP_STYLE, STYLE_DASH);
   */
   string LineName = TpPrefix + DoubleToStr(TicketNo, 0);//TicketNo is set by the calling function - either CountOpenTrades or DoesTradeExist
   HiddenTakeProfit = 0;
   if (TicketNo > -1 && OrderTakeProfit() > 0)
   {
      if (OrderType() == OP_BUY || OrderType() == OP_BUYSTOP || OrderType() == OP_BUYLIMIT)
      {
         HiddenTakeProfit = NormalizeDouble(OrderTakeProfit() - (HiddenPips / factor), Digits);
      }//if (OrderType() == OP_BUY)
      
      if (OrderType() == OP_SELL)
      {
         HiddenTakeProfit = NormalizeDouble(OrderTakeProfit() + (HiddenPips / factor), Digits);
      }//if (OrderType() == OP_BUY)      
   }//if (TicketNo > -1 && OrderTakeProfit() > 0)
   
   if (HiddenTakeProfit > 0 && ObjectFind(LineName) == -1)
   {
      ObjectDelete(LineName);
      ObjectCreate(LineName, OBJ_HLINE, 0, TimeCurrent(), HiddenTakeProfit);
      ObjectSet(LineName, OBJPROP_COLOR, Green);
      ObjectSet(LineName, OBJPROP_WIDTH, 1);
      ObjectSet(LineName, OBJPROP_STYLE, STYLE_DOT);
   }//if (HiddenTakeProfit > 0)
   
   
   LineName = SlPrefix + DoubleToStr(TicketNo, 0);//TicketNo is set by the calling function - either CountOpenTrades or DoesTradeExist
   HiddenStopLoss = 0;
   if (TicketNo > -1 && OrderStopLoss() > 0)
   {
      if (OrderType() == OP_BUY || OrderType() == OP_BUYSTOP || OrderType() == OP_BUYLIMIT)
      {
         HiddenStopLoss = NormalizeDouble(OrderStopLoss() + (HiddenPips / factor), Digits);
      }//if (OrderType() == OP_BUY)
      
      if (OrderType() == OP_SELL || OrderType() == OP_SELLSTOP || OrderType() == OP_SELLLIMIT)
      {
         HiddenStopLoss = NormalizeDouble(OrderStopLoss() - (HiddenPips / factor), Digits);
      }//if (OrderType() == OP_BUY)      
   }//if (TicketNo > -1 && OrderStopLoss() > 0)
   
   if (HiddenStopLoss > 0 && ObjectFind(LineName) == -1)
   {
      ObjectDelete(LineName);
      ObjectCreate(LineName, OBJ_HLINE, 0, TimeCurrent(), HiddenStopLoss);
      ObjectSet(LineName, OBJPROP_COLOR, Red);
      ObjectSet(LineName, OBJPROP_WIDTH, 1);
      ObjectSet(LineName, OBJPROP_STYLE, STYLE_DOT);
   }//if (HiddenStopLoss > 0)
   
   

}//End void DrawPendingPriceLines()


void DeletePendingPriceLines()
{

   
   //ObjectDelete(pendingpriceline);
   string LineName = TpPrefix + DoubleToStr(TicketNo, 0);
   ObjectDelete(LineName);
   LineName = SlPrefix + DoubleToStr(TicketNo, 0);
   ObjectDelete(LineName);
   
}//End void DeletePendingPriceLines()

void ReplaceMissingSlTpLines()
{

   if (OrderTakeProfit() > 0 || OrderStopLoss() > 0) DrawPendingPriceLines();

}//End void ReplaceMissingSlTpLines()

void DeleteOrphanTpSlLines()
{

   if (ObjectsTotal() == 0) return;
   
   for (int cc = ObjectsTotal() - 1; cc >= 0; cc--)
   {
      string name = ObjectName(cc);
      
      if ((StringSubstrOld(name, 0, 2) == TpPrefix || StringSubstrOld(name, 0, 2) == SlPrefix) && ObjectType(name) == OBJ_HLINE)
      {
         int tn = StrToDouble(StringSubstrOld(name, 2));
         if (tn > 0) 
         {
            if (!OrderSelect(tn, SELECT_BY_TICKET, MODE_TRADES) || OrderCloseTime() > 0)
            {
               ObjectDelete(name);
            }//if (!OrderSelect(tn, SELECT_BY_TICKET, MODE_TRADES) || OrderCloseTime() > 0)
            
         }//if (tn > 0) 
         
         
      }//if (StringSubstrOld(name, 0, 1) == TpPrefix)
      
   }//for (int cc = ObjectsTotal() - 1; cc >= 0; cc--)
   
   
}//End void DeleteOrphanTpSlLines()


//END Pending trade price lines module
////////////////////////////////////////////////////////////////////////////////////////

////////////////////////////////////////////////////////////////////////////////////////
//TRADE MANAGEMENT MODULE

void ReportError(string function, string message)
{
   //All purpose sl mod error reporter. Called when a sl mod fails
   
   int err=GetLastError();
   if (err == 1) return;//That bloody 'error but no error' report is a nuisance
   
      
   Alert(WindowExpertName(), " ", OrderTicket(), function, message, err,": ",ErrorDescription(err));
   Print(WindowExpertName(), " ", OrderTicket(), function, message, err,": ",ErrorDescription(err));
   
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
   if (!OrderSelect(ticket, SELECT_BY_TICKET, MODE_TRADES))
      return;
      
   double NewStop;
   bool result;
   bool modify=false;
   string LineName = SlPrefix + DoubleToStr(OrderTicket(), 0);
   double sl = ObjectGet(LineName, OBJPROP_PRICE1);
   double target = OrderOpenPrice();
   
   if (OrderType()==OP_BUY)
   {
      if (HiddenPips > 0) target-= (HiddenPips / factor);
      if (OrderStopLoss() >= target) return;
      if (Bid >= OrderOpenPrice () + (BreakEvenPips / factor))          
      {
         //Calculate the new stop
         NewStop = NormalizeDouble(OrderOpenPrice()+(BreakEvenProfit / factor), Digits);
         if (HiddenPips > 0)
         {
            if (ObjectFind(LineName) == -1)
            {
               ObjectCreate(LineName, OBJ_HLINE, 0, TimeCurrent(), 0);
               ObjectSet(LineName, OBJPROP_COLOR, Red);
               ObjectSet(LineName, OBJPROP_WIDTH, 1);
               ObjectSet(LineName, OBJPROP_STYLE, STYLE_DOT);
            }//if (ObjectFind(LineName == -1) )
         
            ObjectMove(LineName, 0, TimeCurrent(), NewStop);         
         }//if (HiddenPips > 0)
         modify = true;   
      }//if (Bid >= OrderOpenPrice () + (Point*BreakEvenPips) && 
   }//if (OrderType()==OP_BUY)               			         
    
   if (OrderType()==OP_SELL)
   {
     if (HiddenPips > 0) target+= (HiddenPips / factor);
      if (OrderStopLoss() <= target && OrderStopLoss() > 0) return;
     if (Ask <= OrderOpenPrice() - (BreakEvenPips / factor)) 
     {
         //Calculate the new stop
         NewStop = NormalizeDouble(OrderOpenPrice()-(BreakEvenProfit / factor), Digits);
         if (HiddenPips > 0)
         {
            if (ObjectFind(LineName) == -1)
            {
               ObjectCreate(LineName, OBJ_HLINE, 0, TimeCurrent(), 0);
               ObjectSet(LineName, OBJPROP_COLOR, Red);
               ObjectSet(LineName, OBJPROP_WIDTH, 1);
               ObjectSet(LineName, OBJPROP_STYLE, STYLE_DOT);
            }//if (ObjectFind(LineName == -1) )
         
            ObjectMove(LineName, 0, Time[0], NewStop);
         }//if (HiddenPips > 0)         
         modify = true;   
     }//if (Ask <= OrderOpenPrice() - (Point*BreakEvenPips) && (OrderStopLoss()>OrderOpenPrice()|| OrderStopLoss()==0))     
   }//if (OrderType()==OP_SELL)

   //Move 'hard' stop loss whether hidden or not. Don't want to risk losing a breakeven through disconnect.
   if (modify)
   {
      if (NewStop == OrderStopLoss() ) return;
      while (IsTradeContextBusy() ) Sleep(100);
      result = ModifyOrder(OrderTicket(), OrderOpenPrice(), NewStop, OrderTakeProfit(), OrderExpiration(), clrNONE, __FUNCTION__, slm);
      
      while (IsTradeContextBusy() ) Sleep(100);
      if(PartCloseEnabled && OrderComment()==TradeCommentCOT) bool success=PartCloseOrder(OrderTicket()); //MJB
   }//if (modify)
   
} // End BreakevenStopLoss sub

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
bool PartCloseOrder(int ticket)
{
   //Close PartClosePercent of the initial trade.
   //Return true if close succeeds, else false
   if (!OrderSelect(ticket, SELECT_BY_TICKET, MODE_TRADES)) return(true);//in case the trade closed
   
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

   //Security check
   if (!OrderSelect(ticket, SELECT_BY_TICKET, MODE_TRADES))
      return;

   //if (OrderProfit() < 0) return;//Nothing to do
   string LineName = SlPrefix + DoubleToStr(OrderTicket(), 0);
   double sl = ObjectGet(LineName, OBJPROP_PRICE1);
   if (CloseEnough(sl, 0) ) sl = OrderStopLoss();
   
   //if (CloseEnough(sl, 0) ) return;//No line, so nothing to do
   double NewStop;
   bool modify=false;
   bool result;
   
   
    if (OrderType()==OP_BUY)
    {
       if (sl < OrderOpenPrice() ) return;//Not at breakeven yet
       // Increment sl by sl + JumpingStopPips.
       // This will happen when market price >= (sl + JumpingStopPips)
       //if (Bid>= sl + ((JumpingStopPips*2) / factor) )
       if (CloseEnough(sl, 0) ) sl = MathMax(OrderStopLoss(), OrderOpenPrice());
       if (Bid >=  sl + ((JumpingStopPips * 2) / factor) )//George{
       {
          NewStop = NormalizeDouble(sl + (JumpingStopPips / factor), Digits);
          if (AddBEP) NewStop = NormalizeDouble(NewStop + (BreakEvenProfit / factor), Digits);
          if (HiddenPips > 0) ObjectMove(LineName, 0, Time[0], NewStop);
          if (NewStop - OrderStopLoss() >= Point) modify = true;//George again. What a guy
       }// if (Bid>= sl + (JumpingStopPips / factor) && sl>= OrderOpenPrice())     
    }//if (OrderType()==OP_BUY)
       
       if (OrderType()==OP_SELL)
       {
          if (sl > OrderOpenPrice() ) return;//Not at breakeven yet
          // Decrement sl by sl - JumpingStopPips.
          // This will happen when market price <= (sl - JumpingStopPips)
          //if (Bid<= sl - ((JumpingStopPips*2) / factor)) Original code
          if (CloseEnough(sl, 0) ) sl = MathMin(OrderStopLoss(), OrderOpenPrice());
          if (CloseEnough(sl, 0) ) sl = OrderOpenPrice();
          if (Bid <= sl - ((JumpingStopPips * 2) / factor) )//George
          {
             NewStop = NormalizeDouble(sl - (JumpingStopPips / factor), Digits);
             if (AddBEP) NewStop = NormalizeDouble(NewStop - (BreakEvenProfit / factor), Digits);
             if (HiddenPips > 0) ObjectMove(LineName, 0, Time[0], NewStop);
             if (OrderStopLoss() - NewStop >= Point || OrderStopLoss() == 0) modify = true;//George again. What a guy   
          }// close if (Bid>= sl + (JumpingStopPips / factor) && sl>= OrderOpenPrice())         
       }//if (OrderType()==OP_SELL)



   //Move 'hard' stop loss whether hidden or not. Don't want to risk losing a breakeven through disconnect.
   if (modify)
   {
      while (IsTradeContextBusy() ) Sleep(100);
      result = ModifyOrder(OrderTicket(), OrderOpenPrice(), NewStop, OrderTakeProfit(), OrderExpiration(), clrNONE, __FUNCTION__, slm);      
   }//if (modify)

} //End of JumpingStopLoss sub

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void TrailingStopLoss(int ticket)
{

   //Security check
   if (!OrderSelect(ticket, SELECT_BY_TICKET, MODE_TRADES))
      return;
   
   if (OrderProfit() < 0) return;//Nothing to do
   string LineName = SlPrefix + DoubleToStr(OrderTicket(), 0);
   double sl = ObjectGet(LineName, OBJPROP_PRICE1);
   //if (CloseEnough(sl, 0) ) return;//No line, so nothing to do
   if (CloseEnough(sl, 0) ) sl = OrderStopLoss();
   double NewStop;
   bool modify=false;
   bool result;
   
    if (OrderType()==OP_BUY)
       {
          if (sl < OrderOpenPrice() ) return;//Not at breakeven yet
          // Increment sl by sl + TrailingStopPips.
          // This will happen when market price >= (sl + JumpingStopPips)
          //if (Bid>= sl + (TrailingStopPips / factor) ) Original code
          if (CloseEnough(sl, 0) ) sl = MathMax(OrderStopLoss(), OrderOpenPrice());
          if (Bid >= sl + (TrailingStopPips / factor) )//George
          {
             NewStop = NormalizeDouble(sl + (TrailingStopPips / factor), Digits);
             if (HiddenPips > 0) ObjectMove(LineName, 0, Time[0], NewStop);
             if (NewStop - OrderStopLoss() >= Point) modify = true;//George again. What a guy
          }//if (Bid >= MathMax(sl,OrderOpenPrice()) + (TrailingStopPips / factor) )//George
       }//if (OrderType()==OP_BUY)
       
       if (OrderType()==OP_SELL)
       {
          if (sl > OrderOpenPrice() ) return;//Not at breakeven yet
          // Decrement sl by sl - TrailingStopPips.
          // This will happen when market price <= (sl - JumpingStopPips)
          //if (Bid<= sl - (TrailingStopPips / factor) ) Original code
          if (CloseEnough(sl, 0) ) sl = MathMin(OrderStopLoss(), OrderOpenPrice());
          if (CloseEnough(sl, 0) ) sl = OrderOpenPrice();
          if (Bid <= sl  - (TrailingStopPips / factor))//George
          {
             NewStop = NormalizeDouble(sl - (TrailingStopPips / factor), Digits);
             if (HiddenPips > 0) ObjectMove(LineName, 0, Time[0], NewStop);
             if (OrderStopLoss() - NewStop >= Point || OrderStopLoss() == 0) modify = true;//George again. What a guy   
          }//if (Bid <= MathMin(sl, OrderOpenPrice() ) - (TrailingStopPips / factor) )//George
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
   if (!OrderSelect(ticket, SELECT_BY_TICKET, MODE_TRADES))
      return;
   
   //Trails the stop at the hi/lo of the previous candle shifted by the user choice.
   //Only tries to do this once per bar, so an invalid stop error will only be generated once. I could code for
   //a too-close sl, but cannot be arsed. Coders, sort this out for yourselves.
   
   if (OldCstBars == iBars(NULL, CstTimeFrame)) return;
   OldCstBars = iBars(NULL, CstTimeFrame);

   if (OrderProfit() < 0) return;//Nothing to do
   string LineName = SlPrefix + DoubleToStr(OrderTicket(), 0);
   double sl = ObjectGet(LineName, OBJPROP_PRICE1);
   if (CloseEnough(sl, 0) ) sl = OrderStopLoss();
   double NewStop;
   bool modify=false;
   bool result;
   

   if (OrderType() == OP_BUY)
   {
      if (iLow(NULL, CstTimeFrame, CstTrailCandles) > sl)
      {
         NewStop = NormalizeDouble(iLow(NULL, CstTimeFrame, CstTrailCandles), Digits);
         //Check that the new stop is > the old. Exit the function if not.
         if (NewStop < OrderStopLoss() || CloseEnough(NewStop, OrderStopLoss()) ) return;
         //Check that the new stop locks in profit, if the user requires this.
         if (TrailMustLockInProfit && NewStop < OrderOpenPrice() ) return;
         
         if (HiddenPips > 0) 
         {
            ObjectMove(LineName, 0, Time[0], NewStop);
            NewStop = NormalizeDouble(NewStop - (HiddenPips / factor), Digits);
         }//if (HiddenPips > 0) 
         modify = true;   
      }//if (iLow(NULL, CstTimeFrame, CstTrailCandles) > sl)
   }//if (OrderType == OP_BUY)
   
   if (OrderType() == OP_SELL)
   {
      if (iHigh(NULL, CstTimeFrame, CstTrailCandles) < sl)
      {
         NewStop = NormalizeDouble(iHigh(NULL, CstTimeFrame, CstTrailCandles), Digits);
         
         //Check that the new stop is < the old. Exit the function if not.
         if (NewStop > OrderStopLoss() || CloseEnough(NewStop, OrderStopLoss()) ) return;
         //Check that the new stop locks in profit, if the user requires this.
         if (TrailMustLockInProfit && NewStop > OrderOpenPrice() ) return;
         
         if (HiddenPips > 0) 
         {
            ObjectMove(LineName, 0, Time[0], NewStop);
            NewStop = NormalizeDouble(NewStop + (HiddenPips / factor), Digits);
         }//if (HiddenPips > 0) 
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

double PFactor(string symbol)
{
   //This code supplied by Lifesys. Many thanks Paul - we all owe you. Gary was trying to make me see this, but I could not understand his explanation. Paul used Janet and John words
   
   for ( int i = ArraySize(pipFactor)-1; i >=0; i-- ) 
      if (StringFind(symbol,pipFactor[i],0) != -1) 
         return (pipFactors[i]);
   return(10000);

}//End double PFactor(string pair)


void GetSwap(string symbol)
{
   LongSwap = MarketInfo(symbol, MODE_SWAPLONG);
   ShortSwap = MarketInfo(symbol, MODE_SWAPSHORT);

}//End void GetSwap()

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

bool IsClosedTradeRogue()
{
   //~ Safety feature. Sometimes an unexpected concatenation of inputs choice and logic error can cause rapid opening-closing of trades. Detect a closed trade and check that is was not a rogue. Examine trades closed within the last 5 minutes.
   
   //~ If it is a rogue:
   //~ * Show a warning alert.
   //~ * Send an email alert.
   //~ * Suspend the robot
   
   if (OrdersHistoryTotal() == 0) return(false);
   
   datetime latestTime = TimeCurrent() - ( 5 * 60 );
  
   datetime duration = -1; //impossible value
  
   //We cannot guarantee that the most recent trade shown in our History tab is actually the most recent on the crim's server - CraptT4 again. pah has supplied this code to ensure that we are examining the latest trade. Many thanks, Paul.
   
   // look for trades that closed within the last 5 minutes
   // otherwise we will always find the last rogue trade
   // even when that happened some time ago and can be ignored
   
   for ( int i = OrdersHistoryTotal()-1; i >= 0; i-- )
   {
      if ( ! OrderSelect(i, SELECT_BY_POS, MODE_HISTORY) ) continue;
       
      if ( OrderMagicNumber() != MagicNumber || OrderSymbol() != Symbol() ) continue;
        
      if ( OrderCloseTime() >= latestTime )
      {
         latestTime = OrderCloseTime();
         duration    = OrderCloseTime() - OrderOpenTime();
      }//if ( OrderCloseTime() >= latestTime )
       
   }//for ( int i = OrdersHistoryTotal()-1; i >= 0; i-- )
   
  
   bool rogue = ( duration >= 0 ) && ( duration < ( MinMinutesBetweenTradeOpenClose * 60) );
  
   if (rogue)
   {
      RobotSuspended = true;
      Alert(Symbol(), " ", WindowExpertName() , " possible rogue trade.");
      SendMail("Possible rogue trade warning ", Symbol() + " " + WindowExpertName() + " possible rogue trade.");
      Comment(NL, Gap, "****************** ROBOT SUSPENDED. POSSIBLE ROGUE TRADING ACTIVITY. REMOVE THIS EA IMMEDIATELY ****************** ");
      return(true);//Too close, so disallow the trade
   
   }//if (rogue)
   
   //Got this far, so there is no rogue trade
   return(false);
   


}//bool IsClosedTradeRogue()

void DrawTrendLine(string name, datetime time1, double val1, datetime time2, double val2, color col, int width, int style, bool ray)
{
   //Plots a trendline with the given parameters
   
   ObjectDelete(name);
   
   ObjectCreate(name, OBJ_TREND, 0, time1, val1, time2, val2);
   ObjectSet(name, OBJPROP_COLOR, col);
   ObjectSet(name, OBJPROP_WIDTH, width);
   ObjectSet(name, OBJPROP_STYLE, style);
   ObjectSet(name, OBJPROP_RAY, ray);
   
}//End void DrawLine()

void DrawHorizontalLine(string name, double price, color col, int style, int width)
{
   
   ObjectDelete(name);
   
   ObjectCreate(name, OBJ_HLINE, 0, TimeCurrent(), price);
   ObjectSet(name, OBJPROP_COLOR, col);
   ObjectSet(name, OBJPROP_STYLE, style);
   ObjectSet(name, OBJPROP_WIDTH, width);
   

}//void DrawLine(string name, double price, color col)

void DrawVerticalLine(string name, datetime time, color col,int style,int width)
{
   //ObjectCreate(vline,OBJ_VLINE,0,iTime(NULL, TimeFrame, 0), 0);
   ObjectDelete(name);
   ObjectCreate(name,OBJ_VLINE,0,time,0);
   ObjectSet(name,OBJPROP_COLOR,col);
   ObjectSet(name,OBJPROP_STYLE,style);
   ObjectSet(name,OBJPROP_WIDTH,width);

}//void DrawVerticalLine()

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

string PeriodText(int per)
{

	switch (per)
	{
   	case PERIOD_M1:
   		return("M1");
   	case PERIOD_M5:
   		return("M5");
   	case PERIOD_M15:
   		return("M15");
   	case PERIOD_M30:
   		return("M30");
   	case PERIOD_H1:
   		return("H1");
   	case PERIOD_H4:
   		return("H4");
   	case PERIOD_D1:
   		return("D1");
   	case PERIOD_MN1:
   		return("MN1");
   	default:
   		return("");
	}

}//End string PeriodText(int per)


//+------------------------------------------------------------------+
//  Code to check that there are at least 100 bars of history in
//  the sym / per in the passed params
//+------------------------------------------------------------------+
bool HistoryOK(string sym,int per)
{

	double tempArray[][6];  //used for the call to ArrayCopyRates()

    //get the number of bars
	int bars = iBars(sym,per);
	//and report it in the log
	Print("Checking ",sym," for complete data.... number of ",PeriodText(per)," bars = ",bars);

	if (bars < 100)
	{   
	    //we didn't have enough, so set the comment and try to trigger the DL another way
		Comment("Symbol ",sym," -- Waiting for "+PeriodText(per)+" data.");
		ArrayCopyRates(tempArray,sym,per);
		int error=GetLastError();
		if (error != 0) Print(sym," - requesting data from the server...");

      //return false so the caller knows we don't have the data
		return(false);
	}//if (bars < 100)
	
	//if we got here, the data is fine, so clear the comment and return true
	Comment("");
	return(true);

}//End bool HistoryOK(string sym,int per)



void CheckTpSlAreCorrect(int type)
{
   //Looks at an open trade and checks to see that the exact tp/sl were sent with the trade.
   
   
   double stop = 0, take = 0, diff = 0;
   bool ModifyStop = false, ModifyTake = false;
   bool result;
   
   //Is the stop at BE?
   if (type == OP_BUY && OrderStopLoss() >= OrderOpenPrice() ) return;
   if (type == OP_SELL && OrderStopLoss() <= OrderOpenPrice() ) return;
   
   if (type == OP_BUY)
   {
      if (!CloseEnough(OrderStopLoss(), 0) )
      {
         diff = (OrderOpenPrice() - OrderStopLoss()) * factor;
         if (!CloseEnough(diff, StopLoss + (HiddenPips / factor))) 
         {
            ModifyStop = true;
            stop = CalculateStopLoss(OP_BUY, OrderOpenPrice());
         }//if (!CloseEnough(diff, StopLoss) )          
      }//if (!CloseEnough(OrderStopLoss(), 0) )      

      if (!CloseEnough(OrderTakeProfit(), 0) )
      {
         diff = (OrderTakeProfit() - OrderOpenPrice()) * factor;
         if (!CloseEnough(diff, TakeProfit -  (HiddenPips / factor))) 
         {
            ModifyTake = true;
            take = CalculateTakeProfit(OP_BUY, OrderOpenPrice());
         }//if (!CloseEnough(diff, TakeProfit) )          
      }//if (!CloseEnough(OrderStopLoss(), 0) )      
   }//if (type == OP_BUY)
   
   if (type == OP_SELL)
   {
      if (!CloseEnough(OrderStopLoss(), 0) )
      {
         diff = (OrderStopLoss() - OrderOpenPrice() ) * factor;
         if (!CloseEnough(diff, StopLoss -  (HiddenPips / factor))) 
         {
            ModifyStop = true;
            stop = CalculateStopLoss(OP_SELL, OrderOpenPrice());

         }//if (!CloseEnough(diff, StopLoss) )          
      }//if (!CloseEnough(OrderStopLoss(), 0) )      

      if (!CloseEnough(OrderTakeProfit(), 0) )
      {
         diff = (OrderOpenPrice() - OrderTakeProfit() ) * factor;
         if (!CloseEnough(diff, TakeProfit +  (HiddenPips / factor))) 
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



//+------------------------------------------------------------------+
//| NormalizeLots(string symbol, double lots)                        |
//+------------------------------------------------------------------+
//function added by fxdaytrader
//Lot size must be adjusted to be a multiple of lotstep, which may not be a power of ten on some brokers
//see also the original function by WHRoeder, http://forum.mql4.com/45425#564188, fxdaytrader
double NormalizeLots(string symbol, double lots) 
{
  if (MathAbs(lots)==0.0) return(0.0); //just in case ... otherwise it may happen that after rounding 0.0 the result is >0 and we have got a problem, fxdaytrader
  double ls = MarketInfo(symbol,MODE_LOTSTEP);
  lots = MathMin(MarketInfo(symbol,MODE_MAXLOT),MathMax(MarketInfo(symbol,MODE_MINLOT),lots)); //check if lots >= min. lots && <= max. lots, fxdaytrader
return(MathRound(lots/ls)*ls);
}

// for 6xx build compatibilità added by milanese
string StringSubstrOld(string x,int a,int b=-1) 
{
   if (a < 0) a= 0; // Stop odd behaviour
   if (b<=0) b = -1; // new MQL4 EOL flag
   return StringSubstr(x,a,b);
}//End string StringSubstrOld(string x,int a,int b=-1) 

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


void ShouldTradesBeClosed()
{
       
   if (OpenTrades == 0)
      return;//Nothing to do
 
 
   //Can younger winners be offset against the oldest loser?
   if (UseOffsetting)
   {
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
   }//if (UseOffsetting)
      
   
 
   //Calculate the size of lots to send
   double SendLots = Lot;
   if (Hedged)
      if (!CloseEnough(HedgeLotSize, 0) )
         SendLots = HedgeLotSize;
   
   double ClosurePrice = 0;//A semafor signal price
   bool CloseTrades = false;
   
   
   int tries = 0;
   
   //Insufficient margin for trading, so delete pending trades
   //if there are no market orders.
   if (MarginMessage != "")
      if (MarketTradesTotal == 0)
      {
         tries = 0;
         ForceTradeClosure = true;
         while(ForceTradeClosure)
         {
            ForceTradeClosure = false;
            if (SellStopOpen)
               CloseAllTrades(OP_SELLSTOP);
            if (SellLimitOpen)
               CloseAllTrades(OP_SELLLIMIT);
            if (BuyStopOpen)
               CloseAllTrades(OP_BUYSTOP);
            if (BuyLimitOpen)
               CloseAllTrades(OP_BUYLIMIT);  
            tries++;
            if (tries >= 100)
            {
               ForceTradeClosure = false;
            }//if (tries >= 100)
        }//while(ForceTradeClosure)
      }//if (MarketTradesTotal == 0)
      
   
   //Semaforsignals
   //We only want trades closing if the trades are based on a previous candle's signal
   if (LatestTradeTime < iTime(Symbol(), TradingTimeFrame, 0) || EarliestTradeTime < iTime(Symbol(), TradingTimeFrame, 0))
   {
      RefreshRates();
      
      //Opposite direction semafor
      //Close buys
      if (CloseTradesOnRelevantSemafor || CloseImmediatelySemaforAppears)//semafor
      {
            //SemStatus will only == highsemafor or highsemafornow if CloseImmediatelySemaforAppears is enabled
            if (SemStatus == highsemafor || SemStatus == highsemafornow)
            {
               
               //Calculate closure prices
               if (SemStatus == highsemafor)
               {
                  ClosurePrice = NormalizeDouble(iClose(Symbol(), TradingTimeFrame, 1) - (SemaforRetrace / factor), Digits);
                  if (Ask < ClosurePrice)
                     CloseTrades = true;
               }//if (SemStatus == highsemafor)
               
               if (SemStatus == highsemafornow)
               {
                  ClosurePrice = NormalizeDouble(iHigh(Symbol(), TradingTimeFrame, 0) - (SemaforRetrace / factor), Digits);
                  if (Ask < ClosurePrice)
                     CloseTrades = true;
               }//if (SemStatus == highsemafornow)
               //ClosurePrice-= (SemaforRetrace / factor);
               
               tries = 0;
               //Close buys
               if (BuyOpen && (!CloseOnlyInPositivePips || BuyPipsUpl > 0) && CloseTrades)
               {
                  ForceTradeClosure = true;
                  while (ForceTradeClosure)
                  {
                     CloseAllTrades(OP_BUY);
                     if (BuyStopOpen)
                        CloseAllTrades(OP_BUYSTOP);
                     if (BuyLimitOpen)
                        CloseAllTrades(OP_BUYLIMIT);
                     if (GridType == Hedged_Stop_Orders_Only && (DeleteAndReplaceLosersGrid || !SellOpen))
                        CloseAllTrades(OP_SELLSTOP);
                     if (ForceTradeClosure)
                        Sleep(1000);
                     tries++;
                     if (tries >= 100)
                     {
                        ForceTradeClosure = false;
                        break;
                     }//if (tries >= 100)
                  }//while (ForceTradeClosure)
               
                  //Replace the grids for the stop orders method
                  if (GridType == Hedged_Stop_Orders_Only)
                  {
                     if (ReplaceWinnersGrid)
                        if (SellOpen)//open sells means the cycle has not ended and we want new buy stop orders ready in case market resumes its upward move
                           SendBuyGrid(Symbol(), OP_BUYSTOP, NormalizeDouble(Ask + (DistanceBetweenTrades / factor), Digits), SendLots, TradeCommentCOT);
                     if(ReplaceWinnersWithLimitGrid)
                        if (SellOpen)//open sells means the cycle has not ended and we want new buy limit orders in order to catch the retrace
                        {
                           SendBuyGrid(Symbol(), OP_BUYLIMIT, NormalizeDouble(Ask - (DistanceBetweenTrades / factor), Digits), SendLots, TradeCommentCOT);
                           if (AddStopOrdersToLimitGrid)
                              SendSellGrid(Symbol(), OP_SELLSTOP, NormalizeDouble(Bid - ((DistanceBetweenTrades / factor) * (GridSize + 1)), Digits), SendLots, TradeCommentCOT);
                        }//if (SellOpen)//open sells means the cycle has not ended and we want new buy limit orders in order to catch the retrace
                     if (DeleteAndReplaceLosersGrid)
                        if (SellOpen)//open sells means the cycle has not ended and we want new sell stop orders much closer to the market
                           SendSellGrid(Symbol(), OP_SELLSTOP, NormalizeDouble(Bid - (DistanceBetweenTrades / factor), Digits), SendLots, TradeCommentCOT);
                  }//if (GridType == Hedged_Stop_Orders_Only)
                 
                  return;//Nothing more for this function to do
               }//if (BuyOpen)
            }//if (SemStatus == highsemafor || SemStatus == highsemafornow)
           
            //SemStatus will only == lowsemafor or lowsemafornow if CloseImmediatelySemaforAppears is enabled
            if (SemStatus == lowsemafor || SemStatus == lowsemafornow)
            {        
               //Calculate closure prices
               if (SemStatus == lowsemafor)
               {
                  ClosurePrice = NormalizeDouble(iClose(Symbol(), TradingTimeFrame, 1) + (SemaforRetrace / factor), Digits);
                  if (Bid > ClosurePrice)
                     CloseTrades = true;
               }//if (SemStatus == lowsemafor)
               
               if (SemStatus == lowsemafornow)
               {
                  ClosurePrice = NormalizeDouble(iLow(Symbol(), TradingTimeFrame, 0) + (SemaforRetrace / factor), Digits);
                  if (Bid > ClosurePrice)
                     CloseTrades = true;
               }//if (SemStatus == lowsemafornow)
               //ClosurePrice+= (SemaforRetrace / factor);
               
               
               tries = 0;
               //Close sells
               if (SellOpen && (!CloseOnlyInPositivePips || SellPipsUpl > 0) && CloseTrades)
               {
                  ForceTradeClosure = true;
                  while (ForceTradeClosure)
                  {
                     CloseAllTrades(OP_SELL);
                     if (SellStopOpen)
                        CloseAllTrades(OP_SELLSTOP);
                     if (SellLimitOpen)
                        CloseAllTrades(OP_SELLLIMIT);
                     if (GridType == Hedged_Stop_Orders_Only && (DeleteAndReplaceLosersGrid || !BuyOpen))
                        CloseAllTrades(OP_BUYSTOP);
                     if (ForceTradeClosure)
                        Sleep(1000);
                     tries++;
                     if (tries >= 100)
                     {
                        ForceTradeClosure = false;
                        break;
                     }//if (tries >= 100)
                  }//while (ForceTradeClosure)
                 
                  //Replace the sell grid for the stop orders method
                  if (GridType == Hedged_Stop_Orders_Only)
                  {
                      if (ReplaceWinnersGrid)
                        if (BuyOpen)//open buys means the cycle has not ended and we want new sell stop orders ready in case market resumes its downward move
                           SendSellGrid(Symbol(), OP_SELLSTOP, NormalizeDouble(Bid - (DistanceBetweenTrades / factor), Digits), SendLots, TradeCommentCOT);
                      if(ReplaceWinnersWithLimitGrid)
                        if (BuyOpen)//open buys means the cycle has not ended and we want new sell limit orders in order to catch the retrace
                        {
                           SendSellGrid(Symbol(), OP_SELLLIMIT, NormalizeDouble(Bid + (DistanceBetweenTrades / factor), Digits), SendLots, TradeCommentCOT);
                           if (AddStopOrdersToLimitGrid)
                              SendBuyGrid(Symbol(), OP_BUYSTOP, NormalizeDouble(Ask + ((DistanceBetweenTrades / factor) * (GridSize + 1)), Digits), SendLots, TradeCommentCOT);
                        }//if (BuyOpen)//open buys means the cycle has not ended and we want new sell limit orders in order to catch the retrace
                        
                      if (DeleteAndReplaceLosersGrid)
                        if (BuyOpen)//open buys means the cycle has not ended and we want new buy stop orders much closer to the market
                           SendBuyGrid(Symbol(), OP_BUYSTOP, NormalizeDouble(Ask + (DistanceBetweenTrades / factor), Digits), SendLots, TradeCommentCOT);
                  }//if (GridType == Hedged_Stop_Orders_Only)
   
                  return;//Nothing more for this function to do
                     
               }//if (SellOpen)              
            }//if (SemStatus == lowsemafor || SemStatus == lowsemafornow)        
       
      }//if (CloseTradesOnRelevantSemafor || CloseImmediatelySemaforAppears)//semafor
   }//if (LatestTradeTime < iTime(Symbol(), TradingTimeFrame, 0) )
  
     
   //OppositeSignals
   //We only want trades closing if the trades are based on a previous candle's signal
   if (LatestTradeTime < iTime(Symbol(), TradingTimeFrame, 0) || EarliestTradeTime < iTime(Symbol(), TradingTimeFrame, 0))
   {
      if(CloseOnOppositeSignal)
      {
         //Buy signal
         if (BuySignal)
         {
            tries = 0;
            //Close sells
            if (SellOpen && (!OnlyCloseProfitableOppositePositions || SellPipsUpl > 0))
            {
               ForceTradeClosure = true;
               while(ForceTradeClosure)
               {
                  CloseAllTrades(OP_SELL);
                  if (SellStopOpen)
                     CloseAllTrades(OP_SELLSTOP);
                  if (SellLimitOpen)
                     CloseAllTrades(OP_SELLLIMIT);
                  if(GridType == Hedged_Stop_Orders_Only && (DeleteAndReplaceOppositeSignalLosersGrid || !BuyOpen))
                     CloseAllTrades(OP_BUYSTOP);
                  if (ForceTradeClosure)
                     Sleep(1000);
                  tries++;
                  if (tries >= 100)
                  {
                     ForceTradeClosure = false;
                     break;
                  }//if (tries >= 100)
               }//while(ForceTradeClosure)
               
               //Replace the grids for the stop orders method
               if (GridType == Hedged_Stop_Orders_Only)
               {
                   if (ReplaceOppositeSignalWinnersGrid)
                     if (BuyOpen)//open buys means the cycle has not ended and we want new sell stop orders ready in case market resumes its downward move
                        SendSellGrid(Symbol(), OP_SELLSTOP, NormalizeDouble(Bid - (DistanceBetweenTrades / factor), Digits), SendLots, TradeCommentCOT);
                   if (DeleteAndReplaceOppositeSignalLosersGrid)
                     if (BuyOpen)//open buys means the cycle has not ended and we want new buy stop orders much closer to the market
                        SendBuyGrid(Symbol(), OP_BUYSTOP, NormalizeDouble(Ask + (DistanceBetweenTrades / factor), Digits), SendLots, TradeCommentCOT);
               }//if (GridType == Hedged_Stop_Orders_Only)
                 
               return;//Nothing more for this function to do
            }// if (SellOpen)
         }//if (BuySignal)
         
         //Sell signal
         if (SellSignal)
         {
            tries = 0;
            //Close buys
            if (BuyOpen && (!OnlyCloseProfitableOppositePositions || BuyPipsUpl > 0))
            {
               ForceTradeClosure = true;
               while(ForceTradeClosure)
               {
                  CloseAllTrades(OP_BUY);
                  if (BuyStopOpen)
                     CloseAllTrades(OP_BUYSTOP);
                  if (BuyLimitOpen)
                     CloseAllTrades(OP_BUYLIMIT);
                  if (GridType == Hedged_Stop_Orders_Only && (DeleteAndReplaceOppositeSignalLosersGrid || !SellOpen))
                     CloseAllTrades(OP_SELLSTOP);
                  if(ForceTradeClosure)
                     Sleep(1000);
                  tries++;
                  if (tries >= 100)
                  {
                     ForceTradeClosure = false;
                     break;
                  }//if (tries >= 100)
               }//while(ForceTradeClosure)
               
               //Replace the grids for the stop orders method
               if (GridType == Hedged_Stop_Orders_Only)
               {
                  if (ReplaceOppositeSignalWinnersGrid)
                     if (SellOpen)//open sells means the cycle has not ended and we want new buy stop orders ready in case market resumes its upward move
                        SendBuyGrid(Symbol(), OP_BUYSTOP, NormalizeDouble(Ask + (DistanceBetweenTrades / factor), Digits), SendLots, TradeCommentCOT);
                  if (DeleteAndReplaceOppositeSignalLosersGrid)
                     if (SellOpen)//open sells means the cycle has not ended and we want new sell stop orders much closer to the market
                           SendSellGrid(Symbol(), OP_SELLSTOP, NormalizeDouble(Bid - (DistanceBetweenTrades / factor), Digits), SendLots, TradeCommentCOT);
               }//if (GridType == Hedged_Stop_Orders_Only)
                 
               return;//Nothing more for this function to do
            }//if (BuyOpen)
         }//if (SellSignal)
            
      }//if(CloseOnOppositeSignal)    
           
   }//if (LatestTradeTime < iTime(Symbol(), TradingTimeFrame, 0) )
   
   
   //Yellow wavy range signal
   //We only want trades closing if the trades are based on a previous candle's signal
   if (LatestTradeTime < iTime(Symbol(), TradingTimeFrame, 0) || EarliestTradeTime < iTime(Symbol(), TradingTimeFrame, 0))
   {
      if (CloseOnYellowRangeWave)
      {
         if (WaveStatus == Waverange)
         {
            tries = 0;
            //Close buys
            if (BuyOpen && (!OnlyCloseProfitablePositions || BuyPipsUpl > 0))
            {
               ForceTradeClosure = true;
               while(ForceTradeClosure)
               {
                  CloseAllTrades(OP_BUY);
                  if (BuyStopOpen)
                     CloseAllTrades(OP_BUYSTOP);
                  if (BuyLimitOpen)
                     CloseAllTrades(OP_BUYLIMIT);
                  if(GridType == Hedged_Stop_Orders_Only && (DeleteAndReplaceWavyLosersGrid || !SellOpen))
                     CloseAllTrades(OP_SELLSTOP);
                  if (ForceTradeClosure)
                     Sleep(1000);  
                  tries++;
                  if (tries >= 100)
                  {
                     ForceTradeClosure = false;
                     break;
                  }//if (tries >= 100)
               }//while(ForceTradeClosure)
               
               //Replace the grids for the stop orders method
               if (GridType == Hedged_Stop_Orders_Only)
               {
                  if (ReplaceWavyWinnersGrid)
                     if (SellOpen)//open sells means the cycle has not ended and we want new buy stop orders ready in case market resumes its upward move
                        SendBuyGrid(Symbol(), OP_BUYSTOP, NormalizeDouble(Ask + (DistanceBetweenTrades / factor), Digits), SendLots, TradeCommentCOT);
                     if (DeleteAndReplaceWavyLosersGrid)
                        if (SellOpen)//open sells means the cycle has not ended and we want new sell stop orders much closer to the market
                           SendSellGrid(Symbol(), OP_SELLSTOP, NormalizeDouble(Bid - (DistanceBetweenTrades / factor), Digits), SendLots, TradeCommentCOT);
               }//if (GridType == Hedged_Stop_Orders_Only)
               
               return;//Nothing more for this function to do     
            }//if (BuyOpen)
     
            //Close sells
            if (SellOpen && (!OnlyCloseProfitablePositions || SellPipsUpl > 0))
            {
               ForceTradeClosure = true;
               while(ForceTradeClosure)
               {
                  ForceTradeClosure = false;
                  CloseAllTrades(OP_SELL);
                  if (SellStopOpen)
                     CloseAllTrades(OP_SELLSTOP);
                  if (SellLimitOpen)
                     CloseAllTrades(OP_SELLLIMIT);
                  if (GridType == Hedged_Stop_Orders_Only && (DeleteAndReplaceWavyLosersGrid || !BuyOpen))
                     CloseAllTrades(OP_BUYSTOP);  
                  tries++;
                  if (tries >= 100)
                  {
                     ForceTradeClosure = false;
                     break;
                  }//if (tries >= 100)
               }//while(ForceTradeClosure)
            
               //Replace the grids for the stop orders method
               if (GridType == Hedged_Stop_Orders_Only)
               {
                  if (ReplaceWavyWinnersGrid)
                     if (BuyOpen)//open buys means the cycle has not ended and we want new sell stop orders ready in case market resumes its downward move
                        SendSellGrid(Symbol(), OP_SELLSTOP, NormalizeDouble(Bid - (DistanceBetweenTrades / factor), Digits), SendLots, TradeCommentCOT);
                     if (DeleteAndReplaceWavyLosersGrid)
                        if (BuyOpen)//open buys means the cycle has not ended and we want new buy stop orders much closer to the market
                           SendBuyGrid(Symbol(), OP_BUYSTOP, NormalizeDouble(Ask + (DistanceBetweenTrades / factor), Digits), SendLots, TradeCommentCOT);
               }//if (GridType == Hedged_Stop_Orders_Only)
   
               return;//Nothing more for this function to do
                     
            }//if (SellOpen)
         
         }// if (WaveStatus == Waverange)
         
      }//if (CloseOnYellowRangeWave)
   } //if (LatestTradeTime < iTime(Symbol(), TradingTimeFrame, 0) )   
   
      
   //Hedged position. Has it hit tp?
   if (Hedged)
   {
      bool ClosePosition = false;
     
      //Have we hit pips upl
      if (HedgeProfitPips > 0)
         if (PipsUpl >= HedgeProfitPips)
            if (!OnlyCloseInCashProfit || CashUpl > 0)
               ClosePosition = true;
           
      //Have we hit cash upl
      if (!ClosePosition)  
         if (HedgeProfitCash > 0)
            if (CashUpl >= HedgeProfitCash)
               ClosePosition = true;
               
      if (ClosePosition)
      {
         tries = 0;
         ForceTradeClosure = true;
         while(ForceTradeClosure)
         {
            ForceTradeClosure = false;
            if (BuyOpen)
               CloseAllTrades(OP_BUY);
            if (SellOpen)
               CloseAllTrades(OP_SELL);  
            if (SellStopOpen)
               CloseAllTrades(OP_SELLSTOP);
            if (SellLimitOpen)
               CloseAllTrades(OP_SELLLIMIT);
            if (BuyStopOpen)
               CloseAllTrades(OP_BUYSTOP);
            if (BuyLimitOpen)
               CloseAllTrades(OP_BUYLIMIT);  
               
               tries++;
               if (tries >= 100)
               {
                  ForceTradeClosure = false;
                  break;
               }//if (tries >= 100)
         }//while(ForceTradeClosure)
         
           
      }//if (ClosePosition)
         
   }//if (Hedged)
     
     
   //No trade signal. Delete existing pendings if none of them have filled.
   if (LatestTradeTime >= iTime(Symbol(), TradingTimeFrame, 0) )
      if (HgiSignalStatus == hginosignal)
         if (!BuyOpen)
            if (!SellOpen)
            {
               tries = 0;
               ForceTradeClosure = true;
               while(ForceTradeClosure)
               {
                  ForceTradeClosure = false;
                  if (SellStopOpen)
                     CloseAllTrades(OP_SELLSTOP);
                  if (SellLimitOpen)
                     CloseAllTrades(OP_SELLLIMIT);
                  if (BuyStopOpen)
                     CloseAllTrades(OP_BUYSTOP);
                  if (BuyLimitOpen)
                     CloseAllTrades(OP_BUYLIMIT);  
                  tries++;
                  if (tries >= 100)
                  {
                     ForceTradeClosure = false;
                     break;
                  }//if (tries >= 100)
              }//while(ForceTradeClosure)
            }//if (!SellOpen)
           
   //All market trades have hit tp
   if (PendingTradesTotal < GridSize)
   //if (PendingTradesTotal < (GridSize * 2) )//There should be up to GridSize * 2
      if (MarketTradesTotal == 0)//And all the market trades have hit tp or sl
      {
         ForceTradeClosure = true;
         while(ForceTradeClosure)
         {
            tries = 0;
            ForceTradeClosure = false;
            if (SellStopOpen)
               CloseAllTrades(OP_SELLSTOP);
            if (SellLimitOpen)
               CloseAllTrades(OP_SELLLIMIT);
            if (BuyStopOpen)
               CloseAllTrades(OP_BUYSTOP);
            if (BuyLimitOpen)
               CloseAllTrades(OP_BUYLIMIT);  
                  tries++;
                  if (tries >= 100)
                  {
                     ForceTradeClosure = false;
                     break;
                  }//if (tries >= 100)
        }//while(ForceTradeClosure)
      }//if (MarketTradesTotal == 0)//And all the market trades have hit tp or sl
   
}//End void ShouldTradesBeClosed()

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

bool SundayMondayFridayStuff()
{

   //Friday/Saturday stop trading hour
   int d = TimeDayOfWeek(TimeLocal());
   int h = TimeHour(TimeLocal());
   if (d == 5)
      if (h >= FridayStopTradingHour)
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

   //Monday candle
   if (d == 1)
      if (!TradeMondayCandle)
         return(false);

   //Tuesday candle
   if (d == 2)
      if (!TradeTuesdayCandle)
         return(false);

   //Wednesday candle
   if (d == 3)
      if (!TradeWednesdayCandle)
         return(false);

   //Thursday candle
   if (d == 4)
      if (!TradeThursdayCandle)
         return(false);
        
   //Friday candle
   if (d == 5)
      if (!TradeFridayCandle)
         return(false);
        
   //Saturday candle
   if (d == 6)
      if (!TradeSaturdayCandle)
         return(false);


         
   //Got this far, so we are in a trading period
   return(true);      
   
}//End bool  SundayMondayFridayStuff()

void DetectAndDeleteExcessPendings()
{

   if (OrdersTotal() == 0)
      return;
   //Deal with the situation where the receipt return delay safety feature
   //broke down and excessive pending trades were placed.
   
   if (PendingTradesTotal <= (GridSize * 4))   
      return;//Not gone bonkers, even if there are a few too many trades.

   bool bBuyStop = false;//Buy stop
   bool bBuyLimit = false;//Buy limit
   bool bSellStop = false;//Sell stop
   bool bSellLimit = false;//Sell limit
   
   //There can be a variety of stop/limit combos, so we need to store
   //the lowest buy stop and sell limit prices, along with the
   //highest sell stop and buy limit prices.
   double BuyStopPrice = 0;//Buy stop price
   double SellStopPrice = 0;
   double BuyLimitPrice = 0;
   double SellLimitPrice = 0;
   
   //Build a picture of the stop/limit orders in place so
   //the deleted grids can be replaced.
   for (int cc = OrdersTotal() - 1; cc >= 0; cc--)
   {
      if (!OrderSelect(cc, SELECT_BY_POS) ) continue;
      if (OrderSymbol() != Symbol() ) continue;
      if (OrderMagicNumber() != MagicNumber) continue;
      if (OrderType() < 2) continue;
      
      if (OrderType() == OP_BUYLIMIT)
         bBuyLimit = true;
      if (OrderType() == OP_BUYSTOP)
         bBuyStop = true;
      if (OrderType() == OP_SELLLIMIT)
         bSellLimit = true;
      if (OrderType() == OP_SELLSTOP)
         bSellStop = true;
         
      if (bBuyLimit)
         if (bBuyStop)
            if (bSellLimit)
               if (bSellStop)
                  break;
   }//for (int cc = OrdersTotal() - 1; cc >= 0; cc--)

   //Store the relevant stop order prices. CountOpenTrades will lose them
   //when we rebuild the position snapshot a few lines down.
   //Lowest buy stop
   if (bBuyStop)
      BuyStopPrice = LowestBuyStopPrice;
   //Lowest sell limit
   if (bSellLimit)
      SellLimitPrice = LowestSellLimitPrice;
   //Highest sell stop
   if (bSellStop)
      SellStopPrice = HighestSellStopPrice;
   //Highest buy limit price
   if (bBuyLimit)
      BuyLimitPrice = HighestBuyLimitPrice;   
      
   //Delete the stop orders
   ForceTradeClosure = true;
   while (ForceTradeClosure)
   {
      if (BuyStopOpen)
         CloseAllTrades(OP_BUYSTOP);
      if (BuyLimitOpen)
         CloseAllTrades(OP_BUYLIMIT);
      if (SellStopOpen)
         CloseAllTrades(OP_SELLSTOP);
      if (SellLimitOpen)
         CloseAllTrades(OP_SELLLIMIT);
         
      //Rebuild the position snapshot
      ForceTradeClosure = true;
      CountOpenTrades();
      
      if (!BuyStopOpen)
         if (!SellStopOpen)
            if (!BuyLimitOpen)
               if (!SellLimitOpen)
                  ForceTradeClosure = false;
                  
   }//while (ForceTradeClosure)
   
   //We have reached this point, so replace the grids.
   //Calculate the size of lots to send
   double SendLots = Lot;
   if (Hedged)
      if (!CloseEnough(HedgeLotSize, 0) )
         SendLots = HedgeLotSize;


 
   double price = 0;
   
   //There can be a variety of stop and limit orders.
   
   //Buy stop and sell limit
   if (bBuyStop && bSellLimit)
   {
      //Buy stops were first and the sell limits further up
      if (BuyStopPrice < SellLimitPrice)
      {
         price = NormalizeDouble(Ask + (DistanceBetweenTrades / factor), Digits);
         SendBuyGrid(Symbol(), OP_BUYSTOP, price, SendLots, TradeCommentCOT);
         //Set up a sell limit price
         price = NormalizeDouble(price + ((DistanceBetweenTrades / factor) * (GridSize + 1) ), Digits);
         SendSellGrid(Symbol(), OP_SELLLIMIT, price, SendLots, TradeCommentCOT);
      }//if (BuyStopPrice < SellLimitPrice)
      
      //Sell limits first, then buy stops further up
      if (SellLimitPrice < BuyStopPrice)
      {
         price = NormalizeDouble(Bid + (DistanceBetweenTrades / factor), Digits);
         SendSellGrid(Symbol(), OP_SELLLIMIT, price, SendLots, TradeCommentCOT);
         price = NormalizeDouble(price + ((DistanceBetweenTrades / factor) * (GridSize + 1) ), Digits);
         SendBuyGrid(Symbol(), OP_BUYSTOP, price, SendLots, TradeCommentCOT);
      }//if (SellLimitPrice < BuyStopPrice)
      CountOpenTrades();
      return;
   }//if (bBuyStop && bSellLimit)
   
   
   //Buy stop and sell stop
   if (bBuyStop && bSellStop)
   {
      price = NormalizeDouble(Ask + (DistanceBetweenTrades / factor), Digits);
      SendBuyGrid(Symbol(), OP_BUYSTOP, price, SendLots, TradeCommentCOT);
      price = NormalizeDouble(Bid - (DistanceBetweenTrades / factor), Digits);
      SendSellGrid(Symbol(), OP_SELLSTOP, price, SendLots, TradeCommentCOT);
      CountOpenTrades();
      return;
   }//if (bBuyStop && bSellStop)
   
   
   //Sell stop and buy limit
   if (bSellStop && bBuyLimit)
   {
      //Sell stops highest, then buy stops further down
      if (SellStopPrice > BuyLimitPrice)
      {
         price = NormalizeDouble(Bid - (DistanceBetweenTrades / factor), Digits);
         SendSellGrid(Symbol(), OP_SELLSTOP, price, SendLots, TradeCommentCOT);
         price = NormalizeDouble(price - ((DistanceBetweenTrades / factor) * (GridSize + 1) ), Digits);
         SendBuyGrid(Symbol(), OP_BUYLIMIT, price, SendLots, TradeCommentCOT);
      }//if (SellStopPrice > BuyLimitPrice)
      
      //Buy limit highest then sell stop further down
      if (BuyLimitPrice > SellStopPrice)
      {
         price = NormalizeDouble(Bid - (DistanceBetweenTrades / factor), Digits);
         SendBuyGrid(Symbol(), OP_BUYLIMIT, price, SendLots, TradeCommentCOT);
         price = NormalizeDouble(price - ((DistanceBetweenTrades / factor) * (GridSize + 1) ), Digits);
         SendSellGrid(Symbol(), OP_SELLSTOP, price, SendLots, TradeCommentCOT);
      }//if (BuyLimitPrice > SellStopPrice)
      CountOpenTrades();
      return;
   }//if (bSellStop && bBuyLimit)
   
   //Buy stop only
   if (bBuyStop)      
   {
      price = NormalizeDouble(Ask + (DistanceBetweenTrades / factor), Digits);
      SendBuyGrid(Symbol(), OP_BUYSTOP, price, SendLots, TradeCommentCOT);
      CountOpenTrades();
      return;
   }//if (!bBuyStop)
   
   
   //Sell stop only
   if (bSellStop)
   {
      price = NormalizeDouble(Bid - (DistanceBetweenTrades / factor), Digits);
      SendSellGrid(Symbol(), OP_SELLSTOP, price, SendLots, TradeCommentCOT);
      CountOpenTrades();
      return;
   }//if (bSellStop)
   
   
  

}//End void DetectAndDeleteExcessPendings()

///////////////////////////////////////////////////////////////////////////////////////////////////////////
//BUTTONS MODULE

void DrawButtons()
{


   int x = Button_X;
   int y = Button_Y;
   bool result = true;

   //Close all
   result = ButtonCreate(0,CloseAllName,0,x,y,ButtonWidth,ButtonHeight,ButtonCorner,"Close all",ButtonFont,ButtonFontSize,
      ButtonColor,ButtonBackColor,ButtonBorderColor,ButtonState,ButtonBack,ButtonSelection,ButtonHidden,ButtonZOrder);
   
   //Close market trades
   x+= (ButtonWidth + 10);
   result = ButtonCreate(0,CloseMarketOrdersName,0,x,y,ButtonWidth,ButtonHeight,ButtonCorner,"Close market",ButtonFont,ButtonFontSize,
      ButtonColor,ButtonBackColor,ButtonBorderColor,ButtonState,ButtonBack,ButtonSelection,ButtonHidden,ButtonZOrder);
   
   //Close market buy trades
   x+= (ButtonWidth + 10);
   result = ButtonCreate(0,CloseMarketBuysName,0,x,y,ButtonWidth,ButtonHeight,ButtonCorner,"Close buys",ButtonFont,ButtonFontSize,
      ButtonColor,ButtonBackColor,ButtonBorderColor,ButtonState,ButtonBack,ButtonSelection,ButtonHidden,ButtonZOrder);
   
   //Close market sell trades
   x+= (ButtonWidth + 10);
   result = ButtonCreate(0,CloseMarketSellssName,0,x,y,ButtonWidth,ButtonHeight,ButtonCorner,"Close sells",ButtonFont,ButtonFontSize,
      ButtonColor,ButtonBackColor,ButtonBorderColor,ButtonState,ButtonBack,ButtonSelection,ButtonHidden,ButtonZOrder);
   
   
   x = Button_X;
   y+= (ButtonHeight + 10);
   
   result = ButtonCreate(0,DeleteAllPendingsName,0,x,y,ButtonWidth,ButtonHeight,ButtonCorner,"Delete pendings",ButtonFont,ButtonFontSize,
      ButtonColor,ButtonBackColor,ButtonBorderColor,ButtonState,ButtonBack,ButtonSelection,ButtonHidden,ButtonZOrder);
  
   
   //Delete buy stop orders
   x+= (ButtonWidth + 10);
   result = ButtonCreate(0,DeleteBuyStops,0,x,y,ButtonWidth,ButtonHeight,ButtonCorner,"Delete Buy Stops",ButtonFont,ButtonFontSize,
      ButtonColor,ButtonBackColor,ButtonBorderColor,ButtonState,ButtonBack,ButtonSelection,ButtonHidden,ButtonZOrder);
   
   //Delete sell stop orders
   x+= (ButtonWidth + 10);
   result = ButtonCreate(0,DeleteSellStops,0,x,y,ButtonWidth,ButtonHeight,ButtonCorner,"Delete Sell Stops",ButtonFont,ButtonFontSize,
      ButtonColor,ButtonBackColor,ButtonBorderColor,ButtonState,ButtonBack,ButtonSelection,ButtonHidden,ButtonZOrder);

   x = Button_X;
   y+= (ButtonHeight + 10);
   
   //Delete buy limit orders
   x+= (ButtonWidth + 10);
   result = ButtonCreate(0,DeleteBuyLimits,0,x,y,ButtonWidth,ButtonHeight,ButtonCorner,"Delete Buy Limits",ButtonFont,ButtonFontSize,
      ButtonColor,ButtonBackColor,ButtonBorderColor,ButtonState,ButtonBack,ButtonSelection,ButtonHidden,ButtonZOrder);
   
   //Delete sell limit orders
   x+= (ButtonWidth + 10);
   result = ButtonCreate(0,DeleteSellLimits,0,x,y,ButtonWidth,ButtonHeight,ButtonCorner,"Delete Sell Limits",ButtonFont,ButtonFontSize,
      ButtonColor,ButtonBackColor,ButtonBorderColor,ButtonState,ButtonBack,ButtonSelection,ButtonHidden,ButtonZOrder);
   

   x = Button_X;
   y+= (ButtonHeight + 10);
   
   //Send a full grid
   result = ButtonCreate(0,SendFullGrid,0,x,y,ButtonWidth,ButtonHeight,ButtonCorner,"Send Full Grid",ButtonFont,ButtonFontSize,
      ButtonColor,ButtonBackColor,ButtonBorderColor,ButtonState,ButtonBack,ButtonSelection,ButtonHidden,ButtonZOrder);


   //Send a buy stop grid
   x+= (ButtonWidth + 10);
   result = ButtonCreate(0,SendBuyStops,0,x,y,ButtonWidth,ButtonHeight,ButtonCorner,"Send Buy Stops",ButtonFont,ButtonFontSize,
      ButtonColor,ButtonBackColor,ButtonBorderColor,ButtonState,ButtonBack,ButtonSelection,ButtonHidden,ButtonZOrder);

   
   //Send a sell stop grid
   x+= (ButtonWidth + 10);
   result = ButtonCreate(0,SendSellStops,0,x,y,ButtonWidth,ButtonHeight,ButtonCorner,"Send Sell Stops",ButtonFont,ButtonFontSize,
      ButtonColor,ButtonBackColor,ButtonBorderColor,ButtonState,ButtonBack,ButtonSelection,ButtonHidden,ButtonZOrder);


 
   x = Button_X + (ButtonWidth + 10);
   y+= (ButtonHeight + 10);

    //Send a buy limit grid
   result = ButtonCreate(0,SendBuyLimits,0,x,y,ButtonWidth,ButtonHeight,ButtonCorner,"Send Buy Limits",ButtonFont,ButtonFontSize,
      ButtonColor,ButtonBackColor,ButtonBorderColor,ButtonState,ButtonBack,ButtonSelection,ButtonHidden,ButtonZOrder);


  //Send a sell limit grid
   x+= (ButtonWidth + 10);
   result = ButtonCreate(0,SendSellLimits,0,x,y,ButtonWidth,ButtonHeight,ButtonCorner,"Send Sell Limits",ButtonFont,ButtonFontSize,
      ButtonColor,ButtonBackColor,ButtonBorderColor,ButtonState,ButtonBack,ButtonSelection,ButtonHidden,ButtonZOrder);

   
   x = Button_X;
   y+= (ButtonHeight + 10);
   
   //Pause trading
   result = ButtonCreate(0,PauseTrading,0,x,y,ButtonWidth,ButtonHeight,ButtonCorner,"Pause trading",ButtonFont,ButtonFontSize,
      ButtonColor,ButtonBackColor,ButtonBorderColor,ButtonState,ButtonBack,ButtonSelection,ButtonHidden,ButtonZOrder);

   //Resume trading
   x+= (ButtonWidth + 10);
   result = ButtonCreate(0,ResumeTrading,0,x,y,ButtonWidth,ButtonHeight,ButtonCorner,"Resume trading",ButtonFont,ButtonFontSize,
      ButtonColor,ButtonBackColor,ButtonBorderColor,ButtonState,ButtonBack,ButtonSelection,ButtonHidden,ButtonZOrder);

//--- redraw the chart
   ChartRedraw();

}//End void DrawButtons()


//+------------------------------------------------------------------+
//| Create the button                                                |
//+------------------------------------------------------------------+
bool ButtonCreate(const long              chart_ID=0,               // chart's ID
                  const string            name="Button",            // button name
                  const int               sub_window=0,             // subwindow index
                  const int               x=0,                      // X coordinate
                  const int               y=0,                      // Y coordinate
                  const int               width=50,                 // button width
                  const int               height=18,                // button height
                  const ENUM_BASE_CORNER  corner=CORNER_LEFT_UPPER, // chart corner for anchoring
                  const string            text="Button",            // text
                  const string            font="Arial",             // font
                  const int               font_size=10,             // font size
                  const color             clr=clrBlack,             // text color
                  const color             back_clr=C'236,233,216',  // background color
                  const color             border_clr=clrNONE,       // border color
                  const bool              state=false,              // pressed/released
                  const bool              back=false,               // in the background
                  const bool              selection=false,          // highlight to move
                  const bool              hidden=true,              // hidden in the object list
                  const long              z_order=0)                // priority for mouse click
  {
//--- reset the error value
   ResetLastError();
//--- create the button
   if(!ObjectCreate(chart_ID,name,OBJ_BUTTON,sub_window,0,0))
     {
      Print(__FUNCTION__,
            ": failed to create the button! Error code = ",GetLastError());
      return(false);
     }
//--- set button coordinates
   ObjectSetInteger(chart_ID,name,OBJPROP_XDISTANCE,x);
   ObjectSetInteger(chart_ID,name,OBJPROP_YDISTANCE,y);
//--- set button size
   ObjectSetInteger(chart_ID,name,OBJPROP_XSIZE,width);
   ObjectSetInteger(chart_ID,name,OBJPROP_YSIZE,height);
//--- set the chart's corner, relative to which point coordinates are defined
   ObjectSetInteger(chart_ID,name,OBJPROP_CORNER,corner);
//--- set the text
   ObjectSetString(chart_ID,name,OBJPROP_TEXT,text);
//--- set text font
   ObjectSetString(chart_ID,name,OBJPROP_FONT,font);
//--- set font size
   ObjectSetInteger(chart_ID,name,OBJPROP_FONTSIZE,font_size);
//--- set text color
   ObjectSetInteger(chart_ID,name,OBJPROP_COLOR,clr);
//--- set background color
   ObjectSetInteger(chart_ID,name,OBJPROP_BGCOLOR,back_clr);
//--- set border color
   ObjectSetInteger(chart_ID,name,OBJPROP_BORDER_COLOR,border_clr);
//--- display in the foreground (false) or background (true)
   ObjectSetInteger(chart_ID,name,OBJPROP_BACK,back);
//--- set button state
   ObjectSetInteger(chart_ID,name,OBJPROP_STATE,state);
//--- enable (true) or disable (false) the mode of moving the button by mouse
   ObjectSetInteger(chart_ID,name,OBJPROP_SELECTABLE,selection);
   ObjectSetInteger(chart_ID,name,OBJPROP_SELECTED,selection);
//--- hide (true) or display (false) graphical object name in the object list
   ObjectSetInteger(chart_ID,name,OBJPROP_HIDDEN,hidden);
//--- set the priority for receiving the event of a mouse click in the chart
   ObjectSetInteger(chart_ID,name,OBJPROP_ZORDER,z_order);
//--- successful execution
   return(true);
}
  
void OnChartEvent(const int id,
                  const long &lparam,
                  const double &dparam,
                  const string &sparam)
{

   double price=0;

//---
   if(id==CHARTEVENT_OBJECT_CLICK)
     {

      string txt="";
      int ret=0;
      int tries=0;

      //Close all market and delete all pendings
      if(sparam==CloseAllName)
        {
         txt="Click on Yes to Close All trades";
         ret=MessageBox(txt,"CONFIRM CLOSE ALL",MB_YESNO); // Message box
         if(ret==IDYES)
           {
            tries=0;
            ForceTradeClosure=true;
            while(ForceTradeClosure)
              {
               ForceTradeClosure=false;

               //Close buys first if they are the profitable side of the hedge
               if(BuyCashUpl>0)
                 {
                  if(BuyOpen)
                     CloseAllTrades(OP_BUY);

                  if(SellOpen)
                     CloseAllTrades(OP_SELL);

                 }//if (BuyCashUpl > 0)

               //Close sells first if they are the profitable side of the hedge
               if(SellCashUpl>0)
                 {
                  if(SellOpen)
                     CloseAllTrades(OP_SELL);

                  if(BuyOpen)
                     CloseAllTrades(OP_BUY);

                 }//if (SellCashUpl > 0)

               //Mop up any trades that failed to close.
               CountOpenTrades();//Rebuild the position picture

               if(BuyOpen)
                  CloseAllTrades(OP_BUY);

               if(SellOpen)
                  CloseAllTrades(OP_SELL);

               //Delete the pendings
               if(SellStopOpen)
                  CloseAllTrades(OP_SELLSTOP);
               if(SellLimitOpen)
                  CloseAllTrades(OP_SELLLIMIT);
               if(BuyStopOpen)
                  CloseAllTrades(OP_BUYSTOP);
               if(BuyLimitOpen)
                  CloseAllTrades(OP_BUYLIMIT);

               tries++;
               if(tries>=100)
                 {
                  break;
                 }//if (tries >= 100)
               CountOpenTrades();//Recalculate the position
              }//while(ForceTradeClosure)

           }//if(ret ==IDYES)
         ObjectSetInteger(0,CloseAllName,OBJPROP_STATE,false);
         return;//Nothing else to do

        }//if(sparam==CloseAllName)

      //Close all market trades
      if(sparam==CloseMarketOrdersName)
        {
         txt="Click on Yes to Close All market trades";
         ret=MessageBox(txt,"CONFIRM CLOSE ALL MARKET",MB_YESNO); // Message box
         if(ret==IDYES)
           {
            tries=0;
            ForceTradeClosure=true;
            while(ForceTradeClosure)
              {
               ForceTradeClosure=false;

               //Close buys first if they are the profitable side of the hedge
               if(BuyCashUpl>0)
                 {
                  if(BuyOpen)
                     CloseAllTrades(OP_BUY);

                  if(SellOpen)
                     CloseAllTrades(OP_SELL);

                 }//if (BuyCashUpl > 0)

               //Close sells first if they are the profitable side of the hedge
               if(SellCashUpl>0)
                 {
                  if(SellOpen)
                     CloseAllTrades(OP_SELL);

                  if(BuyOpen)
                     CloseAllTrades(OP_BUY);

                 }//if (SellCashUpl > 0)

               //Neither side of the hedge in profit
               if(BuyCashUpl<=0)
                  if(SellCashUpl<=0)
                    {
                     CloseAllTrades(OP_BUY);
                     CloseAllTrades(OP_SELL);
                    }//if (SellCashUpl < 0)

               //Mop up any trades that failed to close.
               CountOpenTrades();//Rebuild the position picture

               tries++;
               if(tries>=100)
                 {
                  break;
                 }//if (tries >= 100)
               CountOpenTrades();//Recalculate the position
              }//while(ForceTradeClosure)

           }//if(ret ==IDYES)
         ObjectSetInteger(0,CloseMarketOrdersName,OBJPROP_STATE,false);
         return;//Nothing else to do

        }//if(sparam==CloseMarketOrdersName)

      //Close all market buys
      if(sparam==CloseMarketBuysName)
        {
         txt="Click on Yes to Close All market buy trades";
         ret=MessageBox(txt,"CONFIRM CLOSE ALL MARKET BUY TRADES",MB_YESNO); // Message box
         if(ret==IDYES)
           {
            tries=0;
            ForceTradeClosure=true;
            while(ForceTradeClosure)
              {
               ForceTradeClosure=false;

               CloseAllTrades(OP_BUY);

               //Mop up any trades that failed to close.
               CountOpenTrades();//Rebuild the position picture

               tries++;
               if(tries>=100)
                 {
                  break;
                 }//if (tries >= 100)
               CountOpenTrades();//Recalculate the position
              }//while(ForceTradeClosure)

           }//if(ret ==IDYES)
         ObjectSetInteger(0,CloseMarketBuysName,OBJPROP_STATE,false);
         return;//Nothing else to do

        }//if(sparam==CloseMarketBuysName)

      //Close all market buys
      if(sparam==CloseMarketSellssName)
        {
         txt="Click on Yes to Close All market sell trades";
         ret=MessageBox(txt,"CONFIRM CLOSE ALL MARKET SELL TRADES",MB_YESNO); // Message box
         if(ret==IDYES)
           {
            tries=0;
            ForceTradeClosure=true;
            while(ForceTradeClosure)
              {
               ForceTradeClosure=false;

               CloseAllTrades(OP_SELL);

               //Mop up any trades that failed to close.
               CountOpenTrades();//Rebuild the position picture

               tries++;
               if(tries>=100)
                 {
                  break;
                 }//if (tries >= 100)
               CountOpenTrades();//Recalculate the position
              }//while(ForceTradeClosure)

           }//if(ret ==IDYES)
         ObjectSetInteger(0,CloseMarketSellssName,OBJPROP_STATE,false);
         return;//Nothing else to do

        }//if(sparam==CloseMarketSellssName)

      //Delete all pendings
      if(sparam==DeleteAllPendingsName)
        {
         txt="Click on Yes to Delete All pending trades";
         ret=MessageBox(txt,"CONFIRM DELETE ALL PENDINGS",MB_YESNO); // Message box
         if(ret==IDYES)
           {
            tries=0;
            ForceTradeClosure=true;
            while(ForceTradeClosure)
              {
               ForceTradeClosure=false;

               //Delete the pendings
               if(SellStopOpen)
                  CloseAllTrades(OP_SELLSTOP);
               if(SellLimitOpen)
                  CloseAllTrades(OP_SELLLIMIT);
               if(BuyStopOpen)
                  CloseAllTrades(OP_BUYSTOP);
               if(BuyLimitOpen)
                  CloseAllTrades(OP_BUYLIMIT);

               //Mop up any trades that failed to close.
               CountOpenTrades();//Rebuild the position picture

               tries++;
               if(tries>=100)
                 {
                  break;
                 }//if (tries >= 100)
              }//while(ForceTradeClosure)

           }//if(ret ==IDYES)
         ObjectSetInteger(0,DeleteAllPendingsName,OBJPROP_STATE,false);
         return;//Nothing else to do

        }//if(sparam==DeleteAllPendingsName)

      //Delete buy stops
      if(sparam==DeleteBuyStops)
        {
         txt="Click on Yes to Delete Buy Stop Orders";
         ret=MessageBox(txt,"CONFIRM DELETE ALL BUY STOPS",MB_YESNO); // Message box
         if(ret==IDYES)
           {
            tries=0;
            ForceTradeClosure=true;
            while(ForceTradeClosure)
              {
               ForceTradeClosure=false;

               CloseAllTrades(OP_BUYSTOP);

               //Mop up any trades that failed to close.
               CountOpenTrades();//Rebuild the position picture

               tries++;
               if(tries>=100)
                 {
                  break;
                 }//if (tries >= 100)
              }//while(ForceTradeClosure)

           }//if(ret ==IDYES)
         ObjectSetInteger(0,DeleteBuyStops,OBJPROP_STATE,false);
         return;//Nothing else to do

        }//if(sparam==DeleteBuyStops)


      //Delete buy stops
      if(sparam==DeleteSellStops)
        {
         txt="Click on Yes to Delete Sell Stop Orders";
         ret=MessageBox(txt,"CONFIRM DELETE ALL SELL STOPS",MB_YESNO); // Message box
         if(ret==IDYES)
           {
            tries=0;
            ForceTradeClosure=true;
            while(ForceTradeClosure)
              {
               ForceTradeClosure=false;

               CloseAllTrades(OP_SELLSTOP);

               //Mop up any trades that failed to close.
               CountOpenTrades();//Rebuild the position picture

               tries++;
               if(tries>=100)
                 {
                  break;
                 }//if (tries >= 100)
              }//while(ForceTradeClosure)

           }//if(ret ==IDYES)
         ObjectSetInteger(0,DeleteSellStops,OBJPROP_STATE,false);
         return;//Nothing else to do

        }//if(sparam==DeleteSellStops)

      //Delete buy limits
      if(sparam==DeleteBuyLimits)
        {
         txt="Click on Yes to Delete Buy Limit Orders";
         ret=MessageBox(txt,"CONFIRM DELETE ALL BUY LIMITS",MB_YESNO); // Message box
         if(ret==IDYES)
           {
            tries=0;
            ForceTradeClosure=true;
            while(ForceTradeClosure)
              {
               ForceTradeClosure=false;

               CloseAllTrades(OP_BUYLIMIT);

               //Mop up any trades that failed to close.
               CountOpenTrades();//Rebuild the position picture

               tries++;
               if(tries>=100)
                 {
                  break;
                 }//if (tries >= 100)
              }//while(ForceTradeClosure)

           }//if(ret ==IDYES)
         ObjectSetInteger(0,DeleteBuyLimits,OBJPROP_STATE,false);
         return;//Nothing else to do

        }//if(sparam==DeleteBuyLimits)


      //Delete buy limits
      if(sparam==DeleteSellLimits)
        {
         txt="Click on Yes to Delete Sell Limit Orders";
         ret=MessageBox(txt,"CONFIRM DELETE ALL SELL LIMITS",MB_YESNO); // Message box
         if(ret==IDYES)
           {
            tries=0;
            ForceTradeClosure=true;
            while(ForceTradeClosure)
              {
               ForceTradeClosure=false;

               CloseAllTrades(OP_SELLLIMIT);

               //Mop up any trades that failed to close.
               CountOpenTrades();//Rebuild the position picture

               tries++;
               if(tries>=100)
                 {
                  break;
                 }//if (tries >= 100)
              }//while(ForceTradeClosure)

           }//if(ret ==IDYES)
         ObjectSetInteger(0,DeleteSellLimits,OBJPROP_STATE,false);
         return;//Nothing else to do

        }//if(sparam==DeleteSellLimits)

      //Send a full grid
      if(sparam==SendFullGrid)
        {
         txt="Click on Yes to send a grid of Buy and Sell Stop Orders";
         ret=MessageBox(txt,"CONFIRM BUY AND SELL STOP GRID",MB_YESNO); // Message box
         if(ret==IDYES)
           {

            SendBuyGrid(Symbol(),OP_BUYSTOP,NormalizeDouble(Ask+(DistanceBetweenTrades/factor),Digits),Lot,TradeCommentCOT);  //MJB

            SendSellGrid(Symbol(),OP_SELLSTOP,NormalizeDouble(Bid -(DistanceBetweenTrades/factor),Digits),Lot,TradeCommentCOT);  //MJB

            CountOpenTrades();

           }//if(ret ==IDYES)
         ObjectSetInteger(0,SendFullGrid,OBJPROP_STATE,false);
         return;//Nothing else to do

        }//if(sparam==SendFullGrid)

      //Send a grid of buy stops
      if(sparam==SendBuyStops)
        {
         txt="Click on Yes to send a grid of Buy Stop Orders";
         ret=MessageBox(txt,"CONFIRM BUY STOP GRID",MB_YESNO); // Message box
         if(ret==IDYES)
           {

            SendBuyGrid(Symbol(),OP_BUYSTOP,NormalizeDouble(Ask+(DistanceBetweenTrades/factor),Digits),Lot,TradeCommentCOT);  //MJB

            CountOpenTrades();

           }//if(ret ==IDYES)
         ObjectSetInteger(0,SendBuyStops,OBJPROP_STATE,false);
         return;//Nothing else to do

        }//if(sparam==SendBuyStops)

      //Send a grid of sell stops
      if(sparam==SendSellStops)
        {
         txt="Click on Yes to send a grid of Sell Stop Orders";
         ret=MessageBox(txt,"CONFIRM SELL STOP GRID",MB_YESNO); // Message box
         if(ret==IDYES)
           {

            SendSellGrid(Symbol(),OP_SELLSTOP,NormalizeDouble(Bid -(DistanceBetweenTrades/factor),Digits),Lot,TradeCommentCOT);  //MJB

            CountOpenTrades();

           }//if(ret ==IDYES)
         ObjectSetInteger(0,SendSellStops,OBJPROP_STATE,false);
         return;//Nothing else to do

        }//if(sparam==SendSellStops)

      //Send a grid of buy limits
      if(sparam==SendBuyLimits)
        {
         txt="Click on Yes to send a grid of Buy Limit Orders";
         ret=MessageBox(txt,"CONFIRM BUY LIMIT GRID",MB_YESNO); // Message box
         if(ret==IDYES)
           {

            SendBuyGrid(Symbol(),OP_BUYLIMIT,NormalizeDouble(Ask -(DistanceBetweenTrades/factor),Digits),Lot,TradeCommentCOT);  //MJB

            CountOpenTrades();

           }//if(ret ==IDYES)
         ObjectSetInteger(0,SendBuyLimits,OBJPROP_STATE,false);
         return;//Nothing else to do

        }//if(sparam==SendBuyLimits)

      //Send a grid of sell limits
      if(sparam==SendSellLimits)
        {
         txt="Click on Yes to send a grid of Sell Limit Orders";
         ret=MessageBox(txt,"CONFIRM SELL LIMIT GRID",MB_YESNO); // Message box
         if(ret==IDYES)
           {

            SendSellGrid(Symbol(),OP_SELLLIMIT,NormalizeDouble(Bid+(DistanceBetweenTrades/factor),Digits),Lot,TradeCommentCOT);  //MJB

            CountOpenTrades();

           }//if(ret ==IDYES)
         ObjectSetInteger(0,SendSellLimits,OBJPROP_STATE,false);
         return;//Nothing else to do

        }//if(sparam==SendSellLimits)


      //Pause trading
      if(sparam==PauseTrading)
        {
         TradingPaused=true;
         DisplayNow=0;
         ObjectSetInteger(0,PauseTrading,OBJPROP_STATE,false);
         DisplayUserFeedback();
         return;//Nothing else to do

        }//if(sparam==PauseTrading)

      //Resume trading
      if(sparam==ResumeTrading)
        {
         TradingPaused=false;
         DisplayNow=0;
         ObjectSetInteger(0,ResumeTrading,OBJPROP_STATE,false);
         DisplayUserFeedback();
         return;//Nothing else to do

        }//if(sparam==ResumeTrading)

     }//if(id==CHARTEVENT_OBJECT_CLICK)

/*
   if(id==CHARTEVENT_MOUSE_MOVE)
   {
      if(ObjectGetInteger(0,"Move",OBJPROP_STATE))
      {
         int cw=(int)ChartGetInteger(0,CHART_WIDTH_IN_PIXELS,0);
         int      newx=(int)(lparam)-15; // X-coordinate
         int      newy=(int)dparam-5; // Y-coordinate
         
         ObjectSet("Move",OBJPROP_XDISTANCE,newx);// X coordinate
         ObjectSet("Move",OBJPROP_YDISTANCE,newy);// Y coordinate
         ObjectSet("TradeButton",OBJPROP_XDISTANCE,newx);// X coordinate
         ObjectSet("TradeButton",OBJPROP_YDISTANCE,newy-Diff_Y_Butt1);// Y coordinate
         ObjectSet("CloseAll",OBJPROP_XDISTANCE,newx);// X coordinate
         ObjectSet("CloseAll",OBJPROP_YDISTANCE,newy-Diff_Y_Butt2);// Y coordinate

         
         ChartRedraw();

      }//if(ObjectGetInteger(0,"Move",OBJPROP_STATE))

   }//if(id==CHARTEVENT_MOUSE_MOVE)
   */
}

//END BUTTONS MODULE
///////////////////////////////////////////////////////////////////////////////////////////////////////////


void ShouldGridsBeReplaced()
{

   //Replace used grids
   double SendLots = Lot;
   
   if (GridType == Stop_And_Limit_Orders)
   {
      //Buy trades. Replace limit orders if the market has fallen a long way
      if (BuyOpen)
      {
         if (BuyLimitsCount == 0)
            SendBuyGrid(Symbol(), OP_BUYLIMIT, Bid - (DistanceBetweenTrades / factor), SendLots, TradeCommentCOT);
      }//if (BuyOpen)
      
      //Sell trades. Replace limit orders if the market has risen a long way
      if (SellOpen)
      {
         if (SellLimitsCount == 0)
            SendSellGrid(Symbol(), OP_SELLLIMIT, Bid + (DistanceBetweenTrades / factor), SendLots, TradeCommentCOT);
      }//if (SellOpen)
      
      
   
   }//if (Stop_And_Limit_Orders)
   

}// End void ShouldGridsBeReplaced()

void CanWeAddAnotherPendingTrade()
{

   //This function adds more pending trades if the market initially moves in the opposite direction 
   //of the signal.
   
   double price = 0;
   bool result = false;
   double stop = 0, take = 0;
   
   //Another buy stop?
   if (!BuyOpen)//Only if the trading sequence has not already started
      if (BuyStopOpen)
      {
         price = NormalizeDouble(LowestBuyStopPrice - ((DistanceBetweenTrades * 2) / factor), Digits);
         if (Bid <= price)
            if (!DoesTradeExist(OP_BUYSTOP, price))
            {
               take = CalculateTakeProfit(OP_BUY, price);
               stop = CalculateStopLoss(OP_BUY, price);
               result = SendSingleTrade(Symbol(), OP_BUYSTOP, TradeCommentCOT, Lot, price, stop, take);
            }//if (!DoesTradeExist(OP_BUYSTOP, price))
      }//if (BuyStopOpen)


   //Another sell stop?
   if (!SellOpen)
      if (SellStopOpen)
      {
         price = NormalizeDouble(HighestSellStopPrice + ((DistanceBetweenTrades * 2) / factor), Digits);
         if (Bid >= price)
            if (!DoesTradeExist(OP_SELLSTOP, price))
            {
               take = CalculateTakeProfit(OP_SELL, price);
               stop = CalculateStopLoss(OP_SELL, price);
               result = SendSingleTrade(Symbol(), OP_SELLSTOP, TradeCommentCOT, Lot, price, stop, take);
            }//if (!DoesTradeExist(OP_BUYSTOP, price))
      }//if (SellStopOpen)


}//End void CanWeAddAnotherPendingTrade()

/////////////////////////////////////////////////////////////////////////////////////////////////////////////
//START OF PAUL'S (Baluda) Lib.CSS module
//Thank you, Paul, for providing the code and showing me how to use it. I am deeply grateful.
//Coders, go to http://www.stevehopwoodforex.com/phpBB3/viewtopic.php?f=45&t=2905 to read about implementing calls to the library. You might prefer the #include method, but you then have to atach the Lib.CSS to your post should you be coding an EA for wider release than just for your own use, and tell readers where it goes.

//+------------------------------------------------------------------+
//|                                                       LibCSS.mq4 |
//|                      Copyright 2013, Deltabron - Paul Geirnaerdt |
//|                                          http://www.deltabron.nl |
//+------------------------------------------------------------------+

#define libCSSversion            "v1.1.2"
#define libCSSEPSILON            0.00000001
#define libCSSCURRENCYCOUNT      8

//+------------------------------------------------------------------+
//| Release Notes                                                    |
//+------------------------------------------------------------------+
// v1.0.0, 5/7/13
// * Initial release
// * NanningBob's 10.5 rules apply
// v1.1.0, 8/2/13
// * Added getSlopeRSI
// * Changed to original NB rules
// v1.1.1, 8/5/13
// * Added getGlobalMarketTrend
// * Added parameters for caching mechanism
// v1.1.2, 9/6/13
// * Added flushCache parameter

bool    libCSSsundayCandlesDetected    = false;
bool    libCSSaddSundayToMonday        = false;
bool    libCSSuseOnlySymbolOnChart     = false;
string  libCSScacheSymbol              = "EURUSD";
int     libCSScacheTimeframe           = PERIOD_M1;
string  libCSSsymbolsToWeigh           = "GBPNZD,EURNZD,GBPAUD,GBPCAD,GBPJPY,GBPCHF,CADJPY,EURCAD,EURAUD,USDCHF,GBPUSD,EURJPY,NZDJPY,AUDCHF,AUDJPY,USDJPY,EURUSD,NZDCHF,CADCHF,AUDNZD,NZDUSD,CHFJPY,AUDCAD,USDCAD,NZDCAD,AUDUSD,EURCHF,EURGBP";
int     libCSSsymbolCount;
string  libCSSsymbolNames[];
string  libCSScurrencyNames[libCSSCURRENCYCOUNT]        = { "USD", "EUR", "GBP", "CHF", "JPY", "AUD", "CAD", "NZD" };
double  libCSScurrencyValues[libCSSCURRENCYCOUNT];      // Currency slope strength
double  libCSScurrencyOccurrences[libCSSCURRENCYCOUNT]; // Holds the number of occurrences of each currency in symbols

//+------------------------------------------------------------------+
//| libCSSinit()                                                    |
//+------------------------------------------------------------------+
void libCSSinit()
{
   libCSSinitSymbols();

   libCSSsundayCandlesDetected = false;
   for ( int i = 0; i < 8; i++ )
   {
      if ( TimeDayOfWeek( iTime( NULL, PERIOD_D1, i ) ) == 0 )
      {
         libCSSsundayCandlesDetected = true;
         break;
      }
   }
  
   return;
}
//+------------------------------------------------------------------+
//| Initialize Symbols Array                                         |
//+------------------------------------------------------------------+
int libCSSinitSymbols()
{
   int i;
   
   // Get extra characters on this crimmal's symbol names
   string symbolExtraChars = StringSubstrOld(Symbol(), 6, 4);

   // Trim user input
   libCSSsymbolsToWeigh = StringTrimLeft(libCSSsymbolsToWeigh);
   libCSSsymbolsToWeigh = StringTrimRight(libCSSsymbolsToWeigh);

   // Add extra comma
   if (StringSubstrOld(libCSSsymbolsToWeigh, StringLen(libCSSsymbolsToWeigh) - 1) != ",")
   {
      libCSSsymbolsToWeigh = StringConcatenate(libCSSsymbolsToWeigh, ",");   
   }   

   // Split user input
   i = StringFind( libCSSsymbolsToWeigh, "," ); 
   while ( i != -1 )
   {
      int size = ArraySize(libCSSsymbolNames);
      string newSymbol = StringConcatenate(StringSubstrOld(libCSSsymbolsToWeigh, 0, i), symbolExtraChars);
      if ( MarketInfo( newSymbol, MODE_TRADEALLOWED ) > libCSSEPSILON )
      {
         ArrayResize( libCSSsymbolNames, size + 1 );
         // Set array
         libCSSsymbolNames[size] = newSymbol;
      }
      // Trim symbols
      libCSSsymbolsToWeigh = StringSubstrOld(libCSSsymbolsToWeigh, i + 1);
      i = StringFind(libCSSsymbolsToWeigh, ","); 
   }
   
   // Kill unwanted symbols from array
   if ( libCSSuseOnlySymbolOnChart )
   {
      libCSSsymbolCount = ArraySize(libCSSsymbolNames);
      string tempNames[];
      for ( i = 0; i < libCSSsymbolCount; i++ )
      {
         for ( int j = 0; j < libCSSCURRENCYCOUNT; j++ )
         {
            if ( StringFind( Symbol(), libCSScurrencyNames[j] ) == -1 )
            {
               continue;
            }
            if ( StringFind( libCSSsymbolNames[i], libCSScurrencyNames[j] ) != -1 )
            {  
               size = ArraySize( tempNames );
               ArrayResize( tempNames, size + 1 );
               tempNames[size] = libCSSsymbolNames[i];
               break;
            }
         }
      }
      for ( i = 0; i < ArraySize( tempNames ); i++ )
      {
         ArrayResize( libCSSsymbolNames, i + 1 );
         libCSSsymbolNames[i] = tempNames[i];
      }
   }
   
   libCSSsymbolCount = ArraySize(libCSSsymbolNames);
   // Print("symbolCount: ", symbolCount);

   ArrayInitialize( libCSScurrencyOccurrences, 0.0 );
   for ( i = 0; i < libCSSsymbolCount; i++ )
   {
      // Increase currency occurrence
      int currencyIndex = libCSSgetCurrencyIndex(StringSubstrOld(libCSSsymbolNames[i], 0, 3));
      libCSScurrencyOccurrences[currencyIndex]++;
      currencyIndex = libCSSgetCurrencyIndex(StringSubstrOld(libCSSsymbolNames[i], 3, 3));
      libCSScurrencyOccurrences[currencyIndex]++;
   }  
   return(0); 
}

//+------------------------------------------------------------------+
//| getCurrencyIndex(string currency)                                |
//+------------------------------------------------------------------+
int libCSSgetCurrencyIndex(string currency)
{
   for (int i = 0; i < libCSSCURRENCYCOUNT; i++)
   {
      if (libCSScurrencyNames[i] == currency)
      {
         return(i);
      }   
   }   
   return (-1);
}

//+------------------------------------------------------------------+
//| getSlope()                                                       |
//+------------------------------------------------------------------+
double libCSSgetSlope( string symbol, int tf, int shift )
{
   double dblTma, dblPrev;
   int shiftWithoutSunday = shift;
   if ( libCSSaddSundayToMonday && libCSSsundayCandlesDetected && tf == PERIOD_D1 )
   {
      if ( TimeDayOfWeek( iTime( symbol, PERIOD_D1, shift ) ) == 0  ) shiftWithoutSunday++;
   }   
   double atr = iATR(symbol, tf, 100, shiftWithoutSunday + 10) / 10;
   double gadblSlope = 0.0;
   if ( atr != 0 )
   {
      dblTma = libCSScalcTmaTrue( symbol, tf, shiftWithoutSunday );
      dblPrev = libCSScalcPrevTrue( symbol, tf, shiftWithoutSunday );
      gadblSlope = ( dblTma - dblPrev ) / atr;
   }

   return ( gadblSlope );
}
//+------------------------------------------------------------------+
//| calcTmaTrue()                                                    |
//+------------------------------------------------------------------+
double libCSScalcTmaTrue( string symbol, int tf, int inx )
{
   return ( iMA( symbol, tf, 21, 0, MODE_LWMA, PRICE_CLOSE, inx ) );
}

//+------------------------------------------------------------------+
//| calcPrevTrue()                                                   |
//+------------------------------------------------------------------+
double libCSScalcPrevTrue( string symbol, int tf, int inx )
{
   double dblSum  = iClose( symbol, tf, inx + 1 ) * 21;
   double dblSumw = 21;
   int jnx, knx;
   
   dblSum  += iClose( symbol, tf, inx ) * 20;
   dblSumw += 20;
         
   for ( jnx = 1, knx = 20; jnx <= 20; jnx++, knx-- )
   {
      dblSum  += iClose( symbol, tf, inx + 1 + jnx ) * knx;
      dblSumw += knx;
   }
   
   return ( dblSum / dblSumw );
}
 
//+------------------------------------------------------------------+
//| getCSS( double& CSS[], int tf, int shift )                       |
//+------------------------------------------------------------------+
void libCSSgetCSS( double& css[], int tf, int shift, bool flushCache = true )
{
   static double volume;
   if ( flushCache || volume != iVolume(libCSScacheSymbol, libCSScacheTimeframe, 0) )
   {
      int i;
      
      ArrayInitialize(libCSScurrencyValues, 0.0);

      // Get Slope for all symbols and totalize for all currencies   
      for ( i = 0; i < libCSSsymbolCount; i++ )
      {
         double slope = libCSSgetSlope(libCSSsymbolNames[i], tf, shift);
         libCSScurrencyValues[libCSSgetCurrencyIndex(StringSubstrOld(libCSSsymbolNames[i], 0, 3))] += slope;
         libCSScurrencyValues[libCSSgetCurrencyIndex(StringSubstrOld(libCSSsymbolNames[i], 3, 3))] -= slope;
      }
      ArrayResize( css, libCSSCURRENCYCOUNT );
      for ( i = 0; i < libCSSCURRENCYCOUNT; i++ )
      {
         // average
         if ( libCSScurrencyOccurrences[i] > 0 ) libCSScurrencyValues[i] /= libCSScurrencyOccurrences[i]; else libCSScurrencyValues[i] = 0;
      }
   }
   for ( i = 0; i < libCSSCURRENCYCOUNT; i++ )
   {
      css[i] = libCSScurrencyValues[i];
   }
   volume = iVolume( libCSScacheSymbol, libCSScacheTimeframe, 0 );
}
//+------------------------------------------------------------------+
//| getCSSCurrency(string currency, int tf, int shift)               |
//+------------------------------------------------------------------+
double libCSSgetCSSCurrency( string currency, int tf, int shift )
{
   double css[];
   libCSSgetCSS( css, tf, shift, true );
   return ( css[libCSSgetCurrencyIndex(currency)] );
}

//+------------------------------------------------------------------+
//| getCSSdiff(int tf, int shift)                                    |
//+------------------------------------------------------------------+
double libCSSgetCSSDiff( string symbol, int tf, int shift )
{
   double css[];
   libCSSgetCSS( css, tf, shift, true );
   double diffLong = css[libCSSgetCurrencyIndex(StringSubstrOld(symbol, 0, 3))];
   double diffShort = css[libCSSgetCurrencyIndex(StringSubstrOld(symbol, 3, 3))];
   return ( diffLong - diffShort );
}

//+------------------------------------------------------------------+
//| getSlopeRSI( string symbol, int tf, int shift )                  |
//+------------------------------------------------------------------+
double libCSSgetSlopeRSI( string symbol, int tf, int shift )
{
   double slope[];
   int workPeriod = 17;                                         // RSI period Bob's default = 2, + overhead
   ArrayResize( slope, workPeriod );
   ArraySetAsSeries( slope, true );
   for ( int i = 0; i < workPeriod; i++ )
   {
      slope[i] = libCSSgetSlope( symbol, tf, shift + i );
   }
   return( iRSIOnArray( slope, workPeriod, 2, 0 ) );            // Again, 2 is Bob's default
}

//+------------------------------------------------------------------+
//| getBBonStoch( string symbol, int tf, int shift )                 |
//+------------------------------------------------------------------+


//+------------------------------------------------------------------+
//| getGlobalMarketTrend( int tf, int shift )                        |
//+------------------------------------------------------------------+
double libCSSgetGlobalMarketTrend( int tf, int shift ) 
{
   double buffer[libCSSCURRENCYCOUNT];
   libCSSgetCSS( buffer, tf, shift, true );
      
   double gmt = 0;
   for ( int i = 0; i < libCSSCURRENCYCOUNT; i++ )
   {
      gmt += MathPow(buffer[i], 2);
   }
   
   return ( gmt );
}


////////////////////////////////////////////////////////////////////////////////////////
//+------------------------------------------------------------------+
//| expert start function                                            |
//+------------------------------------------------------------------+
void OnTick()
{
//----

   if (RemoveExpert)
   {   
      Alert(Symbol() + ": I have removed myself from the chart.");
      ExpertRemove();
      return;
   }//if (RemoveExpert)
      
   //int cc;
   
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

   
   //Code to check that there are sufficient bars in the chart's history. Gaheitman provided this. Many thanks George.
   static bool NeedToCheckHistory=false;
   if (NeedToCheckHistory)
   {
        //Customize these for the EA.  You can use externs for the periods 
        //if the user can change the timeframes used.
        //In a multi-currency bot, you'd put the calls in a loop across
        //all pairs
        
        //Customise these to suit what you are doing
        bool WeHaveHistory = true;
        if (!HistoryOK(Symbol(),Period())) WeHaveHistory = false;
        if (!WeHaveHistory)
        {
            Alert("There are <100 bars on this chart so the EA cannot work. It has removed itself. Please refresh your chart.");
            ExpertRemove();
        }//if (!WeHaveHistory)
        
        //if we get here, history is OK, so stop checking
        NeedToCheckHistory=false;
   }//if (NeedToCheckHistory)

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

   if (!UseAtrForGrid)
   {
      DistanceBetweenTrades = DistanceBetweenTradesPips;
      if (CloseEnough(DistanceBetweenTrades, 0) )
         DistanceBetweenTrades=3;
   }//if (!UseAtrForGrid)

   if (UseAtrForGrid)
      if (CloseEnough(DistanceBetweenTrades, 0) )
      {
                  GridAtrVal = GetAtr(Symbol(), GridAtrTimeFrame, GridAtrPeriod, 1);
         GridAtrVal*= factor;
         GridAtrVal = NormalizeDouble(GridAtrVal * GridAtrMultiplier, 0);
         DistanceBetweenTrades = NormalizeDouble(GridAtrVal / GridSize, 0);

      }//if (CloseEnough(DistanceBetweenTrades, 0) )
      
   
    //If HG is sleeping after a trade closure, is it time to awake?
   if (SafetyViolation) TooClose();
   if (SafetyViolation)//TooClose() sets SafetyViolation
   {
      DisplayUserFeedback();
      return;
   }//if (SafetyViolation) 
  
   //Lot size based on account size
   if (!CloseEnough(LotsPerDollopOfCash, 0))
      CalculateLotAsAmountPerCashDollops();
   
   if (OrdersTotal() == 0)
   {
      TicketNo = -1;
      ForceTradeClosure = false;
   }//if (OrdersTotal() == 0)


   if (ForceTradeClosure) 
   {
      ShouldTradesBeClosed();
      return;
   }//if (ForceTradeClosure) 

   //Check for a massive spread widening event and pause the ea whilst it is happening
   if (!IsDemo())
      CheckForSpreadWidening();

   GetSwap(Symbol() );//For the swap filters, and in case crim has changed swap rates
   
   
   
   //Daily results so far - they work on what in in the history tab, so users need warning that
   //what they see displayed on screen depends on that.   
   //Code courtesy of TIG yet again. Thanks, George.
   static int OldHistoryTotal;
   if (OrdersHistoryTotal() != OldHistoryTotal)
   {
      CalculateDailyResult();//Does no harm to have a recalc from time to time
      OldHistoryTotal = OrdersHistoryTotal();
   }//if (OrdersHistoryTotal() != OldHistoryTotal)
   
   
   ReadIndicatorValues();//This might want moving to the trading section at the end of this function if EveryTickMode = false
   

   //Delete orphaned tp/sl lines
   static int M15Bars;
   if (M15Bars != iBars(NULL, PERIOD_M15) )
   {
      M15Bars = iBars(NULL, PERIOD_M15);
      DeleteOrphanTpSlLines();
   }//if (M15Bars != iBars(NULL, PERIOD_M15)
   
   //Reset variables where user is not using ATR
   if (!UseAtrForGrid)
      DistanceBetweenTrades = DistanceBetweenTradesPips;
   if (!UseAtrForTakeProfit)
      TakeProfit = TakeProfitPips;   
   if (!UseAtrForStopLoss)
      StopLoss = StopLossPips;   

   ///////////////////////////////////////////////////////////////////////////////////
   //Find open trades.
   CountOpenTrades();
   //Has the market moved far enough away from the grid to demand another trade be sent?
   if (OpenTrades > 0)
      if(GridType == Non_Hedged_Stop_Orders_Only)
         CanWeAddAnotherPendingTrade();

   //Examine the position for trade closure/deletion
   ShouldTradesBeClosed();
   //In case any trade closures failed
   if (ArraySize(ForceCloseTickets) > 0)
   {
      MopUpTradeClosureFailures();
      return;
   }//if (ArraySize(ForceCloseTickets) > 0)      
   
   //Deal with excessive numbers of pendings being sent
   DetectAndDeleteExcessPendings();
   
   //Replace missing grids
   ShouldGridsBeReplaced();
   
   //Safety feature. Sometimes an unexpected concatenation of inputs choice and logic error can cause rapid opening-closing of trades. Detect a closed trade and check that is was not a rogue.
   if (OldOpenTrades != OpenTrades)
   {
      if (IsClosedTradeRogue() )
      {
         RobotSuspended = true;
         return;
      }//if (IsClosedTradeRogue() )      
   }//if (OldOpenTrades != OpenTrades)
   
   OldOpenTrades = OpenTrades;

   //Reset various variables
   if (OpenTrades == 0)
   {
      //Remove the OriginalSignal global variable store
      if (GlobalVariableCheck(GvName))
         GlobalVariableDel(GvName);
      OriginalSignal = -1;   
   }//if (OpenTrades > 0)
   
   //In case the opposite direction pendings are missing
   
   ///////////////////////////////////////////////////////////////////////////////////
  
   //Trading times
   TradeTimeOk = CheckTradingTimes();
   if (!TradeTimeOk)
   {
      DisplayUserFeedback();
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
   if (!MarginCheck() )
   {
      DisplayUserFeedback();
      Sleep(1000);
      return;
   }//if (!MarginCheck() )
   
   
   
   
   //Trading
   if(EveryTickMode) OldBarsTime=0;
   if(OldBarsTime!=iTime(NULL,TradingTimeFrame,0))
   {
      OldBarsTime = iTime(NULL, TradingTimeFrame, 0);
      //ReadIndicatorValues();//Remember to delete the call higher up in this function if EveryTickMode = false
      if (TimeCurrent() >= TimeToStartTrading)
         if (!StopTrading)
            if (!TradingPaused)
               if (!GridSent)//Un-comment this line for multi traders. Leave commented 
                                                   //for single traders
               {
                  TimeToStartTrading = 0;//Set to TimeCurrent() + (PostTradeAttemptWaitMinutes * 60) when there is an OrderSend() attempt)
                  LookForTradingOpportunities();
               }//if (TicketNo == -1 or if (OpenTrades < MaxTradesAllowed))
   }//if(OldBarsTime!=iTime(NULL,TradingTimeFrame,0))

   
   ///////////////////////////////////////////////////////////////////////////////////
  
   DisplayUserFeedback();


//----
   return;
}
