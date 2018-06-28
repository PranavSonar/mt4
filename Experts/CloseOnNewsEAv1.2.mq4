//+------------------------------------------------------------------+
//|                                                CloseOnNewsEA.mq4 |
//|                                         Copyright 2015, renexxxx |
//|                                http://www.stevehopwoodforex.com/ |
//+------------------------------------------------------------------+
#property copyright "Copyright 2015, renexxxx"
#property link      "http://www.stevehopwoodforex.com/"
#property version   "1.20"
#property strict

//--- Make sure you add the LibFF library
#include <LibFF.mqh>
#include <OrderReliable.mqh>

#include <WinUser32.mqh>
#import "user32.dll"
int GetAncestor(int, int);
#import

#define MT4_WMCMD_EXPERTS  33020 

//--- Define the URL from which to get the news.
//--- Note that the ForexFactory News xml file is in a specific format
//--- .. that the code in LibFF expects. You just can't replace the feedURL
//--- .. with a URL that points to another news site, as the format of that
//--- .. other news site could be totally incompatible with what LibFF expects.
#define feedURL  "http://www.forexfactory.com/ffcal_week_this.xml"

//--- Object Array to hold the NEWS
CArrayObj* ALLNEWS;

//--- Parameters to control if and how to react to news
input bool              UseNews                      = true;       // Overall On/Off switch for News Filter

input string            CurrenciesToClose            = "";         // Comma-separated list of currencies to watch/close. Leave blank for all.

input bool              CloseOnHighImpactNews        = true;
input bool              CloseOnMediumImpactNews      = false;
input bool              CloseOnLowImpactNews         = false;

input string            NewsFilter                   = "";         // Additional filter to target specific news. Leave blank for all.

input bool              CloseOpenTrades              = true;
input bool              ClosePendingTrades           = false;

input int               SecondsBeforeHighImpact      = 7200;
input int               SecondsBeforeMediumImpact    = 3600;
input int               SecondsBeforeLowImpact       = 900;

input int               SecondsAfterHighImpact       = 3600;
input int               SecondsAfterMediumImpact     = 3600;
input int               SecondsAfterLowImpact        = 3600;

input int               MagicNumberToClose           = -1;         // MagicNumber to close. -1 means all
input bool              DisableTradingOnNews         = true;
input bool              ReenableTradingAfterNews     = true;

input bool              SetGlobalVariableOnNews      = true;
input bool              UnSetGlobalVariableAfterNews = true;
input string            GvName                       = "Under management flag";

input int               BrokerGMTOffSet              = 2;          // Broker time GMT OffSet in hours

string currenciesToClose[];

//+------------------------------------------------------------------+
//| Expert initialization function                                   |
//+------------------------------------------------------------------+
int OnInit() {

   //--- Convert the CurrenciesToClose input parameter into a string-array
   convertCurrencies( CurrenciesToClose, currenciesToClose );

   //--- check for news every 5 seconds
   EventSetTimer(5);
   
   //--- Initialize the news container
   ALLNEWS = new CArrayObj;
      
   //--- Run the timer event handler
   OnTimer();

   //---
   return(INIT_SUCCEEDED);
}

//+------------------------------------------------------------------+
//| Expert deinitialization function                                 |
//+------------------------------------------------------------------+
void OnDeinit(const int reason) {

   // Release the (dynamic) memory for ALLNEWS
   if ( CheckPointer( ALLNEWS ) != POINTER_INVALID ) {
      ALLNEWS.Shutdown();
      delete ALLNEWS;
   }

   //--- destroy timer
   EventKillTimer();
}

//+------------------------------------------------------------------+
//| Expert tick function                                             |
//+------------------------------------------------------------------+
void OnTick() {}

//+------------------------------------------------------------------+
//| Timer function                                                   |
//+------------------------------------------------------------------+
void OnTimer() {

   static const int NewsRefreshSeconds = 300;    // 5 minutes
   static datetime  lastNewsRefresh = -1;
   
   if ( TimeCurrent() > lastNewsRefresh + NewsRefreshSeconds ) {
      
      // Refresh the news
      if ( CheckPointer( ALLNEWS ) != POINTER_INVALID ) {
         getNews( ALLNEWS, feedURL );
      }
      
      lastNewsRefresh = TimeCurrent();
   }
   
   //--- If the currenciesToClose array is empty, any upcoming news will trigger
   //--- the close of *all* trades (with the selected MagicNumberToClose)
   if ( ArraySize(currenciesToClose) == 0 ) {

      if ( hasNews() ) {
      
         // Close Trades
         closeTrades();
         
         // Optionally disable trading
         if ( DisableTradingOnNews ) disableExperts();

         // Optionally set Global Variable, that other EAs can use to disable trading
         if ( SetGlobalVariableOnNews && !GlobalVariableCheck( GvName ) ) GlobalVariableSet( GvName, 1.0 );
      }
      else {
         // Optionally re-enable trading
         if ( ReenableTradingAfterNews ) enableExperts();

         // Optionally remove Global Variable (if set), that other EAs can use to disable trading
         if ( UnSetGlobalVariableAfterNews && GlobalVariableCheck( GvName ) ) GlobalVariableDel( GvName );
      }
   }
   else {
   
      bool anyNews = false;
      for( int iCur=0; iCur < ArraySize(currenciesToClose); iCur++ ) {
      
         string myCur = currenciesToClose[iCur];
         
         if ( hasNews( myCur ) ) {
         
            anyNews = true;
         
            // Close all currencies pairs with myCur in the name
            closeTrades( myCur );
         }
      }
      
      if ( anyNews ) {
         // Optionally disable trading
         if  ( DisableTradingOnNews ) disableExperts();

         // Optionally set Global Variable, that other EAs can use to disable trading
         if ( SetGlobalVariableOnNews && !GlobalVariableCheck( GvName ) ) GlobalVariableSet( GvName, 1.0 );
      }
      else {
         // Optionally re-enable trading
         if ( ReenableTradingAfterNews ) enableExperts();

         // Optionally remove Global Variable (if set), that other EAs can use to disable trading
         if ( UnSetGlobalVariableAfterNews && GlobalVariableCheck( GvName ) ) GlobalVariableDel( GvName );
      }
   }
}

//+------------------------------------------------------------------+
//| hasNews( curName ) :                                             |
//|    Returns true if there is upcoming news for the given curName. |
//+------------------------------------------------------------------+
bool hasNews( string curName = "" ) {

   bool hasNews = false;
   
   //--- If UseNews has been switched off, by definition there is no news
   if ( !UseNews ) return(false);

   //--- Iterate over all news items inside the ALLNEWS container
   for(int newsIndex=0; newsIndex < ALLNEWS.Total(); newsIndex++) {

      CNEWS_ITEM *aNewsItem = ALLNEWS.At( newsIndex );
      
      // Continue if there is a NewsFilter and this news item does not pass the NewsFilter test
      if ( (NewsFilter != "") && StringFind( aNewsItem.ni_title, NewsFilter ) < 0 ) continue;

      // Are we filtering for HIGH impact news and is this a HIGH impact news item?
      if ( CloseOnHighImpactNews && aNewsItem.ni_impact == HIGH ) {
      
         // Is this news item relevant for the given curName? Or is it relevant for ALL currencies?
         if ( (curName == "") || (aNewsItem.ni_country == curName) || (aNewsItem.ni_country == "ALL") ) {
         
            // Is this news item scheduled to be released within the specified cut-off times for HIGH impact news?
            datetime newsTime = GMTToServer( aNewsItem.ni_datetime );
            if ( ( newsTime - SecondsBeforeHighImpact < TimeCurrent() ) && ( TimeCurrent() < newsTime + SecondsAfterHighImpact ) ) {
            
               // There is NEWS!
               hasNews = true;

               // No point continuing here ... We have established there is news, so pack up and leave.
               break;
            }
         }
      }
      // Are we filtering for MEDIUM impact news and is this a MEDIUM impact news item?
      else if ( CloseOnMediumImpactNews && aNewsItem.ni_impact == MEDIUM ) {
      
         // Is this news item relevant for the given curName? Or is it relevant for ALL currencies?
         if ( (curName == "") || (aNewsItem.ni_country == curName) || (aNewsItem.ni_country == "ALL") ) {
         
            // Is this news item scheduled to be released within the specified cut-off times for MEDIUM impact news?
            datetime newsTime = GMTToServer( aNewsItem.ni_datetime );
            if ( ( newsTime - SecondsBeforeMediumImpact < TimeCurrent() ) && ( TimeCurrent() < newsTime + SecondsAfterMediumImpact ) ) {
            
               // There is NEWS!
               hasNews = true;

               // No point continuing here ... We have established there is news, so pack up and leave.
               break;
            }
         }
      }
      // Are we filtering for LOW impact news and is this a LOW impact news item?
      else if ( CloseOnLowImpactNews && aNewsItem.ni_impact == LOW ) {
      
         // Is this news item relevant for the given curName? Or is it relevant for ALL currencies?
         if ( (curName == "") || (aNewsItem.ni_country == curName) || (aNewsItem.ni_country == "ALL") ) {
         
            // Is this news item scheduled to be released within the specified cut-off times for LOW impact news?
            datetime newsTime = GMTToServer( aNewsItem.ni_datetime );
            if ( ( newsTime - SecondsBeforeLowImpact < TimeCurrent() ) && ( TimeCurrent() < newsTime + SecondsAfterLowImpact ) ) {
            
               // There is NEWS!
               hasNews = true;

               // No point continuing here ... We have established there is news, so pack up and leave.
               break;
            }
         }
      }
   } // for
   
   return(hasNews);
}

//+------------------------------------------------------------------+
//| closeTrades( curName )                                           |
//|    -- closes all open trades that contain 'curName'              |
//+------------------------------------------------------------------+
void closeTrades( string curName = "" ) {

   bool tryAgain = true;
   int  maxTries = 10;
   
   // Keep trying this if something goes wrong ...
	while( tryAgain && (maxTries > 0) ) {

      tryAgain = false;
      for (int i = OrdersTotal()-1; !tryAgain && i >= 0; i--) {

	      if (OrderSelect(i,SELECT_BY_POS)) {
            if ( (MagicNumberToClose < 0) || (OrderMagicNumber() == MagicNumberToClose) ) {
               if ( (curName == "") || (StringSubstr(OrderSymbol(), 0, 3) == curName) || (StringSubstr(OrderSymbol(), 3, 3) == curName) ) {
                  if ( CloseOpenTrades && ( ( OrderType() == OP_BUY ) || ( OrderType() == OP_SELL ) ) ) {
                     if ( OrderType() == OP_BUY ) {
                        if (! OrderCloseReliable(OrderTicket(), OrderLots(), MarketInfo( OrderSymbol(), MODE_BID ), 80, clrLime ) ) {
                           tryAgain = true;
                           break;
                        }
                     }
                     else if ( OrderType() == OP_SELL ) {
                        if (! OrderCloseReliable(OrderTicket(), OrderLots(), MarketInfo( OrderSymbol(), MODE_ASK ), 80, clrRed ) ) {
                           tryAgain = true;
                           break;
                        }
                     }
                  }
                  else if ( ClosePendingTrades && ( (OrderType() == OP_BUYSTOP) || (OrderType() == OP_SELLSTOP) || (OrderType() == OP_BUYLIMIT) || (OrderType() == OP_SELLLIMIT) ) ) {
                     if (! OrderDeleteReliable(OrderTicket()) ) {
                        tryAgain = true;
                        break;
                     }
                  }
               }
            }
         }
         else {
            tryAgain = true;
            break;
         }
      } // for
      maxTries--;
   } // while 
}

datetime GMTToServer( datetime GMTTime ) {

   return( GMTTime + BrokerGMTOffSet*60*60 );
}

void convertCurrencies( string csvText, string &myCurrencies[] ) {

   // Reset myCurrencies
   ArrayFree(myCurrencies);
   ArrayResize(myCurrencies, 0);
   
   // Uppercase csvText
   StringToUpper(csvText);

   // Remove rubbish from csvText (non-alpha characters)
   string cleanText = "";
   for (int pos=0; pos < StringLen(csvText); pos++) {
      ushort c = StringGetChar( csvText, pos );
      if ( ( (c >= 'A') &&  (c <= 'Z') ) || (c== ',') ) {
         cleanText = StringConcatenate( cleanText, CharToString((uchar)c) );
      }
   }

   // Remove leading and trailing comma's
   int leftCut=0;
   while( (leftCut < StringLen(cleanText)) && StringGetChar(cleanText,leftCut) == ',' ) leftCut++;
   int rightCut = StringLen(cleanText)-1;
   while( (rightCut >= 0) && StringGetChar(cleanText,rightCut) == ',' ) rightCut--;
   cleanText = StringSubstr(cleanText, leftCut, rightCut-leftCut+1 );
   
   const ushort comma = StringGetChar(",",0);
   // Convert cleanText to string array
   StringSplit( cleanText, comma, myCurrencies);
}

void disableExperts() {

   if ( IsExpertEnabled() ) {
   
      int main = GetAncestor(WindowHandle(Symbol(), Period()), 2/*GA_ROOT*/);

      if ( main > 0 ) PostMessageA(main, WM_COMMAND, MT4_WMCMD_EXPERTS, 0 );
   }
}

void enableExperts() {

   if ( !IsExpertEnabled() ) {
   
      int main = GetAncestor(WindowHandle(Symbol(), Period()), 2/*GA_ROOT*/);

      if ( main > 0 ) PostMessageA(main, WM_COMMAND, MT4_WMCMD_EXPERTS, 0 );
   }
}
