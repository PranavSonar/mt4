//+------------------------------------------------------------------+
//|                                        CurrencySlopeStrength.mq4 |
//|                   Copyright 2012-16, Deltabron - Paul Geirnaerdt |
//|                                          http://www.deltabron.nl |
//+------------------------------------------------------------------+
//
// Parts based on CCFp.mq4, downloaded from mql4.com
// TMA Calculations © 2012 by ZZNBRM
// adaptions for the latest MT4 builds by milanese and again bug fixes
//some corrections, total adaption to property strict by milanese
// again added CHF as requested by milanese
//23 may,2014 modified for use without CHF milanese
//14 may,2014 modified milanese
//12/04/2014 added alerts by milanese
//09/04/2014 6xx build version by milanese
#property copyright "Copyright 2012-2016, Deltabron - Paul Geirnaerdt"
#property link      "http://www.deltabron.nl"
//----
#property indicator_separate_window
#property indicator_buffers 8

#define version            "v3.8"
#property strict




#define CURRENCYCOUNT      8

//---- parameters

extern string  gen               = "----General inputs----";
extern bool    autoSymbols       = False;
extern string   symbolsToWeigh="AUDCAD,AUDCHF,AUDJPY,AUDNZD,AUDUSD,CADJPY,CHFJPY,EURAUD,EURCAD,EURJPY,EURNZD,EURUSD,GBPAUD,GBPCAD,GBPCHF,GBPJPY,GBPNZD,GBPUSD,NZDCHF,NZDJPY,NZDUSD,USDCAD,USDCHF,USDJPY";//CADCHF,NZDCAD,EURCHF,EURGBP,
extern int     maxBars=200;
extern bool    weighOnlySymbolOnChart=false;
extern string  nonPropFont       = "Lucida Console";
extern bool    addSundayToMonday = true;
extern bool    showOnlySymbolOnChart=false;

extern string  ind               = "----Indicator inputs----";
extern bool    autoTimeFrame     = true;
extern string  ind_tf            = "timeFrame M1,M5,M15,M30,H1,H4,D1,W1,MN";
extern string  timeFrame         = "D1";
extern string  extraTimeFrame    = "D1";
extern bool    ignoreFuture      = true;
extern bool    showCrossAlerts   = true;
extern double  differenceThreshold=0.0;
extern bool    showLevelCross    = true;
extern double  levelCrossValue   = 0.20;
extern bool      PopupAlert=true;
extern bool      EmailAlert= false;
extern bool      PushAlert=false;

extern string  cur               = "----Currency inputs----";
extern bool    USD               = true;
extern bool    EUR               = true;
extern bool    GBP               = true;
extern bool    CHF               = true;
extern bool    JPY               = true;
extern bool    AUD               = true;
extern bool    CAD               = true;
extern bool    NZD               = true;

extern string  colour="----Colo(u)r inputs----";
extern color   Color_USD         = clrRed;
extern color   Color_EUR         = clrDeepSkyBlue;
extern color   Color_GBP         = clrRoyalBlue;
extern color   Color_CHF         = clrPaleTurquoise;
extern color   Color_JPY         = clrGold;
extern color   Color_AUD         = clrOrange;
extern color   Color_CAD         = clrMaroon;
extern color   Color_NZD         = clrTan;
extern int     line_widht_USD    = 1;
extern int     line_style_USD    = 0;
extern int     line_widht_EUR    = 1;
extern int     line_style_EUR    = 0;
extern int     line_widht_GBP    = 1;
extern int     line_style_GBP    = 0;
extern int     line_widht_JPY    = 1;
extern int     line_style_JPY    = 0;
extern int     line_widht_AUD    = 1;
extern int     line_style_AUD    = 0;
extern int     line_widht_CAD    = 1;
extern int     line_style_CAD    = 0;
extern int     line_widht_NZD    = 1;
extern int     line_style_NZD    = 0;
extern int     line_widht_CHF    = 1;
extern int     line_style_CHF    = 0;
extern color   colorWeakCross    = clrGold;
extern color   colorNormalCross  = clrGold;
extern color   colorStrongCross  = clrGold;
extern color   colorDifferenceUp = 0x303000;
extern color   colorDifferenceDn = 0x000030;
extern color   colorDifferenceLo = 0x005454;
extern color   colorTimeframe    = clrWhite;
extern color   colorLevelHigh    = clrLimeGreen;
extern color   colorLevelLow     = clrCrimson;


// global indicator variables
string   indicatorName="CurrencySlopeStrength";
string   shortName;
int      userTimeFrame;
int      userExtraTimeFrame;
string   almostUniqueIndex;
bool     sundayCandlesDetected;

// indicator buffers
double   arrUSD[];
double   arrEUR[];
double   arrGBP[];
double   arrJPY[];
double   arrAUD[];
double   arrCAD[];
double   arrNZD[];
double   arrCHF[];

// symbol & currency variables
int      symbolCount;
string   symbolNames[];
string   currencyNames[CURRENCYCOUNT]={ "USD","EUR","GBP","JPY","AUD","CAD","NZD","CHF" };
double   currencyValues[CURRENCYCOUNT];      // Currency slope strength
double   currencyValuesPrior[CURRENCYCOUNT]; // Currency slope strength prior bar
double   currencyOccurrences[CURRENCYCOUNT]; // Holds the number of occurrences of each currency in symbols
int   line_widht[CURRENCYCOUNT];
int   line_style[CURRENCYCOUNT];
color    currencyColors[CURRENCYCOUNT];

// object parameters
int      verticalShift=14;
int      verticalOffset=30;
int      horizontalShift=100;
int      horizontalOffset=10;
//----

//+------------------------------------------------------------------+
//| Custom indicator initialization function                         |
//+------------------------------------------------------------------+
int OnInit(void)
  {
   initSymbols();

   string now=string(TimeCurrent());
   almostUniqueIndex=StringSubstrOld(now,StringLen(now)-3)+IntegerToString(WindowsTotal());

//---- indicators
   shortName=indicatorName+" - "+version+" - id"+IntegerToString(WindowsTotal())+StringSubstrOld(now,StringLen(now)-1);
   IndicatorShortName(shortName);
//----
   currencyColors[0]=Color_USD;
   line_widht[0]=line_widht_USD;
   line_style[0]=line_style_USD;
   SetIndexBuffer(0,arrUSD);
   SetIndexLabel(0,"USD");

   currencyColors[1]=Color_EUR;
   line_widht[1]=line_widht_EUR;
   line_style[1]=line_style_EUR;
   SetIndexBuffer(1,arrEUR);
   SetIndexLabel(1,"EUR");

   currencyColors[2]=Color_GBP;
   line_widht[2]=line_widht_GBP;
   line_style[2]=line_style_GBP;
   SetIndexBuffer(2,arrGBP);
   SetIndexLabel(2,"GBP");

   currencyColors[3]=Color_JPY;
   line_widht[3]=line_widht_JPY;
   line_style[3]=line_style_JPY;
   SetIndexBuffer(3,arrJPY);
   SetIndexLabel(3,"JPY");

   currencyColors[4]=Color_AUD;
   line_widht[4]=line_widht_AUD;
   line_style[4]=line_style_AUD;
   SetIndexBuffer(4,arrAUD);
   SetIndexLabel(4,"AUD");

   currencyColors[5]=Color_CAD;
   line_widht[5]=line_widht_CAD;
   line_style[5]=line_style_CAD;
   SetIndexBuffer(5,arrCAD);
   SetIndexLabel(5,"CAD");

   currencyColors[6]=Color_NZD;
   line_widht[6]=line_widht_NZD;
   line_style[6]=line_style_NZD;
   SetIndexBuffer(6,arrNZD);
   SetIndexLabel(6,"NZD");
   currencyColors[7]=Color_CHF;
   line_widht[7]=line_widht_CHF;
   line_style[7]=line_style_CHF;
   SetIndexBuffer(7,arrCHF);
   SetIndexLabel(7,"CHF");
//----

   sundayCandlesDetected=false;
   for(int i=0; i<8; i++)
     {
      if(TimeDayOfWeek(iTime(NULL,PERIOD_D1,i))==0)
        {
         sundayCandlesDetected=true;
         break;
        }
     }

   if(weighOnlySymbolOnChart) showOnlySymbolOnChart=true;

   return(0);
  }
//+------------------------------------------------------------------+
//| Initialize Symbols Array                                         |
//+------------------------------------------------------------------+
int initSymbols()
  {
   int i;

// Get extra characters on this crimmal's symbol names
   string symbolExtraChars=StringSubstrOld(Symbol(),6,4);

   if(weighOnlySymbolOnChart)
     {
      symbolsToWeigh=Symbol();
     }

// Trim user input
   symbolsToWeigh = StringTrimLeft(symbolsToWeigh);
   symbolsToWeigh = StringTrimRight(symbolsToWeigh);

// Add extra comma
   if(StringSubstrOld(symbolsToWeigh,StringLen(symbolsToWeigh)-1)!=",")
     {
      symbolsToWeigh=StringConcatenate(symbolsToWeigh,",");
     }

// Build symbolNames array as the user likes it
   if(autoSymbols)
     {
      createSymbolNamesArray();
     }
   else
     {
      // Split user input
      i=StringFind(symbolsToWeigh,",");
      while(i!=-1)
        {
         int size=ArraySize(symbolNames);
         string newSymbol=StringConcatenate(StringSubstrOld(symbolsToWeigh,0,i),symbolExtraChars);

         ArrayResize(symbolNames,size+1);
         // Set array
         symbolNames[size]=newSymbol;

         // Trim symbols
         symbolsToWeigh=StringSubstrOld(symbolsToWeigh,i+1);
         i=StringFind(symbolsToWeigh,",");
        }
     }

// Kill unwanted symbols from array
   if(showOnlySymbolOnChart)
     {
      symbolCount=ArraySize(symbolNames);
      string tempNames[];
      for(i=0; i<symbolCount; i++)
        {
         for(int j=0; j<CURRENCYCOUNT; j++)
           {
            if(StringFind(Symbol(),currencyNames[j])==-1)
              {
               continue;
              }
            if(StringFind(symbolNames[i],currencyNames[j])!=-1)
              {
               int size=ArraySize(tempNames);
               ArrayResize(tempNames,size+1);
               tempNames[size]=symbolNames[i];
               break;
              }
           }
        }
      for(i=0; i<ArraySize(tempNames); i++)
        {
         ArrayResize(symbolNames,i+1);
         symbolNames[i]=tempNames[i];
        }
     }

   symbolCount=ArraySize(symbolNames);
// Print("symbolCount: ", symbolCount);

   for(i=0; i<symbolCount; i++)
     {
      // Increase currency occurrence
      int currencyIndex=getCurrencyIndex(StringSubstrOld(symbolNames[i],0,3));
      currencyOccurrences[currencyIndex]++;
      currencyIndex=getCurrencyIndex(StringSubstrOld(symbolNames[i],3,3));
      currencyOccurrences[currencyIndex]++;
     }

   userTimeFrame=PERIOD_D1;
   if(autoTimeFrame)
     {
      userTimeFrame=Period();
     }
   else
     {
      if(timeFrame=="M1") userTimeFrame=PERIOD_M1;
      else if( timeFrame == "M5" )  userTimeFrame = PERIOD_M5;
      else if( timeFrame == "M15" ) userTimeFrame = PERIOD_M15;
      else if( timeFrame == "M30" ) userTimeFrame = PERIOD_M30;
      else if( timeFrame == "H1" )  userTimeFrame = PERIOD_H1;
      else if( timeFrame == "H4" )  userTimeFrame = PERIOD_H4;
      else if( timeFrame == "D1" )  userTimeFrame = PERIOD_D1;
      else if( timeFrame == "W1" )  userTimeFrame = PERIOD_W1;
      else if( timeFrame == "MN" )  userTimeFrame = PERIOD_MN1;

      if(userTimeFrame<Period())
        {
         userTimeFrame=Period();
        }
     }
   userExtraTimeFrame = PERIOD_D1;
   if( extraTimeFrame == "M1" )       userExtraTimeFrame = PERIOD_M1;
   else if( extraTimeFrame == "M5" )  userExtraTimeFrame = PERIOD_M5;
   else if( extraTimeFrame == "M15" ) userExtraTimeFrame = PERIOD_M15;
   else if( extraTimeFrame == "M30" ) userExtraTimeFrame = PERIOD_M30;
   else if( extraTimeFrame == "H1" )  userExtraTimeFrame = PERIOD_H1;
   else if( extraTimeFrame == "H4" )  userExtraTimeFrame = PERIOD_H4;
   else if( extraTimeFrame == "D1" )  userExtraTimeFrame = PERIOD_D1;
   else if( extraTimeFrame == "W1" )  userExtraTimeFrame = PERIOD_W1;
   else if( extraTimeFrame == "MN" )  userExtraTimeFrame = PERIOD_MN1;
   return(0);
  }
//+------------------------------------------------------------------+
//| getCurrencyIndex(string currency)                                |
//+------------------------------------------------------------------+
int getCurrencyIndex(string currency)
  {
   for(int i=0; i<CURRENCYCOUNT; i++)
     {
      if(currencyNames[i]==currency)
        {
         return(i);
        }
     }
   return (-1);
  }
//+------------------------------------------------------------------+
//| createSymbolNamesArray()                                         |
//+------------------------------------------------------------------+
void createSymbolNamesArray()
  {
   int hFileName=FileOpenHistory("symbols.raw",FILE_BIN|FILE_READ);
   int recordCount=int(FileSize(hFileName)/1936);
   int counter=0;
   for(int i=0; i<recordCount; i++)
     {
      string tempSymbol=StringTrimLeft(StringTrimRight(FileReadString(hFileName,12)));
      if(MarketInfo(tempSymbol,MODE_BID)>0 && MarketInfo(tempSymbol,MODE_TRADEALLOWED))
        {
         ArrayResize(symbolNames,counter+1);
         symbolNames[counter]=tempSymbol;
         counter++;
        }
      FileSeek(hFileName,1924,SEEK_CUR);
     }
   FileClose(hFileName);

  }
//+------------------------------------------------------------------+
//| GetTimeframeString( int tf )                                     |
//+------------------------------------------------------------------+
string GetTimeframeString(int tf)
  {
   string result;
   switch(tf)
     {
      case PERIOD_M1:   result = "M1";    break;
      case PERIOD_M5:   result = "M5";    break;
      case PERIOD_M15:  result = "M15";   break;
      case PERIOD_M30:  result = "M30";   break;
      case PERIOD_H1:   result = "H1";    break;
      case PERIOD_H4:   result = "H4";    break;
      case PERIOD_D1:   result = "D1";    break;
      case PERIOD_W1:   result = "W1";    break;
      case PERIOD_MN1:  result = "MN1";   break;
      default: result="SRITSOD";
     }
   return ( result );
  }
//+------------------------------------------------------------------+
//| Custom indicator deinitialization function                       |
//+------------------------------------------------------------------+
void OnDeinit(const int reason)
  {
//----
   int windex=WindowFind(shortName);
   if(windex>0)
     {
      ObjectsDeleteAll(windex);
     }
//----

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
   int limit;
   int counted_bars=IndicatorCounted();

   if(counted_bars < 0)  return( -1 );
   if(counted_bars>0) counted_bars-=10;

   limit=Bars-counted_bars;

   if(maxBars>0)
     {
      limit=MathMin(maxBars,limit);
     }

   int i;

   for(i=0; i<CURRENCYCOUNT; i++)
     {
      SetIndexStyle(i,DRAW_LINE,line_style[i],line_widht[i],currencyColors[i]);
     }

   RefreshRates();

   int lowLimit=0;
   limit=WindowFirstVisibleBar();
   lowLimit=limit-WindowBarsPerChart();
   if(lowLimit<=0) lowLimit=0;
   int windex=WindowFind(shortName);

   for(i=limit; i>=lowLimit; i--)
     {

      double diff=0.0;

      ArrayInitialize(currencyValues,0.0);

      int bar=iBarShift(NULL,userTimeFrame,Time[i]);
      // Calc Slope into currencyValues[]  
      calcCSS(userTimeFrame,bar);

      if(( showOnlySymbolOnChart && (StringFind(Symbol(),"USD")!=-1)) || (!showOnlySymbolOnChart && USD))
        {
         arrUSD[i]=currencyValues[0];
         if(diff==0) diff+=currencyValues[0]; else diff-=currencyValues[0];
        }
      if(( showOnlySymbolOnChart && (StringFind(Symbol(),"EUR")!=-1)) || (!showOnlySymbolOnChart && EUR))
        {
         arrEUR[i]=currencyValues[1];
         if(diff==0) diff+=currencyValues[1]; else diff-=currencyValues[1];
        }
      if(( showOnlySymbolOnChart && (StringFind(Symbol(),"GBP")!=-1)) || (!showOnlySymbolOnChart && GBP))
        {
         arrGBP[i]=currencyValues[2];
         if(diff==0) diff+=currencyValues[2]; else diff-=currencyValues[2];
        }

      if(( showOnlySymbolOnChart && (StringFind(Symbol(),"JPY")!=-1)) || (!showOnlySymbolOnChart && JPY))
        {
         arrJPY[i]=currencyValues[3];
         if(diff==0) diff+=currencyValues[3]; else diff-=currencyValues[3];
        }
      if(( showOnlySymbolOnChart && (StringFind(Symbol(),"AUD")!=-1)) || (!showOnlySymbolOnChart && AUD))
        {
         arrAUD[i]=currencyValues[4];
         if(diff==0) diff+=currencyValues[4]; else diff-=currencyValues[4];
        }
      if(( showOnlySymbolOnChart && (StringFind(Symbol(),"CAD")!=-1)) || (!showOnlySymbolOnChart && CAD))
        {
         arrCAD[i]=currencyValues[5];
         if(diff==0) diff+=currencyValues[5]; else diff-=currencyValues[5];
        }
      if(( showOnlySymbolOnChart && (StringFind(Symbol(),"NZD")!=-1)) || (!showOnlySymbolOnChart && NZD))
        {
         arrNZD[i]=currencyValues[6];
         if(diff==0) diff+=currencyValues[6]; else diff-=currencyValues[6];
        }
      if(( showOnlySymbolOnChart && (StringFind(Symbol(),"CHF")!=-1)) || (!showOnlySymbolOnChart && CHF))
        {
         arrCHF[i]=currencyValues[7];
         if(diff==0) diff+=currencyValues[7]; else diff-=currencyValues[7];
        }

      if(i==1)
        {
         ArrayCopy(currencyValuesPrior,currencyValues);
        }
      if(i==0)
        {
         // Show ordered table
         ShowCurrencyTable(userTimeFrame);
         ShowCurrencyTable(userExtraTimeFrame,false);
        }

      // Only two currencies, show background
      if(showOnlySymbolOnChart)
        {
         // Create background object
         string objectName=almostUniqueIndex+"_diff_"+TimeToString(Time[i]);
         if(ObjectFind(objectName)==-1)
           {
            if(ObjectCreate(objectName,OBJ_VLINE,windex,Time[i],0))
              {
               ObjectSet(objectName,OBJPROP_BACK,true);
               ObjectSet(objectName,OBJPROP_WIDTH,8);
              }
           }
         // Determine background color
         if(MathAbs(diff)>differenceThreshold)
           {
            // Check diff sign
            double cssLong=currencyValues[getCurrencyIndex(StringSubstrOld(Symbol(),0,3))];
            double cssShort=currencyValues[getCurrencyIndex(StringSubstrOld(Symbol(),3,3))];
            if(cssLong>cssShort)
               ObjectSet(objectName,OBJPROP_COLOR,colorDifferenceUp);
            else
               ObjectSet(objectName,OBJPROP_COLOR,colorDifferenceDn);
           }
         else
           {
            // Below threshold
            ObjectSet(objectName,OBJPROP_COLOR,colorDifferenceLo);
           }
        }
     }



   if(showLevelCross)
     {
      string objectName=almostUniqueIndex+"_high";
      if(ObjectFind(objectName)==-1)
        {
         if(ObjectCreate(objectName,OBJ_HLINE,windex,0,levelCrossValue))
           {
            ObjectSet(objectName,OBJPROP_BACK,true);
            ObjectSet(objectName,OBJPROP_WIDTH,2);
            ObjectSet(objectName,OBJPROP_COLOR,colorLevelHigh);
           }
        }
      objectName=almostUniqueIndex+"_low";
      if(ObjectFind(objectName)==-1)
        {
         if(ObjectCreate(objectName,OBJ_HLINE,windex,0,-levelCrossValue))
           {
            ObjectSet(objectName,OBJPROP_BACK,true);
            ObjectSet(objectName,OBJPROP_WIDTH,2);
            ObjectSet(objectName,OBJPROP_COLOR,colorLevelLow);
           }
        }
     }

//--- OnCalculate done. Return new prev_calculated.
   return(rates_total);
  }
//+------------------------------------------------------------------+
//| getSlope()                                                       |
//+------------------------------------------------------------------+
double getSlope(string symbol,int tf,int shift)
  {
   double dblTma,dblPrev;
   int shiftWithoutSunday=shift;
   if(addSundayToMonday && sundayCandlesDetected && tf==PERIOD_D1)
     {
      if(TimeDayOfWeek(iTime(symbol,PERIOD_D1,shift))==0) shiftWithoutSunday++;
     }
   double atr=iATR(symbol,tf,100,shiftWithoutSunday+10)/10;
   double gadblSlope=0.0;
   if(atr!=0)
     {
      if(ignoreFuture)
        {
         // int barSymbol = iBarShift( symbol, tf, iTime( Symbol(), tf, shiftWithoutSunday ), true );
         dblTma=iMA(symbol,tf,21,0,MODE_LWMA,PRICE_CLOSE,shiftWithoutSunday);
         dblPrev=(iMA(symbol,tf,21,0,MODE_LWMA,PRICE_CLOSE,shiftWithoutSunday+1)*231+iClose(symbol,tf,shiftWithoutSunday)*20)/251;
        }
      else
        {
         dblTma=calcTma(symbol,tf,shiftWithoutSunday);
         dblPrev=calcTma(symbol,tf,shiftWithoutSunday+1);
        }
      gadblSlope=(dblTma-dblPrev)/atr;
     }

   return ( gadblSlope );

  }
//+------------------------------------------------------------------+
//| calcTma()                                                        |
//+------------------------------------------------------------------+
double calcTma(string symbol,int tf,int shift)
  {
   double dblSum  = iClose( symbol, tf, shift ) * 21;
   double dblSumw = 21;
   int jnx,knx;

   for(jnx=1,knx=20; jnx<=20; jnx++,knx--)
     {
      dblSum  += iClose(symbol, tf, shift + jnx) * knx;
      dblSumw += knx;

      if(jnx<=shift)
        {
         dblSum  += iClose(symbol, tf, shift - jnx) * knx;
         dblSumw += knx;
        }
     }

   return ( dblSum / dblSumw );
  }
//+------------------------------------------------------------------+
//| calcCSS(int tf, int shift                 |
//+------------------------------------------------------------------+
void calcCSS(int tf,int shift)
  {
   int i;
// Get Slope for all symbols and totalize for all currencies   
   for(i=0; i<symbolCount; i++)
     {
      double slope=getSlope(symbolNames[i],tf,shift);
      currencyValues[getCurrencyIndex(StringSubstrOld(symbolNames[i], 0, 3))] += slope;
      currencyValues[getCurrencyIndex(StringSubstrOld(symbolNames[i], 3, 3))] -= slope;
     }
   for(i=0; i<CURRENCYCOUNT; i++)
     {
      // average
      if(currencyOccurrences[i]>0) currencyValues[i]/=currencyOccurrences[i]; else currencyValues[i]=0;
     }
  }
//+------------------------------------------------------------------+
//| ShowCurrencyTable()                                              |
//+------------------------------------------------------------------+
void ShowCurrencyTable(int tf,bool mainTable=TRUE)
  {
   int i=0;
   int tempValue;
   int tempValue_2;
   string objectName;
   string showText;
   string showText_2;
   color showColor;
   int windex=WindowFind(shortName);
   int tableOffset=-100;
   if(mainTable) tableOffset=0;
   static datetime tLastAlert[8];
   static datetime tLastAlert_1[8];
   static datetime tLastAlert_2[8];

   if(showOnlySymbolOnChart)
     {
      // Header
      objectName=almostUniqueIndex+"_css_obj_column_currency_tf";
      if(ObjectFind(objectName)==-1)
        {
         if(ObjectCreate(objectName,OBJ_LABEL,windex,0,0))
           {
            ObjectSet(objectName,OBJPROP_CORNER,1);
            ObjectSet(objectName,OBJPROP_XDISTANCE,horizontalShift*0+horizontalOffset+70+tableOffset);
            ObjectSet(objectName,OBJPROP_YDISTANCE,verticalOffset-18);
           }
        }
      showText="TF ";
      ObjectSetText(objectName,showText,14,nonPropFont,colorTimeframe);

      objectName=almostUniqueIndex+"_css_obj_column_value_tf";
      if(ObjectFind(objectName)==-1)
        {
         if(ObjectCreate(objectName,OBJ_LABEL,windex,0,0))
           {
            ObjectSet(objectName,OBJPROP_CORNER,1);
            ObjectSet(objectName,OBJPROP_XDISTANCE,horizontalShift*0+horizontalOffset-65+70+tableOffset);
            ObjectSet(objectName,OBJPROP_YDISTANCE,verticalOffset-18);
           }
        }
      ObjectSetText(objectName,GetTimeframeString(tf),14,nonPropFont,colorTimeframe);

      // Chart symbols only
      // Loop currency values and header output objects, creating them if necessary 
      for(i=0; i<2; i++)
        {
         int index=getCurrencyIndex(StringSubstrOld(Symbol(),3*i,3));
         objectName=almostUniqueIndex+"_css_obj_column_currency_"+IntegerToString(i);
         if(ObjectFind(objectName)==-1)
           {
            if(ObjectCreate(objectName,OBJ_LABEL,windex,0,0))
              {
               ObjectSet(objectName,OBJPROP_CORNER,1);
               ObjectSet(objectName,OBJPROP_XDISTANCE,horizontalShift*0+horizontalOffset+70+tableOffset);
               ObjectSet(objectName,OBJPROP_YDISTANCE,(verticalShift+6) *(i+1)+verticalOffset-18);
              }
           }
         ObjectSetText(objectName,currencyNames[index],14,nonPropFont,currencyColors[index]);

         objectName=almostUniqueIndex+"_css_obj_column_value_"+IntegerToString(i);
         if(ObjectFind(objectName)==-1)
           {
            if(ObjectCreate(objectName,OBJ_LABEL,windex,0,0))
              {
               ObjectSet(objectName,OBJPROP_CORNER,1);
               ObjectSet(objectName,OBJPROP_XDISTANCE,horizontalShift*0+horizontalOffset-65+70+tableOffset);
               ObjectSet(objectName,OBJPROP_YDISTANCE,(verticalShift+6) *(i+1)+verticalOffset-18);
              }
           }
         showText=RightAlign(DoubleToStr(currencyValues[index],2),5);
         ObjectSetText(objectName,showText,14,nonPropFont,currencyColors[index]);
        }
      objectName=almostUniqueIndex+"_css_obj_column_currency_3";
      if(ObjectFind(objectName)==-1)
        {
         if(ObjectCreate(objectName,OBJ_LABEL,windex,0,0))
           {
            ObjectSet(objectName,OBJPROP_CORNER,1);
            ObjectSet(objectName,OBJPROP_XDISTANCE,horizontalShift*0+horizontalOffset+5+tableOffset);
            ObjectSet(objectName,OBJPROP_YDISTANCE,(verticalShift+6)*3+verticalOffset-10);
           }
        }
      showText="threshold = "+DoubleToStr(differenceThreshold,1);
      ObjectSetText(objectName,showText,8,nonPropFont,Yellow);
     }
   else
     {
      // Header
      objectName=almostUniqueIndex+"_css_obj_column_currency_tf"+GetTimeframeString(tf);
      if(ObjectFind(objectName)==-1)
        {
         if(ObjectCreate(objectName,OBJ_LABEL,windex,0,0))
           {
            ObjectSet(objectName,OBJPROP_CORNER,1);
            ObjectSet(objectName,OBJPROP_XDISTANCE,horizontalShift*0+horizontalOffset+150+tableOffset);
            ObjectSet(objectName,OBJPROP_YDISTANCE,(verticalShift+2)*i+verticalOffset-18);
           }
        }
      showText="TF ";
      ObjectSetText(objectName,showText,12,nonPropFont,colorTimeframe);

      objectName=almostUniqueIndex+"_css_obj_column_value_tf"+GetTimeframeString(tf);
      if(ObjectFind(objectName)==-1)
        {
         if(ObjectCreate(objectName,OBJ_LABEL,windex,0,0))
           {
            ObjectSet(objectName,OBJPROP_CORNER,1);
            ObjectSet(objectName,OBJPROP_XDISTANCE,horizontalShift*0+horizontalOffset-55+150+tableOffset);
            ObjectSet(objectName,OBJPROP_YDISTANCE,(verticalShift+2)*i+verticalOffset-18);
           }
        }
      ObjectSetText(objectName,GetTimeframeString(tf),12,nonPropFont,colorTimeframe);

      // Full table
      double tempCurrencyValues[CURRENCYCOUNT][3];
      ArrayInitialize(tempCurrencyValues,0.0);

      if(mainTable)
        {
         for(i=0; i<CURRENCYCOUNT; i++)
           {
            tempCurrencyValues[i][0] = currencyValues[i];
            tempCurrencyValues[i][1] = NormalizeDouble(currencyValuesPrior[i], 2);
            tempCurrencyValues[i][2] = i;

           }
        }
      else
        {
         for(i=0; i<symbolCount; i++)
           {
            double slope=getSlope(symbolNames[i],tf,0);
            tempCurrencyValues[getCurrencyIndex(StringSubstrOld(symbolNames[i], 0, 3))][0] += slope;
            tempCurrencyValues[getCurrencyIndex(StringSubstrOld(symbolNames[i], 3, 3))][0] -= slope;
           }
         for(i=0; i<CURRENCYCOUNT; i++)
           {
            tempCurrencyValues[i][2]=i;
            // average
            if(currencyOccurrences[i]>0) tempCurrencyValues[i][0]/=currencyOccurrences[i]; else tempCurrencyValues[i][0]=0;
           }
        }

      // Sort currency to values
      ArraySort(tempCurrencyValues,WHOLE_ARRAY,0,MODE_DESCEND);

      int horizontalOffsetCross=0;
      // Loop currency values and header output objects, creating them if necessary 
      for(i=0; i<CURRENCYCOUNT; i++)
        {
         objectName=almostUniqueIndex+"_css_obj_column_currency_"+GetTimeframeString(tf)+"_"+IntegerToString(i);
         if(ObjectFind(objectName)==-1)
           {
            if(ObjectCreate(objectName,OBJ_LABEL,windex,0,0))
              {
               ObjectSet(objectName,OBJPROP_CORNER,1);
               ObjectSet(objectName,OBJPROP_XDISTANCE,horizontalShift*0+horizontalOffset+150+tableOffset);
               ObjectSet(objectName,OBJPROP_YDISTANCE,(verticalShift+2) *(i+1)+verticalOffset-18);
              }
           }
         tempValue= int(tempCurrencyValues[i][2]);
         showText = currencyNames[tempValue];
         ObjectSetText(objectName,showText,12,nonPropFont,currencyColors[tempValue]);

         objectName=almostUniqueIndex+"_css_obj_column_value_"+GetTimeframeString(tf)+"_"+IntegerToString(i);
         if(ObjectFind(objectName)==-1)
           {
            if(ObjectCreate(objectName,OBJ_LABEL,windex,0,0))
              {
               ObjectSet(objectName,OBJPROP_CORNER,1);
               ObjectSet(objectName,OBJPROP_XDISTANCE,horizontalShift*0+horizontalOffset-55+150+tableOffset);
               ObjectSet(objectName,OBJPROP_YDISTANCE,(verticalShift+2) *(i+1)+verticalOffset-18);
              }
           }
         showText=RightAlign(DoubleToStr(tempCurrencyValues[i][0],2),5);
         ObjectSetText(objectName,showText,12,nonPropFont,currencyColors[tempValue]);

         // Continue if this is a secondary table
         if(!mainTable) continue;
         // PopUp alert Stuff
         if(showCrossAlerts
            && i<CURRENCYCOUNT-1
            && NormalizeDouble(tempCurrencyValues[i][0],2)>NormalizeDouble(tempCurrencyValues[i+1][0],2)
            && NormalizeDouble(tempCurrencyValues[i][1],2)<NormalizeDouble(tempCurrencyValues[i+1][1],2)
            )
           {
            if(tLastAlert[i]<Time[0])
              {
               tempValue=int(tempCurrencyValues[i][2]);
               tempValue_2=int(tempCurrencyValues[i+1][2]);
               showText=currencyNames[tempValue];
               showText_2=currencyNames[tempValue_2];
               fireAlerts(showText+" did a cross up "+showText_2);
               tLastAlert[i]=Time[0];
              }
           }



         // Detect and show crosses if users want to
         // Test for normalized values to filter trivial crosses
         objectName=almostUniqueIndex+"_css_obj_column_cross_"+IntegerToString(i);
         if(showCrossAlerts
            && i<CURRENCYCOUNT-1
            && NormalizeDouble(tempCurrencyValues[i][0],2)>NormalizeDouble(tempCurrencyValues[i+1][0],2)
            && tempCurrencyValues[i][1]<tempCurrencyValues[i+1][1]
            )
           {

            showColor=colorStrongCross;
            if(tempCurrencyValues[i][0]>0.8 || tempCurrencyValues[i+1][0]<-0.8)
              {
               showColor=colorWeakCross;

              }
            else if(tempCurrencyValues[i][0]>0.4 || tempCurrencyValues[i+1][0]<-0.4)
              {
               showColor=colorNormalCross;

              }


            // Prior values of this currency is lower than next currency, this is a cross.
            DrawCell(windex,objectName,horizontalShift*0+horizontalOffset+88+horizontalOffsetCross,(verticalShift+2) *(i+1)+verticalOffset-20,1,27,showColor);

            // Move cross location to next column if necessary
            if(horizontalOffsetCross==0)
              {
               horizontalOffsetCross=-4;
              }
            else
              {
               horizontalOffsetCross=0;
              }
           }
         else
           {
            DeleteCell(objectName);
            horizontalOffsetCross=0;
           }

         if(showLevelCross)
           {
            // Show level cross
            double currentValue=tempCurrencyValues[i][0];
            double priorValue=0;
            switch(tempValue)
              {
               case 0: priorValue = arrUSD[1]; break;
               case 1: priorValue = arrEUR[1]; break;
               case 2: priorValue = arrGBP[1]; break;
               case 3: priorValue = arrJPY[1]; break;
               case 4: priorValue = arrAUD[1]; break;
               case 5: priorValue = arrCAD[1]; break;
               case 6: priorValue = arrNZD[1]; break;
               case 7: priorValue = arrCHF[1]; break;
              }
            objectName=almostUniqueIndex+"_css_obj_column_level_"+IntegerToString(i);

            // START DEBUG CODE
            // DrawBullet( windex, objectName, horizontalShift * 0 + horizontalOffset - 55 + 136, (verticalShift + 2) * (i + 1) + verticalOffset - 21, colorLevelHigh );
            // showText = RightAlign(DoubleToStr(priorValue, 2), 5);
            // ObjectSetText ( objectName, showText, 12, nonPropFont, colorLevelHigh );
            // END DEBUG CODE


            //OLD CODE cross -20 and 0 up and +20 and 0 down

            // if ( priorValue > levelCrossValue && currentValue < levelCrossValue )
            //{
            //    DrawBullet( windex, objectName, horizontalShift * 0 + horizontalOffset - 55 + 136, (verticalShift + 2) * (i + 1) + verticalOffset - 21, colorLevelHigh );
            // }
            //  else if ( priorValue > 0 && currentValue < 0 )
            //  {
            //      DrawBullet( windex, objectName, horizontalShift * 0 + horizontalOffset - 55 + 136, (verticalShift + 2) * (i + 1) + verticalOffset - 21, colorLevelHigh );
            //  }
            //  else if ( priorValue < -levelCrossValue && currentValue > -levelCrossValue )
            //  {
            //     DrawBullet( windex, objectName, horizontalShift * 0 + horizontalOffset - 55 + 136, (verticalShift + 2) * (i + 1) + verticalOffset - 21, colorLevelLow );
            //  }
            //  else if ( priorValue < 0 && currentValue > 0 )
            //  {
            //     DrawBullet( windex, objectName, horizontalShift * 0 + horizontalOffset - 55 + 136, (verticalShift + 2) * (i + 1) + verticalOffset - 21, colorLevelLow );
            //  }
            //   else
            //  {
            //     ObjectDelete( objectName );

            //NEW CODE cross 0 +20 up and 0 -20 down
            if(priorValue>0 && currentValue<0)
              {
               DrawBullet(windex,objectName,horizontalShift*0+horizontalOffset-55+136,(verticalShift+2) *(i+1)+verticalOffset-21,colorLevelHigh);
              }
            if(priorValue<levelCrossValue && currentValue>levelCrossValue)// change from - to none
              {
               DrawBullet(windex,objectName,horizontalShift*0+horizontalOffset-55+136,(verticalShift+2) *(i+1)+verticalOffset-21,colorLevelHigh);
               if(tLastAlert_1[i]<Time[0])
                 {
                  showText=currencyNames[tempValue];
                  fireAlerts(showText+" did a cross up "+DoubleToStr(levelCrossValue,2));
                  tLastAlert_1[i]=Time[0];
                 }
              }
            if(priorValue<0 && currentValue>0)
              {
               DrawBullet(windex,objectName,horizontalShift*0+horizontalOffset-55+136,(verticalShift+2) *(i+1)+verticalOffset-21,colorLevelLow);
              }
            if(priorValue>-levelCrossValue && currentValue<-levelCrossValue)//change from none to -
              {
               DrawBullet(windex,objectName,horizontalShift*0+horizontalOffset-55+136,(verticalShift+2) *(i+1)+verticalOffset-21,colorLevelLow);
               if(tLastAlert_2[i]<Time[0])
                 {
                  showText=currencyNames[tempValue];
                  fireAlerts(showText+" did a cross down "+DoubleToStr(-levelCrossValue,2));
                  tLastAlert_2[i]=Time[0];
                 }
              }
            else
              {
               ObjectDelete(objectName);

               // break here if changing back to old code.
              }
           }
        }
     }
  }
//+------------------------------------------------------------------+
//| Right Align Text                                                 |
//+------------------------------------------------------------------+
string RightAlign(string text,int length=10,int trailing_spaces=0)
  {
   string text_aligned=text;
   for(int i=0; i<length-StringLen(text)-trailing_spaces; i++)
     {
      text_aligned=" "+text_aligned;
     }
   return ( text_aligned );
  }
//+------------------------------------------------------------------+
//| DrawCell(), credits go to Alexandre A. B. Borela                 |
//+------------------------------------------------------------------+
void DrawCell(int nWindow,string nCellName,double nX,double nY,double nWidth,double nHeight,color nColor)
  {
   double   iHeight,iWidth,iXSpace;
   int      iSquares,i;

   if(nWidth>nHeight)
     {
      iSquares=int(MathCeil(nWidth/nHeight)); // Number of squares used.
      iHeight  = MathRound( ( nHeight * 100 ) / 77 ); // Real height size.
      iWidth   = MathRound ( ( nWidth * 100 ) / 77 ); // Real width size.
      iXSpace  = iWidth / iSquares - ( ( iHeight / ( 9 - ( nHeight / 100 ) ) ) * 2 );

      for(i=0; i<iSquares; i++)
        {
         ObjectCreate(nCellName+IntegerToString(i),OBJ_LABEL,nWindow,0,0);
         ObjectSetText(nCellName+IntegerToString(i),CharToStr(110),int(iHeight),"Wingdings",nColor);
         ObjectSet(nCellName+IntegerToString(i),OBJPROP_CORNER,1);
         ObjectSet(nCellName+IntegerToString(i),OBJPROP_XDISTANCE,nX+iXSpace*i);
         ObjectSet(nCellName+IntegerToString(i),OBJPROP_YDISTANCE,nY);
         ObjectSet(nCellName+IntegerToString(i),OBJPROP_BACK,true);
        }
     }
   else
     {
      iSquares=int(MathCeil(nHeight/nWidth)); // Number of squares used.
      iHeight  = MathRound( ( nHeight * 100 ) / 77 ); // Real height size.
      iWidth   = MathRound ( ( nWidth * 100 ) / 77 ); // Real width size.
      iXSpace  = iHeight / iSquares - ( ( iWidth / ( 9 - ( nWidth / 100 ) ) ) * 2 );

      for(i=0; i<iSquares; i++)
        {
         ObjectCreate(nCellName+IntegerToString(i),OBJ_LABEL,nWindow,0,0);
         ObjectSetText(nCellName+IntegerToString(i),CharToStr(110),int(iWidth),"Wingdings",nColor);
         ObjectSet(nCellName+IntegerToString(i),OBJPROP_CORNER,1);
         ObjectSet(nCellName+IntegerToString(i),OBJPROP_XDISTANCE,nX);
         ObjectSet(nCellName+IntegerToString(i),OBJPROP_YDISTANCE,nY+iXSpace*i);
         ObjectSet(nCellName+IntegerToString(i),OBJPROP_BACK,true);
        }
     }
  }
//+------------------------------------------------------------------+
//| DeleteCell()                                                     |
//+------------------------------------------------------------------+
void DeleteCell(string name)
  {
   int square=0;
   while(ObjectFind(name+IntegerToString(square))>-1)
     {
      ObjectDelete(name+IntegerToString(square));
      square++;
     }
  }
//+------------------------------------------------------------------+
//| DrawBullet()                                                     |
//+------------------------------------------------------------------+
void DrawBullet(int window,string cellName,int col,int row,color bulletColor)
  {
   if(ObjectFind(cellName)==-1)
     {
      if(ObjectCreate(cellName,OBJ_LABEL,window,0,0))
        {
         ObjectSet(cellName,OBJPROP_CORNER,1);
         ObjectSet(cellName,OBJPROP_XDISTANCE,col);
         ObjectSet(cellName,OBJPROP_YDISTANCE,row);
         ObjectSet(cellName,OBJPROP_BACK,true);
         ObjectSetText(cellName,CharToStr(108),12,"Wingdings",bulletColor);
        }
     }
  }
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void fireAlerts(string sMsg)
  {

   if(PopupAlert)
      Alert(sMsg);

   if(EmailAlert)
      SendMail("CSS Alert "+"",sMsg);
   if(PushAlert)
      SendNotification(sMsg);
  }
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
string StringSubstrOld(string x,int a,int b=-1) 
  {
   if(a<0) a=0; // Stop odd behaviour
   if(b<=0) b=-1; // new MQL4 EOL flag
   return StringSubstr(x,a,b);
  }
//+------------------------------------------------------------------+
