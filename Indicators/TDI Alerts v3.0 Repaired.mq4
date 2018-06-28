//+------------------------------------------------------------------+ 
//|                      TDI Alerts v3.mq4                           |
//|              previous name: TDI-With Alerts                      |
//|                                                                  |
//|      (since there are so many versions around, imho the          |
//|       renaming makes sense, Marc)                                |
//|                                                                  |
//|   Version 1.  Completed by Dean Malone 2006 (www.compassfx.com)  |
//|   Version 2.  Completed by Tim Hyder 2008                        |
//|               a)   Complete Code rewrite                         |
//|               b)   Added Entry / Exit Signal Arrows Option       | 
//|               b)   Added Audio, Visual and eMail alerts          | 
//|   Version 2.a Completed by Marc (fxdaytrader), forexBaron.net    |
//|               a)   Added/mod. Alertmodes (sound/push/texts)      |
//|               b)   Added ma-parameters (trend-signal-shift,etc.  |
//|               c)   Made the colors changeable (external params)  |
//|               d)   Made the ob/os/cons levels changeable         |
//|                                                                  |
//|   Copyright © 2008, Tim Hyder aka Hiachiever                     |
//|                                                                  |
//|   PO BOX 768, Hillarys, Western Australia, Australia, 6923       |
//|                                                                  |
//|   GIFTS AND DONATIONS ACCEPTED                                   | 
//|   All my indicators should be considered donationware. That is   |
//|   you are free to use them for your personal use, and are        |
//|   under no obligation to pay for them. However, if you do find   |
//|   this or any of my other indicators help you with your trading  |
//|   then any Gift or Donation as a show of appreciation is         |
//|   gratefully accepted.                                           |
//|                                                                  |
//|   Gifts or Donations also keep me motivated in producing more    |
//|   great free indicators. :-)                                     |
//|                                                                  |
//|   PayPal - hiachiever@gmail.com                                  |  
//+------------------------------------------------------------------+ 
//+------------------------------------------------------------------+
//|                                                                  |
//|               Traders Dynamic Index - Overview                   |
//|                                                                  |
//| Introduction                                                     |
//| ------------                                                     |
//| The TDI indicator was developed by Dean Malone (CompassFx.com)   |
//| in 2006 and rewritten by Tim Hyder aka Hiachiever                |
//| (hiachiever@gmail.com) in 2008. Finally it got the final touch   |
//| (to date?) in 2013 by Marc aka fxdaytrader (www.forexBaron.net). |
//|                                                                  |
//| Let us listen to Dean's explanation about the functional         |
//| principle of the Traders Dynamic Index:                          |
//|                                                                  |
//|  This hybrid indicator is developed to assist traders in their   |
//|  ability to decipher and monitor market conditions related to    |
//|  trend direction, market strength, and market volatility.        |
//|                                                                  | 
//|  Even though comprehensive, the T.D.I. is easy to read and use.  |
//|                                                                  |
//|  Green line = RSI Price line                                     |
//|  Red line = Trade Signal line                                    |
//|  Blue lines = Volatility Band                                    | 
//|  Yellow line = Market Base Line                                  |  
//|                                                                  |
//|  Trend Direction - Immediate and Overall                         |
//|  ---------------------------------------                         |
//|   Immediate = Green over Red...price action is moving up.        |
//|               Red over Green...price action is moving down.      |
//|                                                                  |   
//|   Overall = Yellow line trends up and down generally between the |
//|             lines 32 & 68. Watch for Yellow line to bounces off  |
//|             these lines for market reversal. Trade long when     |
//|             price is above the Yellow line, and trade short when |
//|             price is below.                                      |        
//|                                                                  |
//|  Market Strength & Volatility - Immediate and Overall            |
//|   Immediate = Green Line - Strong = Steep slope up or down.      | 
//|                            Weak = Moderate to Flat slope.        |
//|                                                                  |               
//|   Overall = Blue Lines - When expanding, market is strong and    |
//|             trending. When constricting, market is weak and      |
//|             in a range. When the Blue lines are extremely tight  |                                                       
//|             in a narrow range, expect an economic announcement   | 
//|             or other market condition to spike the market.       |
//|                                                                  |               
//|                                                                  |
//|  Entry conditions  
//|  ----------------                                                |
//|   Scalping  - Long = Green over Red, Short = Red over Green      |
//|   Active - Long = Green over Red & Yellow lines                  |
//|            Short = Red over Green & Yellow lines                 |    
//|   Moderate - Long = Green over Red, Yellow, & 50 lines           |
//|              Short= Red over Green, Green below Yellow & 50 line |
//|                                                                  |
//|  Exit conditions*                                                |
//|  ----------------                                                |   
//|   Long = Green crosses below Red                                 |
//|   Short = Green crosses above Red                                |
//|   * If Green crosses either Blue lines, consider exiting when    |
//|     when the Green line crosses back over the Blue line.         |
//|                                                                  |
//|                                                                  |
//|  IMPORTANT: The default settings are well tested and proven.     |
//|  ---------- But, you can change the settings to fit your         |
//|             trading style.                                       |
//|                                                                  |
//|                                                                  |
//|  Price & Line Type settings:                                     |                
//|   RSI Price settings                                             |               
//|   0 = Close price     [DEFAULT]                                  |               
//|   1 = Open price.                                                |               
//|   2 = High price.                                                |               
//|   3 = Low price.                                                 |               
//|   4 = Median price, (high+low)/2.                                |               
//|   5 = Typical price, (high+low+close)/3.                         |               
//|   6 = Weighted close price, (high+low+close+close)/4.            |               
//|                                                                  |               
//|   RSI Price Line & Signal Line Type settings                     |               
//|   0 = Simple moving average       [DEFAULT]                      |               
//|   1 = Exponential moving average                                 |               
//|   2 = Smoothed moving average                                    |               
//|   3 = Linear weighted moving average                             |               
//|                                                                  |
//|   Good trading,                                                  |   
//|                                                                  |
//|   Dean                                                           |                              
//+------------------------------------------------------------------+
/*
  SIGNAL GENERATION:
  ------------------
  
  The TDI (Traders Dynamic Index)
  ===============================

  Volatility Band High (VB HIGH), color: SkyBlue, buffer: UpZone
  Volatility Band Low (VB LOW),   color: SkyBlue, buffer: DnZone
  RSI PRICE LINE (RSI),           color: Green,   buffer: MaBuf
  MARKET BASE LINE,               color: Yellow,  buffer: MdZone
  TRADE SIGNAL LINE,              color: Red,     buffer: MbBuf
  TRADE SIGNAL2 LINE,             color: Aqua,    buffer: McBuf, -> has no function for signal generation!

  Indicator SignalLevels:
  RSI_OversoldLevel     : 23 (default: 32)
  RSI_OverboughtLevel   : 78 (default: 68)
  VB_ConsolidationLevel : 20 (default: 20)

  Conditions:
  ===========

  Strong Buy:  RSI>TRADE SIGNAL LINE && TRADE SIGNAL LINE> MARKET BASE LINE && RSI>RSI_OversoldLevel && RSI<RSI_OverboughtLevel

  Medium Buy:  RSI>TRADE SIGNAL LINE && RSI> MARKET BASE LINE && TRADE SIGNAL LINE< MARKET BASE LINE && RSI>RSI_OversoldLevel && RSI<RSI_OverboughtLevel

  Weak Buy:    RSI>TRADE SIGNAL LINE && TRADE SIGNAL LINE<MARKET BASE LINE && RSI< MARKET BASE LINE && RSI>RSI_OversoldLevel && RSI<RSI_OverboughtLevel

  Strong Sell: RSI<TRADE SIGNAL LINE && TRADE SIGNAL LINE< MARKET BASE LINE && RSI>RSI_OversoldLevel && RSI<RSI_OverboughtLevel

  Medium Sell: RSI<TRADE SIGNAL LINE && RSI< MARKET BASE LINE && TRADE SIGNAL LINE> MARKET BASE LINE && RSI>RSI_OversoldLevel && RSI<RSI_OverboughtLevel

  Weak Sell:   RSI<TRADE SIGNAL LINE && TRADE SIGNAL LINE> MARKET BASE LINE && RSI> MARKET BASE LINE && RSI>RSI_OversoldLevel && RSI<RSI_OverboughtLevel

  HIGH LEVEL CAUTION (Overbought): RSI>=RSI_OverboughtLevel

  LOW LEVEL CAUTION (Oversold): RSI<=RSI_OversoldLevel


  TrendSignals:
  =============               

  Strong Up:     TRADE SIGNAL LINE>MARKET BASE LINE

  Weak Up:       TRADE SIGNAL LINE>MARKET BASE LINE && RSI<MARKET BASE LINE

  Strong Down:   TRADE SIGNAL LINE<=MARKET BASE LINE

  Weak Down:     TRADE SIGNAL LINE<=MARKET BASE LINE && RSI>=MARKET BASE LINE

  Consolidation: VB HIGH-VB LOW<VB_ConsolidationLevel

  RESOURCES/MORE
  -------------
  nice tdi-tutorial (pdf): http://www.forexfactory.com/attachment.php?attachmentid=1306506&d=1383707123
  download source for that current version: http://www.forexfactory.com/showthread.php?t=460148
   see also http://www.forexfabrik.de/mt-indikatoren/traders-dynamic-index-(tdi)-alerts-new/
  download source of the previous version 2 (this is 3!): http://codebase.mql4.com/2999
  see also: http://www.greattradingsystems.com/2010/11/tdi-metatrader-indicator/
*/
#property copyright "Copyright © 2008 Tim Hyder, Dan Malone et. al."
#property link      "http://forexBaron.net"
#define vers    "12.2013 / 11.2011 / 02.2008" //09-Feb-2008
#define major   "2"
#define minor   "a"
#define indicatorName "TDI Alerts v" //"TDIvisual new"
//----
#property indicator_separate_window
#property indicator_buffers 7
#property indicator_color1 Gray
#property indicator_color2 SkyBlue //MediumBlue
#property indicator_color3 Yellow
//#property indicator_width3 2
#property indicator_color4 SkyBlue //MediumBlue
#property indicator_color5 Green
//#property indicator_width5 2
#property indicator_color6 Red
#property indicator_color7 Aqua
//#property indicator_style7 2

/////////////////////////////////////////////////////////////////////////////////////////
extern string NoteIndic=" --- Indicator Options --- ";
extern int    RSI_Period                  = 8;//13 //8-25
extern int    RSI_Price                   = PRICE_MEDIAN;//0;  //0-6
//
extern int    Volatility_Band             = 23;//34;  //20-40
extern int    RSI_Price_Line              = 2;//2
extern int    RSI_Price_Line_Shift        = 0;   //0;
extern int    RSI_Price_Type              = MODE_LWMA; //0;   //0-3
//
extern int    Trade_Signal_Line           = 7;//7
extern int    Trade_Signal_Line_Shift     = 0;//0
extern int    Trade_Signal_Type           = PRICE_CLOSE;//0   //0-3
//
extern int    Trade_Signal2_Line          = 18;//18
extern int    Trade_Signal2_Line_Shift    = 0;//0
extern int    Trade_Signal2_Type          = PRICE_MEDIAN;//0   //0-3
extern bool   SHOW_Trade_Signal2_Line     = FALSE;//TRUE;
//----
extern string NoteLevels=" --- OB/OS Levels (32,68,20) --- ";
extern int    RSI_OversoldLevel           = 23;//32;
extern int    RSI_OverboughtLevel         = 78;//68;
extern int    VB_ConsolidationLevel       = 20;//20;
//---
extern string NoteAlerts=" --- Alert Options --- ";
extern bool   StrongBuySellAlerts         = true;
extern bool   MediumWeakBuySellAlerts     = true;
extern bool   CautionAlerts               = true;//shown in indicatorwindow
extern int    AlertBar                    = 1;//0:current bar, 1:one bar ago, etc.
extern bool   SendTimeInfoAsTimeLocal     = false;//true:use local time, false:use server time for time infos
extern string NoteAlerts1="*** ALERT METHODS ***:";
extern bool   PopupAlerts                 = true;
extern bool   eMailAlerts                 = false;
extern bool   PushNotificationAlerts      = false;
extern bool   SoundAlerts                 = false;
extern string SoundAlertFileLong          = "alert.wav";
extern string SoundAlertFileShort         = "alert2.wav";
extern string SoundAlertFileCautionAlert  = "news.wav";
string SoundAlertFile;
datetime MyTime;
//----
extern string NoteLevel=" --- Visual Levels: ---";
//extern int Level1 = 78;//68;
extern int Level2 = 50;//50;
//extern int Level3 = 23;//32;
//---
extern string NoteColor=" --- Colors --- ";
extern color  BuyArrowColor               = Lime;
extern color  SellArrowColor              = Red;
extern color  StrongBuyArrowCautionColor  = Chartreuse;  //Gold;
extern color  StrongSellArrowCautionColor = DeepPink;    //Gold;
extern string NoteColor1=" --- TrendSignals --- ";
extern color  WeakUpColor                 = Green;
extern color  StrongUpColor               = Lime;
extern color  WeakDownColor               = Orange;
extern color  StrongDownColor             = Red;
extern color  ConsolidationColor          = Silver; 
extern string NoteColor2=" --- TrendVisuals ---";
extern color  StrongBuyColor              = Lime;
extern color  MediumBuyColor              = Green;
extern color  WeakBuyColor                = SeaGreen;
extern color  StrongSellColor             = Red;
extern color  MediumSellColor             = Tomato;
extern color  WeakSellColor               = Orange;
//extern color  HighLevelCautionColor       = Yellow; //Red;
//extern color  LowLevelCautionColor        = White; //Red;
//----
extern string NoteGeneral=" --- General Options (true,true,0,0) --- ";
extern bool   Show_TrendVisuals           = true;
extern bool   Show_SignalArrows           = true;
extern int    SHIFT_Sideway               = -50;
extern int    SHIFT_Up_Down               = -10;
extern string NoteFonts=" --- Font/Size (25,15,13,Tahoma Narrow) ---";
extern int    TrendArrowFontSize          = 15;//25;
extern int    TrendSignalsFontSize        = 10;//15;
extern int    TrendPriceFontSize          = 10;//13;
extern string TypeFace                    = "Arial Black";//"Tahoma Narrow";//"Tahoma Narrow";
/////////////////////////
//mod.:
extern string NoteIndiRsi=" --- misc: --- ";
extern string nirh="replace the RSI with:";
extern bool   UseStochInsteadOfRsi        = FALSE;//if false: use rsi, if true: use stoch ...
extern int	  stochKPeriod	               = 11;
extern int	  stochDPeriod	               = 2;
extern int	  stochSlowing                = 2;
extern int	  stochMethod	               = MODE_LWMA;
extern int	  stochPrice              		= 1; //0=Low/High, 1=Close/Close
//custom alert, nellycopter:
extern string NoteCustomAlert=" --- custom alert, nellycopter: --- ";
extern string NoteCustomAlert1=" --- price cross tradesignal above/under marketbase line (optional ma-filter) --- ";
extern bool RsiTradeSignalCrossAlerts   = true;
extern bool RsiTradeSignalCrossMaFilter = false;
extern int filterMaPeriod = 60;
extern int filterMaShift  = 0;
extern int filterMaMethod = MODE_EMA;
extern int filterMaPrice  = PRICE_CLOSE;
extern string CustomAlertSoundFileLong = "news.wav";
extern string CustomAlertSoundFileShort = "news.wav";

//end mod.
string indicatorsName;
/////////////////////////////////////////////////////////////////////
//----
bool InitialLoad=True;
string prefix="TDIV_";
double RSIBuf[],UpZone[],MdZone[],DnZone[],MaBuf[],MbBuf[],McBuf[];
string Signal="", Signal2="", Signal3="",Signal4="";
color TDI_col,TDI_col2;
int LastAlert=0, LastAlertBar,SigCounter=0;
double BidCur;
datetime TimeCur;
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
int init()
  {
  /*
   indicatorsName=indicatorName+major+minor+" (";
   if (UseStochInsteadOfRsi) indicatorsName=indicatorsName+"STOCH)";
     else indicatorsName=indicatorsName+"RSI)";
   */
   IndicatorShortName(indicatorName);
   //
   SetIndexBuffer(0,RSIBuf); //Black/no color
   SetIndexBuffer(1,UpZone); //SkyBlue, VB HIGH
   SetIndexBuffer(2,MdZone); //Yellow,  MARKET BASE LINE
   SetIndexBuffer(3,DnZone); //SkyBlue, VB LOW
   SetIndexBuffer(4,MaBuf);  //Green,   RSI PRICE LINE
   SetIndexBuffer(5,MbBuf);  //Red,     TRADE SIGNAL LINE
   SetIndexBuffer(6,McBuf);  //Aqua,    TRADE SIGNAL2 LINE (has no function for signal generation)
//----
   if(SHOW_Trade_Signal2_Line == true){ SHOW_Trade_Signal2_Line = DRAW_LINE; }
    else { SHOW_Trade_Signal2_Line = DRAW_NONE; }
   SetIndexStyle(6,SHOW_Trade_Signal2_Line,0,2); // SetIndexStyle(6,SHOW_Trade_Signal2_Line);
   //SetIndexBuffer(6,McBuf);
   SetIndexStyle(0,DRAW_NONE);
   SetIndexStyle(1,DRAW_LINE);
   SetIndexStyle(2,DRAW_LINE);
   SetIndexStyle(3,DRAW_LINE);
   SetIndexStyle(4,DRAW_LINE);
   SetIndexStyle(5,DRAW_LINE);
//----
   SetIndexLabel(0,NULL);
   SetIndexLabel(1,"VolatilityBand High");
   SetIndexLabel(2,"Market Base Line");
   SetIndexLabel(3,"VolatilityBand Low");
     
   //
    if (UseStochInsteadOfRsi) SetIndexLabel(4,"STOCH Price Line");
      else SetIndexLabel(4,"RSI Price Line");
   //
   
   SetIndexLabel(5,"Trade Signal Line");
   SetIndexLabel(6,"Trade Signal2 Line");
   //
   /*
   SetLevelValue(0,61.8);
   SetLevelValue(1,50.0);
   SetLevelValue(2,38.2);
   SetLevelValue(3,23.6);
   SetLevelStyle(STYLE_DOT,1,DimGray);
   */
   //
   LastAlertBar=Bars-1;
//----
   return(0);
  }
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
int deinit()
  {
   int total=ObjectsTotal();
   for(int i=total-1; i>=0; i--)
     {
      string name=ObjectName(i);
      if (StringFind(name, prefix)==0) ObjectDelete(name);
     }
//----   
   return(0);
  }
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
int start() {
//----
   double indicatorVal;//mod. to replace rsi easily, fxdaytrader
   int Win=WindowFind(indicatorName);
   if (Win==- 1) Win=0;
//----
   double MA,RSI[];
   ArrayResize(RSI,Volatility_Band);
   int counted_bars=IndicatorCounted();
   int limit=Bars-counted_bars-1;
//----
////////////////////////////////////////////////////////////////
   for(int i=limit; i>=0; i--)
     {
      //mod if you'd like to replace rsi by something else, eg. stoch:
       indicatorVal = iRSI(NULL,0,RSI_Period,RSI_Price,i); //default
        if (UseStochInsteadOfRsi) indicatorVal = iStochastic(NULL,0,stochKPeriod,stochDPeriod,stochSlowing,stochMethod,stochPrice,MODE_MAIN,i);
      //end mod
      
      RSIBuf[i]=indicatorVal; //original: iRSI(NULL,0,RSI_Period,RSI_Price,i);
      MA=0;
      for(int x=i; x<i+Volatility_Band; x++)
        {
         RSI[x-i]=RSIBuf[x];
         MA+=RSIBuf[x]/Volatility_Band;
        }
      UpZone[i]=(MA + (1.6185 * StDev(RSI,Volatility_Band)));
      DnZone[i]=(MA - (1.6185 * StDev(RSI,Volatility_Band)));
      MdZone[i]=((UpZone[i] + DnZone[i])/2);
     }
   for(i=limit-1;i>=0;i--)
     {
      MaBuf[i]=(iMAOnArray(RSIBuf,0,RSI_Price_Line,RSI_Price_Line_Shift,RSI_Price_Type,i));
      MbBuf[i]=(iMAOnArray(RSIBuf,0,Trade_Signal_Line,Trade_Signal_Line_Shift,Trade_Signal_Type,i));
      McBuf[i]=(iMAOnArray(RSIBuf,0,Trade_Signal2_Line,Trade_Signal2_Line_Shift,Trade_Signal2_Type,i));
      BidCur=Close[i]; //Could use bid however no good when using visual back tester
      TimeCur=Time[i];

//CUSTOM ALERT:   
    double filterma    = iMA(NULL,0,filterMaPeriod,filterMaShift,filterMaMethod,filterMaPrice,i);
    double filterprice = iClose(NULL,0,i);
    
    string stext;
    //RSI > MarketBaseLine && RSI > TradeSignal && RSI b4 < TradeSignal b4
    if (RsiTradeSignalCrossAlerts)
     if ((filterprice>filterma && RsiTradeSignalCrossMaFilter)||!RsiTradeSignalCrossMaFilter)
      
      if (MaBuf[i]<MdZone[i] && MaBuf[i]>MbBuf[i] && MaBuf[i+1]<MbBuf[i+1]) {//new, bull cross below marketbase
      //if (MaBuf[i]>MdZone[i] && MaBuf[i]>MbBuf[i] && MaBuf[i+1]<MbBuf[i+1]) { //nellycopter old
       if (SendTimeInfoAsTimeLocal) MyTime=TimeLocal(); else if (!SendTimeInfoAsTimeLocal) MyTime=TimeCurrent();
       stext=Symbol()+ ", " + TF2Str(Period()) + ": BUY SIGNAL - PriceLine crossed TradeSignalLine below MarketBaseLine @ "+DoubleToStr(Close[i],Digits) + ", @ " + TimeToStr(MyTime,TIME_SECONDS);
       if (Bars>LastAlertBar && i==AlertBar)
        {
         LastAlertBar=Bars;
         DoAlerts(stext,Symbol()+ ", " + TF2Str(Period()) + ": BUY SIGNAL - PriceLine crossed TradeSignalLine below MarketBaseLine",CustomAlertSoundFileLong);
        }
    }//if (RsiTradeSignalCrossAlerts)
    
    //RSI < MarketBaseLine && RSI < TradeSignal && RSI b4 > TradeSignal b4
    if (RsiTradeSignalCrossAlerts) 
     if ((filterprice<filterma && RsiTradeSignalCrossMaFilter)||!RsiTradeSignalCrossMaFilter)
      
      if (MaBuf[i]>MdZone[i] && MaBuf[i]<MbBuf[i] && MaBuf[i+1]>MbBuf[i+1]) {//new, bear cross above marketbase
      //if (MaBuf[i]<MdZone[i] && MaBuf[i]<MbBuf[i] && MaBuf[i+1]>MbBuf[i+1]) {//nellycopter old
       if (SendTimeInfoAsTimeLocal) MyTime=TimeLocal(); else if (!SendTimeInfoAsTimeLocal) MyTime=TimeCurrent();
       stext=Symbol()+ ", " + TF2Str(Period()) + ": SELL SIGNAL - PriceLine crossed TradeSignalLine above MarketBaseLine @ "+DoubleToStr(Close[i],Digits) + ", @ " + TimeToStr(MyTime,TIME_SECONDS);
       if (Bars>LastAlertBar && i==AlertBar)
        {
         LastAlertBar=Bars;
         DoAlerts(stext,Symbol()+ ", " + TF2Str(Period()) + ": SELL SIGNAL - PriceLine crossed TradeSignalLine above MarketBaseLine",CustomAlertSoundFileShort);
        }
    }//if (RsiTradeSignalCrossAlerts)

//end CUSTOM ALERT
  /////////////////////////
      if(Show_TrendVisuals)
        {
         //signals
         // "RSI PRICE LINE" > "TRADE SIGNAL LINE" && "TRADE SIGNAL LINE" < "MARKET BASE LINE" && "RSI PRICE LINE" < "MARKET BASE LINE"
         if((MaBuf[i]>MbBuf[i])&&(MbBuf[i]<MdZone[i])&&(MaBuf[i]< MdZone[i])&&(MaBuf[i]>RSI_OversoldLevel)&&(MaBuf[i]<RSI_OverboughtLevel))
           {
            Signal2="Weak Buy";
            Signal="é";
            TDI_col=WeakBuyColor;
           }
         else if((MaBuf[i]<MbBuf[i])&&(MbBuf[i]> MdZone[i])&&(MaBuf[i]> MdZone[i])&&(MaBuf[i]>RSI_OversoldLevel)&&(MaBuf[i]<RSI_OverboughtLevel))
              {
               Signal2="Weak Sell";
               Signal="ê";
               TDI_col=WeakSellColor;
              }
            // "RSI PRICE LINE" > "TRADE SIGNAL LINE" && "TRADE SIGNAL LINE" > "MARKET BASE LINE" 
            else if((MaBuf[i]>MbBuf[i])&&(MbBuf[i]> MdZone[i])&&(MaBuf[i]>RSI_OversoldLevel)&&(MaBuf[i]<RSI_OverboughtLevel))
                 {
                  Signal2="Strong Buy";
                  Signal="é";
                  TDI_col=StrongBuyColor;
                 }
               // "RSI PRICE LINE" > "TRADE SIGNAL LINE"
               else if((MaBuf[i]>MbBuf[i])&&(MaBuf[i]> MdZone[i])&&(MbBuf[i]< MdZone[i])&&(MaBuf[i]>RSI_OversoldLevel)&&(MaBuf[i]<RSI_OverboughtLevel))
                    {
                     Signal2="Medium Buy";
                     Signal="é";
                     TDI_col=MediumBuyColor;
                    }
                  else if((MaBuf[i]<MbBuf[i])&&(MbBuf[i]< MdZone[i])&&(MaBuf[i]>RSI_OversoldLevel)&&(MaBuf[i]<RSI_OverboughtLevel))
                       {
                        Signal2="Strong Sell";
                        Signal="ê";
                        TDI_col=StrongSellColor;
                       }
                     else if((MaBuf[i]<MbBuf[i])&&(MaBuf[i]< MdZone[i])&&(MbBuf[i]> MdZone[i])&&(MaBuf[i]>RSI_OversoldLevel)&&(MaBuf[i]<RSI_OverboughtLevel))
                          {
                           Signal2="Medium Sell";
                           Signal="ê";
                           TDI_col=MediumSellColor;
                          }
         // reversals
                        else if(MaBuf[i]>=RSI_OverboughtLevel)
                             {
                              Signal2="Caution - Overbought !";
                              Signal="ê";
                              TDI_col=StrongBuyArrowCautionColor;//HighLevelCautionColor;
                             }
                           else if(MaBuf[i]<=RSI_OversoldLevel)
                                {
                                 Signal2="Caution - Oversold !";
                                 Signal="é";
                                 TDI_col=StrongSellArrowCautionColor;//LowLevelCautionColor;
                                }
         //TDI - Trend Signals     
         if((MbBuf[i]>MdZone[i])&&(MaBuf[i]<MdZone[i]))
           {
            Signal4= "Weak Up";
            Signal3="é";
            TDI_col2=WeakUpColor;
           }
         else if (MbBuf[i]>MdZone[i])
              {
               Signal4= "Strong Up";
               Signal3="é";
               TDI_col2=StrongUpColor;
              }
         if((MbBuf[i]<=MdZone[i])&&(MaBuf[i]>=MdZone[i]))
           {
            Signal4= "Weak Down";
            Signal3="é";
            TDI_col2=WeakDownColor;
           }
         else if (MbBuf[i]<=MdZone[i])
              {
               Signal4= "Strong Down";
               Signal3="ê";
               TDI_col2=StrongDownColor;
              }
         //ranging
         if(UpZone[i]-DnZone[i]<VB_ConsolidationLevel)
           {
            Signal4="Consolidation";
            Signal3="h";
            TDI_col2=ConsolidationColor;
           }
         string Subj=Symbol()+ ", " + TF2Str(Period()) + " " + Signal2;
         string Msg;
         
         //ALERTS
         //strong buy alert:
         if (Signal2=="Signal: Strong Buy" && Signal4=="Strong Up" && LastAlert!=1)
           {
            if (SendTimeInfoAsTimeLocal) MyTime=TimeLocal(); else if (!SendTimeInfoAsTimeLocal) MyTime=TimeCurrent();
            Msg=Subj + " (Trend: "+Signal4+") @ "+DoubleToStr(Close[i],Digits) + ", @ " + TimeToStr(MyTime,TIME_SECONDS);
            if (Bars>LastAlertBar && i==AlertBar)
              {
               LastAlertBar=Bars;
               if (StrongBuySellAlerts) DoAlerts(Msg,Subj,SoundAlertFileLong);
              }
            LastAlert=1; //Last trend Alert was Up Trend Buy Alert
//----
            if (Show_SignalArrows)//BUY
              {
               CreateText(prefix+"En"+SigCounter,0," B",10,"Arial Bold",BuyArrowColor,Time[i],Low[i]-SignalArrowSpacer(),false);
               SigCounter++;
              }
            //Print("Text: " + TimeToStr(Time[i],TIME_MINUTES) + ", High: " + High[i]);
           }
         
         //strong sell alert:
         else if  (Signal2=="Strong Sell" && Signal4=="Strong Down" && LastAlert!=2)
              {
               if (SendTimeInfoAsTimeLocal) MyTime=TimeLocal(); else if (!SendTimeInfoAsTimeLocal) MyTime=TimeCurrent();
               Msg=Subj + " (Trend: "+Signal4+")  @ "+DoubleToStr(Close[i],Digits) + ", @ " + TimeToStr(MyTime,TIME_SECONDS);
               if (Bars>LastAlertBar && i==AlertBar)
                 {
                  LastAlertBar=Bars;
                  if(StrongBuySellAlerts) DoAlerts(Msg,Subj,SoundAlertFileShort);
                 }
               LastAlert=2; //Last trend Alert was Down Trend Buy Alert
               if (Show_SignalArrows)//SELL
                 {
                  CreateText(prefix+"En"+SigCounter,0," S",10,"Arial Bold",SellArrowColor,Time[i],High[i]+SignalArrowSpacer(),false);
                  SigCounter++;
                 }
               //Print("Text: " + TimeToStr(Time[i],TIME_MINUTES) + ", High: " + High[i]);
              }
            //else if ((LastAlert==1 || LastAlert==2) && Signal2=="Caution !")
              
              //overbought/oversold alert:
              else if ((LastAlert==1 || LastAlert==2) && (Signal2=="Caution - Overbought !" || Signal2=="Caution - Oversold !"))
                 {
                  Subj=Symbol()+ ", " + TF2Str(Period()) +". Trend "+Signal2;//+". Trend Caution Alert!";
                  if (LastAlert==2) Subj=Symbol()+ ", " + TF2Str(Period()) +". Trend "+Signal2;//+". Trend Caution Alert!";
//----
                  if (SendTimeInfoAsTimeLocal) MyTime=TimeLocal(); else if (!SendTimeInfoAsTimeLocal) MyTime=TimeCurrent();
                  Msg=Subj + " @ "+DoubleToStr(Close[i],Digits) + ", @ " + TimeToStr(MyTime,TIME_SECONDS);
                  if (Bars>LastAlertBar && i==AlertBar)
                    {
                     LastAlertBar=Bars;
                     if (CautionAlerts) DoAlerts(Msg,Subj,SoundAlertFileCautionAlert);
                    }
                  if (Show_SignalArrows)
                    {
                     if (LastAlert==1)//BUY
                       {
                        CreateText(prefix+"En"+SigCounter,0,"*",25,"Arial Bold",StrongBuyArrowCautionColor,Time[i],High[i]+SignalArrowSpacer(),false);
                        SigCounter++;
                       }
                     else//SELL
                       {
                        CreateText(prefix+"En"+SigCounter,0,"*",25,"Arial Bold",StrongSellArrowCautionColor,Time[i],Low[i]-SignalArrowSpacer(),false);
                        SigCounter++;
                       }
                    }
                  LastAlert=3; //Last trend Alert was Down Trend Buy Alert
                 } // End old Alerts
            //addition: new Alerts:
//
                
         //medium/weak alerts:
          else if ((Signal2=="Medium Buy" || Signal2=="Weak Buy") && Signal4=="Weak Up"  && LastAlert!=4)
               {
                if (SendTimeInfoAsTimeLocal) MyTime=TimeLocal(); else if (!SendTimeInfoAsTimeLocal) MyTime=TimeCurrent();
                Msg=Subj + " (Trend: "+Signal4+") @ "+DoubleToStr(Close[i],Digits) + ", @ " + TimeToStr(MyTime,TIME_SECONDS);
                if (Bars>LastAlertBar && i==AlertBar)
                 {
                  LastAlertBar=Bars;
                  if (MediumWeakBuySellAlerts) DoAlerts(Msg,Subj,SoundAlertFileLong);
                 }
                LastAlert=4; //Last trend Alert was weak up trend weak buy Alert
                }
                
          else if ((Signal2=="Medium Sell" || Signal2=="Weak Sell") && Signal4=="Weak Down" && LastAlert!=5)
               {
                if (SendTimeInfoAsTimeLocal) MyTime=TimeLocal(); else if (!SendTimeInfoAsTimeLocal) MyTime=TimeCurrent();
                Msg=Subj + " (Trend: "+Signal4+") @ "+DoubleToStr(Close[i],Digits) + ", @ " + TimeToStr(MyTime,TIME_SECONDS);
                if (Bars>LastAlertBar && i==AlertBar)
                 {
                  LastAlertBar=Bars;
                  if (MediumWeakBuySellAlerts) DoAlerts(Msg,Subj,SoundAlertFileShort);
                 }
                LastAlert=5; //Last trend Alert was weak down trend weak down Alert
                }
           //consolidation alerts:
          else if ( (Signal2=="Caution - Overbought !" || Signal2=="Caution - Oversold !") && Signal4=="Consolidation" && LastAlert!=6)
               {
                if (SendTimeInfoAsTimeLocal) MyTime=TimeLocal(); else if (!SendTimeInfoAsTimeLocal) MyTime=TimeCurrent();
                Msg=Subj + " (Trend: "+Signal4+") @ "+DoubleToStr(Close[i],Digits) + ", @ " + TimeToStr(MyTime,TIME_SECONDS);
                if (Bars>LastAlertBar && i==AlertBar)
                 {
                  LastAlertBar=Bars;
                  if (CautionAlerts) DoAlerts(Msg,Subj,SoundAlertFileCautionAlert);
                 }
                LastAlert=6; //Last trend Alert was weak down trend weak down Alert
                }
                 //end addition: new Alerts

//
      }//if(Show_TrendVisuals) //End If Show Trend Visuals
  /////////////////////////
        
     }//for(i=limit-1;i>=0;i--) //End For Loop 
     
   if(Show_TrendVisuals)
     {
      for(i=1;i<=12;i++) //Create the Visuals
        {
         switch(i)
           {
            /* old:
            case 1 : CreateLabel(prefix+"SIG"+i,Win,Signal,25,"Wingdings",TDI_col,1,80+SHIFT_Sideway,20+SHIFT_Up_Down); break;
            case 2 : CreateLabel(prefix+"SIG"+i,Win," @ "+DoubleToStr(BidCur,Digits),13,"Tahoma Narrow",TDI_col,1,125+SHIFT_Sideway,32+SHIFT_Up_Down); break;
            case 3 : CreateLabel(prefix+"SIG"+i,Win,Signal2,15,"Tahoma Narrow",TDI_col,1,120+SHIFT_Sideway,10+SHIFT_Up_Down); break;
            case 4 : CreateLabel(prefix+"SIG"+i,Win,"TDI Trend",15,"Tahoma Narrow",TDI_col2,1,120+SHIFT_Sideway,60+SHIFT_Up_Down); break;
            case 5 : CreateLabel(prefix+"SIG"+i,Win,Signal3,25,"Wingdings",TDI_col2,1,80+SHIFT_Sideway,60+SHIFT_Up_Down); break;
            case 6 : CreateLabel(prefix+"SIG"+i,Win,Signal4,15,"Tahoma Narrow",TDI_col2,1,115+SHIFT_Sideway,82+SHIFT_Up_Down); break;
            case 7 : CreateText(prefix+"SIG"+i,Win,"          68 ",7,"Tahoma Narrow",CadetBlue,TimeCur,70,true); break;
            case 8 : CreateText(prefix+"SIG"+i,Win,"          50 ",7,"Tahoma Narrow",CadetBlue,TimeCur,52,true); break;
            case 9 : CreateText(prefix+"SIG"+i,Win,"          32 ",7,"Tahoma Narrow",CadetBlue,TimeCur,34,true); break;
            case 10: Createline(prefix+"UPPERLINE", Win, 68, 68,DarkSlateGray); break;
            case 11: Createline(prefix+"LOWERLINE", Win, 50, 50,DarkSlateGray); break;
            case 12: Createline(prefix+"MEDLINE", Win, 32, 32,DarkSlateGray); break;
            */
            case 1 : CreateLabel(prefix+"SIG"+i,Win,Signal,TrendArrowFontSize,"Wingdings",TDI_col,1,80+SHIFT_Sideway,20+SHIFT_Up_Down); break;//red arrow
            case 2 : CreateLabel(prefix+"SIG"+i,Win," @ "+DoubleToStr(BidCur,Digits),TrendPriceFontSize,TypeFace,TDI_col,1,125+SHIFT_Sideway,32+SHIFT_Up_Down); break;//price
            case 3 : CreateLabel(prefix+"SIG"+i,Win,Signal2,TrendSignalsFontSize,TypeFace,TDI_col,1,120+SHIFT_Sideway,10+SHIFT_Up_Down); break;//sell trend signals
            case 4 : CreateLabel(prefix+"SIG"+i,Win,"TDI Trend",TrendSignalsFontSize,TypeFace,TDI_col2,1,120+SHIFT_Sideway,60+SHIFT_Up_Down); break;//tdi-trend writing
            case 5 : CreateLabel(prefix+"SIG"+i,Win,Signal3,TrendArrowFontSize,"Wingdings",TDI_col2,1,80+SHIFT_Sideway,60+SHIFT_Up_Down); break;//green arrow
            case 6 : CreateLabel(prefix+"SIG"+i,Win,Signal4,TrendSignalsFontSize,TypeFace,TDI_col2,1,115+SHIFT_Sideway,82+SHIFT_Up_Down); break;//buy trend signals
            //indicator levels:
            //case 7 : CreateText(prefix+"SIG"+i,Win,"          "+RSI_OverboughtLevel+" ",7,TypeFace,CadetBlue,TimeCur,70,true); break;
            case 7 : CreateText(prefix+"SIG"+i,Win,"          "+RSI_OverboughtLevel+" ",7,TypeFace,CadetBlue,TimeCur,RSI_OverboughtLevel,true); break;
            //case 8 : CreateText(prefix+"SIG"+i,Win,"          "+Level2+" ",7,TypeFace,CadetBlue,TimeCur,52,true); break;
            case 8 : CreateText(prefix+"SIG"+i,Win,"          "+Level2+" ",7,TypeFace,CadetBlue,TimeCur,Level2,true); break;
            //case 9 : CreateText(prefix+"SIG"+i,Win,"          "+RSI_OversoldLevel+" ",7,TypeFace,CadetBlue,TimeCur,34,true); break;
            case 9 : CreateText(prefix+"SIG"+i,Win,"          "+RSI_OversoldLevel+" ",7,TypeFace,CadetBlue,TimeCur,RSI_OversoldLevel,true); break;
            case 10: Createline(prefix+"UPPERLINE", Win, RSI_OverboughtLevel, RSI_OverboughtLevel,DarkSlateGray); break; 
            case 11: Createline(prefix+"LOWERLINE", Win, Level2, Level2,DarkSlateGray); break;
            case 12: Createline(prefix+"MEDLINE", Win, RSI_OversoldLevel, RSI_OversoldLevel,DarkSlateGray); break;            
           }
        }
     }//End if(Show_TrendVisuals)
     
   //If the indicator has just been loaded force a redraw as the Visual labels
   //don't update properly until the first tick after loading.   
   if (InitialLoad)
     {
      InitialLoad=false;
      if (Show_TrendVisuals) WindowRedraw();
     }
//----
   return(0);
  }
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void Createline(string objName, int Window, double start, double end, color clr)
  {
   ObjectDelete(objName);
   ObjectCreate(objName, OBJ_TREND,Window,0, start, Time[0], end);
   ObjectSet(objName, OBJPROP_COLOR, clr);
   ObjectSet(objName, OBJPROP_STYLE, 2);
   ObjectSet(objName, OBJPROP_RAY, false);
  }
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void CreateLabel(string LblName, int Window, string LblTxt, int FontSz, string FontName, color FontColor, int Corner, int xPos, int yPos)
  {
   if(ObjectFind(LblName)!=0) ObjectCreate(LblName, OBJ_LABEL, Window, 0, 0);
   ObjectSetText(LblName, LblTxt, FontSz, FontName, FontColor);
   ObjectSet(LblName, OBJPROP_CORNER, Corner);
   ObjectSet(LblName, OBJPROP_XDISTANCE, xPos);
   ObjectSet(LblName, OBJPROP_YDISTANCE, yPos);
  }
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void CreateText(string TextName, int Window, string LabelText, int FontSz, string FontName, color TextColor, datetime Time1, double Price1, bool deletez)
  {
   if (deletez) ObjectDelete(TextName);
   if(ObjectFind(TextName)!=0)
     {
      ObjectCreate(TextName, OBJ_TEXT, Window, Time1, Price1);
      ObjectSetText(TextName, LabelText, FontSz, FontName, TextColor);
     }
   else
      ObjectMove(TextName, 0, Time1, Price1);
  }
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
double StDev(double& Data[], int Per)
  {
   return(MathSqrt(Variance(Data,Per)));
  }
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
double Variance(double& Data[], int Per)
  {
   double sum, ssum;
   for(int i=0; i<Per; i++)
     {
      sum+=Data[i];
      ssum+=MathPow(Data[i],2);
     }
   return((ssum*Per - sum*sum)/(Per*(Per-1)));
  }
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
string TF2Str(int period)
  {
   switch(period)
     {
      case PERIOD_M1: return("M1");
      case PERIOD_M5: return("M5");
      case PERIOD_M15: return("M15");
      case PERIOD_M30: return("M30");
      case PERIOD_H1: return("H1");
      case PERIOD_H4: return("H4");
      case PERIOD_D1: return("D1");
      case PERIOD_W1: return("W1");
      case PERIOD_MN1: return("MN1");
     }
   return(Period());
  }
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void DoAlerts(string msgText,string eMailSub,string SoundAlertFile)
  {
    msgText="TDI Alerts v"+major+minor+": "+msgText;
   eMailSub="TDI Alerts v"+major+minor+": "+eMailSub;
   
   if (PopupAlerts)            Alert(msgText);
   if (SoundAlerts)            PlaySound(SoundAlertFile);
   if (eMailAlerts)            SendMail(eMailSub, msgText);
   if (PushNotificationAlerts) SendNotification(msgText);
  }
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
double SignalArrowSpacer()
  {
   switch(Period())
     {
      case PERIOD_M1: return(5*Point); break;
      case PERIOD_M5: return(10*Point); break;
      case PERIOD_M15: return(15*Point); break;
      case PERIOD_M30: return(20*Point); break;
      case PERIOD_H1: return(15*Point); break;
      case PERIOD_H4: return(40*Point); break;
      case PERIOD_D1: return(80*Point); break;
      case PERIOD_W1: return(150*Point); break;
      case PERIOD_MN1: return(200*Point); break;
     }
  }
//+------------------------------------------------------------------+