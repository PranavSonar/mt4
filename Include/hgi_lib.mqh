//+------------------------------------------------------------------+
//|                                                      hgi_lib.mqh |
//|                                http://www.stevehopwoodforex.com/ |
//| This library was developed by milanese from the                  |
//|    http://www.stevehopwoodforex.com/ forum.                      |
//+------------------------------------------------------------------+
#property copyright "milanese"
#property link      "http://www.stevehopwoodforex.com/"
#property strict


#import "hgi_lib.ex4"

enum SIGNAL {
   NONE=0,
   TRENDUP=1,
   TRENDDN=2,
   RANGEUP=3,
   RANGEDN=4,
   RADUP=5,
   RADDN=6 };
   
enum SLOPE {
   UNDEFINED=0,
   RANGEABOVE=1,
   RANGEBELOW=2,
   TRENDABOVE=3,
   TRENDBELOW=4 };
   
SIGNAL getHGISignal( string symbol, int timeframe, int shift );

SLOPE getHGISlope( string symbol, int timeframe, int shift );
   
#import