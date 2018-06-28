//+------------------------------------------------------------------+
//|                                      ForceLoadHistoricalData.mq4 |
//|                                    Copyright � 2012, Matt Kennel |
//+------------------------------------------------------------------+
#property copyright "Copyright � 2012, Matt Kennel"
#property link      "http://www.stevehopwoodforex.com"

/*
   This script uses iBars() to ATTEMPT to force-load historical data for all
   found FX symbols and timeframes.  Note that iBars() call
   is supposed to return number of bars, but actually forces load
   of 2048 points in an undocumented way in some cases, but not always.
   
   There is no way I know
   to force load all data, but this will get a reasonable amount
   on all symbols & timeframes.

   Message will go to Experts tab via Print() statement.
   
   Read the message and attempt to manually download
   those which failed. Why?  CrapT4.    

 */

#define MaxForceLoadRetries 10

int barsWithRetry(string TempSymbol, int tf) {
   int bars=0;
   for (int i=0; i < MaxForceLoadRetries; i++) {
      bars=iBars(TempSymbol,tf);
      if (bars > 0) {
         return(bars);
      }  
      int err=GetLastError();
      if (err != 4066) {
         // ERR_HISTORY_WILL_UPDATED   4066   Requested history data in updating state.
         return(0); 
      } else {
         Sleep(2000); 
      }
   }
   return(0); 
}

bool ForceLoadOneSym(string TempSymbol, int& totbars, string& badperiods) {
    /* attempt to force-load one symbol. Return false if any iBars() return false
       comes out to be zero, could be waiting for download */
    int timeFrames[] = { PERIOD_M1,PERIOD_M5,PERIOD_M15,PERIOD_M30,PERIOD_H1,
                         PERIOD_H4,PERIOD_D1,PERIOD_W1, PERIOD_MN1
                       };

    int ntf = ArraySize(timeFrames);
    totbars=0;
    bool OK=true;
    string s=TempSymbol+" NumBars(TF): ";
    badperiods="";
    for (int j=0; j < ntf; j++) {
        int tf = timeFrames[j];
        RefreshRates();
        int bars=barsWithRetry(TempSymbol,tf);
        totbars += bars;
        bool tfOK=true;
        
        if (bars == 0) {
            tfOK = false;
        }
        double z = iClose(TempSymbol,tf,0);
        if (z == 0.0) {
            tfOK = false;
        }
        double y = iMA(TempSymbol,tf,1,0,MODE_SMA,PRICE_MEDIAN,0);
        if (y == 0.0) {
            tfOK = false;
        }

        s = s + bars+"("+tf+") ";
        if (!tfOK) {
            badperiods = badperiods + " "+tf;
            OK=false; 
        }
    }
    if (OK) {
      Print("Success: "+s);
    } else {
      Print("Fail:    "+s); 
    }
    return(OK);
}

void ForceLoadHistoricalData() {
    string suffix = StringSubstr(Symbol(),6);

    int hFileName = FileOpenHistory("symbols.raw",FILE_BIN|FILE_READ);
    int Records   = FileSize(hFileName) / 1936;
    string success="", fail="";
    for(int count = 0; count < Records; count++) {
        string TempSymbol = StringTrimLeft(StringTrimRight(FileReadString(hFileName,12)));
        TempSymbol = StringSubstr(TempSymbol,0,6)+suffix; 
        if (MarketInfo(TempSymbol,MODE_MARGINCALCMODE) == 0 &&
                MarketInfo(TempSymbol,MODE_PROFITCALCMODE) == 0 &&
                MarketInfo(TempSymbol,MODE_BID)            >  0) {
            bool OK=false;
            int totbars;
            string badperiods="";
            OK = ForceLoadOneSym(TempSymbol,totbars,badperiods); 
            

            if (!OK) {
                Print("Failed:    "+TempSymbol+" after "+MaxForceLoadRetries+" retries, got "+totbars+" bars. Failed periods:"+badperiods);
                fail = fail + " "+TempSymbol+"("+badperiods+")";
            } else {
                success = success + " "+TempSymbol;
    //            Print("Succeeded: "+TempSymbol+" got "+totbars+" bars");
            }

        }
        FileSeek(hFileName,1924,SEEK_CUR);

    }
    FileClose(hFileName);
    Print("ForceLoadHistoricalData: successful: "+success);
    if (StringLen(fail) == 0) {
      fail="none"; 
    } else {
      Alert("Failed: "+fail); 
    }
    Print("ForceLoadHistoricalData: failed: "+fail);
    return(0);

}

//+------------------------------------------------------------------+
//| script program start function                                    |
//+------------------------------------------------------------------+
int start() {
//----
    ForceLoadHistoricalData();
//----
    return(0);
}
//+------------------------------------------------------------------+