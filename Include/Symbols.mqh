//+------------------------------------------------------------------+
//|                                                      Symbols.mqh |
//|                                                         renexxxx |
//| This include was developed by renexxxx from the                  |
//|    http://www.stevehopwoodforex.com/ forum.                      |
//|                                                                  |
//| version 0.1   initial release (RZ)                               |
//|------------------------------------------------------------------+
#property copyright "renexxxx"
#property link      "http://www.stevehopwoodforex.com/"
#property strict

input string    IncludeSymbols       = "AUDCAD,AUDCHF,AUDJPY,AUDNZD,AUDUSD,CADCHF,CADJPY,CHFJPY,EURAUD,EURCAD,EURJPY,EURNZD,EURUSD,GBPAUD,GBPCAD,GBPCHF,GBPJPY,GBPNZD,GBPUSD,NZDCAD,NZDCHF,NZDJPY,NZDUSD,USDCAD,USDCHF,USDJPY";
//input string    IncludeSymbols       = "GBPAUD";
input string    ExcludeSymbols       = "";
input string    IncludeCurrencies    = "";
input string    ExcludeCurrencies    = "SEK,SGD,DKK,NOK,TRY,HKD,ZAR,MXN,XAG,XAU";

//+------------------------------------------------------------------+
//| createSymbolNamesArray()                                         |
//+------------------------------------------------------------------+
void createSymbolNamesArray( string &symbolNames[] ) {

   static const ushort comma = StringGetChar(",",0);
   string tempSymbols[];
   string tempSymbol;

   // Empty symbol-array
   ArrayFree( symbolNames );
   ArrayResize( symbolNames, 0 );

   // Get the included symbolNames
   string tempString = IncludeSymbols;
   string includeSymbols[];
   ArrayResize(tempSymbols,0);
   StringSplit(tempString, comma, tempSymbols );
   for(int iSymbol=0; iSymbol<ArraySize(tempSymbols); iSymbol++) {
      tempSymbol = StringTrimLeft( StringTrimRight( tempSymbols[iSymbol] ) );
      if ( tempSymbol == "NULL" ) tempSymbol = Symbol();
      addToStringArray( includeSymbols, tempSymbol );
   }
   
   printArray(includeSymbols,"Included");

   // Get the excluded symbolNames
   tempString = ExcludeSymbols;
   string excludeSymbols[];
   ArrayResize(tempSymbols,0);
   StringSplit(tempString, comma, tempSymbols );
   for(int iSymbol=0; iSymbol<ArraySize(tempSymbols); iSymbol++) {
      tempSymbol = StringTrimLeft( StringTrimRight( tempSymbols[iSymbol] ) );
      if ( tempSymbol == "NULL" ) tempSymbol = Symbol();
      addToStringArray( excludeSymbols, tempSymbol );
   }
   
   printArray(excludeSymbols,"Excluded");

   // Get the included currencies
   tempString = IncludeCurrencies;
   string includeCurrencies[];
   ArrayResize(tempSymbols,0);
   StringSplit(tempString, comma, tempSymbols );
   for(int iSymbol=0; iSymbol<ArraySize(tempSymbols); iSymbol++) {
      tempSymbol = StringTrimLeft( StringTrimRight( tempSymbols[iSymbol] ) );
      addToStringArray( includeCurrencies, tempSymbol );
   }
   
   printArray(includeCurrencies,"IncludedCurrencies");

   // Get the excluded currencies
   tempString = ExcludeCurrencies;
   string excludeCurrencies[];
   ArrayResize(tempSymbols,0);
   StringSplit(tempString, comma, tempSymbols );
   for(int iSymbol=0; iSymbol<ArraySize(tempSymbols); iSymbol++) {
      tempSymbol = StringTrimLeft( StringTrimRight( tempSymbols[iSymbol] ) );
      addToStringArray( excludeCurrencies, tempSymbol );
   }
   
   printArray(excludeCurrencies,"ExcludedCurrencies");

   // Get the market symbolNames
   string marketSymbols[];
   for (int iSymbol=0; iSymbol < SymbolsTotal(true); iSymbol++) {
      addToStringArray( marketSymbols,SymbolName(iSymbol,true) );
   }
   printArray(marketSymbols,"MarketSymbols");
   
   // If includeSymbols is empty, we take all marketSymbols that contain a currency in includeCurrencies,
   // minus the excludeSymbols, minus those with a currency in excludeCurrencies
   if ( ArraySize(includeSymbols) == 0 ) {
   
      for(int iSymbol=0; iSymbol<ArraySize(marketSymbols); iSymbol++) {
      
         if ( ( findInStringArray(excludeSymbols, marketSymbols[iSymbol]) < 0 )                      && 
              ( ( ArraySize(includeCurrencies) == 0 )                                                   ||
                ( findInStringArray(includeCurrencies, StringSubstr(marketSymbols[iSymbol],0,3)) >= 0 ) ||
                ( findInStringArray(includeCurrencies, StringSubstr(marketSymbols[iSymbol],3,3)) >= 0 ) ) &&
              ( findInStringArray(excludeCurrencies, StringSubstr(marketSymbols[iSymbol],0,3)) < 0 ) &&
              ( findInStringArray(excludeCurrencies, StringSubstr(marketSymbols[iSymbol],3,3)) < 0 ) ) {
      
            addToStringArray(symbolNames,marketSymbols[iSymbol]);
         }
      } // for
   } // if
   // Else If includeSymbols is not empty, we take all symbolNames in includeSymbols minus the excludeSymbols, 
   // as long as they are in marketSymbols, and as long as their currency are not in excludeCurrencies
   else {

      for(int iSymbol=0; iSymbol<ArraySize(includeSymbols); iSymbol++) {
      
         if ( ( findInStringArray(excludeSymbols, includeSymbols[iSymbol]) < 0 )                       && 
              ( findInStringArray(marketSymbols, includeSymbols[iSymbol]) >= 0 )                       && 
              ( ( ArraySize(includeCurrencies) == 0 )                                                    ||
                ( findInStringArray(includeCurrencies, StringSubstr(includeSymbols[iSymbol],0,3)) >= 0 ) ||
                ( findInStringArray(includeCurrencies, StringSubstr(includeSymbols[iSymbol],3,3)) >= 0 ) ) &&
              ( findInStringArray(excludeCurrencies, StringSubstr(includeSymbols[iSymbol],0,3)) < 0 )  &&
              ( findInStringArray(excludeCurrencies, StringSubstr(includeSymbols[iSymbol],3,3)) < 0 ) ) {
      
            addToStringArray(symbolNames,includeSymbols[iSymbol]);
         }
      } // for
   } // else
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

void printArray(string &array[], string label) {

   string output = StringFormat("%s::",label);
   
   for(int index=0; index < ArraySize(array); index++) {
      output = StringConcatenate(output,array[index],";");
   }
   
   Print(output);
}