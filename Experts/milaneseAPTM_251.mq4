// it is against copyright to publish this EA outside of www.stevehopwoodforex.com
// input dialog modified by simplex, Feb. 2016 thanks Jurgen!!
#define  version "milaneseAPTM EA 2.51" //new build anOtherAllPairTradeManager 
#property strict
#property copyright "Copyright 2017, milanese"
#property link      "http://www.stevehopwoodforex.com/phpBB3/index.php"
#include <WinUser32.mqh>
#include <stdlib.mqh>
#define  NL    "\n"

#import "user32.dll"
int GetAncestor(int hWnd,int gaFlags);
int PostMessageA(int hWnd,int msg,int wParam,string IpWindow);
#import
#define MT4_WMCMD_ALL_HISTORY 33058
int windowHdlFound;
bool expertsDisabeled=false;
//Error reporting
#define  slm " stop loss modification failed with error "
#define  tpm " take profit modification failed with error "
#define  ocm " order close failed with error "
#define  odm " order delete failed with error "
#define  pcm " part close failed with error ";
string          Gap,ScreenMessage;
int             DisplayCount;
extern string gen=" ---- General Settings ---- ";      // ----------------------------------------------------------------------------
extern bool showUserDisplay                             = true;                     // show User Display            
extern bool showDisplayBox                              = true;                     // show Display Box             
extern bool useNewDisplayType                           = false;                     // use New Display Type          
extern color displayBoxBackgroundColour                 = clrDarkOliveGreen;         // display Box Background Colour
extern int DisplayX                                     = 20;                        // Display X                    
extern int DisplayY=0;                        // Display Y                    
extern int fontSize=14;                        // Font Size
extern string fontName="Arial";                  // Font Name                 
extern color colour=clrWhite;                  // Font Colour                    
extern double spacingtweek                              = 0.62;                     // spacing tweek
extern bool enableCloseAllButton                        = true;                     // enable Close All Button              
extern bool useFIFOforCloseAll                          = true;                     // use FIFO for Close All                
extern bool enableResetTPandSLButton                    = true;                     // enable Reset TP and SL Button          
extern bool NotDeletePendingOrdersWithCloseAll=false;                     // Not Delete Pending Orders With Close All
extern bool showAlerts=true;                     // show Alerts                        
extern bool DoNeverUseATR=false;                     // Never Use ATR
extern int checkMilliSeconds=1000;                        // check milliseconds
extern string special=" ---- Special Account Currency defined SL/TP BE Settings ---- ";      // ----------------------------------------------------------------------------
extern string special2=" ";                        // True will deactivate incompatible settings like ATR.
extern bool useAccountCurrValuesForSL_TP_BE_JS          = false;                     // use Account Currency Values For SL TP BE JS
extern double SLAccountCurr                             = 25;                        // SL Account Currency
extern double TPAccountCurr                             = 75;                        // TP Account Currency                
extern double BEProfitAccCurr                           = 4;                         // BE Profit Account Currency              
extern double JumpStepAccCurr                           = 15;                        // Jump Step Account Currency
extern double SLMinDistanceToPriceBEAccCurr             = 20;                        // SL min distance to price BE Account Currency
extern double SLMinDistanceToPriceJSAccCurr             = 25;                        // SL min distance to price JS Account Currency
extern string special4=" ---- Special Basket TP/SL Option in Account Currency ---- ";      // ----------------------------------------------------------------------------
extern bool UseBasketSLTP                               = false;                     // Use Basket SL TP             
extern bool UseBasketSLTPinAccountCurr                  = false;                     // Use Basket SL TP in Account Curr
extern double BasketSL                                  = 500;                       // Basket SL                
extern double BasketTP                                  = 750;                       // Basket TP                
extern bool UseBasketSLTPinPips                         = true;                      // Use Basket SL TP in Pips
extern double BasketSLinPips                            = 2500;                      // Basket SL in Pips          
extern double BasketTPinPips                            = 3500;                      // Basket TP in Pips          
extern string genmang=" ---- General Trade Management Settings ---- ";      // ----------------------------------------------------------------------------
extern bool ManageAllOpenTrades=true;                     // Manage All Open Trades (overwrites all others)
extern string genmang1a                                 = " ";                        // Set exclude Magic Number to true for excluding one Magic
extern string genmang1b                                 = " ";                        // Number using <Manage All Open Trades = true>
extern bool excludeMagicNumber                          = false;                     // exclude Magic Number 
extern int MagicNumberToExclude                         = 15;                        // Magic Number To Exclude
extern string genmang2=" ---- Manage Only By Selections ---- ";      // ----------------------------------------------------------------------------
extern bool ManageByMagicNumber                         = false;                     // Manage By Magic Number   
extern int MagicNumber                                  = 0;                         // Magic Number            
extern bool ManageByTicketNumber                        = false;                     // Manage By Ticket Number  
extern int TicketNumber                                 = 0;                         // Ticket Number           
extern bool ManageByOrderComment                        = false;                     // Manage By Order Comment  
extern string orderComment                              = "";                        // Order Comment        
extern bool ManageOnlyActualSymbol                      = false;                     // Manage Only Actual Symbol
extern string  PairsToExclude="";                                                    // Give here comma separated list of symbols to exclude like "AUDJPY,AUDUSD,CHFJPY,EURCHF"
extern string gen1= " ---- Do Not Manage Positions Opened Before Inputs ---- ";      // ----------------------------------------------------------------------------
extern bool doNotManagePositionsOpenedBefore            = false;                     // open date filter on & off
extern string doNotDate                                 = "";                        // open date YYYY.MM.DD
extern string gen3=" ---- SL & TP Settings ---- ";      // ----------------------------------------------------------------------------
extern bool SetInitialStopLoss=true;                     // Set Initial Stop Loss  
extern bool SetInintialSLforSELL                        = true;             // here you can exclude sell trades
extern bool SetInintialSLforBUY                         = true;             // here you can exclude buy trades
extern bool SetInitialSLtoForPendings=false;                     // Set Initial SL to For Pendings
extern bool useATRForStopLoss=true;                     // use ATR For Stop Loss (true overrides other settings)
extern ENUM_TIMEFRAMES atrForStopLossTF= PERIOD_D1;                  // ATR For Stop Loss TF
extern double atrMultiplicatorForStopLoss= 1;                        // ATR Multiplicator For Stop Loss
extern int atrPeriodForStopLoss                         = 14;                        // ATR Period For StopLoss
extern double SL                                        = 50;                        // SL
extern string SLset2=" ---- MA as SL  Settings ---- ";      // ----------------------------------------------------------------------------
extern string SLset3                                    = " ";                        // This will set the MA as SL and disable all
extern string SLset4                                    = " ";                        // incompatible settings like ATR-SL, Set BE and Jump.
extern bool useMAasSL                                   = false;                     // use MA as SL
extern ENUM_TIMEFRAMES MaTimeFrame                      = PERIOD_H4;                 // MA Time Frame
extern int MaPeriod                                     = 55;                        // MA Period
extern ENUM_MA_METHOD MaMethod                          = MODE_SMA;                  // MA Method
extern ENUM_APPLIED_PRICE MaAppliedPrice                = PRICE_CLOSE;               // MA Applied Price
extern int MaShift                                      = 1;                         // MA Shift
extern string gen3a=" ---- TP Settings ---- ";      // ----------------------------------------------------------------------------
extern bool SetInitialTakeProfit                        = true;                      // Set Initial TP
extern bool SetInitialTPtoForPendings                   = false;                     // Set Initial TP to For Pendings
extern bool SetInintialTPforSELL=true;                // here you can exclude sell trades
extern bool SetInintialTPforBUY=true;               // here you can exclude buy trades
extern bool useATRForTakeProfit=true;                     // use ATR for TP (true overrides other settings)
extern ENUM_TIMEFRAMES atrForTakeProfitTF               = PERIOD_D1;                  // ATR For TP TF
extern double atrMultiplicatorForTakeProfit             = 3.0;                        // ATR Multiplicator For TP
extern int atrPeriodForTakeProfit                       = 14;                         // ATR Period For TP
extern double TP                                        = 150;                        // TP
extern string partSet=" ---- Partial Close Inputs ---- ";      // ----------------------------------------------------------------------------
extern bool PartCloseEnabled                            = false;                     // partial close enabled
extern double PartClosePercent                          = 10;                        // partial close percent
extern bool PartCloseWithBE                             = false;                     // partial close with BE
extern bool PartCloseAsFirstTP                          = true;                      // partial close as First TP
extern bool SetBEonPartCloseFirstTP                     = false;                     // Set BE on partial close First TP
extern bool useATRForPartClosePips=true;                     // use ATR for partial close (true overrides other settings)
extern ENUM_TIMEFRAMES atrForPartClosePipsTF            = PERIOD_D1;                  // ATR for partial close pips TF
extern double atrMultiplicatorForPartClosePips          = 0.5;                        // ATR multiplicator For partial close pips
extern int atrPeriodForPartClosePips                    = 14;                        // ATR period For partial close pips
extern double PartCloseFirstTpPips                      = 25;                        // partial close First TP pips
extern string bejsSet=" ---- BE & JS Inputs ---- ";      // ----------------------------------------------------------------------------
extern bool Use_SetBEAndJump                            = true;                     // Use Set BE And Jump
extern bool MoveSLOnlyIfWin                             = true;                     // move SL only if in profit
extern double BEProfit                                  = 4;                        // BE Profit
extern double JumpStep=15;                        // Jump Step
extern bool useATRForSLMinDistanceToPrice=true;                     // use ATR for SL min distance (true overrides)
extern ENUM_TIMEFRAMES atrForSLMinDistanceToPriceTF     = PERIOD_D1;                  // ATR For SL Min Distance To Price TF
extern double atrMultiplicatorForSLMinDistanceToPriceBE = 1;                          // ATR Multiplicator For SL Min Distance To Price BE
extern double atrMultiplicatorForSLMinDistanceToPriceJS = 1.5;                        // ATR Multiplicator For SL Min Distance To Price JS
extern int atrPeriodForSLMinDistanceToPrice             = 14;                         // ATR Period For SL Min Distance To Price
extern double SLMinDistanceToPriceBE                    = 45;                         // SL Min Distance To Price BE
extern double SLMinDistanceToPriceJS                    = 65;                         // SL Min Distance To Price JS
extern string bejsSet2=" ---- Note TP will only be removed if SL is in profit ---- ";      // ----------------------------------------------------------------------------
extern bool useRemoveTPifPriceIsNearTP                  = false;                     // use Remove TP if Price Is Near TP
extern double RemoveTPdistanceToTPpips                  = 25;                        // Remove TP distance To TP pips
extern string ClSets=" ---- Close at a defined time Inputs (all using BrokerTime) ---- ";      // ----------------------------------------------------------------------------
extern bool UseCloseAllAtDefinedTime                    = false;                     // Use Close All At Defined Time
extern int CloseHour                                    = 21;                        // Close Hour  
extern int CloseMinute                                  = 15;                        // Close Minute
extern string fridayClSet=" ---- FridayClose Inputs (uses BrokerTime) ---- ";      // ----------------------------------------------------------------------------
extern bool UseCloseFriday                              = false;                     // Use Close Friday
extern int FridayCloseHour                              = 21;                        // Friday Close Hour  
extern int FridayCloseMinute                            = 15;

bool    UseMarginCalculatedSLTPBEJSValues=false;
double  SLMarginMultipler=2;
double  TPMarginMultipler=4;
double  BEMarginMultipler=0.5;
double  JumpStepMarginMultipler=1;
double  SLMinDistanceToPriceBEMarginMultipler=2;
double  SLMinDistanceToPriceJSMarginMultipler=2;
double  SLMinDistanceToPrice=45;
double MASLMinDistanceToPrice=20;
double minDistanceSLTP=1;
int             a=0;
bool   debugTheEA=false;
bool     moveSLonlyIfInTradeDirection=true;
double          ask=0;
double          bid=0;

string         BE_Value,symbol;
int             eDigits;
bool ForceTradeClosureBasket=false;
bool   disableExpertsAfterClose=true;
string          CommentOfOrderInitial="";
double factor,adr;
bool TradeHasPartClosed=false;
int TicketNo=-1;
double digiter;
string           ButtonOne="Button";            // Button name
string           ButtonTwo="ButtonTwo";            // Button name
ENUM_BASE_CORNER InpCorner=CORNER_RIGHT_UPPER;// Chart corner for anchoring
string           InpFont="Arial";             // Font
int              InpFontSize=12;              // Font size
color            InpColor=clrWhite;           // Text color
color            InpBackColor=clrRed; // Background color
color            InpBackColor1=clrDarkOliveGreen; // Background color
color            InpBorderColor=clrAntiqueWhite;      // Border color
bool             InpState=false;              // Pressed/Released
bool             InpBack=false;               // Background object
bool             InpSelection=false;          // Highlight to move
bool             InpHidden=true;              // Hidden in the object list
long             InpZOrder=0;                 // Priority for mouse click
string            String;
int               SymbolQTY;
string suffix;
string ExcludedSymbol[56];
bool debug=false;
int SymbolQTY()
  {
   int i=0;
   int j=0;
   int qty=0;

   while(i>-1)
     {
      i=StringFind(String,",",j);
      if(i>-1)
        {
         qty++;
         j=i+1;
        }
     }
   return(qty);
  }
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
int OnInit(void)
  {
   while(IsConnected()==false)
     {
      Comment("APTM"+":Waiting for MT4 connection...");

      Sleep(1000);
     }//while (IsConnected()==false)
   if(checkMilliSeconds==0) checkMilliSeconds=50;
   if(UseMarginCalculatedSLTPBEJSValues==true)useAccountCurrValuesForSL_TP_BE_JS=true;
   if(ManageAllOpenTrades==true)
     {
      ManageByMagicNumber=false;
      ManageByOrderComment=false;
      ManageByTicketNumber=false;
      ManageOnlyActualSymbol=false;
     }
   if(MoveSLOnlyIfWin==false)
     {

      PartCloseWithBE=false;
      SetBEonPartCloseFirstTP=false;
      Alert("APTM:Note BE with PartClose set to false, as you are using'MoveSLOnlyIfWin==false'");
     }
   if(useMAasSL==true)
     {

      Use_SetBEAndJump=false;
      SetInitialStopLoss=false;
      useATRForStopLoss=false;
      PartCloseWithBE=false;

     }
   if(useAccountCurrValuesForSL_TP_BE_JS==true)
     {
      DoNeverUseATR=true;
      MoveSLOnlyIfWin=true;
      PartCloseEnabled=false;

     }
   CommentOfOrderInitial=orderComment;
   if(IsDllsAllowed()==false)
     {
      Alert("APTM"+": *.dll import must be allowed!");
     }
   windowHdlFound=GetAncestor(WindowHandle(Symbol(),Period()),3);

   if(!IsExpertEnabled())
     {
      Alert("APTM"+": Please enable \"Expert Advisors\" in the top toolbar of Metatrader to run this EA");
     }
   if(!IsTradeAllowed())
     {
      Alert("APTM"+": Trade is not allowed. EA cannot run. Please check \"Allow live trading\" in the \"Common\" tab of the EA properties window");
     }

   if(doNotManagePositionsOpenedBefore==true)
     {
      if(doNotDate!="")
        {
         if(showAlerts==true) Alert("APTM"+": EA will not manage orders opened before : ",doNotDate);
        }
      else doNotManagePositionsOpenedBefore=false;

     }
   String=PairsToExclude;
   if(StringSubstr(String,StringLen(String)-1)!=",") String=StringConcatenate(String,",");
   EnableAllHistory();
   ChartSetInteger(ChartID(),CHART_FOREGROUND,false);
   EventSetMillisecondTimer(checkMilliSeconds);
   OnTimer();

   return(INIT_SUCCEEDED);
  }
//+------------------------------------------------------------------+
//| expert deinitialization function                                 |
//+------------------------------------------------------------------+

void OnDeinit(const int reason)
  {
   Comment("");
   EventKillTimer();
   removeAllObjects();
   ObjectDelete("messageBox");
   ObjectDelete(0,ButtonOne);
   ObjectDelete(0,ButtonTwo);
   if(showAlerts==true) Alert(__FUNCTION__,"_UninitReason = ",getUninitReasonText(_UninitReason));
  }
//+------------------------------------------------------------------+
//| expert start function                                            |
//+------------------------------------------------------------------+
void OnTick()
  {
  
   

   if(debug==true || ManageOnlyActualSymbol==true) OnTimer();

  }
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void OnTimer()
  {
   factor=0;
   TicketNo=-1;
   int lenght = 150;
   int height = 45;
   if(a==0)
     {
      Comment("Waiting for Initializing...");
      Sleep(2000);
      if(showUserDisplay==true)
        {
         DisplayUserFeedback();
        }

      a=1;

     }
   if(enableCloseAllButton)
     {

      if(ObjectFind(ButtonOne)<0)
        {
         if(!ButtonCreate(0,ButtonOne,0,200,80,lenght,height,InpCorner,"CloseALL!",InpFont,InpFontSize,InpColor,InpBackColor,InpBorderColor,InpState,InpBack,InpSelection,InpHidden,InpZOrder))
           {
            Print("APTM:ButtonCreate Error 34562");
           }
        }

        }else {
      ObjectDelete(0,ButtonOne);
     }
   if(enableResetTPandSLButton)
     {

      if(ObjectFind(ButtonTwo)<0)
        {
         if(!ButtonCreate(0,ButtonTwo,0,200,120,lenght,height,InpCorner,"Reset SL&TP!",InpFont,InpFontSize,InpColor,InpBackColor1,InpBorderColor,InpState,InpBack,InpSelection,InpHidden,InpZOrder))
           {
            Print("APTM:ButtonCreate Error 34569");
           }
        }

        }else {
      ObjectDelete(0,ButtonTwo);
     }
   if(showUserDisplay==true)
     {
      DisplayUserFeedback();
     }

   for(int cc=OrdersTotal()-1; cc>=0; cc--)
     {

      if(!OrderSelect(cc,SELECT_BY_POS,MODE_TRADES)) continue;
      if((ManageByMagicNumber==true) && (OrderMagicNumber()!=MagicNumber)) continue;
      if((ManageByTicketNumber==true) && (OrderTicket()!=TicketNumber))continue;
      if((ManageOnlyActualSymbol==true) && (OrderSymbol()!=Symbol()))continue;
      if((ManageByOrderComment==true) && ((OrderComment()!=orderComment) || (OrderComment()!=CommentOfOrderInitial)))continue;
      if((excludeMagicNumber==true) && (OrderMagicNumber()==MagicNumberToExclude)) continue;
      if(doNotManagePositionsOpenedBefore==true)
        {
         string var1=TimeToStr(OrderOpenTime(),TIME_DATE);

         if(StrToTime(var1)<StrToTime(doNotDate)) continue;
        }
      symbol=OrderSymbol();
      eDigits=int(MarketInfo(OrderSymbol(),MODE_DIGITS));
      ask = NormalizeDouble(MarketInfo(OrderSymbol(), MODE_ASK),eDigits);
      bid = NormalizeDouble(MarketInfo(OrderSymbol(), MODE_BID),eDigits);
      factor=GetPipFactor(OrderSymbol());
      TicketNo=OrderTicket();
      suffix = StringSubstr(Symbol(),6,4);
      int qty=SymbolQTY();


   int i=0;int j=0;
   for(int k=0; k<qty; k++)
     {
      i=StringFind(String,",",j);
      if(i>-1)
        {
         ExcludedSymbol[k] = StringSubstr(String, j,i-j);
         ExcludedSymbol[k] = StringTrimLeft(ExcludedSymbol[k]);
         ExcludedSymbol[k] = StringTrimRight(ExcludedSymbol[k]);
         ExcludedSymbol[k] = StringConcatenate(ExcludedSymbol[k], suffix);
         j=i+1;
        }
     }
      for(int d=0;d<SymbolQTY();d++)
              {
               if(OrderSymbol()==ExcludedSymbol[d])
                 {
                 return;
                 }
              }
      //now we go through the trades checking what we have to do..
      if(SetInitialStopLoss==true)
        {
         if(NormalizeDouble(OrderStopLoss(),eDigits)==0) SetInitialSL(TicketNo,factor,eDigits);
        }
      if(SetInitialTakeProfit==true)
        {
         if(useRemoveTPifPriceIsNearTP==true && OrderType()==OP_BUY && OrderStopLoss()<=OrderOpenPrice())
           {
            if(NormalizeDouble(OrderTakeProfit(),eDigits)==0) SetInitialTP(TicketNo,factor,eDigits);
           }
         if(useRemoveTPifPriceIsNearTP==true && OrderType()==OP_SELL && OrderStopLoss()>=OrderOpenPrice())
           {
            if(NormalizeDouble(OrderTakeProfit(),eDigits)==0) SetInitialTP(TicketNo,factor,eDigits);
           }
         if(useRemoveTPifPriceIsNearTP==false)
           {
            if(NormalizeDouble(OrderTakeProfit(),eDigits)==0) SetInitialTP(TicketNo,factor,eDigits);
           }

        }
      if(useRemoveTPifPriceIsNearTP==true)
        {
         if(OrderType()==OP_BUY && OrderStopLoss()>OrderOpenPrice() && ask>(OrderTakeProfit()-RemoveTPdistanceToTPpips/factor) && NormalizeDouble(OrderTakeProfit(),eDigits)!=0)
           {
            bool result=OrderModify(TicketNo,OrderOpenPrice(),OrderStopLoss(),0,OrderExpiration(),CLR_NONE);
           }
         if(OrderType()==OP_SELL && OrderStopLoss()<OrderOpenPrice() && bid<(OrderTakeProfit()+RemoveTPdistanceToTPpips/factor) && NormalizeDouble(OrderTakeProfit(),eDigits)!=0)
           {
            bool result=OrderModify(TicketNo,OrderOpenPrice(),OrderStopLoss(),0,OrderExpiration(),CLR_NONE);
           }
        }
      if(useMAasSL==true)
        {
         SetInitialMASL(TicketNo,factor,eDigits);
        }
      if(useMAasSL==true)
        {
         if(NormalizeDouble(OrderStopLoss(),eDigits)==0) SetInitialMASL(TicketNo,factor,eDigits);
        }
      if(Use_SetBEAndJump)
        {
         if(MoveSLOnlyIfWin==true)
           {
            SetBEAndJump(TicketNo,factor,eDigits);
           }
         if(MoveSLOnlyIfWin==false)
           {
            DoJS(TicketNo,factor,eDigits);
           }

        }
      if(PartCloseEnabled==true)
        {
         if(PartCloseAsFirstTP==true)
           {
            doPartCloseFirstTP(TicketNo,factor,eDigits);
           }
        }
      if(UseCloseFriday==true && DayOfWeek()==5)
        {
         CloseFriday(TicketNo,factor,eDigits);
        }
      if(UseCloseAllAtDefinedTime==true)
        {
         CloseDefinedTime(TicketNo,factor,eDigits);
        }
      if(UseBasketSLTP==true && UseBasketSLTPinAccountCurr==true)
        {
         double ProfitPair=GetProfitPair(Symbol());
         if(NormalizeDouble(BasketTP,2)!=0)
           {
            if(ProfitPair>=BasketTP) CloseAll();
           }
         if(NormalizeDouble(BasketSL,2)!=0)
           {
            if(ProfitPair<=-1*(BasketSL)) CloseAll();
           }

        }
      if(UseBasketSLTP==true && UseBasketSLTPinPips==true)
        {
         double ProfitPair=GetProfitPairPip(Symbol());
         if(NormalizeDouble(BasketTPinPips,1)!=0)
           {
            if(ProfitPair>=BasketTPinPips) CloseAll();
           }
         if(NormalizeDouble(BasketSLinPips,1)!=0)
           {
            if(ProfitPair<=-1*(BasketSLinPips)) CloseAll();
           }

        }

     }
  }
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void DisplayUserFeedback()
  {
   if(showUserDisplay==false)
     {
      ObjectDelete("messageBox");
      return;
     }
   if(showDisplayBox==true)
     {
      RectLabelCreate();
     }
   else ObjectDelete("messageBox");
   ScreenMessage="";
   DisplayCount=1;
   removeAllObjects();
   ScreenMessage="";
//ScreenMessage = StringConcatenate(ScreenMessage,Gap + NL);
   SM(NL);

   SM("Updates to be found at http://www.stevehopwoodforex.com"+NL);
   SM(version);
   SM(" Copyright 2017, by milanese"+NL);
   if(useNewDisplayType==true)
     {
      SM("Broker time = "+TimeToStr(TimeCurrent(),TIME_DATE|TIME_SECONDS)+NL);
      SM("Local time = "+TimeToStr(TimeLocal(),TIME_DATE|TIME_SECONDS)+NL);
      SM("GMT time = "+TimeToStr(TimeGMT(),TIME_DATE|TIME_SECONDS)+NL);
        }else{
      SM("----------------------------------------------------------------------------------------------------------------------------------------------------------------"+NL);
      SM("Broker time = "+TimeToStr(TimeCurrent(),TIME_DATE|TIME_SECONDS)+" Local time = "+TimeToStr(TimeLocal(),TIME_DATE|TIME_SECONDS)+" GMT time = "+TimeToStr(TimeGMT(),TIME_DATE|TIME_SECONDS)+NL);
      SM("----------------------------------------------------------------------------------------------------------------------------------------------------------------"+NL);
     }
   if(ManageAllOpenTrades==true)
     {
      SM("APTM will manage all open trades.."+NL);
      if(excludeMagicNumber==true)
         SM("excluding MagicNumber:"+IntegerToString(MagicNumberToExclude)+NL);
     }
     if(PairsToExclude!="")
     {
      SM("APTM will exlude: "+PairsToExclude+NL);
     }
   if(ManageByMagicNumber==true)
     {
      SM("APTM will manage open trades with MagicNumber: "+IntegerToString(MagicNumber)+NL);
     }
   if(ManageByOrderComment==true)
     {
      SM("APTM will manage open trades with OrderComment: "+orderComment+NL);
     }
   if(ManageByTicketNumber==true)
     {
      SM("APTM will manage Ticket Number: "+IntegerToString(TicketNumber)+NL);
     }
   if(ManageOnlyActualSymbol==true)
     {
      SM("APTM will manage open Trades with Symbol: "+Symbol()+NL);
     }
   if(useMAasSL==true)
     {
      SM("APTM uses MA for SL"+NL);
      if(ManageOnlyActualSymbol==true)
        {
         SM("Your selected MA is at: "+DoubleToStr(MAstopValue(Symbol()),Digits)+NL);
        }
     }
   if(useAccountCurrValuesForSL_TP_BE_JS==true)
     {
      SM("APTM uses SL/TP & BE/JS SLMinDistance Values in AccountCurrency!"+NL);
      SM("YourAccountCurrency is: "+AccountCurrency()+NL);

      SM("YourAccountLeverage is: 1:"+DoubleToStr(AccountLeverage(),0)+NL);

     }
   if(UseBasketSLTP==true)
     {
      SM("Basket TP&SL are used"+NL);
      if(UseBasketSLTPinAccountCurr==true)
        {
         SM("Basket SL is: "+DoubleToStr(BasketSL,2)+AccountCurrency()+NL);
         SM("Basket TP is: "+DoubleToStr(BasketTP,2)+AccountCurrency()+NL);
        }
      if(UseBasketSLTPinPips==true)
        {
         SM("Basket SL is: "+DoubleToStr(BasketSLinPips,2)+NL);
         SM("Basket TP is: "+DoubleToStr(BasketTPinPips,2)+NL);
         SM("Basket-Profit in Pips is: "+DoubleToStr(GetProfitPairPip(Symbol()),2)+NL);

        }
     }
   if(useNewDisplayType==false)
     {
      SM("----------------------------------------------------------------------------------------------------------------------------------------------------------------"+NL);
     }
   if(DoNeverUseATR==true)
     {

      SM("All automatic calculating ATR settings are deactivated, manual inputs are used"+NL);

     }
   if(DoNeverUseATR==false)
     {

      if(useATRForStopLoss==true && SetInitialStopLoss==true)
        {
         SM("Initial-SL are calculated by ATR(TF:"+MinutesToTFString(atrForStopLossTF)+" Period:"+IntegerToString(atrPeriodForStopLoss)+" MP:"+DoubleToStr(atrMultiplicatorForStopLoss,1)+")"+NL);

        }
      if(useATRForTakeProfit==true && SetInitialTakeProfit==true)
        {
         SM("Initial-TP are calculated by ATR(TF:"+MinutesToTFString(atrForTakeProfitTF)+" Period:"+IntegerToString(atrPeriodForTakeProfit)+" MP:"+DoubleToStr(atrMultiplicatorForTakeProfit,1)+")"+NL);

        }
      if(useATRForSLMinDistanceToPrice==true && Use_SetBEAndJump==true)
        {
         SM("SLMinDistance is calculated by ATR(TF:"+MinutesToTFString(atrForSLMinDistanceToPriceTF)+" Period:"+IntegerToString(atrPeriodForSLMinDistanceToPrice)+" MP:"+DoubleToStr(atrMultiplicatorForSLMinDistanceToPriceJS,1)+")"+NL);

        }
      if(useATRForPartClosePips==true && PartCloseEnabled==true && PartCloseAsFirstTP==true)
        {
         SM("PartClosePipsForFirstTP are calculated by ATR(TF:"+MinutesToTFString(atrForPartClosePipsTF)+" Period:"+IntegerToString(atrPeriodForPartClosePips)+" MP:"+DoubleToStr(atrMultiplicatorForPartClosePips,1)+")"+NL);

        }
     }

   if(PartCloseEnabled==true && PartCloseAsFirstTP==true)
     {
      if(SetBEonPartCloseFirstTP==true)
        {
         SM("BE will set with first TP part-close"+NL);
        }
      SM("PartClose as first TP is enabled, PartClose % are: "+DoubleToString(PartClosePercent,1)+NL);

     }
   if(PartCloseEnabled==true && PartCloseWithBE==true)
     {
      SM("PartClose with setting BE is enabled, PartClose % are: "+DoubleToString(PartClosePercent,1)+NL);

     }
   if(useNewDisplayType==false)
     {
      SM("----------------------------------------------------------------------------------------------------------------------------------------------------------------"+NL);
     }
   if(Use_SetBEAndJump==true && MoveSLOnlyIfWin==true)
     {

      SM("APTM will set BE and move the SL in Win"+NL);
     }
   if(Use_SetBEAndJump==true && MoveSLOnlyIfWin==false)
     {

      SM("APTM will will move SL always to SLMinDistance"+NL);
     }
   if(useNewDisplayType==false)
     {
      SM("----------------------------------------------------------------------------------------------------------------------------------------------------------------"+NL);
     }
   if(doNotManagePositionsOpenedBefore==true)
     {
      SM("APTM will not manage orders opened before : "+doNotDate+NL);
     }
   if(UseCloseFriday==true)
     {
      if(useNewDisplayType==false)
        {
         SM("----------------------------------------------------------------------------------------------------------------------------------------------------------------"+NL);
        }
      SM("APTM will close all open Trades Friday at : "+IntegerToString(FridayCloseHour)+":"+IntegerToString(FridayCloseMinute)+" BrokerTime"+NL);
     }
   if(UseCloseAllAtDefinedTime==true)
     {
      if(useNewDisplayType==false)
        {
         SM("----------------------------------------------------------------------------------------------------------------------------------------------------------------"+NL);
        }
      SM("APTM will close all open Trades  at : "+IntegerToString(CloseHour)+":"+IntegerToString(CloseMinute)+" BrokerTime"+NL);
     }
   if(useNewDisplayType==false)
     {
      SM("----------------------------------------------------------------------------------------------------------------------------------------------------------------"+NL);
     }
   SM("Account Equity is: "+DoubleToStr(AccountEquity(),2)+AccountCurrency()+NL);
   if(ManageOnlyActualSymbol==false)
     {
      SM("Account Profit is: "+DoubleToStr((AccountEquity()-AccountBalance()),2)+AccountCurrency()+NL);
        }else{

      SM("PairProfit for managed Pair: "+DoubleToStr(GetProfitPair(Symbol()),2)+AccountCurrency()+NL);
     }
   if(useNewDisplayType==false)
     {
      SM("----------------------------------------------------------------------------------------------------------------------------------------------------------------"+NL);
     }
   if(OrdersTotal()!=0)
     {
      SM("Count Active Buys="+IntegerToString(CountBuys())+" Count BuyLot="+DoubleToStr(CountBuyLot(),2)+NL);
      SM("Count Active Sells="+IntegerToString(CountSells())+" Count SellLot="+DoubleToStr(CountSellLot(),2)+NL);
     }
   if(OrdersTotal()==0)
     {
      SM("No Open Trades found, waiting for work!!"+NL);
     }
   Comment(ScreenMessage);

  }//void DisplayUserFeedback()
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void SM(string message)
  {
   if(useNewDisplayType==true)
     {
      DisplayCount++;
      Display(message);
     }
   else  ScreenMessage=StringConcatenate(ScreenMessage,Gap,message);
  }//End void SM()
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
int CountSells()
  {
   int nOrderCount=0;
   for(int i=OrdersTotal()-1; i>=0; i--)
     {
      if(!OrderSelect(i,SELECT_BY_POS)) continue;
      if(ManageOnlyActualSymbol==true && OrderSymbol()!=Symbol()) continue;
      if((excludeMagicNumber==true) && (OrderMagicNumber()==MagicNumberToExclude)) continue;
      if(ManageByMagicNumber==true)
        {
         if(OrderMagicNumber()!=MagicNumber)continue;
        }
      if(ManageByOrderComment==true)
        {
         if(OrderComment()!=orderComment)continue;

        }

      if(OrderType()==OP_SELL)

         nOrderCount++;
     }
   return(nOrderCount);
  }
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
int CountBuys()
  {
   int nOrderCount=0;
   for(int i=OrdersTotal()-1; i>=0; i--)
     {
      if(!OrderSelect(i,SELECT_BY_POS)) continue;
      if(ManageOnlyActualSymbol==true && OrderSymbol()!=Symbol()) continue;
      if((excludeMagicNumber==true) && (OrderMagicNumber()==MagicNumberToExclude)) continue;
      if(ManageByMagicNumber==true)
        {
         if(OrderMagicNumber()!=MagicNumber)continue;
        }
      if(ManageByOrderComment==true)
        {
         if(OrderComment()!=orderComment)continue;

        }

      if(OrderType()==OP_BUY)

         nOrderCount++;
     }
   return(nOrderCount);
  }
//+-------------------
string getUninitReasonText(int reasonCode)
  {
   string text="";
//---
   switch(reasonCode)
     {
      case REASON_ACCOUNT:
         text="Account was changed";break;
      case REASON_CHARTCHANGE:
         text="Symbol or timeframe was changed";break;
      case REASON_CHARTCLOSE:
         text="Chart was closed";break;
      case REASON_PARAMETERS:
         text="Input-parameter was changed";break;
      case REASON_RECOMPILE:
         text="Program "+__FILE__+" was recompiled";break;
      case REASON_REMOVE:
         text="Program "+__FILE__+" was removed from chart";break;
      case REASON_TEMPLATE:
         text="New template was applied to chart";break;
      default:text="Another reason";
     }
//---
   return text;
  }
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void disableEA()
  {

   if(IsExpertEnabled()==true)
     {
      if(windowHdlFound>0) PostMessageA(windowHdlFound,WM_COMMAND,33020,0);

      Sleep(3000);
      if(IsExpertEnabled()==false && expertsDisabeled==false)
        {

         Alert("EquitySL/TP"+": All EAs were disabled at "+TimeToStr(TimeLocal()));
         expertsDisabeled=true;
        }
      if(IsExpertEnabled()==true && expertsDisabeled==true)
        {

         Alert("EquitySL/TP"+" was unable to disable all EAs at "+TimeToStr(TimeLocal()));
        }
     }

  }
//+------------------------------------------------------------------+
//| getPipFactor()                                                   |
//+------------------------------------------------------------------+
int GetPipFactor(string Xsymbol)
  {
   static const string factor1000[]={"SEK","TRY","ZAR","MXN"};
   static const string factor100[]         = {"JPY","XAG","SILVER","BRENT","WTI"};
   static const string factor10[]          = {"XAU","GOLD","SP500","US500Cash","US500","Bund"};
   static const string factor1[]           = {"UK100","WS30","DAX30","NAS100","CAC40","FRA40","GER30","ITA40","EUSTX50","JPN225","US30Cash","US30"};

   int xFactor=10000;       // correct xFactor for most pairs
   if(MarketInfo(Xsymbol,MODE_DIGITS)<=1) xFactor=1;
   else if(MarketInfo(Xsymbol,MODE_DIGITS)==2) xFactor=10;
   else if(MarketInfo(Xsymbol,MODE_DIGITS)==3) xFactor=100;
   else if(MarketInfo(Xsymbol,MODE_DIGITS)==4) xFactor=1000;
   else if(MarketInfo(Xsymbol,MODE_DIGITS)==5) xFactor=10000;
   else if(MarketInfo(Xsymbol,MODE_DIGITS)==6) xFactor=100000;
   else if(MarketInfo(Xsymbol,MODE_DIGITS)==7) xFactor=1000000;
   for(int j=0; j<ArraySize(factor1000); j++)
     {
      if(StringFind(Xsymbol,factor1000[j])!=-1) xFactor=1000;
     }
   for(int j=0; j<ArraySize(factor100); j++)
     {
      if(StringFind(Xsymbol,factor100[j])!=-1) xFactor=100;
     }
   for(int j=0; j<ArraySize(factor10); j++)
     {
      if(StringFind(Xsymbol,factor10[j])!=-1) xFactor=10;
     }
   for(int j=0; j<ArraySize(factor1); j++)
     {
      if(StringFind(Xsymbol,factor1[j])!=-1) xFactor=1;
     }

   return (xFactor);
  }
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void SetInitialSL(int ticket,double Xfactor,int Xdigits)
  {
   bool modify=false;
   double NewStop=0;
   bool selectedOrder=OrderSelect(ticket,SELECT_BY_TICKET,MODE_TRADES);
   if(selectedOrder==false) return;//in case the trade closed
   ask = NormalizeDouble(MarketInfo(OrderSymbol(), MODE_ASK),Xdigits);
   bid = NormalizeDouble(MarketInfo(OrderSymbol(), MODE_BID),Xdigits);
   if((OrderType()==OP_BUY) && (SetInintialSLforBUY==true))
     {

      NewStop=CalculateSLBuy(ticket,Xfactor,Xdigits);

      modify=true;

     }//if (OrderType() == OP_BUY)
   if(SetInitialSLtoForPendings==true)
     {

      if(((OrderType()==OP_BUYLIMIT) || (OrderType()==OP_BUYSTOP)) && (SetInintialSLforBUY==true))
        {

         NewStop=CalculateSLBuy(ticket,Xfactor,Xdigits);

         modify=true;

        }

      if(((OrderType()==OP_SELLLIMIT) || (OrderType()==OP_SELLSTOP)) && (SetInintialSLforSELL==true))
        {

         NewStop=CalculateSLSell(ticket,Xfactor,Xdigits);

         modify=true;

        }
     }
   if((OrderType()==OP_SELL) && (SetInintialSLforSELL==true))
     {

      NewStop=CalculateSLSell(ticket,Xfactor,Xdigits);

      modify=true;

     }//if (OrderType() == OP_SELL)

//Send the new stop loss 
   if(modify==true)
     {
      bool result=OrderModify(TicketNo,OrderOpenPrice(),NewStop,OrderTakeProfit(),OrderExpiration(),CLR_NONE);

      if(!result && OrderType()==OP_SELL)
        {
         NewStop=NewStop+(0.1/Xfactor);
         result=OrderModify(TicketNo,OrderOpenPrice(),NewStop,OrderTakeProfit(),OrderExpiration(),CLR_NONE);
         if(result==false)ReportError(" APTM ",slm);

        }//if (!result)
      if(!result && OrderType()==OP_BUY)
        {
         NewStop=NewStop-(0.1/Xfactor);
         result=OrderModify(TicketNo,OrderOpenPrice(),NewStop,OrderTakeProfit(),OrderExpiration(),CLR_NONE);
         if(result==false)ReportError(" APTM ",slm);

        }//if (!result)

     }

  }//void SetInitialSL()
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void SetInitialTP(int ticket,double Xfactor,int Xdigits)
  {
   bool modify=false;
   double NewTP=0;
   bool selectedOrder=OrderSelect(ticket,SELECT_BY_TICKET,MODE_TRADES);
   if(selectedOrder==false) return;//in case the trade closed
   ask = NormalizeDouble(MarketInfo(OrderSymbol(), MODE_ASK),Xdigits);
   bid = NormalizeDouble(MarketInfo(OrderSymbol(), MODE_BID),Xdigits);
   if((OrderType()==OP_BUY) && (SetInintialTPforBUY==true))
     {

      NewTP=CalculateTPBuy(ticket,Xfactor,Xdigits);

      modify=true;

     }//if (OrderType() == OP_BUY)
   if(SetInitialTPtoForPendings==true)
     {

      if(((OrderType()==OP_BUYLIMIT) || (OrderType()==OP_BUYSTOP)) && (SetInintialTPforBUY==true))
        {

         NewTP=CalculateTPBuy(ticket,Xfactor,Xdigits);

         modify=true;

        }

      if(((OrderType()==OP_SELLLIMIT) || (OrderType()==OP_SELLSTOP)) && (SetInintialTPforSELL==true))
        {

         NewTP=CalculateTPSell(ticket,Xfactor,Xdigits);

         modify=true;

        }
     }
   if((OrderType()==OP_SELL) && (SetInintialTPforSELL==true))
     {

      NewTP=CalculateTPSell(ticket,Xfactor,Xdigits);

      modify=true;

     }//if (OrderType() == OP_SELL)

//Send the new stop loss 
   if(modify==true)
     {
      bool result=OrderModify(TicketNo,OrderOpenPrice(),OrderStopLoss(),NewTP,OrderExpiration(),CLR_NONE);

      if(!result && OrderType()==OP_SELL)
        {
         NewTP=NewTP-(0.1/Xfactor);
         result=OrderModify(TicketNo,OrderOpenPrice(),OrderStopLoss(),NewTP,OrderExpiration(),CLR_NONE);
         if(result==false)ReportError(" APTM ",slm);

        }//if (!result)
      if(!result && OrderType()==OP_BUY)
        {
         NewTP=NewTP+(0.1/Xfactor);
         result=OrderModify(TicketNo,OrderOpenPrice(),OrderStopLoss(),NewTP,OrderExpiration(),CLR_NONE);
         if(result==false)ReportError(" APTM ",slm);

        }//if (!result)

     }

  }
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
double CalculateSLBuy(int ticket,double Xfactor,int Xdigits)
  {
   bool selectedOrder=OrderSelect(ticket,SELECT_BY_TICKET,MODE_TRADES);
   if(selectedOrder==false) return(0);//in case the trade closed
   ask = NormalizeDouble(MarketInfo(OrderSymbol(), MODE_ASK),Xdigits);
   bid = NormalizeDouble(MarketInfo(OrderSymbol(), MODE_BID),Xdigits);
   double CalculatedBuySL=0;
   if(Xdigits==5) digiter=0.1;
   else if(Xdigits==3) digiter=0.1;
   else digiter=1;
   if(useATRForStopLoss==true)
     {

      adr=GetAtr(OrderSymbol(),atrForStopLossTF,atrPeriodForStopLoss,0);
      if(adr==0)adr=MathAbs(iHigh(OrderSymbol(),PERIOD_W1,1)-iLow(OrderSymbol(),PERIOD_W1,1));
      SL=NormalizeDouble((atrMultiplicatorForStopLoss*adr*Xfactor),0);
     }
   if(UseMarginCalculatedSLTPBEJSValues==true)
     {
      TPAccountCurr=TPMarginMultipler*MarginCalculate(OrderSymbol(),  OrderLots());
      SLAccountCurr=SLMarginMultipler*MarginCalculate(OrderSymbol(),  OrderLots());
      BEProfitAccCurr=BEMarginMultipler*MarginCalculate(OrderSymbol(),  OrderLots());
      JumpStepAccCurr=JumpStepMarginMultipler*MarginCalculate(OrderSymbol(),  OrderLots());
      SLMinDistanceToPriceBEAccCurr=SLMinDistanceToPriceBEMarginMultipler*MarginCalculate(OrderSymbol(),  OrderLots());
      SLMinDistanceToPriceJSAccCurr=SLMinDistanceToPriceJSMarginMultipler*MarginCalculate(OrderSymbol(),  OrderLots());
     }
   if(useAccountCurrValuesForSL_TP_BE_JS==true)
     {
      SL=NormalizeDouble((SLAccountCurr/((MarketInfo(OrderSymbol(),MODE_TICKVALUE) *MarketInfo(OrderSymbol(),MODE_TICKSIZE))*OrderLots())*(MarketInfo(OrderSymbol(),MODE_POINT)*digiter)),2);
     }
   CalculatedBuySL=NormalizeDouble(OrderOpenPrice()-(SL/Xfactor),Xdigits);
   if(OrderType()==OP_BUY)
     {
      if(bid<CalculatedBuySL+minDistanceSLTP/Xfactor)
        {
         CalculatedBuySL=NormalizeDouble(bid-(SLMinDistanceToPrice/Xfactor),Xdigits);
        }
     }
   if(OrderType()==OP_BUYLIMIT || OrderType()==OP_BUYSTOP)
     {
      if(OrderOpenPrice()<CalculatedBuySL+minDistanceSLTP/Xfactor)
        {
         CalculatedBuySL=NormalizeDouble(OrderOpenPrice()-(SLMinDistanceToPrice/Xfactor),Xdigits);
        }
     }
   return(CalculatedBuySL);
  }
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
double CalculateSLSell(int ticket,double Xfactor,int Xdigits)
  {
   bool selectedOrder=OrderSelect(ticket,SELECT_BY_TICKET,MODE_TRADES);
   if(selectedOrder==false)return(0);//in case the trade closed
   ask=NormalizeDouble(MarketInfo(OrderSymbol(),MODE_ASK),Xdigits);
   bid=NormalizeDouble(MarketInfo(OrderSymbol(),MODE_BID),Xdigits);
   double CalculatedSellSL=0;
   if(Xdigits==5) digiter=0.1;
   else if(Xdigits==3) digiter=0.1;
   else digiter=1;

   if(useATRForStopLoss==true)
     {

      adr=GetAtr(OrderSymbol(),atrForStopLossTF,atrPeriodForStopLoss,0);
      if(adr==0)adr=MathAbs(iHigh(OrderSymbol(),PERIOD_W1,1)-iLow(OrderSymbol(),PERIOD_W1,1));
      SL=NormalizeDouble((atrMultiplicatorForStopLoss*adr*Xfactor),0);
     }
   if(UseMarginCalculatedSLTPBEJSValues==true)
     {
      TPAccountCurr=TPMarginMultipler*MarginCalculate(OrderSymbol(),  OrderLots());
      SLAccountCurr=SLMarginMultipler*MarginCalculate(OrderSymbol(),  OrderLots());
      BEProfitAccCurr=BEMarginMultipler*MarginCalculate(OrderSymbol(),  OrderLots());
      JumpStepAccCurr=JumpStepMarginMultipler*MarginCalculate(OrderSymbol(),  OrderLots());
      SLMinDistanceToPriceBEAccCurr=SLMinDistanceToPriceBEMarginMultipler*MarginCalculate(OrderSymbol(),  OrderLots());
      SLMinDistanceToPriceJSAccCurr=SLMinDistanceToPriceJSMarginMultipler*MarginCalculate(OrderSymbol(),  OrderLots());
     }
   if(useAccountCurrValuesForSL_TP_BE_JS==true)
     {
      SL=NormalizeDouble((SLAccountCurr/((MarketInfo(OrderSymbol(),MODE_TICKVALUE) *MarketInfo(OrderSymbol(),MODE_TICKSIZE))*OrderLots())*(MarketInfo(OrderSymbol(),MODE_POINT)*digiter)),2);

     }
   CalculatedSellSL=NormalizeDouble(OrderOpenPrice()+(SL/Xfactor),Xdigits);
   if(OrderType()==OP_SELL)
     {
      if(ask>CalculatedSellSL-minDistanceSLTP/Xfactor)
        {
         CalculatedSellSL=NormalizeDouble(ask+(SLMinDistanceToPrice/Xfactor),Xdigits);
        }
     }
   if(OrderType()==OP_SELLLIMIT || OP_SELLSTOP)
     {

      if(OrderOpenPrice()>CalculatedSellSL-minDistanceSLTP/Xfactor)
        {
         CalculatedSellSL=NormalizeDouble(OrderOpenPrice()+(SLMinDistanceToPrice/Xfactor),Xdigits);
        }
     }
   return (CalculatedSellSL);
  }
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
double CalculateTPBuy(int ticket,double Xfactor,int Xdigits)
  {
   bool selectedOrder=OrderSelect(ticket,SELECT_BY_TICKET,MODE_TRADES);
   if(selectedOrder==false) return(0);//in case the trade closed
   ask=NormalizeDouble(MarketInfo(OrderSymbol(),MODE_ASK),Xdigits);
   bid=NormalizeDouble(MarketInfo(OrderSymbol(),MODE_BID),Xdigits);
   double CalculatedBuyTP=0;
   if(Xdigits==5) digiter=0.1;
   else if(Xdigits==3) digiter=0.1;
   else digiter=1;
   if(useATRForTakeProfit==true)
     {

      adr=GetAtr(OrderSymbol(),atrForTakeProfitTF,atrPeriodForTakeProfit,0);
      if(adr==0)adr=MathAbs(iHigh(OrderSymbol(),PERIOD_W1,1)-iLow(OrderSymbol(),PERIOD_W1,1));
      TP=NormalizeDouble((atrMultiplicatorForTakeProfit*adr*Xfactor),0);
     }
   if(UseMarginCalculatedSLTPBEJSValues==true)
     {
      TPAccountCurr=TPMarginMultipler*MarginCalculate(OrderSymbol(),  OrderLots());
      SLAccountCurr=SLMarginMultipler*MarginCalculate(OrderSymbol(),  OrderLots());
      BEProfitAccCurr=BEMarginMultipler*MarginCalculate(OrderSymbol(),  OrderLots());
      JumpStepAccCurr=JumpStepMarginMultipler*MarginCalculate(OrderSymbol(),  OrderLots());
      SLMinDistanceToPriceBEAccCurr=SLMinDistanceToPriceBEMarginMultipler*MarginCalculate(OrderSymbol(),  OrderLots());
      SLMinDistanceToPriceJSAccCurr=SLMinDistanceToPriceJSMarginMultipler*MarginCalculate(OrderSymbol(),  OrderLots());
     }
   if(useAccountCurrValuesForSL_TP_BE_JS==true)
     {
      TP=NormalizeDouble((TPAccountCurr/((MarketInfo(OrderSymbol(),MODE_TICKVALUE) *MarketInfo(OrderSymbol(),MODE_TICKSIZE))*OrderLots())*(MarketInfo(OrderSymbol(),MODE_POINT)*digiter)),2);

     }
   CalculatedBuyTP=NormalizeDouble(OrderOpenPrice()+(TP/Xfactor),Xdigits);
   if(bid>CalculatedBuyTP-minDistanceSLTP/Xfactor)
     {
      CalculatedBuyTP=NormalizeDouble(bid+(SLMinDistanceToPrice/Xfactor),Xdigits);
     }

   return(CalculatedBuyTP);
  }
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
double CalculateTPSell(int ticket,double Xfactor,int Xdigits)
  {
   bool selectedOrder=OrderSelect(ticket,SELECT_BY_TICKET,MODE_TRADES);
   if(selectedOrder==false)return(0);//in case the trade closed
   ask = NormalizeDouble(MarketInfo(OrderSymbol(), MODE_ASK),Xdigits);
   bid = NormalizeDouble(MarketInfo(OrderSymbol(), MODE_BID),Xdigits);
   double CalculatedSellTP=0;
   if(Xdigits==5) digiter=0.1;
   else if(Xdigits==3) digiter=0.1;
   else digiter=1;
   if(useATRForTakeProfit==true)
     {

      adr=GetAtr(OrderSymbol(),atrForTakeProfitTF,atrPeriodForTakeProfit,0);
      if(adr==0)adr=MathAbs(iHigh(OrderSymbol(),PERIOD_W1,1)-iLow(OrderSymbol(),PERIOD_W1,1));
      TP=NormalizeDouble((atrMultiplicatorForTakeProfit*adr*Xfactor),0);
     }
   if(UseMarginCalculatedSLTPBEJSValues==true)
     {
      TPAccountCurr=TPMarginMultipler*MarginCalculate(OrderSymbol(),  OrderLots());
      SLAccountCurr=SLMarginMultipler*MarginCalculate(OrderSymbol(),  OrderLots());
      BEProfitAccCurr=BEMarginMultipler*MarginCalculate(OrderSymbol(),  OrderLots());
      JumpStepAccCurr=JumpStepMarginMultipler*MarginCalculate(OrderSymbol(),  OrderLots());
      SLMinDistanceToPriceBEAccCurr=SLMinDistanceToPriceBEMarginMultipler*MarginCalculate(OrderSymbol(),  OrderLots());
      SLMinDistanceToPriceJSAccCurr=SLMinDistanceToPriceJSMarginMultipler*MarginCalculate(OrderSymbol(),  OrderLots());
     }
   if(useAccountCurrValuesForSL_TP_BE_JS==true)
     {
      TP=NormalizeDouble((TPAccountCurr/((MarketInfo(OrderSymbol(),MODE_TICKVALUE) *MarketInfo(OrderSymbol(),MODE_TICKSIZE))*OrderLots())*(MarketInfo(OrderSymbol(),MODE_POINT)*digiter)),2);

     }
   CalculatedSellTP=NormalizeDouble(OrderOpenPrice()-(TP/Xfactor),Xdigits);
   if(ask<CalculatedSellTP-minDistanceSLTP/Xfactor)
     {
      CalculatedSellTP=NormalizeDouble(ask-(SLMinDistanceToPrice/Xfactor),Xdigits);
     }

   return (CalculatedSellTP);
  }
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void ReportError(string function,string message)
  {

   int err=GetLastError();

   if(showAlerts==true) Alert(WindowExpertName()," ",OrderTicket(),function,message,err,": ",ErrorDescription(err));
   Print(WindowExpertName()," ",OrderTicket(),function,message,err,": ",ErrorDescription(err));

  }//void ReportError()
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
double GetAtr(string Xsymbol,int tf,int period,int shift)
  {
//Returns the value of atr

   return(iATR(Xsymbol, tf, period, shift) );

  }//End double GetAtr()
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void SetBEAndJump(int ticket,double Xfactor,int Xdigits)
  {

   bool selectedOrder=OrderSelect(ticket,SELECT_BY_TICKET,MODE_TRADES);
   if(selectedOrder==false) return;//in case the trade closed
   ask = NormalizeDouble(MarketInfo(OrderSymbol(), MODE_ASK),Xdigits);
   bid = NormalizeDouble(MarketInfo(OrderSymbol(), MODE_BID),Xdigits);
   double NewSL=0;
   TradeHasPartClosed=false;
   bool doPartClose=false;
   if(Xdigits==5) digiter=0.1;
   else if(Xdigits==3) digiter=0.1;
   else digiter=1;
   if(useATRForSLMinDistanceToPrice==true)
     {

      adr=GetAtr(OrderSymbol(),atrForSLMinDistanceToPriceTF,atrPeriodForSLMinDistanceToPrice,0);
      if(adr==0)adr=MathAbs(iHigh(OrderSymbol(),PERIOD_W1,1)-iLow(OrderSymbol(),PERIOD_W1,1));
      SLMinDistanceToPrice=NormalizeDouble((2*adr*Xfactor),0);
      SLMinDistanceToPriceBE=NormalizeDouble((atrMultiplicatorForSLMinDistanceToPriceBE*adr*Xfactor),0);
      SLMinDistanceToPriceJS=NormalizeDouble((atrMultiplicatorForSLMinDistanceToPriceJS*adr*Xfactor),0);
     }
   if(UseMarginCalculatedSLTPBEJSValues==true)
     {
      TPAccountCurr=TPMarginMultipler*MarginCalculate(OrderSymbol(),  OrderLots());
      SLAccountCurr=SLMarginMultipler*MarginCalculate(OrderSymbol(),  OrderLots());
      BEProfitAccCurr=BEMarginMultipler*MarginCalculate(OrderSymbol(),  OrderLots());
      JumpStepAccCurr=JumpStepMarginMultipler*MarginCalculate(OrderSymbol(),  OrderLots());
      SLMinDistanceToPriceBEAccCurr=SLMinDistanceToPriceBEMarginMultipler*MarginCalculate(OrderSymbol(),  OrderLots());
      SLMinDistanceToPriceJSAccCurr=SLMinDistanceToPriceJSMarginMultipler*MarginCalculate(OrderSymbol(),  OrderLots());
     }
   if(useAccountCurrValuesForSL_TP_BE_JS==true)
     {
      JumpStep=NormalizeDouble((JumpStepAccCurr/ ((MarketInfo(OrderSymbol(), MODE_TICKVALUE)* MarketInfo(OrderSymbol(), MODE_TICKSIZE))*OrderLots())*(MarketInfo(OrderSymbol(),MODE_POINT)*digiter)),2);
      BEProfit=NormalizeDouble((BEProfitAccCurr/ ((MarketInfo(OrderSymbol(), MODE_TICKVALUE)* MarketInfo(OrderSymbol(), MODE_TICKSIZE))*OrderLots())*(MarketInfo(OrderSymbol(),MODE_POINT)*digiter)),2);
      SLMinDistanceToPriceBE=NormalizeDouble((SLMinDistanceToPriceBEAccCurr/((MarketInfo(OrderSymbol(), MODE_TICKVALUE)* MarketInfo(OrderSymbol(), MODE_TICKSIZE))*OrderLots())*(MarketInfo(OrderSymbol(),MODE_POINT)*digiter)),2);
      SLMinDistanceToPriceJS=NormalizeDouble((SLMinDistanceToPriceJSAccCurr/ ((MarketInfo(OrderSymbol(), MODE_TICKVALUE)* MarketInfo(OrderSymbol(), MODE_TICKSIZE))*OrderLots())*(MarketInfo(OrderSymbol(),MODE_POINT)*digiter)),2);
     }

   if(OrderType()==OP_SELL)
     {

      doPartClose=false;
      if(OrderStopLoss()>OrderOpenPrice() || NormalizeDouble(OrderStopLoss(),Xdigits)==0)
        {

         NewSL=NormalizeDouble(OrderOpenPrice()-(BEProfit/Xfactor),Xdigits);
         SLMinDistanceToPrice=SLMinDistanceToPriceBE;
         if(PartCloseWithBE==true && PartCloseEnabled==true)
           {
            doPartClose=true;
           }
        }
      else
        {
         doPartClose=false;
         NewSL=NormalizeDouble(OrderStopLoss()-(JumpStep/Xfactor),Xdigits);
         SLMinDistanceToPrice=SLMinDistanceToPriceJS;
        }

      if((NewSL-ask)>(SLMinDistanceToPrice/Xfactor))
        {

         if(NewSL!=OrderStopLoss() && NewSL!=0)
           {

            if(showAlerts==true)Alert("APTM: SetBEAndJump :Attempting to move SL of ",OrderSymbol()," to ",DoubleToStr(NewSL,Xdigits));
            Print("APTM: SetBEAndJump :Attempting to move SL of ",OrderSymbol()," to ",DoubleToStr(NewSL,Xdigits));
            bool result=OrderModify(ticket,OrderOpenPrice(),NewSL,OrderTakeProfit(),OrderExpiration(),CLR_NONE);
            if(!result)
              {
               NewSL=NewSL+(1/Xfactor);
               result=OrderModify(ticket,OrderOpenPrice(),NewSL,OrderTakeProfit(),OrderExpiration(),CLR_NONE);
               if(result==false)ReportError(" APTM ",slm);

              }//if (!result)

            if(doPartClose==true)
              {
               PartCloseTrade(ticket);
               if(TradeHasPartClosed==true)
                 {
                  if(showAlerts==true)Alert("APTM: Ticket: ",ticket," was part closed");
                 }
               else
                 {
                  if(showAlerts==true) Alert("APTM: Partclose failed!");

                  TradeHasPartClosed=false;
                 }
              }//doPartClose
           }// if(((NewSL<OrderStopLoss()) || (OrderStopLoss()<(1/Xfactor))) && (NewSL!=0) && (NewSL>Ask+(10/Xfactor)))
        }//if((NewSL-Bid)>(SLMinDistanceToPrice/Xfactor))

     }//OP_SELL

   if(OrderType()==OP_BUY)
     {

      doPartClose=false;
      if(OrderStopLoss()<OrderOpenPrice() || NormalizeDouble(OrderStopLoss(),Xdigits)==0)
        {
         NewSL=NormalizeDouble(OrderOpenPrice()+(BEProfit/Xfactor),Xdigits);
         SLMinDistanceToPrice=SLMinDistanceToPriceBE;
         if(PartCloseWithBE==true && PartCloseEnabled==true)
           {
            doPartClose=true;
           }

        }
      else
        {
         NewSL=NormalizeDouble(OrderStopLoss()+(JumpStep/Xfactor),Xdigits);
         SLMinDistanceToPrice=SLMinDistanceToPriceJS;
         doPartClose=false;
        }
      if(bid-NewSL>(SLMinDistanceToPrice/Xfactor))
        {
         if(NewSL!=OrderStopLoss() && NewSL!=0)

           {

            if(showAlerts==true)Alert("APTM: SetBEAndJump :Attempting to move SL of ",OrderSymbol()," to ",DoubleToStr(NewSL,Xdigits));
            Print("APTM: SetBEAndJump :Attempting to move SL of ",OrderSymbol()," to ",DoubleToStr(NewSL,Xdigits));

            bool result=OrderModify(ticket,OrderOpenPrice(),NewSL,OrderTakeProfit(),OrderExpiration(),CLR_NONE);
            if(!result)
              {
               NewSL=NewSL-(1/Xfactor);
               result=OrderModify(ticket,OrderOpenPrice(),NewSL,OrderTakeProfit(),OrderExpiration(),CLR_NONE);
               if(result==false)ReportError(" APTM ",slm);

              }//if (!result)
            if(doPartClose==true)
              {
               PartCloseTrade(ticket);
               if(TradeHasPartClosed==true)
                 {
                  if(showAlerts==true) Alert("APTM: Ticket: ",ticket," was part closed");
                 }
               else
                 {
                  if(showAlerts==true) Alert("APTM: Partclose failed!");
                  TradeHasPartClosed=false;
                 }
              }//doPartClose
           }//if(((NewSL>OrderStopLoss()) || (OrderStopLoss()<(1/Xfactor))) && (NewSL!=0) && (NewSL<Bid -(10/Xfactor)))
        }//if((Bid-NewSL)>(SLMinDistanceToPrice/Xfactor))

     }//OP_BUY

  }
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
bool PartCloseTrade(int ticket)
  {
//Close PartClosePercent of the initial trade.
//Return true if close succeeds, else false
   bool selectedOrder=OrderSelect(ticket,SELECT_BY_TICKET,MODE_TRADES);
   if(selectedOrder==false) return(true);//in case the trade closed
   bool Success=false;
   double CloseLots=NormalizeLots(OrderSymbol(),OrderLots() *(PartClosePercent/100));

   RefreshRates();
   if(OrderType()==OP_BUY) Success = OrderClose(ticket, CloseLots, MarketInfo(OrderSymbol(),MODE_BID), 5000, Blue);
   if(OrderType()==OP_SELL) Success = OrderClose(ticket, CloseLots, MarketInfo(OrderSymbol(),MODE_ASK), 5000, Blue);
   if(Success) TradeHasPartClosed=true;//Warns CountOpenTrades() that the OrderTicket() is incorrect.
   if(!Success)
     {

      while(IsTradeContextBusy()) Sleep(500);
      RefreshRates();
      if(OrderType()==OP_BUY) Success = OrderClose(ticket, CloseLots, MarketInfo(OrderSymbol(),MODE_BID), 5000, Blue);
      if(OrderType()==OP_SELL) Success = OrderClose(ticket, CloseLots, MarketInfo(OrderSymbol(),MODE_ASK), 5000, Blue);
      //end mod.  
      //original:
      if(Success) TradeHasPartClosed=true;//Warns CountOpenTrades() that the OrderTicket() is incorrect.

      if(!Success)
        {

         return (false);
        }
     }//if (!Success) 

   if((ManageByTicketNumber==true) || (ManageByOrderComment==true))
     {
      string OrderNumber=StringConcatenate(ticket);
      ManageByTicketNumber=false;
      ManageByOrderComment=true;
      string OC="from #";
      orderComment=StringConcatenate(OC,OrderNumber);
     }
   return (true);

  }//bool PartCloseTrade(int ticket)
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
double NormalizeLots(string Xsymbol,double lots)
  {
   if(CloseEnough(MathAbs(lots),0.0)) return(0.0); //just in case ... otherwise it may happen that after rounding 0.0 the result is >0 and we have got a problem, fxdaytrader
   double ls=MarketInfo(Xsymbol,MODE_LOTSTEP);
   lots=MathMin(MarketInfo(Xsymbol,MODE_MAXLOT),MathMax(MarketInfo(Xsymbol,MODE_MINLOT),lots)); //check if lots >= min. lots && <= max. lots, fxdaytrader
   return(MathRound(lots/ls)*ls);
  }
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
void DoJS(int ticket,double Xfactor,int Xdigits)
  {

   bool selectedOrder=OrderSelect(ticket,SELECT_BY_TICKET,MODE_TRADES);
   if(selectedOrder==false) return;//in case the trade closed
   ask = NormalizeDouble(MarketInfo(OrderSymbol(), MODE_ASK),Xdigits);
   bid = NormalizeDouble(MarketInfo(OrderSymbol(), MODE_BID),Xdigits);
   double NewSL=0;

   if(useATRForSLMinDistanceToPrice==true)
     {

      adr=GetAtr(OrderSymbol(),atrForSLMinDistanceToPriceTF,atrPeriodForSLMinDistanceToPrice,0);
      if(adr==0)adr=MathAbs(iHigh(OrderSymbol(),PERIOD_W1,1)-iLow(OrderSymbol(),PERIOD_W1,1));
      SLMinDistanceToPrice=NormalizeDouble((2*adr*Xfactor),0);
      SLMinDistanceToPriceBE=NormalizeDouble((atrMultiplicatorForSLMinDistanceToPriceBE*adr*Xfactor),0);
      SLMinDistanceToPriceJS=NormalizeDouble((atrMultiplicatorForSLMinDistanceToPriceJS*adr*Xfactor),0);
     }

   if(OrderType()==OP_SELL)
     {

      NewSL=NormalizeDouble(OrderStopLoss()-(JumpStep/Xfactor),Xdigits);

      if(((NewSL-ask)>(SLMinDistanceToPriceJS/Xfactor)) && ((NewSL-ask)<((SLMinDistanceToPriceJS/Xfactor)+(5/Xfactor))))
        {

         if(NewSL<(OrderStopLoss()-(1/Xfactor)) && NewSL!=0)
           {

            if(showAlerts==true) Alert("APTM: DoJS :Attempting to move SL of ",OrderSymbol()," to ",DoubleToStr(NewSL,Xdigits));
            Print("APTM: DoJS :Attempting to move SL of ",OrderSymbol()," to ",DoubleToStr(NewSL,Xdigits));
            bool result=OrderModify(ticket,OrderOpenPrice(),NewSL,OrderTakeProfit(),OrderExpiration(),CLR_NONE);
            if(!result)
              {
               NewSL=NewSL+(1/Xfactor);
               result=OrderModify(ticket,OrderOpenPrice(),NewSL,OrderTakeProfit(),OrderExpiration(),CLR_NONE);
               if(result==false)ReportError(" APTM ",slm);

              }//if (!result)
           }
        }
     }

   if(OrderType()==OP_BUY)
     {

      NewSL=NormalizeDouble(OrderStopLoss()+(JumpStep/Xfactor),Xdigits);
      if(((bid-NewSL)>(SLMinDistanceToPriceJS/Xfactor)) && ((bid-NewSL)<((SLMinDistanceToPriceJS/Xfactor)+(5/Xfactor))))
        {
         if(NewSL>(OrderStopLoss()+(1/Xfactor)) && NewSL!=0)

           {

            if(showAlerts==true) Alert("APTM: DoJS :Attempting to move SL of ",OrderSymbol()," to ",DoubleToStr(NewSL,Xdigits));
            Print("APTM: DoJS :Attempting to move SL of ",OrderSymbol()," to ",DoubleToStr(NewSL,Xdigits));
            bool result=OrderModify(ticket,OrderOpenPrice(),NewSL,OrderTakeProfit(),OrderExpiration(),CLR_NONE);
            if(!result)
              {
               NewSL=NewSL-(1/Xfactor);
               result=OrderModify(ticket,OrderOpenPrice(),NewSL,OrderTakeProfit(),OrderExpiration(),CLR_NONE);
               if(result==false)ReportError(" APTM ",slm);

              }//if (!result)
           }
        }

     }

  }
//+------
void doPartCloseFirstTP(int ticket,double Xfactor,int Xdigits)
  {

   bool selectedOrder=OrderSelect(ticket,SELECT_BY_TICKET,MODE_TRADES);
   if(selectedOrder==false) return;//in case the trade closed
   ask = NormalizeDouble(MarketInfo(OrderSymbol(), MODE_ASK),Xdigits);
   bid = NormalizeDouble(MarketInfo(OrderSymbol(), MODE_BID),Xdigits);
   double NewSL=0;
   string name;

   if(useATRForPartClosePips==true)
     {

      adr=GetAtr(OrderSymbol(),atrForPartClosePipsTF,atrPeriodForPartClosePips,0);
      if(adr==0)adr=MathAbs(iHigh(OrderSymbol(),PERIOD_W1,1)-iLow(OrderSymbol(),PERIOD_W1,1));
      PartCloseFirstTpPips=NormalizeDouble((atrMultiplicatorForPartClosePips*adr*Xfactor),0);
     }

   bool doPartClose=false;

   TradeHasPartClosed=false;

   if(OrderType()==OP_SELL)
     {

      doPartClose=false;

      NewSL=NormalizeDouble((OrderOpenPrice()-(BEProfit/factor)),Xdigits);

      name=OrderComment();
      if(StringFind(name,"from #")<0)doPartClose=true;

      if((NewSL-ask)>(PartCloseFirstTpPips/Xfactor))
        {

         if(doPartClose==true)
           {
            if(SetBEonPartCloseFirstTP==true && NormalizeDouble(OrderStopLoss(),Xdigits)!=NormalizeDouble(NewSL,Xdigits))
              {
               if(showAlerts==true)Alert("APTM:SetBEonFirstTP :Attempting to move SL of ",symbol," to ",NewSL);
               Print("APTM:SetBEonFirstTP :Attempting to move SL of ",symbol," to ",NewSL);

               bool result=OrderModify(ticket,OrderOpenPrice(),NewSL,OrderTakeProfit(),OrderExpiration(),CLR_NONE);
               if(!result)
                 {
                  NewSL=NewSL-(1/Xfactor);
                  result=OrderModify(ticket,OrderOpenPrice(),NewSL,OrderTakeProfit(),OrderExpiration(),CLR_NONE);
                  if(result==false)ReportError(" APTM ",slm);

                 }//if (!result)

              }
            PartCloseTrade(ticket);
            if(TradeHasPartClosed==true)
              {
               if(showAlerts==true) Alert("APTM: Ticket: ",ticket," was part closed");
              }
            else
              {
               if(showAlerts==true) Alert("APTM: Partclose failed!");

               TradeHasPartClosed=false;
              }
           }//doPartClose

        }//if((NewSL-Bid)>(SLMinDistanceToPrice/Xfactor))

     }//OP_SELL

   if(OrderType()==OP_BUY)
     {

      doPartClose=false;

      NewSL=NormalizeDouble((OrderOpenPrice()+(BEProfit/factor)),Xdigits);

      name=OrderComment();
      if(StringFind(name,"from #")<0)doPartClose=true;

      if((bid-NewSL)>(PartCloseFirstTpPips/Xfactor))
        {
         if(SetBEonPartCloseFirstTP==true && NormalizeDouble(OrderStopLoss(),Xdigits)!=NormalizeDouble(NewSL,Xdigits))
           {
            if(showAlerts==true)Alert("APTM:SetBEonFirstTP :Attempting to move SL of ",symbol," to ",NewSL);
            Print("APTM:SetBEonFirstTP :Attempting to move SL of ",symbol," to ",NewSL);

            bool result=OrderModify(ticket,OrderOpenPrice(),NewSL,OrderTakeProfit(),OrderExpiration(),CLR_NONE);
            if(!result)
              {
               NewSL=NewSL+(1/Xfactor);
               result=OrderModify(ticket,OrderOpenPrice(),NewSL,OrderTakeProfit(),OrderExpiration(),CLR_NONE);
               if(result==false)ReportError(" APTM ",slm);

              }//if (!result)

           }

         if(doPartClose==true)
           {
            PartCloseTrade(ticket);
            if(TradeHasPartClosed==true)
              {
               if(showAlerts==true) Alert("APTM: Ticket: ",ticket," was part closed");
              }
            else
              {
               if(showAlerts==true) Alert("APTM: Partclose failed!");

               TradeHasPartClosed=false;
              }
           }//doPartClose

        }//if((Bid-NewSL)>(PartCloseFirstTpPips/factor))

     }//OP_BUY

  }
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
//+------------------------------------------------------------------+
bool RectLabelCreate()
  {
//--- reset the error value
   ResetLastError();
//--- create a rectangle label
   if(ObjectFind(0,"messageBox")>=0) return true;
   if(!ObjectCreate(0,"messageBox",OBJ_RECTANGLE_LABEL,0,0,0))
     {
      Print(__FUNCTION__,
            ": failed to create a rectangle label! Error code = ",GetLastError());
      return(false);
     }
//--- set label coordinates
   ObjectSetInteger(0,"messageBox",OBJPROP_XDISTANCE,0);
   ObjectSetInteger(0,"messageBox",OBJPROP_YDISTANCE,0);
//--- set label size
   if(useNewDisplayType==true)
     {
      ObjectSetInteger(0,"messageBox",OBJPROP_XSIZE,500+int(14 *fontSize));
      ObjectSetInteger(0,"messageBox",OBJPROP_YSIZE,600+int(14 *fontSize));
     }
   else
     {
      ObjectSetInteger(0,"messageBox",OBJPROP_XSIZE,500);
      ObjectSetInteger(0,"messageBox",OBJPROP_YSIZE,480);
     }
//--- set background color
   ObjectSetInteger(0,"messageBox",OBJPROP_BGCOLOR,displayBoxBackgroundColour);
//--- set border type
   ObjectSetInteger(0,"messageBox",OBJPROP_BORDER_TYPE,BORDER_SUNKEN);
//--- set the chart's corner, relative to which point coordinates are defined
   ObjectSetInteger(0,"messageBox",OBJPROP_CORNER,0);
//--- set flat border color (in Flat mode)
   ObjectSetInteger(0,"messageBox",OBJPROP_COLOR,Red);
//--- set flat border line style
   ObjectSetInteger(0,"messageBox",OBJPROP_STYLE,STYLE_SOLID);
//--- set flat border width
   ObjectSetInteger(0,"messageBox",OBJPROP_WIDTH,1);
//--- display in the foreground (false) or background (true)
   ObjectSetInteger(0,"messageBox",OBJPROP_BACK,false);
//--- enable (true) or disable (false) the mode of moving the label by mouse
   ObjectSetInteger(0,"messageBox",OBJPROP_SELECTABLE,true);
   ObjectSetInteger(0,"messageBox",OBJPROP_SELECTED,false);
//--- hide (true) or display (false) graphical object name in the object list
   ObjectSetInteger(0,"messageBox",OBJPROP_HIDDEN,false);
//--- set the priority for receiving the event of a mouse click in the chart
   ObjectSetInteger(0,"messageBox",OBJPROP_ZORDER,0);
//--- successful execution
   return(true);
  }
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void CloseFriday(int ticket,double Xfactor,int Xdigits)
  {
    bool orderResultPending=false;
   bool selectedOrder=OrderSelect(ticket,SELECT_BY_TICKET,MODE_TRADES);
   if(selectedOrder==false) return;//in case the trade closed
   ask = NormalizeDouble(MarketInfo(OrderSymbol(), MODE_ASK),Xdigits);
   bid = NormalizeDouble(MarketInfo(OrderSymbol(), MODE_BID),Xdigits);
   if((TimeDayOfWeek(TimeCurrent())==5) && (TimeHour(TimeCurrent())>=FridayCloseHour) && (TimeMinute(TimeCurrent())>=FridayCloseMinute))
     {

      if(OrderType()==OP_BUY)
        {
         while(IsTradeContextBusy()) Sleep(100);
         if(showAlerts==true) Alert("APTM:CloseFriday:Attempting to close ",IntegerToString(ticket));
         Print("APTM:CloseFriday:Attempting to close ",IntegerToString(ticket));
         if(OrderClose(ticket,OrderLots(),bid,5000,clrNONE))
           {
            if(showAlerts==true)Alert("APTM:CloseFriday:Close ",IntegerToString(ticket)," Succeeded !");
            Print("APTM:CloseFriday:Close ",IntegerToString(ticket)," Succeeded !");
              } else {
            if(showAlerts==true)Alert("APTM:CloseFriday:Close ",IntegerToString(ticket)," Failed !");
            Print("APTM:CloseFriday:Close ",IntegerToString(ticket)," Failed !");
           }
        }

      if(OrderType()==OP_SELL)
        {
         while(IsTradeContextBusy()) Sleep(100);
         if(showAlerts==true)Alert("APTM:CloseFriday:Attempting to close ",IntegerToString(ticket));
         Print("APTM:CloseFriday:Attempting to close ",IntegerToString(ticket));
         if(OrderClose(ticket,OrderLots(),ask,5000,clrNONE))
           {
            if(showAlerts==true) Alert("APTM:CloseFriday:Close ",IntegerToString(ticket)," Succeeded !");
            Print("APTM:CloseFriday:Close ",IntegerToString(ticket)," Succeeded !");
              } else {
            if(showAlerts==true) Alert("APTM:CloseFriday:Close ",IntegerToString(ticket)," Failed !");
            Print("APTM:CloseFriday:Close ",IntegerToString(ticket)," Failed !");
           }
        }
        if(OrderType()==OP_BUYLIMIT || OrderType()==OP_SELLLIMIT || OrderType()==OP_BUYSTOP || OrderType()==OP_SELLSTOP)
        {

         orderResultPending=OrderDelete(OrderTicket());
         if(showAlerts==true) Alert("APTM:CloseFriday:DeletePending ",IntegerToString(ticket)," Succeeded !");
            Print("APTM:CloseFriday:DeletePending ",IntegerToString(ticket)," Succeeded !");

        }
     }
  }
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void CloseDefinedTime(int ticket,double Xfactor,int Xdigits)
  {
   bool orderResultPending=false;
   bool selectedOrder=OrderSelect(ticket,SELECT_BY_TICKET,MODE_TRADES);
   if(selectedOrder==false) return;//in case the trade closed
   ask = NormalizeDouble(MarketInfo(OrderSymbol(), MODE_ASK),Xdigits);
   bid = NormalizeDouble(MarketInfo(OrderSymbol(), MODE_BID),Xdigits);
   if((TimeHour(TimeCurrent())==CloseHour) && (TimeMinute(TimeCurrent())==CloseMinute))
     {

      if(OrderType()==OP_BUY)
        {
         while(IsTradeContextBusy()) Sleep(100);
         if(showAlerts==true) Alert("APTM:CloseDefinedTime:Attempting to close ",IntegerToString(ticket));
         Print("APTM:CloseDefinedTime:Attempting to close ",IntegerToString(ticket));
         if(OrderClose(ticket,OrderLots(),bid,5000,clrNONE))
           {
            if(showAlerts==true)Alert("APTM:CloseDefinedTime:Close ",IntegerToString(ticket)," Succeeded !");
            Print("APTM:CloseDefinedTime:Close ",IntegerToString(ticket)," Succeeded !");
              } else {
            if(showAlerts==true)Alert("APTM:CloseDefinedTime:Close ",IntegerToString(ticket)," Failed !");
            Print("APTM:CloseDefinedTime:Close ",IntegerToString(ticket)," Failed !");
           }
        }

      if(OrderType()==OP_SELL)
        {
         while(IsTradeContextBusy()) Sleep(100);
         if(showAlerts==true)Alert("APTM:CloseDefinedTime:Attempting to close ",IntegerToString(ticket));
         Print("APTM:CloseDefinedTime:Attempting to close ",IntegerToString(ticket));
         if(OrderClose(ticket,OrderLots(),ask,5000,clrNONE))
           {
            if(showAlerts==true) Alert("APTM:CloseDefinedTime:Close ",IntegerToString(ticket)," Succeeded !");
            Print("APTM:CloseDefinedTime:Close ",IntegerToString(ticket)," Succeeded !");
              } else {
            if(showAlerts==true) Alert("APTM:CloseDefinedTime:Close ",IntegerToString(ticket)," Failed !");
            Print("APTM:CloseDefinedTime:Close ",IntegerToString(ticket)," Failed !");
           }
        }
          if(OrderType()==OP_BUYLIMIT || OrderType()==OP_SELLLIMIT || OrderType()==OP_BUYSTOP || OrderType()==OP_SELLSTOP)
        {

         orderResultPending=OrderDelete(OrderTicket());
         if(showAlerts==true) Alert("APTM:CloseDefinedTime:DeletePending ",IntegerToString(ticket)," Succeeded !");
            Print("APTM:CloseDefinedTime:DeletePending ",IntegerToString(ticket)," Succeeded !");

        }
     }
  }
//+------------------------------------------------------------------+
//+------------------------------------------------------------------+
//| Create the button                                                |
//+------------------------------------------------------------------+
bool ButtonCreate(const long              chart_ID=0,               // chart's ID
                  const string            name="Button",            // button name
                  const int               sub_window=0,             // subwindow index
                  const int               x=0,                      // X coordinate
                  const int               y=0,                      // Y coordinate
                  const int               width=80,                 // button width
                  const int               height=20,                // button height
                  const ENUM_BASE_CORNER  corner=CORNER_RIGHT_UPPER,// chart corner for anchoring
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
//+------------------------------------------------------------------+
//| ChartEvent function                                              |
//+------------------------------------------------------------------+
void OnChartEvent(const int id,         // Event identifier  
                  const long& lparam,   // Event parameter of long type
                  const double& dparam, // Event parameter of double type
                  const string& sparam) // Event parameter of string type
  {
//--- the left mouse button has been pressed on the chart

//--- the mouse has been clicked on the graphic object
   if(id==CHARTEVENT_OBJECT_CLICK)
     {
      if(sparam==ButtonOne) CloseAll();
      if(sparam==ButtonTwo) ResetSLandTP();
     }
  }
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void CloseAll()
  {

   bool orderResult=false;
   bool orderResultPending=false;
   int  totalOrders   = OrdersTotal();
   int  orders        = 0;
   int lastError=0;
   datetime posOpen[][2];
   if(OrdersTotal() == 0) return;
   if(showAlerts)Alert("APTM: Starting to close the entire Basket..");
   for(int i=0; i<totalOrders; i++)
     {
      if(!OrderSelect(i,SELECT_BY_POS,MODE_TRADES))
        {
         lastError=GetLastError();
         Print("Error in OrderSelect!!");
         continue;
        }
      if(ManageOnlyActualSymbol==true && OrderSymbol()!=Symbol()) continue;
      if((excludeMagicNumber==true) && (OrderMagicNumber()==MagicNumberToExclude)) continue;
      if(ManageByMagicNumber==true)
        {
         if(OrderMagicNumber()!=MagicNumber)continue;
        }
      if(ManageByOrderComment==true)
        {
         if(OrderComment()!=orderComment)continue;

        }
      if(NotDeletePendingOrdersWithCloseAll==true)
        {
         if(OrderType() ==  OP_BUYLIMIT || OrderType() ==  OP_SELLLIMIT)continue;
         if(OrderType() ==  OP_BUYSTOP || OrderType() ==  OP_SELLSTOP)continue;
        }

      orders++;
      ArrayResize(posOpen,orders);
      posOpen[orders - 1][0] = OrderOpenTime();
      posOpen[orders - 1][1] = OrderTicket();
     }

   if(useFIFOforCloseAll==true)
      ArraySort(posOpen,WHOLE_ARRAY,0,MODE_ASCEND);
   else
      ArraySort(posOpen,WHOLE_ARRAY,0,MODE_DESCEND);

   for(int i=0; i<orders; i++)
     {
      if(!OrderSelect((int) posOpen[i][1],SELECT_BY_TICKET))
        {
         lastError=GetLastError();
         Print("Error in OrderSelect!!");
         continue;
        }

      if(OrderType()==OP_BUY || OrderType()==OP_SELL)
        {

         orderResult=OrderClose(OrderTicket(),OrderLots(),OrderClosePrice(),5000,CLR_NONE);
         if(!orderResult)
           {
            while(IsTradeContextBusy()) Sleep(125);
            RefreshRates();
            if(OrderType()==OP_BUY) orderResult=OrderClose(OrderTicket(),OrderLots(),MarketInfo(OrderSymbol(),MODE_BID),5000,CLR_NONE);
            if(OrderType()==OP_SELL) orderResult=OrderClose(OrderTicket(),OrderLots(),MarketInfo(OrderSymbol(),MODE_ASK),5000,CLR_NONE);
           }
        }
      else if(OrderType()==OP_BUYLIMIT || OrderType()==OP_SELLLIMIT || OrderType()==OP_BUYSTOP || OrderType()==OP_SELLSTOP)
        {

         orderResultPending=OrderDelete(OrderTicket());

        }
     }

  }
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
double MAstopValue(string Xsymbol)
  {
   double maValue=iMA(Xsymbol,MaTimeFrame,MaPeriod,0,MaMethod,MaAppliedPrice,MaShift);
   return(maValue);
  }
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
double CalculateMASLSell(int ticket,double Xfactor,int Xdigits)
  {
   bool selectedOrder=OrderSelect(ticket,SELECT_BY_TICKET,MODE_TRADES);
   if(selectedOrder==false)return(0);//in case the trade closed
   ask=NormalizeDouble(MarketInfo(OrderSymbol(),MODE_ASK),Xdigits);
   bid=NormalizeDouble(MarketInfo(OrderSymbol(),MODE_BID),Xdigits);
   double CalculatedSellSL=0;

   CalculatedSellSL=NormalizeDouble(MAstopValue(OrderSymbol()),Xdigits);
   if(ask>CalculatedSellSL-minDistanceSLTP/Xfactor)
     {
      CalculatedSellSL=NormalizeDouble(ask+(MASLMinDistanceToPrice/Xfactor),Xdigits);
      if(showAlerts==true)Alert("APTM:MA can't be SL EmergencySL used!!");
     }

   return (CalculatedSellSL);
  }
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
double CalculateMASLBuy(int ticket,double Xfactor,int Xdigits)
  {
   bool selectedOrder=OrderSelect(ticket,SELECT_BY_TICKET,MODE_TRADES);
   if(selectedOrder==false)return(0);//in case the trade closed
   ask=NormalizeDouble(MarketInfo(OrderSymbol(),MODE_ASK),Xdigits);
   bid=NormalizeDouble(MarketInfo(OrderSymbol(),MODE_BID),Xdigits);
   double CalculatedBuySL=0;

   CalculatedBuySL=NormalizeDouble(MAstopValue(OrderSymbol()),Xdigits);
   if(bid<CalculatedBuySL+minDistanceSLTP/Xfactor)
     {
      CalculatedBuySL=NormalizeDouble(bid-(MASLMinDistanceToPrice/Xfactor),Xdigits);
      if(showAlerts==true)Alert("APTM:MA can't be SL EmergencySL used!!");
     }

   return (CalculatedBuySL);
  }
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void SetInitialMASL(int ticket,double Xfactor,int Xdigits)
  {
   bool modify=false;
   double NewStop=0;
   bool selectedOrder=OrderSelect(ticket,SELECT_BY_TICKET,MODE_TRADES);
   if(selectedOrder==false) return;//in case the trade closed
   ask = NormalizeDouble(MarketInfo(OrderSymbol(), MODE_ASK),Xdigits);
   bid = NormalizeDouble(MarketInfo(OrderSymbol(), MODE_BID),Xdigits);
   factor=GetPipFactor(OrderSymbol());
   if((OrderType()==OP_BUY))
     {

      NewStop=CalculateMASLBuy(ticket,Xfactor,Xdigits);
      if(NormalizeDouble(NewStop,Xdigits)<=NormalizeDouble((OrderStopLoss()+(5/factor)),Xdigits)) modify=false;
      else modify=true;
      if(moveSLonlyIfInTradeDirection==true && NormalizeDouble(OrderStopLoss(),Xdigits)!=0)
        {
         if(NormalizeDouble(OrderStopLoss(),Xdigits)>=NormalizeDouble(NewStop,Xdigits))modify=false;
         else modify=true;
        }

     }//if (OrderType() == OP_BUY)

   if((OrderType()==OP_SELL))
     {

      NewStop=CalculateMASLSell(ticket,Xfactor,Xdigits);

      if(NormalizeDouble(NewStop,Xdigits)>=NormalizeDouble((OrderStopLoss()-(5/factor)),Xdigits)) modify=false;
      else modify=true;
      if(moveSLonlyIfInTradeDirection==true && NormalizeDouble(OrderStopLoss(),Xdigits)!=0)
        {
         if(NormalizeDouble(OrderStopLoss(),Xdigits)<=NormalizeDouble(NewStop,Xdigits))modify=false;
         else modify=true;
        }
     }//if (OrderType() == OP_SELL)

//Send the new stop loss 
   if(modify==true)
     {
      bool result=OrderModify(TicketNo,OrderOpenPrice(),NewStop,OrderTakeProfit(),OrderExpiration(),CLR_NONE);
      if(result==true && showAlerts==true)Alert("APTM ",OrderSymbol(),": ","MA depended SL moved to: ",DoubleToString(NewStop,Xdigits));
      if(!result && OrderType()==OP_SELL)
        {
         NewStop=NewStop+(0.1/Xfactor);
         result=OrderModify(TicketNo,OrderOpenPrice(),NewStop,OrderTakeProfit(),OrderExpiration(),CLR_NONE);
         if(result==false)ReportError(" APTM ",slm);

        }//if (!result)
      if(!result && OrderType()==OP_BUY)
        {
         NewStop=NewStop-(0.1/Xfactor);
         result=OrderModify(TicketNo,OrderOpenPrice(),NewStop,OrderTakeProfit(),OrderExpiration(),CLR_NONE);
         if(result==false)ReportError(" APTM ",slm);

        }//if (!result)

     }

  }//void SetInitialSL()
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
bool NewBar(int tf)
  {
   static datetime LastTime=0;
   if(iTime(NULL,tf,0)!=LastTime)
     {
      LastTime=iTime(NULL,tf,0);
      return (true);
     }
   else
      return (false);
  }
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
double MarginCalculate(string Xsymbol,double volume)
  {
   double leverage = AccountLeverage();
   double contract = MarketInfo(Xsymbol, MODE_LOTSIZE);
   return(contract*volume / leverage);

  }
//+------------------------------------------------------------------+
double GetProfitPair(string strSymbol)
  {
   double profit=0;
   double loti=0;
   double relevantLot=0;
   int orders=0;
   for(int i=OrdersTotal()-1; i>=0; i--)
     {
      if(!OrderSelect(i,SELECT_BY_POS)) continue;
      //if(OrderMagicNumber()!=nMagic) continue;
      if((excludeMagicNumber==true) && (OrderMagicNumber()==MagicNumberToExclude)) continue;
      if(ManageOnlyActualSymbol==true)
        {
         if(OrderSymbol()!=strSymbol) continue;
        }
      if(ManageByMagicNumber==true)
        {
         if(OrderMagicNumber()!=MagicNumber)continue;
        }
      if(ManageByOrderComment==true)
        {
         if(OrderComment()!=orderComment)continue;

        }
      if((OrderType()==OP_BUY) || (OrderType()==OP_SELL))

         profit=profit+(OrderProfit()+OrderSwap()+OrderCommission());
     }

   return(profit);
  }
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
double GetProfitPairPip(string strSymbol)
  {
   double profit=0;
   double profitpip=0;
   double profitpip_addition=0;
   double loti=0;
   double relevantLot=0;
   int Xdigits=0;
   int orders=0;
   for(int i=OrdersTotal()-1; i>=0; i--)
     {
      if(!OrderSelect(i,SELECT_BY_POS)) continue;
      //if(OrderMagicNumber()!=nMagic) continue;
      if(ManageOnlyActualSymbol==true)
        {
         if(OrderSymbol()!=strSymbol) continue;
        }
      if((excludeMagicNumber==true) && (OrderMagicNumber()==MagicNumberToExclude)) continue;
      if(ManageByMagicNumber==true)
        {
         if(OrderMagicNumber()!=MagicNumber)continue;
        }
      if(ManageByOrderComment==true)
        {
         if(OrderComment()!=orderComment)continue;

        }
      if((OrderType()==OP_BUY) || (OrderType()==OP_SELL))
         Xdigits=int(MarketInfo(OrderSymbol(),MODE_DIGITS));
      if(Xdigits==5) digiter=0.1;
      else if(Xdigits==3) digiter=0.1;
      else digiter=1;
      profit=(OrderProfit()+OrderSwap()+OrderCommission());
      profitpip=NormalizeDouble((NormalizeDouble(profit,2)/((MarketInfo(OrderSymbol(),MODE_TICKVALUE) *MarketInfo(OrderSymbol(),MODE_TICKSIZE))*OrderLots())*(MarketInfo(OrderSymbol(),MODE_POINT)*digiter)),2);
      profitpip_addition=profitpip_addition+profitpip;
     }

   return(profitpip_addition);
  }
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void     EnableAllHistory()
  {

   int main=GetAncestor(WindowHandle(Symbol(),Period()),3);
   PostMessageA(main,WM_COMMAND,MT4_WMCMD_ALL_HISTORY,0);
  }
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void ResetSLandTP()
  {
//----

   if(OrdersTotal()==0) return;
   if(showAlerts==true) Alert("APTM- Starting to reset SL/TP values");
   for(int cnt=0;cnt<OrdersTotal();cnt++)
     {

      bool order_select=OrderSelect(cnt,SELECT_BY_POS);
      if(order_select==false) return;
      if(OrderType() ==  OP_BUYLIMIT || OrderType() ==  OP_SELLLIMIT)continue;
      if(OrderType() ==  OP_BUYSTOP || OrderType() ==  OP_SELLSTOP)continue;
      if(ManageOnlyActualSymbol==true && OrderSymbol()!=Symbol()) continue;
      if((excludeMagicNumber==true) && (OrderMagicNumber()==MagicNumberToExclude)) continue;
      if(ManageByMagicNumber==true)
        {
         if(OrderMagicNumber()!=MagicNumber)continue;
        }
      if(ManageByOrderComment==true)
        {
         if(OrderComment()!=orderComment)continue;

        }
      int ticket=OrderModify(OrderTicket(),OrderOpenPrice(),0,0,0,CLR_NONE);

     }

   return;
  }
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
double CountBuyLot()
  {
   double nLotCount=0;
   for(int i=OrdersTotal()-1; i>=0; i--)
     {
      if(!OrderSelect(i,SELECT_BY_POS)) continue;
      if(ManageOnlyActualSymbol==true && OrderSymbol()!=Symbol()) continue;
      if((excludeMagicNumber==true) && (OrderMagicNumber()==MagicNumberToExclude)) continue;
      if(ManageByMagicNumber==true)
        {
         if(OrderMagicNumber()!=MagicNumber)continue;
        }
      if(ManageByOrderComment==true)
        {
         if(OrderComment()!=orderComment)continue;

        }
      if(OrderType()==OP_BUY)

         nLotCount=nLotCount+OrderLots();
     }
   return(nLotCount);
  }
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
double CountSellLot()
  {
   double nLotCount=0;
   for(int i=OrdersTotal()-1; i>=0; i--)
     {
      if(!OrderSelect(i,SELECT_BY_POS)) continue;
      if(ManageOnlyActualSymbol==true && OrderSymbol()!=Symbol()) continue;
      if((excludeMagicNumber==true) && (OrderMagicNumber()==MagicNumberToExclude)) continue;
      if(ManageByMagicNumber==true)
        {
         if(OrderMagicNumber()!=MagicNumber)continue;
        }
      if(ManageByOrderComment==true)
        {
         if(OrderComment()!=orderComment)continue;

        }
      if(OrderType()==OP_SELL)

         nLotCount=nLotCount+OrderLots();
     }
   return(nLotCount);
  }
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
string MinutesToTFString(int minutes)
  {
   switch(minutes)
     {
      case 1 :
         return("M1");
      case 2 :
         return("M2");
      case 3 :
         return("M3");
      case 4 :
         return("M4");
      case 5 :
         return("M5");
      case 6 :
         return("M6");
      case 10 :
         return("M10");
      case 11 :
         return("M11");
      case 15 :
         return("M15");
      case 22 :
         return("M22");
      case 30 :
         return("M30");
      case 33 :
         return("M33");
      case 60 :
         return("H1");
      case 120 :
         return("H2");
      case 180 :
         return("H3");
      case 240 :
         return("H4");
      case 1440 :
         return("D1");
      case 10080 :
         return("W1");
      case 43200 :
         return("MN1");
      default:
         return("OFF");
         break;
     }
  }
//   ************************* added for OBJ_LABEL
void removeAllObjects()
  {
   for(int i=ObjectsTotal()-1; i>=0; i--)
      if(StringFind(ObjectName(i),"OAM-",0)>-1)
         ObjectDelete(ObjectName(i));
  }//End void removeAllObjects()
//   ************************* added for OBJ_LABEL

void Display(string text)
  {

   string lab_str="OAM-"+(string)DisplayCount;
   double ofset=0;
   string textpart[5];
   for(int cc=0; cc<5; cc++)
     {
      textpart[cc]=StringSubstr(text,cc*63,64);
      if(StringLen(textpart[cc])==0) continue;
      ofset=cc*63*fontSize*spacingtweek;
      lab_str=lab_str+(string)cc;
      ObjectCreate(lab_str,OBJ_LABEL,0,0,0);
      ObjectSet(lab_str,OBJPROP_CORNER,0);
      ObjectSet(lab_str,OBJPROP_XDISTANCE,DisplayX+ofset);
      ObjectSet(lab_str,OBJPROP_YDISTANCE,DisplayY+DisplayCount*(fontSize+4));
      ObjectSet(lab_str,OBJPROP_BACK,false);
      ObjectSetText(lab_str,textpart[cc],fontSize,fontName,colour);
     }//for (int cc = 0; cc < 5; cc++) 
  }
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
string FormatNumber(double x,int width,int precision)
  {
   string p=DoubleToStr(x,precision);
   while(StringLen(p)<width)
      p="  "+p;
   return(p);
  }//End void Display(string text)
