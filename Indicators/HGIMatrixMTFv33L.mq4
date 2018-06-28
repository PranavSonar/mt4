//+------------------------------------------------------------------+
//|                                                    HGIMatrix.mq4 |
//|                                http://www.flashwebdesign.com.au/ |
//| This indicator was developed by renexxxx from the                |
//|    http://www.stevehopwoodforex.com/ forum.                      |
//+------------------------------------------------------------------+
#property copyright "renexxxx"
#property link      "http://www.stevehopwoodforex.com/"
#property version   "33.50"
#property strict
#property indicator_chart_window
#include <hgi_lib.mqh>

#import "user32.dll"
   int      GetParent(int hWnd);
   int      SendMessageW(int hWnd,int Msg,int wParam,int lParam);
#import
#define WM_MDIACTIVATE 0x222

//+------------------------------------------------------------------+
//| Custom indicator initialization function                         |
//+------------------------------------------------------------------+
#define screenFont "tahoma"
#define INF     0x6FFFFFFF
#define CAPTION "HGI Matrix"
#define MAX_TIMEFRAMES 5

enum LWMATREND {
   UNKNOWN
,  LWMAUP
,  LWMADN
,  LWMARANGE };

struct ELEMENT {
   string symbol;
   bool    selected;
   int     timeFrame;
   SIGNAL  signal;
   int     signalShift;
   bool    hurstOK;       // Direction is in agreement with hurst (i.e. if BUY: hurst5 < hurst11, if SELL: hurst5 > hurst11)
   LWMATREND lwmaTrend;   // Old-fashioned TREND Direction by looking at LWMA60 and LWMA240 on H4
   double  atr;
   SIGNAL  oldSignal;
   SLOPE   slope;
   int     slopeShift;
   SLOPE   oldSlope;
};

static string currencies[] = { "AUD", "CAD", "CHF", "GBP", "EUR", "JPY", "NZD", "USD" }; 
static color  tableBorderColor     = clrWhite;
static color  tableHeadBackColor   = clrDarkBlue;
static color  tableHeadTextColor   = clrWhite;
static color  tableBackColor       = clrLightGray;
static color  tableCellBackColor   = clrBlack;
static color  captionTextColor     = clrYellow;
static color  captionBackColor     = clrBlack;

ELEMENT symbols[][MAX_TIMEFRAMES];

//AUDCAD,AUDCHF,AUDJPY,AUDNZD,AUDUSD,CADCHF,CADJPY,CHFJPY,EURAUD,EURCAD,EURCHF,EURGBP,EURJPY,EURNZD,EURUSD,GBPAUD,GBPCAD,GBPCHF,GBPJPY,GBPNZD,GBPUSD,NZDCAD,NZDCHF,NZDJPY,NZDUSD,USDCAD,USDCHF,USDJPY";
input string          IncludeSymbols     = "";
input string          ExcludeSymbols     = "";
input string          ExcludeExtensions  = "";
input string          TimeFrames         = "240:10,60:30,15:100";    // Comma-separated list of timeFrame:maxBarLookback tuples
input string          TemplateName       = "default";   // Template Name for opening charts 
input int             CellWidth          = 90;
input int             CellHeight         = 60;
input int             XOffSet            = 10;
input int             YOffSet            = 10;
input bool            UseClosedCandle    = false;
input bool            ShowMostRecentSignal = true;
input bool            ShowBarNo          = true;
input bool            ShowHurst          = true;
input bool            ShowOnlyHurst      = false;
input bool            AlertOnlyHurst     = true;
input bool            ShowTrendSignal    = true;
input bool            ShowRangeSignal    = true;
input bool            ShowRadSignal      = true;
input bool            ShowTrend          = true;
input bool            ShowFlash          = true;
input bool            ShowATR            = true;
input int             ATRTimeFrame       = PERIOD_D1;
input int             ATRPeriod          = 20;
input double          ATRThreshold       = 100.0;
input bool            ShowOnlyATR        = false;       // ShowOnlyATR: if true, filter by ATR < Threshold
input int             ScreenHeight       = 720;
input int             MaxBarLookback     = 200;
input bool            AlertsOn           = false;
input bool            NotificationsOn    = false;
input bool            AlertsToFile       = true;
input string          AlertOnTrendChange = "1440,240,15";
input string          AlertOnRangeChange = "";
input string          AlertOnRadChange   = "240";
input string          AlertOnRangeWave   = "240";
input string          AlertOnTrendWave   = "240";
input string          SymbolFont         = "WingDings";
input color           ClrRangeWave       = clrOrange;
input color           ClrTrendWave       = clrDodgerBlue;
input color           ClrAlert           = clrDarkRed;
input color           ClrSelect          = clrNavy;
input color           ClrHurst           = clrDarkGreen;

struct TIMEFRAME {
   int timeframe;
   int maxLookBack;
};

TIMEFRAME timeFrames[];
int trendChangeTimeFrames[];
int rangeChangeTimeFrames[];
int radChangeTimeFrames[];
int rangeWaveChangeTimeFrames[];
int trendWaveChangeTimeFrames[];

struct FLASHER {
   string objectName;
   color  objectColor;
};

FLASHER flashingObject[];

string objPrefix;
string captionText;
bool inInit = false;

int OnInit() {
   
   // Initialize Seed for Random Generator
   MathSrand( (uint)TimeLocal() );
   
   // Set 'unique' objPrefix to allow multiple matrices on a chart
   objPrefix = StringFormat("x%d:y%d_",XOffSet,YOffSet);
   deleteAllObjects();
   
   // Set the Caption Text
   captionText = CAPTION;
   
   // Parse the selected timeFrames
   convertTF( TimeFrames, timeFrames );
   convertTF( AlertOnTrendChange, trendChangeTimeFrames );
   convertTF( AlertOnRangeChange, rangeChangeTimeFrames );
   convertTF( AlertOnRadChange, radChangeTimeFrames );
   convertTF( AlertOnRangeWave, rangeWaveChangeTimeFrames );
   convertTF( AlertOnTrendWave, trendWaveChangeTimeFrames );
   
   // Initialize symbols[] array
   discoverSymbols();
   
   // Set timer for every 500 milliseconds
   EventSetMillisecondTimer(500);
   
   // Move the candles to the background   
   ChartSetInteger(ChartID(),CHART_FOREGROUND,false);
/* // Switch off the chart colors;
   ChartSetInteger(ChartID(),CHART_COLOR_BACKGROUND,clrBlack);
   ChartSetInteger(ChartID(),CHART_COLOR_FOREGROUND,clrNONE);
   ChartSetInteger(ChartID(),CHART_COLOR_GRID,clrNONE);
   ChartSetInteger(ChartID(),CHART_COLOR_VOLUME,clrNONE);
   ChartSetInteger(ChartID(),CHART_COLOR_CHART_UP,clrNONE);
   ChartSetInteger(ChartID(),CHART_COLOR_CHART_DOWN,clrNONE);
   ChartSetInteger(ChartID(),CHART_COLOR_CHART_LINE,clrNONE);
   ChartSetInteger(ChartID(),CHART_COLOR_CANDLE_BULL,clrNONE);
   ChartSetInteger(ChartID(),CHART_COLOR_CANDLE_BEAR,clrNONE);
   ChartSetInteger(ChartID(),CHART_COLOR_BID,clrNONE);
   ChartSetInteger(ChartID(),CHART_COLOR_ASK,clrNONE);
   ChartSetInteger(ChartID(),CHART_COLOR_LAST,clrNONE);
   ChartSetInteger(ChartID(),CHART_COLOR_STOP_LEVEL,clrNONE);*/

   // This has been added to avoid having Alert the first time round
   inInit = true;

   return(INIT_SUCCEEDED);
}

void OnDeinit( const int reason ) {

   deleteAllObjects();

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
                const int &spread[]) {

   static datetime nextTime = -1;

   if ( nextTime < TimeCurrent() ) {
      // Calculate the status for the symbols and draw the list
      calcSymbols();
      drawList();
      
      nextTime = TimeCurrent() + 60;
   }
   
//--- return value of prev_calculated for next call
   return(rates_total);
  }

//+------------------------------------------------------------------+
//| Timer function                                                   |
//+------------------------------------------------------------------+
void OnTimer() {
//---
   // Flash all FLASHER objects
   if (ShowFlash) flashObjects( flashingObject );
}

//+------------------------------------------------------------------+
//| discoverSymbols()                                                |
//+------------------------------------------------------------------+
void discoverSymbols() {

   static const ushort comma = StringGetChar(",",0);
   string tempSymbols[];
   string tempSymbol;

   // Empty symbol-array
   ArrayFree( symbols );
   ArrayResize( symbols, 0 );

   // Get the included symbols
   string tempString = IncludeSymbols;
   string includeSymbols[];
   ArrayResize(tempSymbols,0);
   StringSplit(tempString, comma, tempSymbols );
   for(int iSymbol=0; iSymbol<ArraySize(tempSymbols); iSymbol++) {
      tempSymbol = StringTrimLeft( StringTrimRight( tempSymbols[iSymbol] ) );
      if ( tempSymbol == "NULL" ) tempSymbol = Symbol();
      addToStringArray( includeSymbols, tempSymbol );
   }

   // Get the excluded symbols
   tempString = ExcludeSymbols;
   string excludeSymbols[];
   ArrayResize(tempSymbols,0);
   StringSplit(tempString, comma, tempSymbols );
   for(int iSymbol=0; iSymbol<ArraySize(tempSymbols); iSymbol++) {
      tempSymbol = StringTrimLeft( StringTrimRight( tempSymbols[iSymbol] ) );
      if ( tempSymbol == "NULL" ) tempSymbol = Symbol();
      addToStringArray( excludeSymbols, tempSymbol );
   }

   // Get the excluded extensions
   tempString = ExcludeExtensions;
   string excludeExtensions[];
   ArrayResize(tempSymbols,0);
   StringSplit(tempString, comma, tempSymbols );
   for(int iSymbol=0; iSymbol<ArraySize(tempSymbols); iSymbol++) {
      tempSymbol = StringTrimLeft( StringTrimRight( tempSymbols[iSymbol] ) );
      addToStringArray( excludeExtensions, tempSymbol );
   }

   // Get the market symbols
   int hFileName = FileOpenHistory ("symbols.raw", FILE_BIN|FILE_READ );
   int recordCount = (int)FileSize ( hFileName ) / 1936;
   string marketSymbols[];
   for ( int i = 0; i < recordCount; i++ ) {
      tempSymbol = StringTrimLeft ( StringTrimRight ( FileReadString ( hFileName, 12 ) ) );
      if ( MarketInfo ( tempSymbol, MODE_BID ) > 0 ) {
         addToStringArray(marketSymbols,tempSymbol);
      }
      FileSeek( hFileName, 1924, SEEK_CUR );
   }
   FileClose( hFileName );
   
   int counter = 0;

   // If includeSymbols is empty, we take all marketSymbols minus the excludeSymbols, minus those with an extension in excludeExtensions
   if ( ArraySize(includeSymbols) == 0 ) {
   
      for(int iSymbol=0; iSymbol<ArraySize(marketSymbols); iSymbol++) {
      
         if ( ( findInStringArray(excludeSymbols, marketSymbols[iSymbol]) < 0 ) && ( findInStringArray(excludeExtensions, StringSubstr(marketSymbols[iSymbol],6 )) < 0 ) ) {
      
            ArrayResize( symbols, counter + 1 );
            for(int itf=0; itf < ArraySize(timeFrames); itf++) {
               symbols[counter][itf].symbol = marketSymbols[iSymbol];
               symbols[counter][itf].selected = false;
               if ( GlobalVariableCheck( StringFormat("%s%s_select",objPrefix,symbols[counter][itf].symbol) ) ) {
                  symbols[counter][itf].selected = (bool)GlobalVariableGet( StringFormat("%s%s_select",objPrefix,symbols[counter][itf].symbol) );
               }
               symbols[counter][itf].timeFrame = timeFrames[itf].timeframe;
               symbols[counter][itf].signal = NONE;
               symbols[counter][itf].signalShift = 0;
               symbols[counter][itf].hurstOK = false;
               symbols[counter][itf].lwmaTrend = UNKNOWN;
               symbols[counter][itf].atr = 0.0;
               symbols[counter][itf].oldSignal = NONE;
               symbols[counter][itf].slope  = UNDEFINED;
               symbols[counter][itf].slopeShift = 0;
               symbols[counter][itf].oldSlope = UNDEFINED;
            }
            counter++;

         }
         
      }
      
   }
   // Else If includeSymbols is not empty, we take all symbols in includeSymbols minus the excludeSymbols, as long as they are in marketSymbols, and as long as their
   // extension is not in excludeExtensions
   else {

      for(int iSymbol=0; iSymbol<ArraySize(includeSymbols); iSymbol++) {
      
         PrintFormat("includeSymbols[%d] == %s", iSymbol, includeSymbols[iSymbol]);
      
         if ( (findInStringArray(excludeSymbols, includeSymbols[iSymbol]) < 0) && (findInStringArray(marketSymbols, includeSymbols[iSymbol]) >= 0) && ( findInStringArray(excludeExtensions, StringSubstr(includeSymbols[iSymbol],6 )) < 0 ) ) {
      
            ArrayResize( symbols, counter + 1 );
            for(int itf=0; itf < ArraySize(timeFrames); itf++) {
               symbols[counter][itf].symbol = includeSymbols[iSymbol];
               symbols[counter][itf].selected = false;
               if ( GlobalVariableCheck( StringFormat("%s%s_select",objPrefix,symbols[counter][itf].symbol) ) ) {
                  symbols[counter][itf].selected = (bool)GlobalVariableGet( StringFormat("%s%s_select",objPrefix,symbols[counter][itf].symbol) );
               }
               symbols[counter][itf].timeFrame = timeFrames[itf].timeframe;
               symbols[counter][itf].signal = NONE;
               symbols[counter][itf].signalShift = 0;
               symbols[counter][itf].hurstOK = false;
               symbols[counter][itf].lwmaTrend = UNKNOWN;
               symbols[counter][itf].atr = 0.0;
               symbols[counter][itf].oldSignal = NONE;
               symbols[counter][itf].slope  = UNDEFINED;
               symbols[counter][itf].slopeShift = 0;
               symbols[counter][itf].oldSlope = UNDEFINED;
            }
            counter++;

         }
         
      }
      
   }
      
}


int findInStringArray( string &array[], string elem ) {

   int index = -1;
   for(int i = 0; i < ArraySize(array); i++) {
      if ( array[i] == elem ) {
         index = i;
         break;
      }
   }
   return(index);
}

void addToStringArray( string &array[], string elem ) {

   if ( (StringLen(elem) > 0) && ( findInStringArray( array, elem ) < 0 ) ) {
      int currentSize = ArraySize(array);
      ArrayResize(array, currentSize+1);
      array[currentSize] = elem;
   }
}

void calcSymbols() {

   //Print("Recalculating ... ");

   int shiftStart = ( UseClosedCandle ) ? 1 : 0;
   SIGNAL theSignal;
   SLOPE theSlope;
   int timeFrame;
   
   //Alert(StringFormat("calcSymbols: number of symbols == %d, number of timeFrames == %d", ArrayRange(symbols,0), ArraySize(timeFrames) ) );

   for (int itf=0; itf < ArraySize(timeFrames); itf++) {

      // Set the timeFrame
      timeFrame = timeFrames[itf].timeframe;
      int shiftEnd   = ( ShowMostRecentSignal ) ? timeFrames[itf].maxLookBack : shiftStart+1;
      
      for (int iSymbol = 0; iSymbol < ArrayRange(symbols,0); iSymbol++) {
           
         symbols[iSymbol][itf].signal = NONE;
         symbols[iSymbol][itf].signalShift = 0;
         symbols[iSymbol][itf].hurstOK = false;
         symbols[iSymbol][itf].lwmaTrend = UNKNOWN;
         symbols[iSymbol][itf].atr = 0.0;
         symbols[iSymbol][itf].slope  = UNDEFINED;
         symbols[iSymbol][itf].slopeShift = 0;
   
         // First set the signal
         for(int shift=shiftStart; (shift < shiftEnd); shift++) {
            theSignal = getHGISignal( symbols[iSymbol][itf].symbol, timeFrame, shift );
            if ( !ShowTrendSignal && ( (theSignal == TRENDUP) || (theSignal == TRENDDN) ) ) continue;
            if ( !ShowRangeSignal && ( (theSignal == RANGEUP) || (theSignal == RANGEDN) ) ) continue;
            if ( !ShowRadSignal && ( (theSignal == RADUP) || (theSignal == RADDN) ) ) continue;
            if ( theSignal != NONE ) {
               symbols[iSymbol][itf].signal = theSignal;
               symbols[iSymbol][itf].signalShift = shift;
               break;
            }
         }

         // Same for the slope
         for(int shift=shiftStart; (shift < shiftEnd); shift++) {
            theSlope = getHGISlope( symbols[iSymbol][itf].symbol, timeFrame, shift );
            if ( theSlope != UNDEFINED ) {
               symbols[iSymbol][itf].slope = theSlope;
               symbols[iSymbol][itf].slopeShift = shift;
               break;
            }
         }
   
         if ( ShowHurst ) {
            // Workout hurst direction
            double hurst5 = getHurst( symbols[iSymbol][itf].symbol, timeFrame, shiftStart );
            double hurst11 = getHurst( symbols[iSymbol][itf].symbol, timeFrame, shiftStart, 11 );
            
            if ( (hurst5 < hurst11) && ( (symbols[iSymbol][itf].signal == TRENDUP) || (symbols[iSymbol][itf].signal == RANGEUP) || (symbols[iSymbol][itf].signal == RADUP) ) ) {
               symbols[iSymbol][itf].hurstOK = true;
            }
            else if ( (hurst5 > hurst11) && ( (symbols[iSymbol][itf].signal == TRENDDN) || (symbols[iSymbol][itf].signal == RANGEDN) || (symbols[iSymbol][itf].signal == RADDN) ) ) {
               symbols[iSymbol][itf].hurstOK = true;
            }
         }
         
         if ( ShowTrend && (itf == 0)) {
            double lwma60 = iMA( symbols[iSymbol][itf].symbol, PERIOD_H4, 60, 0, MODE_LWMA, PRICE_OPEN, 0 );
            double lwma240 = iMA( symbols[iSymbol][itf].symbol, PERIOD_H4, 240, 0, MODE_LWMA, PRICE_OPEN, 0 );
            double bid = MarketInfo( symbols[iSymbol][itf].symbol, MODE_BID );
            double ask = MarketInfo( symbols[iSymbol][itf].symbol, MODE_ASK );
            
            if ( (bid > lwma60) && (bid > lwma240) ) {
               symbols[iSymbol][itf].lwmaTrend = LWMAUP;
            }
            else if ( (ask < lwma60) && (ask < lwma240) ) {
               symbols[iSymbol][itf].lwmaTrend = LWMADN;
            }
            else {
               symbols[iSymbol][itf].lwmaTrend = LWMARANGE;
            }
         }

         if ( ShowATR && (itf == 0)) {
            symbols[iSymbol][itf].atr = iATR( symbols[iSymbol][itf].symbol, ATRTimeFrame, ATRPeriod, 1 ) * GetPipFactor( symbols[iSymbol][itf].symbol );
         }

         if ( !inInit && (AlertsOn || NotificationsOn || AlertsToFile) ) {
            if ( (symbols[iSymbol][itf].signal != NONE) && ( symbols[iSymbol][itf].signal != symbols[iSymbol][itf].oldSignal ) && ( !ShowHurst || !AlertOnlyHurst || ( AlertOnlyHurst && symbols[iSymbol][itf].hurstOK ) ) ) {
               string message = "";
               
               if ( (findInIntArray(trendChangeTimeFrames, timeFrame) >= 0) && ( ( symbols[iSymbol][itf].signal == TRENDUP ) ) ) {
                  message = StringFormat( "TREND UP signal for %s on %s (%d)", symbols[iSymbol][itf].symbol, GetTimeframeString(timeFrame), symbols[iSymbol][itf].signalShift );   //TRENDUP Alert
               }
               else if ( (findInIntArray(trendChangeTimeFrames, timeFrame) >= 0) && ( ( symbols[iSymbol][itf].signal == TRENDDN ) ) ) {
                  message = StringFormat( "TREND DOWN signal for %s on %s (%d)", symbols[iSymbol][itf].symbol, GetTimeframeString(timeFrame), symbols[iSymbol][itf].signalShift ); //TREND DOWN Alert
               }
                else if ( (findInIntArray(rangeChangeTimeFrames, timeFrame) >= 0) && ( ( symbols[iSymbol][itf].signal == RANGEUP ) ) ) {
                  message = StringFormat( "RANGE UP signal for %s on %s (%d)", symbols[iSymbol][itf].symbol, GetTimeframeString(timeFrame), symbols[iSymbol][itf].signalShift );   //RANGE UP Alert
               }           
               else if ( (findInIntArray(rangeChangeTimeFrames, timeFrame) >= 0) && ( ( symbols[iSymbol][itf].signal == RANGEDN ) ) ) {
                  message = StringFormat( "RANGE DOWN signal for %s on %s (%d)", symbols[iSymbol][itf].symbol, GetTimeframeString(timeFrame), symbols[iSymbol][itf].signalShift ); //RANGE DOWN Alert
               }
               else if ( (findInIntArray(radChangeTimeFrames, timeFrame) >= 0) && ( ( symbols[iSymbol][itf].signal == RADUP ) ) ) {
                  message = StringFormat( "RAD UP signal for %s on %s (%d)", symbols[iSymbol][itf].symbol, GetTimeframeString(timeFrame), symbols[iSymbol][itf].signalShift );     //RAD UP Alert
               }
               else if ( (findInIntArray(radChangeTimeFrames, timeFrame) >= 0) && ( ( symbols[iSymbol][itf].signal == RADDN ) ) ) {
                  message = StringFormat( "RAD DOWN signal for %s on %s (%d)", symbols[iSymbol][itf].symbol, GetTimeframeString(timeFrame), symbols[iSymbol][itf].signalShift );   //RAD DOWN Alert
               }
               if ( (message != "") && AlertsOn ) Alert( message );
               if ( (message != "") && NotificationsOn ) SendNotification( message );
               if ( (message != "") && AlertsToFile ) SaveText( message );
            }
            if ( (symbols[iSymbol][itf].slope != UNDEFINED) && ( symbols[iSymbol][itf].slope != symbols[iSymbol][itf].oldSlope ) && ( !ShowHurst || !AlertOnlyHurst || ( AlertOnlyHurst && symbols[iSymbol][itf].hurstOK ) ) ) {
               string message = "";
               if ( (findInIntArray(rangeWaveChangeTimeFrames, timeFrame) >= 0) && ( symbols[iSymbol][itf].slope == RANGEABOVE ) ) {
                  message = StringFormat( "RANGE Wave Above for %s on %s (%d)", symbols[iSymbol][itf].symbol, GetTimeframeString(timeFrame), symbols[iSymbol][itf].slopeShift );
               }
               else if ( (findInIntArray(rangeWaveChangeTimeFrames, timeFrame) >= 0) && ( symbols[iSymbol][itf].slope == RANGEBELOW ) ) {
                  message = StringFormat( "RANGE Wave Below for %s on %s (%d)", symbols[iSymbol][itf].symbol, GetTimeframeString(timeFrame), symbols[iSymbol][itf].slopeShift );
               }
               else if ( (findInIntArray(trendWaveChangeTimeFrames, timeFrame) >= 0) && ( symbols[iSymbol][itf].slope == TRENDABOVE ) ) {
                  message = StringFormat( "TREND Wave Above for %s on %s (%d)", symbols[iSymbol][itf].symbol, GetTimeframeString(timeFrame), symbols[iSymbol][itf].slopeShift );
               }
               else if ( (findInIntArray(trendWaveChangeTimeFrames, timeFrame) >= 0) && ( symbols[iSymbol][itf].slope == TRENDBELOW ) ) {
                  message = StringFormat( "TREND Wave Below for %s on %s (%d)", symbols[iSymbol][itf].symbol, GetTimeframeString(timeFrame), symbols[iSymbol][itf].slopeShift );
               }
               if ( (message != "") && AlertsOn ) Alert( message );
               if ( (message != "") && NotificationsOn ) SendNotification( message );
               if ( (message != "") && AlertsToFile  ) SaveText( message );
            }
         }
      }
   }
   // Switch Alerts back on for subsequent calls
   inInit = false;
}

//+------------------------------------------------------------------+
//| GetTimeframeString( int tf )                                     |
//+------------------------------------------------------------------+
string GetTimeframeString( int tf )
{
   string result;
   switch ( tf )
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
      default: result = "NaN";
   }
   return ( result );
}

//+------------------------------------------------------------------+
//| SaveText( string message )                                       |
//|    --- Write a new line to the end of the file                   |
//+------------------------------------------------------------------+
void SaveText( string message ) {

   ResetLastError();
   
   string fileName = StringFormat( "%s.txt", WindowExpertName() );
   
   int file_handle = FileOpen(fileName,FILE_READ|FILE_WRITE|FILE_TXT);

   if ( file_handle != INVALID_HANDLE ) {

      //PrintFormat("%s file is open for writing",file);
 
      // Go to the end of the file
      FileSeek(file_handle, 0, SEEK_END);

      // Write the message
      FileWrite( file_handle, StringFormat("%s: %s", TimeToStr(TimeLocal()), message ));

      // Play a sound
      PlaySound("alert.wav");

      //--- close the file
      FileClose(file_handle);

   }
   else {
      PrintFormat( "Failed to open %s file for writing, Error code = %d",fileName,GetLastError() );
   }
}

void convertTF( string csvText, int &tf[] ) {

   // Remove rubbish from csvText
   string cleanText = "";
   for (int pos=0; pos < StringLen(csvText); pos++) {
      ushort c = StringGetChar( csvText, pos );
      if ( c=='0' || c=='1' || c=='2' || c=='3' || c=='4' || c=='5' || c=='6' || c=='7' || c=='8' || c=='9' || c==',' ) {
         cleanText = StringConcatenate( cleanText, CharToString((uchar)c) );
      }
   }

   // Remove leading and trailing comma's
   int leftCut=0;
   while( (leftCut < StringLen(cleanText)) && StringGetChar(cleanText,leftCut) == ',' ) leftCut++;
   int rightCut = StringLen(cleanText)-1;
   while( (rightCut >= 0) && StringGetChar(cleanText,rightCut) == ',' ) rightCut--;
   cleanText = StringSubstr(cleanText, leftCut, rightCut-leftCut+1 );
   
   string tempArray[];
   const ushort comma = StringGetChar(",",0);
   // Convert cleanText to string array
   StringSplit( cleanText, comma, tempArray);
   
   // Check if tempArray[iTemp] is one of the recognised Time Frames
   for (int iTemp=0; iTemp < ArraySize(tempArray); iTemp++) {
      if ( tempArray[iTemp] == "1" || tempArray[iTemp] == "5" || tempArray[iTemp] == "15" || tempArray[iTemp] == "30" ||
           tempArray[iTemp] == "60" || tempArray[iTemp] == "240" || tempArray[iTemp] == "1440"  || tempArray[iTemp] == "10080" || tempArray[iTemp] == "43200" ) {
         if ( findInIntArray( tf, StrToInteger(tempArray[iTemp] ) ) < 0 ) {
            int currentSize = ArraySize(tf);
            if ( currentSize < MAX_TIMEFRAMES ) {
               ArrayResize(tf, currentSize+1 );
               tf[currentSize] = StrToInteger(tempArray[iTemp]);
            }
            else {
               PrintFormat("HGIMatrixMTF can currently only handle a maximum of %d time frames", MAX_TIMEFRAMES );
            }
         }
      }
   }
}

void convertTF( string csvText, TIMEFRAME &tf[] ) {

   // Remove rubbish from csvText
   string cleanText = "";
   for (int pos=0; pos < StringLen(csvText); pos++) {
      ushort c = StringGetChar( csvText, pos );
      if ( c=='0' || c=='1' || c=='2' || c=='3' || c=='4' || c=='5' || c=='6' || c=='7' || c=='8' || c=='9' || c==',' || c==':' ) {
         cleanText = StringConcatenate( cleanText, CharToString((uchar)c) );
      }
   }

   // Remove leading and trailing comma's
   int leftCut=0;
   while( (leftCut < StringLen(cleanText)) && StringGetChar(cleanText,leftCut) == ',' ) leftCut++;
   int rightCut = StringLen(cleanText)-1;
   while( (rightCut >= 0) && StringGetChar(cleanText,rightCut) == ',' ) rightCut--;
   cleanText = StringSubstr(cleanText, leftCut, rightCut-leftCut+1 );
   
   string tempArray[];
   const ushort comma = StringGetChar(",",0);
   const ushort colon = StringGetChar(":",0);

   // Convert cleanText to string array
   StringSplit( cleanText, comma, tempArray);
   
   // Check if tempArray[iTemp] is one of the recognised Time Frames
   for (int iTemp=0; iTemp < ArraySize(tempArray); iTemp++) {

      string tupleArray[];
      StringSplit( tempArray[iTemp], colon, tupleArray );

      if ( tupleArray[0] == "1" || tupleArray[0] == "5" || tupleArray[0] == "15" || tupleArray[0] == "30" ||
           tupleArray[0] == "60" || tupleArray[0] == "240" || tupleArray[0] == "1440"  || tupleArray[0] == "10080" || tupleArray[0] == "43200" ) {
         if ( findInIntArray( tf, StrToInteger(tupleArray[0] ) ) < 0 ) {
            int currentSize = ArraySize(tf);
            if ( currentSize < MAX_TIMEFRAMES ) {
               ArrayResize(tf, currentSize+1 );
               tf[currentSize].timeframe = StrToInteger(tupleArray[0]);
               if ( (ArraySize( tupleArray ) > 0) && StrToInteger(tupleArray[1]) > 0 ) 
                  tf[currentSize].maxLookBack = StrToInteger(tupleArray[1]);
               else
                  tf[currentSize].maxLookBack = MaxBarLookback;
            }
            else {
               PrintFormat("HGIMatrixMTF can currently only handle a maximum of %d time frames", MAX_TIMEFRAMES );
            }
         }
      }
   }
}

int findInIntArray( int &array[], int item ) {
   int index = -1;
   
   for(int i=0; i < ArraySize(array); i++) {
      if ( array[i] == item ) {
         index = i;
         break;
      }
   }
   return(index);
}

int findInIntArray( TIMEFRAME &array[], int item ) {
   int index = -1;
   
   for(int i=0; i < ArraySize(array); i++) {
      if ( array[i].timeframe == item ) {
         index = i;
         break;
      }
   }
   return(index);
}

void drawList() {

   deleteAllObjects();
   //printFlashers(flashingObject);
   removeAllFlashers(flashingObject);
   color cellColor, textColor;
   
   // This doesn't work when the chart is not active (i.e. when we are looking at another chart ...)
   //int screenHeight = (int)ChartGetInteger( ChartID(), CHART_HEIGHT_IN_PIXELS, 0 );
   int screenHeight = ScreenHeight;
   int maxRows = (int)MathFloor( ((double)(screenHeight - YOffSet))/((double)CellHeight) );
   int timeFrame;
   int nTimeFrames = ArraySize(timeFrames);

   DrawText(0, objPrefix+"HGIMatrixTitle", WindowExpertName(), XOffSet, YOffSet-12, clrWhite, 8);

   // draw element tiles
   for(int itf=0; itf < nTimeFrames; itf++) {

      timeFrame = timeFrames[itf].timeframe;
      
      int rowNum = 0; int colNum = 0;

      for(int iSymbol = 0; iSymbol < ArrayRange(symbols,0); iSymbol++) {
      
         // Continue if, for this symbol, none of the timeFrames is in agreement with hurst
         if ( ShowOnlyHurst ) {
            bool includeMe = false;
            for ( int itf1=0; itf1 < nTimeFrames; itf1++ ) {
               includeMe = includeMe || symbols[iSymbol][itf1].hurstOK;
            }
            if (!includeMe) {
               // Update the oldSlope      
               symbols[iSymbol][itf].oldSlope = symbols[iSymbol][itf].slope;
               symbols[iSymbol][itf].oldSignal = symbols[iSymbol][itf].signal;
               continue;
            }
         }
         
         // Continue if, for this symbol, the ATR is below the ATRThreshold
         if ( ShowOnlyATR ) {
            if ( symbols[iSymbol][0].atr < ATRThreshold ) continue;
         }
      
         if ( rowNum == 0) {
            // Draw Header
            if (itf == 0) {
               RectLabelCreate( 0, objPrefix+"SymbolHeadBack"+(string)colNum+","+(string)itf, 0, XOffSet + (1+nTimeFrames)*CellWidth*colNum+itf*CellWidth, YOffSet, CellWidth, CellHeight, tableHeadBackColor, BORDER_RAISED,CORNER_LEFT_UPPER, tableBorderColor );
               ButtonCreate( 0, objPrefix+"SymbolHeadText"+(string)colNum+","+(string)itf, 0, XOffSet + (1+nTimeFrames)*CellWidth*colNum+itf*CellWidth + 3, YOffSet+CellHeight/4, CellWidth-6, CellHeight/2, CORNER_LEFT_UPPER, "SYMBOL", screenFont, iMathMin(CellWidth/6,CellHeight/5), tableHeadTextColor, tableHeadBackColor, tableHeadBackColor );
            }
            RectLabelCreate( 0, objPrefix+"SignalHeadBack"+(string)colNum+","+(string)itf, 0, XOffSet + (1+nTimeFrames)*CellWidth*colNum+itf*CellWidth + CellWidth, YOffSet, CellWidth, CellHeight, tableHeadBackColor, BORDER_RAISED,CORNER_LEFT_UPPER, tableBorderColor );
            ButtonCreate( 0, objPrefix+"TFHeadText"+(string)colNum+","+(string)itf, 0,                         XOffSet + (1+nTimeFrames)*CellWidth*colNum+itf*CellWidth + CellWidth + 3, YOffSet + CellHeight / 4,  CellWidth - 6, CellHeight / 2, CORNER_LEFT_UPPER, GetTimeframeString( timeFrame ), screenFont, iMathMin(CellWidth/6,CellHeight/5), tableHeadTextColor, tableHeadBackColor, tableHeadBackColor );

            // timeRemaining has been contributed by Baluda. Thanks Paul, you are a star!
            datetime timeRemaining = iTime( symbols[iSymbol][itf].symbol, timeFrame, 0 ) + 60*timeFrame - TimeCurrent();
            ButtonCreate( 0, objPrefix+"TFHeadRemaining"+(string)rowNum+","+(string)colNum+","+(string)itf, 0, XOffSet + (1+nTimeFrames)*CellWidth*colNum+itf*CellWidth + CellWidth + 3, YOffSet + (3*CellHeight) / 4 - 5, CellWidth - 6, CellHeight / 3, CORNER_LEFT_UPPER, TimeToString( timeRemaining, TIME_MINUTES|TIME_SECONDS ), screenFont, iMathMin(CellWidth/7,CellHeight/6), tableHeadTextColor, tableHeadBackColor, tableHeadBackColor );

            rowNum++;
         }

         // Do stuff for rows
         if (itf==0) {
            cellColor = tableCellBackColor;
            if ( symbols[iSymbol][itf].selected ) cellColor = ClrSelect;
            textColor = tableHeadTextColor;
            if ( ShowTrend ) {
               if ( symbols[iSymbol][itf].lwmaTrend == LWMAUP ) textColor = clrGreen;
               else if ( symbols[iSymbol][itf].lwmaTrend == LWMADN ) textColor = clrRed;
               else if ( symbols[iSymbol][itf].lwmaTrend == LWMARANGE ) textColor = clrGoldenrod;
            }
            RectLabelCreate( 0, objPrefix+"SymbolBack"+(string)rowNum+","+(string)colNum+","+(string)itf, 0, XOffSet + (1+nTimeFrames)*CellWidth*colNum+itf*CellWidth, YOffSet+rowNum*CellHeight, CellWidth, CellHeight, cellColor, BORDER_RAISED,CORNER_LEFT_UPPER, tableBorderColor );
            ButtonCreate( 0, objPrefix+"Symbol("+(string)iSymbol+","+(string)itf+")"+(string)rowNum+","+(string)colNum, 0, XOffSet + (1+nTimeFrames)*CellWidth*colNum+itf*CellWidth + 3, YOffSet+rowNum*CellHeight+CellHeight/4, CellWidth-6, CellHeight/2, CORNER_LEFT_UPPER, symbols[iSymbol][itf].symbol, screenFont, iMathMin(CellWidth/6,CellHeight/5), textColor, cellColor, cellColor );
            if ( ShowATR ) {
               ButtonCreate( 0, objPrefix+"ATR("+(string)iSymbol+","+(string)itf+")"+(string)rowNum+","+(string)colNum, 0, XOffSet + (1+nTimeFrames)*CellWidth*colNum+itf*CellWidth + 3, YOffSet+rowNum*CellHeight+3*CellHeight/4, CellWidth-6, CellHeight/4, CORNER_LEFT_UPPER, StringFormat("%5.0f", symbols[iSymbol][itf].atr), screenFont, iMathMin(CellWidth/8,CellHeight/7), textColor, cellColor, cellColor );
            }                        
         }
   
         cellColor = clrBlack;
         if ( symbols[iSymbol][itf].hurstOK ) cellColor = ClrHurst;
         if ( (symbols[iSymbol][itf].oldSlope != symbols[iSymbol][itf].slope) || (symbols[iSymbol][itf].oldSignal != symbols[iSymbol][itf].signal) ) cellColor = ClrAlert;
         RectLabelCreate( 0, objPrefix+"SignalBack"+(string)rowNum+","+(string)colNum+","+(string)itf, 0, XOffSet + (1+nTimeFrames)*CellWidth*colNum+itf*CellWidth + CellWidth, YOffSet+rowNum*CellHeight, CellWidth, CellHeight, cellColor, BORDER_RAISED,CORNER_LEFT_UPPER, cellColor );

         //ButtonCreate( 0, objPrefix+"SignalHeadText"+(string)colNum+","+(string)itf, 0, XOffSet + (1+nTimeFrames)*CellWidth*colNum+itf*CellWidth + CellWidth + 3, YOffSet+CellHeight/2, CellWidth-6, 22, CORNER_LEFT_UPPER, "", screenFont, 10, tableHeadTextColor, tableHeadBackColor, tableHeadBackColor );
   
         if ( !ShowOnlyHurst || ( ShowOnlyHurst && symbols[iSymbol][itf].hurstOK ) ) {

            if ( symbols[iSymbol][itf].signal == TRENDUP ) 
               ButtonCreate( 0, objPrefix+"Arrow("+(string)iSymbol+","+(string)itf+")"+(string)rowNum+","+(string)colNum, 0, XOffSet + (1+nTimeFrames)*CellWidth*colNum+itf*CellWidth + CellWidth + 3, YOffSet+rowNum*CellHeight + CellHeight/4, 3*CellWidth/4, CellHeight/2+5, CORNER_LEFT_UPPER, CharToStr(233), SymbolFont, CellHeight/3, clrForestGreen, cellColor, cellColor );
            else if ( symbols[iSymbol][itf].signal == TRENDDN ) 
               ButtonCreate( 0, objPrefix+"Arrow("+(string)iSymbol+","+(string)itf+")"+(string)rowNum+","+(string)colNum, 0, XOffSet + (1+nTimeFrames)*CellWidth*colNum+itf*CellWidth + CellWidth + 3, YOffSet+rowNum*CellHeight + CellHeight/4, 3*CellWidth/4, CellHeight/2+5, CORNER_LEFT_UPPER, CharToStr(234), SymbolFont, CellHeight/3, clrRed, cellColor, cellColor );
            else if ( symbols[iSymbol][itf].signal == RANGEUP ) 
               ButtonCreate( 0, objPrefix+"Arrow("+(string)iSymbol+","+(string)itf+")"+(string)rowNum+","+(string)colNum, 0, XOffSet + (1+nTimeFrames)*CellWidth*colNum+itf*CellWidth + CellWidth + 3, YOffSet+rowNum*CellHeight + CellHeight/4, 3*CellWidth/4, CellHeight/2, CORNER_LEFT_UPPER, CharToStr(233), SymbolFont, CellHeight/5, clrForestGreen, cellColor, cellColor );
            else if ( symbols[iSymbol][itf].signal == RANGEDN ) 
               ButtonCreate( 0, objPrefix+"Arrow("+(string)iSymbol+","+(string)itf+")"+(string)rowNum+","+(string)colNum, 0, XOffSet + (1+nTimeFrames)*CellWidth*colNum+itf*CellWidth + CellWidth + 3, YOffSet+rowNum*CellHeight + CellHeight/4, 3*CellWidth/4, CellHeight/2, CORNER_LEFT_UPPER, CharToStr(234), SymbolFont, CellHeight/5, clrRed, cellColor, cellColor );
            else if ( symbols[iSymbol][itf].signal == RADUP ) 
               ButtonCreate( 0, objPrefix+"Arrow("+(string)iSymbol+","+(string)itf+")"+(string)rowNum+","+(string)colNum, 0, XOffSet + (1+nTimeFrames)*CellWidth*colNum+itf*CellWidth + CellWidth + 3, YOffSet+rowNum*CellHeight + CellHeight/4, 3*CellWidth/4, CellHeight/2, CORNER_LEFT_UPPER, CharToStr(236), SymbolFont, CellHeight/5, clrForestGreen, cellColor, cellColor );
            else if ( symbols[iSymbol][itf].signal == RADDN ) 
               ButtonCreate( 0, objPrefix+"Arrow("+(string)iSymbol+","+(string)itf+")"+(string)rowNum+","+(string)colNum, 0, XOffSet + (1+nTimeFrames)*CellWidth*colNum+itf*CellWidth + CellWidth + 3, YOffSet+rowNum*CellHeight + CellHeight/4, 3*CellWidth/4, CellHeight/2, CORNER_LEFT_UPPER, CharToStr(238), SymbolFont, CellHeight/5, clrRed, cellColor, cellColor );
      
            // Draw the shift
            if (  ShowBarNo && (symbols[iSymbol][itf].signal != NONE) ) {
               ButtonCreate( 0, objPrefix+"SignalShift_"+(string)rowNum+","+(string)colNum+","+(string)itf, 0, XOffSet + (1+nTimeFrames)*CellWidth*colNum+itf*CellWidth + CellWidth + 3*CellWidth/4, YOffSet+rowNum*CellHeight + CellHeight/4, CellWidth/4-2, CellHeight/2, CORNER_LEFT_UPPER, StringFormat("%d",symbols[iSymbol][itf].signalShift), "helvetica", CellHeight/7, clrWhite, cellColor, cellColor );
               if ( symbols[iSymbol][itf].signalShift == 0 ) addFlasher( flashingObject, objPrefix+"Arrow("+(string)iSymbol+","+(string)itf+")"+(string)rowNum+","+(string)colNum );
            }
      
            if ( symbols[iSymbol][itf].slope == RANGEABOVE ) {
               ButtonCreate( 0, objPrefix+"Wave("+(string)iSymbol+","+(string)itf+")"+(string)rowNum+","+(string)colNum, 0, XOffSet + (1+nTimeFrames)*CellWidth*colNum+itf*CellWidth + CellWidth + 3, YOffSet+rowNum*CellHeight+7,3*CellWidth/4, CellHeight/4+2, CORNER_LEFT_UPPER,  CharToStr(104), SymbolFont, CellHeight/4, ClrRangeWave, cellColor, cellColor );
            }
            else if ( symbols[iSymbol][itf].slope == RANGEBELOW ) {
               ButtonCreate( 0, objPrefix+"Wave("+(string)iSymbol+","+(string)itf+")"+(string)rowNum+","+(string)colNum, 0, XOffSet + (1+nTimeFrames)*CellWidth*colNum+itf*CellWidth + CellWidth + 3, YOffSet+rowNum*CellHeight + 3*CellHeight/4-2,3*CellWidth/4, CellHeight/4+2, CORNER_LEFT_UPPER,  CharToStr(104), SymbolFont, CellHeight/4, ClrRangeWave, cellColor, cellColor );
            }
            else if ( symbols[iSymbol][itf].slope == TRENDABOVE ) {
               ButtonCreate( 0, objPrefix+"Wave("+(string)iSymbol+","+(string)itf+")"+(string)rowNum+","+(string)colNum, 0, XOffSet + (1+nTimeFrames)*CellWidth*colNum+itf*CellWidth + CellWidth + 3, YOffSet+rowNum*CellHeight+7,3*CellWidth/4, CellHeight/4+2, CORNER_LEFT_UPPER,  CharToStr(104), SymbolFont, CellHeight/4, ClrTrendWave, cellColor, cellColor );
            }
            else if ( symbols[iSymbol][itf].slope == TRENDBELOW ) {
               ButtonCreate( 0, objPrefix+"Wave("+(string)iSymbol+","+(string)itf+")"+(string)rowNum+","+(string)colNum, 0, XOffSet + (1+nTimeFrames)*CellWidth*colNum+itf*CellWidth + CellWidth + 3, YOffSet+rowNum*CellHeight + 3*CellHeight/4-2,3*CellWidth/4-2, CellHeight/4+2, CORNER_LEFT_UPPER,  CharToStr(104), SymbolFont, CellHeight/4, ClrTrendWave, cellColor, cellColor );
            }
            // Draw the shift
            if ( ShowBarNo ) {
               if ( ( symbols[iSymbol][itf].slope == RANGEABOVE ) || ( symbols[iSymbol][itf].slope == TRENDABOVE ) )  {
                  ButtonCreate( 0, objPrefix+"SlopeShift_"+(string)rowNum+","+(string)colNum+","+(string)itf, 0, XOffSet + (1+nTimeFrames)*CellWidth*colNum+itf*CellWidth + CellWidth + 3*CellWidth/4, YOffSet+rowNum*CellHeight+3, CellWidth/4, CellHeight/4-2, CORNER_LEFT_UPPER, StringFormat("%d",symbols[iSymbol][itf].slopeShift), "helvetica", CellHeight/7, clrWhite, cellColor, cellColor );
               }
               else if ( ( symbols[iSymbol][itf].slope == RANGEBELOW ) || ( symbols[iSymbol][itf].slope == TRENDBELOW ) )  {
                  ButtonCreate( 0, objPrefix+"SlopeShift_"+(string)rowNum+","+(string)colNum+","+(string)itf, 0, XOffSet + (1+nTimeFrames)*CellWidth*colNum+itf*CellWidth + CellWidth + 3*CellWidth/4, YOffSet+rowNum*CellHeight + 3*CellHeight/4, CellWidth/4, CellHeight/4-2, CORNER_LEFT_UPPER, StringFormat("%d",symbols[iSymbol][itf].slopeShift), "helvetica", CellHeight/7, clrWhite, cellColor, cellColor );
               }
               if ( symbols[iSymbol][itf].slopeShift == 0 ) addFlasher( flashingObject, objPrefix+"Wave("+(string)iSymbol+","+(string)itf+")"+(string)rowNum+","+(string)colNum );
            }
         }
   
         rowNum++;
         if ( rowNum >= maxRows ) {
            colNum++;
            rowNum = 0;
         }
   
         // Update the oldSlope      
         symbols[iSymbol][itf].oldSlope = symbols[iSymbol][itf].slope;
         symbols[iSymbol][itf].oldSignal = symbols[iSymbol][itf].signal;
   
      }
   }
}   

//+------------------------------------------------------------------+
//| Create text object                                               |
//+------------------------------------------------------------------+
void DrawText( int nWindow, string nCellName, string nText, double nX, double nY, color nColor, int fontSize = 9, string font = screenFont ) {

   ObjectCreate( nCellName, OBJ_LABEL, nWindow, 0, 0);
   ObjectSetText( nCellName, nText, fontSize, font, nColor);
   ObjectSet( nCellName, OBJPROP_XDISTANCE, nX );
   ObjectSet( nCellName, OBJPROP_YDISTANCE, nY );
   ObjectSet( nCellName, OBJPROP_BACK, false);
}

//+------------------------------------------------------------------+
//| Create rectangle label                                           |
//+------------------------------------------------------------------+
bool RectLabelCreate(const long             chart_ID=0,               // chart's ID
                     const string           name="RectLabel",         // label name
                     const int              sub_window=0,             // subwindow index
                     const int              x=0,                      // X coordinate
                     const int              y=0,                      // Y coordinate
                     const int              width=50,                 // width
                     const int              height=18,                // height
                     const color            back_clr=C'0xA7,0xC9,0x42',  // background color
                     const ENUM_BORDER_TYPE border=BORDER_RAISED,     // border type
                     const ENUM_BASE_CORNER corner=CORNER_LEFT_UPPER, // chart corner for anchoring
                     const color            clr=C'0x98,0xBF,0x21',    // flat border color (Flat)
                     const ENUM_LINE_STYLE  style=STYLE_SOLID,        // flat border style
                     const int              line_width=1,             // flat border width
                     const bool             back=false,               // in the background
                     const bool             selection=false,          // highlight to move
                     const bool             hidden=true,              // hidden in the object list
                     const long             z_order=0)                // priority for mouse click
{
//--- reset the error value
   ResetLastError();
//--- create a rectangle label
   if(!ObjectCreate(chart_ID,name,OBJ_RECTANGLE_LABEL,sub_window,0,0)) {
      Print(__FUNCTION__, ": failed to create a rectangle label! Error code = ",GetLastError());
      return(false);
   }
//--- set label coordinates
   ObjectSetInteger(chart_ID,name,OBJPROP_XDISTANCE,x);
   ObjectSetInteger(chart_ID,name,OBJPROP_YDISTANCE,y);
//--- set label size
   ObjectSetInteger(chart_ID,name,OBJPROP_XSIZE,width);
   ObjectSetInteger(chart_ID,name,OBJPROP_YSIZE,height);
//--- set background color
   ObjectSetInteger(chart_ID,name,OBJPROP_BGCOLOR,back_clr);
//--- set border type
   ObjectSetInteger(chart_ID,name,OBJPROP_BORDER_TYPE,border);
//--- set the chart's corner, relative to which point coordinates are defined
   ObjectSetInteger(chart_ID,name,OBJPROP_CORNER,corner);
//--- set flat border color (in Flat mode)
   ObjectSetInteger(chart_ID,name,OBJPROP_COLOR,clr);
//--- set flat border line style
   ObjectSetInteger(chart_ID,name,OBJPROP_STYLE,style);
//--- set flat border width
   ObjectSetInteger(chart_ID,name,OBJPROP_WIDTH,line_width);
//--- display in the foreground (false) or background (true)
   ObjectSetInteger(chart_ID,name,OBJPROP_BACK,back);
//--- enable (true) or disable (false) the mode of moving the label by mouse
   ObjectSetInteger(chart_ID,name,OBJPROP_SELECTABLE,selection);
   ObjectSetInteger(chart_ID,name,OBJPROP_SELECTED,selection);
//--- hide (true) or display (false) graphical object name in the object list
   ObjectSetInteger(chart_ID,name,OBJPROP_HIDDEN,hidden);
//--- set the priority for receiving the event of a mouse click in the chart
   ObjectSetInteger(chart_ID,name,OBJPROP_ZORDER,z_order);
//--- successful execution
   return(true);
}   

bool ButtonCreate(const long              chart_ID=0,               // chart's ID
                  const string            name="Signal0",            // button name
                  const int               sub_window=0,             // subwindow index
                  const int               x=0,                      // X coordinate
                  const int               y=0,                      // Y coordinate
                  const int               width=50,                 // button width
                  const int               height=18,                // button height
                  const ENUM_BASE_CORNER  corner=CORNER_LEFT_UPPER, // chart corner for anchoring
                  const string            text="Trade",             // text
                  const string            font="Helvetica",         // font
                  const int               font_size=10,             // font size
                  const color             clr=clrBlack,             // text color
                  const color             back_clr=clrDarkSlateGray,       // background color
                  const color             border_clr=clrBlack,   // border color
                  const bool              state=false,              // pressed/released
                  const bool              back=false,               // in the background
                  const bool              selection=false,          // highlight to move
                  const bool              hidden=true,              // hidden in the object list
                  const long              z_order=0)                // priority for mouse click
  {
//--- reset the error value
   ResetLastError();
//--- create the button
   if(!ObjectCreate(chart_ID,name,OBJ_BUTTON,sub_window,0,0)) {
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

double getHurst( string symbol, int timeframe, int shift, int prd = 5, int ecart_pips = 0 ) {

   double sum    = (prd+1)*iMA(symbol,timeframe,1,0,MODE_SMA,PRICE_OPEN,shift);
   double sumw   = (prd+1);
   double result = 0.0;

   for(int j=1, k=prd; j<=prd; j++, k--) {

      sum += k*iMA(symbol,timeframe,1,0,MODE_SMA,PRICE_OPEN,shift+j);
      sumw += k;

      if (j<=shift) {
         sum += k*iMA(symbol,timeframe,1,0,MODE_SMA,PRICE_OPEN,shift-j);
         sumw += k;
      }

      double snake = sum/sumw;
      double p = (Digits == 5) ? ecart_pips*10 : ecart_pips;


      result = snake + (p*MarketInfo(symbol, MODE_POINT));
   }
   
   return(result);
}

void deleteAllObjects() {

   for (int iObject=ObjectsTotal()-1; iObject >= 0; iObject--) {
      if ( StringFind( ObjectName(iObject), objPrefix ) == 0 ) {
         ObjectDelete( ObjectName(iObject) );
      }
   }
}

//+------------------------------------------------------------------+
//| Generate a random  string                                        |
//+------------------------------------------------------------------+
string RandomString(int minLength, int maxLength) {

   if ((minLength > maxLength) || (minLength <= 0)) return("");
   
   string rstring = "";
   int strLen = RandomNumber( minLength, maxLength );
   
   for (int i=0; i<strLen; i++) {
      rstring = rstring + CharToStr( (uchar)RandomNumber( 97, 122 ) );
   }
   return(rstring);
}   

//+------------------------------------------------------------------+
//| Generate a random  number                                        |
//+------------------------------------------------------------------+
int RandomNumber(int low, int high) {

   if (low > high) return(-1);

   int number = low + (int)MathFloor(((MathRand() * (high-low)) / 32767));
   return(number);
}   

//+------------------------------------------------------------------+
//| ChartEvent function                                              |
//+------------------------------------------------------------------+
void OnChartEvent(const int id, const long &lparam, const double &dparam, const string &sparam) {
//---
   if (id==CHARTEVENT_OBJECT_CLICK) {
      ObjectSetInteger(0,sparam,OBJPROP_SELECTED, false );
      ObjectSetInteger(0,sparam,OBJPROP_STATE, false );
      
      string objectName = sparam;
      if ( StringFind(objectName, objPrefix) == 0 ) objectName = StringSubstr( objectName, StringLen(objPrefix) );
      
      // Check if someone clicked the SYMBOL name
      if ( StringFind(objectName, "Symbol(") == 0 ) {

         objectName = StringSubstr( objectName, StringLen("Symbol(") );

         int iSymbol = StrToInteger( StringSubstr(objectName, 0, StringFind(objectName,",") ) );
         
         objectName = StringSubstr( objectName, StringFind(objectName,",")+1 );
         int itf     = StrToInteger( StringSubstr(objectName, 0, StringFind(objectName,")") ) );
         
         if ( (iSymbol >= 0) && (iSymbol < ArrayRange(symbols,0)) && (itf>=0) && (itf<ArraySize(timeFrames)) ) {
            symbols[iSymbol][itf].selected = !symbols[iSymbol][itf].selected;
            GlobalVariableSet( StringFormat("%s%s_select",objPrefix,symbols[iSymbol][itf].symbol), (double)symbols[iSymbol][itf].selected );
            drawList();
         }
      }
      // Check if someone clicked on a signal ARROW
      else if ( StringFind(objectName, "Arrow(") == 0 ) {

         objectName = StringSubstr( objectName, StringLen("Arrow(") );

         int iSymbol = StrToInteger( StringSubstr(objectName, 0, StringFind(objectName,",") ) );
         
         objectName = StringSubstr( objectName, StringFind(objectName,",")+1 );
         int itf     = StrToInteger( StringSubstr(objectName, 0, StringFind(objectName,")") ) );
         
         if ( (iSymbol >= 0) && (iSymbol < ArrayRange(symbols,0)) && (itf>=0) && (itf<ArraySize(timeFrames)) ) {
            if ( !isChartOpen(symbols[iSymbol][itf].symbol, timeFrames[itf].timeframe ) ) {
               long chartID = ChartOpen( symbols[iSymbol][itf].symbol, timeFrames[itf].timeframe );
               if ( chartID > 0 ) {
                  string templateName = TemplateName;
                  string extension = StringSubstr(templateName, StringLen(templateName)-4);
                  StringToLower(extension);
                  // Check if the templateName ends with .tpl, and add it if not.
                  if ( extension != ".tpl" ) templateName = templateName+".tpl";
                  ChartApplyTemplate(chartID, templateName);
               }
            }
            else {
               int handle = WindowHandle( symbols[iSymbol][itf].symbol, timeFrames[itf].timeframe );
               if ( handle > 0 ) ActivateWindow(handle);
            }
         }
      }
      // Check if someone clicked on a signal WAVE
      else if ( StringFind(objectName, "Wave(") == 0 ) {

         objectName = StringSubstr( objectName, StringLen("Wave(") );

         int iSymbol = StrToInteger( StringSubstr(objectName, 0, StringFind(objectName,",") ) );
         
         objectName = StringSubstr( objectName, StringFind(objectName,",")+1 );
         int itf     = StrToInteger( StringSubstr(objectName, 0, StringFind(objectName,")") ) );
         
         if ( (iSymbol >= 0) && (iSymbol < ArrayRange(symbols,0)) && (itf>=0) && (itf<ArraySize(timeFrames)) ) {
            if ( !isChartOpen(symbols[iSymbol][itf].symbol, timeFrames[itf].timeframe ) ) {
               long chartID = ChartOpen( symbols[iSymbol][itf].symbol, timeFrames[itf].timeframe );
               if ( chartID > 0 ) {
                  string templateName = TemplateName;
                  string extension = StringSubstr(templateName, StringLen(templateName)-4);
                  StringToLower(extension);
                  // Check if the templateName ends with .tpl, and add it if not.
                  if ( extension != ".tpl" ) templateName = templateName+".tpl";
                  ChartApplyTemplate(chartID, templateName);
               }
            }
            else {
               int handle = WindowHandle( symbols[iSymbol][itf].symbol, timeFrames[itf].timeframe );
               if ( handle > 0 ) ActivateWindow(handle);
            }
         }
      }
   }
}

bool isChartOpen( string symbol, int timeFrame ) {

   bool isOpen = false;
   long chartID = ChartFirst();
   
   while( chartID >= 0 ) {
      if ( ( chartID != ChartID() ) && ( ChartSymbol( chartID ) == symbol ) && ( ChartPeriod( chartID ) == timeFrame ) ) {
         isOpen = true;
         break;
      }
      chartID = ChartNext( chartID );
   }
   return(isOpen);
}

int ActivateWindow(int hwnd) {
   int p = GetParent(hwnd);
   return(SendMessageW(GetParent(p), WM_MDIACTIVATE, p, 0));
}

int iMathMin(int x, int y) {
   return((x < y) ? x : y);
}

void addFlasher( FLASHER &flashers[], string objectName ) {

   bool exists = false;
   for(int iFlasher=0; iFlasher < ArraySize(flashers); iFlasher++) {
      if ( flashers[iFlasher].objectName == objectName ) {
         exists = true;
         break;
      }
   }
   
   if ( !exists && (ObjectFind(objectName) == 0) ) {   
      int currentSize = ArraySize(flashers);
      ArrayResize(flashers, currentSize+1);
      flashers[currentSize].objectName = objectName;
      flashers[currentSize].objectColor = (color)ObjectGetInteger(0, objectName, OBJPROP_COLOR);
   }
}

void removeAllFlashers( FLASHER &flashers[]) {

   ArrayFree( flashers );
   ArrayResize( flashers, 0 );
}

void flashObjects( FLASHER &flashers[] ) {

   static bool on = false;
   
   for(int iFlasher=0; iFlasher < ArraySize(flashers); iFlasher++) {
   
      if ( ObjectFind(flashers[iFlasher].objectName) == 0) {
         if (on) {
            ObjectSetInteger( 0, flashers[iFlasher].objectName, OBJPROP_COLOR, flashers[iFlasher].objectColor );
         }
         else {
            ObjectSetInteger( 0, flashers[iFlasher].objectName, OBJPROP_COLOR, clrNONE );
         }
      }
   }
   on = !on;
}

void printFlashers( FLASHER &flashers[] ) {

   for(int iFlasher=0; iFlasher < ArraySize(flashers); iFlasher++) {

      PrintFormat("Flasher[%d] = %s", iFlasher, flashers[iFlasher].objectName);
   }
}

//+------------------------------------------------------------------+
//| getPipFactor()                                                   |
//+------------------------------------------------------------------+
int GetPipFactor(string symbol) {

  static const string factor100[]         = {"JPY","XAG","SILVER","BRENT","WTI"};
  static const string factor10[]          = {"XAU","GOLD","SP500"};
  static const string factor1[]           = {"UK100","WS30","DAX30","NAS100","CAC400"};
   
  int factor = 10000;       // correct factor for most pairs
  for ( int j = 0; j < ArraySize( factor100 ); j++ ) {
     if ( StringFind( symbol, factor100[j] ) != -1 ) factor = 100;
  }   
  for ( int j = 0; j < ArraySize( factor10 ); j++ ) {
     if ( StringFind( symbol, factor10[j] ) != -1 ) factor = 10;
  }   
  for ( int j = 0; j < ArraySize( factor1 ); j++ ) {
     if ( StringFind( symbol, factor1[j] ) != -1 ) factor = 1;
  }
  
  return (factor);
}

