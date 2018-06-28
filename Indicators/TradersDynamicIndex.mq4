//+------------------------------------------------------------------+
//| Based on:																	      |
//|                                    Traders Dynamic Index.mq4     |
//|                                    Copyright © 2006, Dean Malone |
//|                                    www.compassfx.com             |
//+------------------------------------------------------------------+
//+------------------------------------------------------------------+
//| Updated by:                     											|
//|                                                    Andriy Moraru |
//|                                         http://www.earnforex.com |
//|            							                            2015 |
//+------------------------------------------------------------------+
#property copyright "www.EarnForex.com, 2015"
#property link      "http://www.earnforex.com"
#property version   "1.01"

//+------------------------------------------------------------------+
//|                                                                  |
//|                     Traders Dynamic Index                        |
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
//|  Entry conditions                                                |
//|   Scalping  - Long = Green over Red, Short = Red over Green      |
//|   Active - Long = Green over Red & Yellow lines                  |
//|            Short = Red over Green & Yellow lines                 |    
//|   Moderate - Long = Green over Red, Yellow, & 50 lines           |
//|              Short= Red over Green, Green below Yellow & 50 line |
//|                                                                  |
//|  Exit conditions*                                                |   
//|   Long = Green crosses below Red                                 |
//|   Short = Green crosses above Red                                |
//|   * If Green crosses either Blue lines, consider exiting when    |
//|     when the Green line crosses back over the Blue line.         |
//|                                                                  |
//|                                                                  |
//|  IMPORTANT: The default settings are well tested and proven.     |
//|             But, you can change the settings to fit your         |
//|             trading style.                                       |
//|                                                                  |
//|   Good trading,                                                  |   
//|                                                                  |
//|   Dean                                                           |                              
//+------------------------------------------------------------------+

#property description "Shows trend direction, strength, and volatility."
#property description "Green line  - RSI Price line."
#property description "Red line    - Trade Signal line."
#property description "Blue lines  - Volatility Band."
#property description "Yellow line - Market Base line."

#property indicator_separate_window
#property indicator_buffers 6
#property indicator_level1 32
#property indicator_level2 50
#property indicator_level3 68
#property indicator_levelcolor clrDimGray
#property indicator_levelstyle STYLE_DOT
#property indicator_levelwidth 1
#property indicator_color1 clrNONE
#property indicator_type1  DRAW_NONE
#property indicator_color2 clrMediumBlue
#property indicator_label2 "VB High"
#property indicator_type2  DRAW_LINE
#property indicator_width2 1
#property indicator_style2 STYLE_SOLID
#property indicator_color3 clrYellow
#property indicator_label3 "Market Base Line"
#property indicator_type3  DRAW_LINE
#property indicator_width3 2
#property indicator_style3 STYLE_SOLID
#property indicator_color4 clrMediumBlue
#property indicator_label4 "VB Low"
#property indicator_type4  DRAW_LINE
#property indicator_width4 1
#property indicator_style4 STYLE_SOLID
#property indicator_color5 clrGreen
#property indicator_label5 "RSI Price Line"
#property indicator_type5  DRAW_LINE
#property indicator_width5 2
#property indicator_style5 STYLE_SOLID
#property indicator_color6 clrRed
#property indicator_label6 "Trade Signal Line"
#property indicator_type6  DRAW_LINE
#property indicator_width6 2
#property indicator_style6 STYLE_SOLID

input int RSI_Period = 13; // RSI_Period: 8-25
input ENUM_APPLIED_PRICE RSI_Price = PRICE_CLOSE;
input int Volatility_Band = 34; // Volatility_Band: 20-40
input double StdDev = 1.6185; // Standard Deviations: 1-3
input int RSI_Price_Line = 2;      
input ENUM_MA_METHOD RSI_Price_Type = MODE_SMA;
input int Trade_Signal_Line = 7;   
input ENUM_MA_METHOD Trade_Signal_Type = MODE_SMA;
input bool UseAlerts = false;

double RSIBuf[], UpZone[], MdZone[], DnZone[], MaBuf[], MbBuf[];

int AlertPlayedonBar = 0;

//+------------------------------------------------------------------+
//| Custom indicator initialization function                         |
//+------------------------------------------------------------------+
int init()
{
   IndicatorShortName("TDI(" + IntegerToString(RSI_Period) + "," + IntegerToString(Volatility_Band) + "," + IntegerToString(RSI_Price_Line) + "," + IntegerToString(Trade_Signal_Line) +  ")");
   
   SetIndexBuffer(0, RSIBuf);
   SetIndexBuffer(1, UpZone);
   SetIndexBuffer(2, MdZone);
   SetIndexBuffer(3, DnZone);
   SetIndexBuffer(4, MaBuf);
   SetIndexBuffer(5, MbBuf);
   
   return(0);
}

//+------------------------------------------------------------------+
//| Traders Dynamic Index                                            |
//+------------------------------------------------------------------+
int start()
{
   double MA, RSI[];
   ArrayResize(RSI, Volatility_Band);
   
   int counted_bars = IndicatorCounted();
   int limit = Bars - counted_bars - 1;
   
   for (int i = limit; i >= 0; i--)
   {
      RSIBuf[i] = iRSI(NULL, 0, RSI_Period, RSI_Price, i);
      MA = 0;
      for (int x = i; x < i + Volatility_Band; x++) 
      {
         RSI[x - i] = RSIBuf[x];
         MA += RSIBuf[x] / Volatility_Band;
      }
      double SD = StdDev * StDev(RSI, Volatility_Band);
      UpZone[i] = MA + SD;
      DnZone[i] = MA - SD;
      MdZone[i] = (UpZone[i] + DnZone[i]) / 2;
   }
   for (i = limit - 1; i >= 0; i--)  
   {
      MaBuf[i] = iMAOnArray(RSIBuf, 0, RSI_Price_Line, 0, RSI_Price_Type, i);
      MbBuf[i] = iMAOnArray(RSIBuf, 0, Trade_Signal_Line, 0, Trade_Signal_Type, i);
   }
   if ((MbBuf[0] > MdZone[0]) && (MbBuf[1] <= MdZone[1]) && (UseAlerts == true) && (AlertPlayedonBar != Bars))
   {
      Alert("Bullish cross");
      PlaySound("alert.wav");
      AlertPlayedonBar = Bars;
   }
   if ((MbBuf[0] < MdZone[0]) && (MbBuf[1] >= MdZone[1]) && (UseAlerts == true) && (AlertPlayedonBar != Bars))
   {
      Alert("Bearish cross");
      PlaySound("alert.wav");
      AlertPlayedonBar = Bars;
   }
   
   return(0);
}
  
// Standard Deviation function.
double StDev(double& Data[], int Per)
{
	return(MathSqrt(Variance(Data, Per)));
}

// Math Variance function.
double Variance(double& Data[], int Per)
{
	double sum = 0, ssum = 0;
	for (int i = 0; i < Per; i++)
	{
		sum += Data[i];
		ssum += MathPow(Data[i], 2);
	}
	return((ssum * Per - sum * sum) / (Per * (Per - 1)));
}
//+------------------------------------------------------------------+