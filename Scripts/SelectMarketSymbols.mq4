//+------------------------------------------------------------------+
//|                                          SelectMarketSymbols.mq4 |
//|                                         Copyright 2015, renexxxx |
//|                                http://www.stevehopwoodforex.com/ |
//+------------------------------------------------------------------+
#property copyright "Copyright 2015, renexxxx"
#property link      "http://www.stevehopwoodforex.com/"
#property version   "1.00"
#property strict
#property show_inputs

input string    IncludeSymbols = "AUDUSD,EURGBP,EURJPY,EURUSD,GBPUSD,NZDUSD,USDCAD,USDCHF,USDJPY";          // Majors
//input string    IncludeSymbols = "AUDCAD,AUDCHF,AUDJPY,AUDNZD,CADCHF,CADJPY,CHFJPY,EURAUD,EURCAD,EURCHF,EURNZD,GBPAUD,GBPCAD,GBPCHF,GBPJPY,GBPNZD,NZDCAD,NZDCHF,NZDJPY"; // Non-Majors
//+------------------------------------------------------------------+
//| Script program start function                                    |
//+------------------------------------------------------------------+
void OnStart() {
   
   string symbolName;

   // First remove ALL symbols from the MarketWatch panel
   for (int iSymbol=0; iSymbol < SymbolsTotal(false); iSymbol++) {
      symbolName = SymbolName(iSymbol, false);

      // Remove symbolName from MarketWatch panel
      PrintFormat("Removing %s", symbolName);
      SymbolSelect(symbolName,false);
   }

   // Then Show selected symbols in the MarketWatch panel
   for (int iSymbol=0; iSymbol < SymbolsTotal(false); iSymbol++) {
      symbolName = SymbolName(iSymbol, false);

      // If the first six characters of symbolName appear anywhere in IncludeSymbols: Select that symbolName in the MarketWatch panel
      if ( StringFind( IncludeSymbols, StringSubstr(symbolName,0,6) ) >= 0 ) {
         PrintFormat("Selecting %s", symbolName);
         SymbolSelect(symbolName,true);
      }
   }

}
//+------------------------------------------------------------------+
