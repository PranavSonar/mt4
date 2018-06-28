//+------------------------------------------------------------------+
//|                                               milaneseMarketInfo |
//|                                      Copyright 2016, milanese    |
//|                                 http://www.stevehopwoodforex.com |
//+------------------------------------------------------------------+
#property copyright "(c)2016 by milanese"
#property link      "http://www.stevehopwoodforex.com"
#define version     "1.02"
#property strict
#property indicator_chart_window
sinput ENUM_TIMEFRAMES MA_Timeframe=PERIOD_CURRENT;
sinput int MA_Period=34;
sinput int up_downShift=0;
sinput int sideAdjustment= 0;
sinput color symbolColor = clrMediumTurquoise;
sinput color commentColor= clrWhite;
sinput color spreadColor = clrGold;
sinput color colorPriceUp= clrLime;
sinput color colorPriceDown=clrRed;
sinput color ProfitLossColor=clrGold;
bool showPairSymbol=true;
bool showMagnifiedPrice=true;
bool showOnRightTop=true;
bool showMoreInfo=true;
bool showPipProfit=true;
color tradeValueColor=clrGold;
color profitColor=clrGold;
double oldPrice=0;
int ordersTotal= 0;
int multiplier = 10;
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
int OnInit()
  {
   if(MarketInfo(Symbol(),MODE_PROFITCALCMODE)==0)
     {
      if(Digits == 0 || Digits == 1) multiplier = 1;
      if(Digits == 2 || Digits == 4) multiplier = 1;
      if(Digits == 3 || Digits == 5) multiplier = 10;
      if(Digits == 6) multiplier = 100;
      if(Digits == 7) multiplier = 1000;

        } else if(MarketInfo(Symbol(),MODE_PROFITCALCMODE)!=0) {
      multiplier=1;
     }
// Special case for gold silver.
   if((StringFind(Symbol(),"XAUUSD",0)!=-1)&&(Digits==3))multiplier = 100;
   if((StringFind(Symbol(),"XAUUSD",0)!=-1)&&(Digits==2))multiplier = 10;
   if((StringFind(Symbol(),"XAUUSD",0)!=-1)&&(Digits==1))multiplier = 1;
   if((StringFind(Symbol(),"XAGUSD",0)!=-1)&&(Digits==4))multiplier = 100;
   if((StringFind(Symbol(),"XAGUSD",0)!=-1)&&(Digits==3))multiplier = 10;
   if((StringFind(Symbol(),"XAGUSD",0)!=-1)&&(Digits==2))multiplier = 1;
   return(INIT_SUCCEEDED);
  }
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void OnDeinit(const int reason)
  {
   ObjectsDeleteAll(0,OBJ_LABEL);

  }
//+------------------------------------------------------------------+
//|                                                                  |
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
   color priceColor;
   double tradeValue=0;
   double profit=0;
   double totalprofit=0;
   int i = 0;
   int j = 0;
   int total=0;
   if(Bid>oldPrice) priceColor=colorPriceUp;
   else if(Bid<oldPrice) priceColor=colorPriceDown;
   else priceColor=Gold;
   oldPrice=Bid;
   string actualPrice=DoubleToStr(Bid,Digits);
   double spreadActual=(Ask-Bid)/Point/multiplier;
   double dayHigh= iHigh(NULL,PERIOD_D1,0);
   double dayLow = iLow(NULL,PERIOD_D1,0);
   string spreadValue=DoubleToStr(spreadActual,1);
   string dayHighValue= DoubleToStr(dayHigh,Digits);
   string dayLowValue = DoubleToStr(dayLow, Digits);
   int candeleRestTime = int(Time[0] + 60 * Period() - TimeCurrent());
   int candleRestTimeM= candeleRestTime%60;
   candeleRestTime = (candeleRestTime - candeleRestTime % 60) / 60;
   string longSwap = DoubleToStr( MarketInfo(Symbol(),MODE_SWAPLONG), 2 );
   string shortSwap= DoubleToStr(MarketInfo(Symbol(),MODE_SWAPSHORT),2);
   double ma240=iMA(NULL,MA_Timeframe,MA_Period,0,MODE_LWMA,PRICE_OPEN,0);
   double distance=(Bid-ma240)/Point/multiplier;
   string ma240Distance=DoubleToStr(distance,1);
   string Sym=Symbol()+" "+PeriodToStr(Period());
   if(ordersTotal!=OrdersTotal()) ObjectsDeleteAll(0,OBJ_LABEL);

   if(showPairSymbol==true) 
     {
      ObjectCreate("pairsymbol",OBJ_LABEL,0,0,0);
      ObjectSetText("pairsymbol",""+Sym+"",20,"Arial",symbolColor);
      ObjectSet("pairsymbol",OBJPROP_CORNER,showOnRightTop);
      ObjectSet("pairsymbol",OBJPROP_XDISTANCE,sideAdjustment+10);
      ObjectSet("pairsymbol",OBJPROP_YDISTANCE,up_downShift+0);
     }

   if(showMagnifiedPrice==true) 
     {
      ObjectCreate("actualPrice",OBJ_LABEL,0,0,0);
      ObjectSetText("actualPrice",""+actualPrice+"",20,"Arial",priceColor);
      ObjectSet("actualPrice",OBJPROP_CORNER,showOnRightTop);
      ObjectSet("actualPrice",OBJPROP_XDISTANCE,sideAdjustment+10);
      ObjectSet("actualPrice",OBJPROP_YDISTANCE,up_downShift+30);
     }

   if(showMoreInfo==true) 
     {
      if(showMagnifiedPrice==true) 
        {
         ObjectCreate("spreadLabel",OBJ_LABEL,0,0,0);
         ObjectSetText("spreadLabel","Spread",10,"Arial",commentColor);
         ObjectSet("spreadLabel",OBJPROP_CORNER,showOnRightTop);
         ObjectSet("spreadLabel",OBJPROP_XDISTANCE,sideAdjustment+58);
         ObjectSet("spreadLabel",OBJPROP_YDISTANCE,up_downShift+67);
         ObjectCreate("spreadValue",OBJ_LABEL,0,0,0);
         ObjectSetText("spreadValue",""+spreadValue+"",10,"Arial",spreadColor);
         ObjectSet("spreadValue",OBJPROP_CORNER,showOnRightTop);
         ObjectSet("spreadValue",OBJPROP_XDISTANCE,sideAdjustment+10);
         ObjectSet("spreadValue",OBJPROP_YDISTANCE,up_downShift+67);
         ObjectCreate("dayHighLabel",OBJ_LABEL,0,0,0);
         ObjectSetText("dayHighLabel","DayHigh",10,"Arial",commentColor);
         ObjectSet("dayHighLabel",OBJPROP_CORNER,showOnRightTop);
         ObjectSet("dayHighLabel",OBJPROP_XDISTANCE,sideAdjustment+58);
         ObjectSet("dayHighLabel",OBJPROP_YDISTANCE,up_downShift+82);
         ObjectCreate("dayHighValue",OBJ_LABEL,0,0,0);
         ObjectSetText("dayHighValue",""+dayHighValue+"",10,"Arial",colorPriceUp);
         ObjectSet("dayHighValue",OBJPROP_CORNER,showOnRightTop);
         ObjectSet("dayHighValue",OBJPROP_XDISTANCE,sideAdjustment+10);
         ObjectSet("dayHighValue",OBJPROP_YDISTANCE,up_downShift+82);
         ObjectCreate("dayLowLabel",OBJ_LABEL,0,0,0);
         ObjectSetText("dayLowLabel","DayLow",10,"Arial",commentColor);
         ObjectSet("dayLowLabel",OBJPROP_CORNER,showOnRightTop);
         ObjectSet("dayLowLabel",OBJPROP_XDISTANCE,sideAdjustment+58);
         ObjectSet("dayLowLabel",OBJPROP_YDISTANCE,up_downShift+97);
         ObjectCreate("dayLowValue",OBJ_LABEL,0,0,0);
         ObjectSetText("dayLowValue",""+dayLowValue+"",10,"Arial",colorPriceDown);
         ObjectSet("dayLowValue",OBJPROP_CORNER,showOnRightTop);
         ObjectSet("dayLowValue",OBJPROP_XDISTANCE,sideAdjustment+10);
         ObjectSet("dayLowValue",OBJPROP_YDISTANCE,up_downShift+97);
         ObjectCreate("candleTimeLabel",OBJ_LABEL,0,0,0);
         ObjectSetText("candleTimeLabel","Candle will close in",10,"Arial",commentColor);
         ObjectSet("candleTimeLabel",OBJPROP_CORNER,showOnRightTop);
         ObjectSet("candleTimeLabel",OBJPROP_XDISTANCE,sideAdjustment+58);
         ObjectSet("candleTimeLabel",OBJPROP_YDISTANCE,up_downShift+112);
         ObjectCreate("candleRestTimeValue",OBJ_LABEL,0,0,0);
         ObjectSetText("candleRestTimeValue",""+IntegerToString(candeleRestTime)+":"+IntegerToString(candleRestTimeM)+"",10,"Arial",spreadColor);
         ObjectSet("candleRestTimeValue",OBJPROP_CORNER,showOnRightTop);
         ObjectSet("candleRestTimeValue",OBJPROP_XDISTANCE,sideAdjustment+10);
         ObjectSet("candleRestTimeValue",OBJPROP_YDISTANCE,up_downShift+112);
         ObjectCreate("swapLongLabel",OBJ_LABEL,0,0,0);
         ObjectSetText("swapLongLabel","Swap Long",10,"Arial",commentColor);
         ObjectSet("swapLongLabel",OBJPROP_CORNER,showOnRightTop);
         ObjectSet("swapLongLabel",OBJPROP_XDISTANCE,sideAdjustment+58);
         ObjectSet("swapLongLabel",OBJPROP_YDISTANCE,up_downShift+127);
         ObjectCreate("swapLongValue",OBJ_LABEL,0,0,0);
         ObjectSetText("swapLongValue",""+longSwap+"",10,"Arial",spreadColor);
         ObjectSet("swapLongValue",OBJPROP_CORNER,showOnRightTop);
         ObjectSet("swapLongValue",OBJPROP_XDISTANCE,sideAdjustment+10);
         ObjectSet("swapLongValue",OBJPROP_YDISTANCE,up_downShift+127);
         ObjectCreate("swapShortLabel",OBJ_LABEL,0,0,0);
         ObjectSetText("swapShortLabel","Swap Short",10,"Arial",commentColor);
         ObjectSet("swapShortLabel",OBJPROP_CORNER,showOnRightTop);
         ObjectSet("swapShortLabel",OBJPROP_XDISTANCE,sideAdjustment+58);
         ObjectSet("swapShortLabel",OBJPROP_YDISTANCE,up_downShift+142);
         ObjectCreate("swapShortValue",OBJ_LABEL,0,0,0);
         ObjectSetText("swapShortValue",""+shortSwap+"",10,"Arial",spreadColor);
         ObjectSet("swapShortValue",OBJPROP_CORNER,showOnRightTop);
         ObjectSet("swapShortValue",OBJPROP_XDISTANCE,sideAdjustment+10);
         ObjectSet("swapShortValue",OBJPROP_YDISTANCE,up_downShift+142);
         ObjectCreate("maDisstanceLabel",OBJ_LABEL,0,0,0);
         ObjectSetText("maDisstanceLabel","Distance from MA"+IntegerToString(MA_Period),10,"Arial",commentColor);
         ObjectSet("maDisstanceLabel",OBJPROP_CORNER,showOnRightTop);
         ObjectSet("maDisstanceLabel",OBJPROP_XDISTANCE,sideAdjustment+58);
         ObjectSet("maDisstanceLabel",OBJPROP_YDISTANCE,up_downShift+157);
         ObjectCreate("maDisstanceValue",OBJ_LABEL,0,0,0);
         ObjectSetText("maDisstanceValue",""+ma240Distance+"",10,"Arial",spreadColor);
         ObjectSet("maDisstanceValue",OBJPROP_CORNER,showOnRightTop);
         ObjectSet("maDisstanceValue",OBJPROP_XDISTANCE,sideAdjustment+10);
         ObjectSet("maDisstanceValue",OBJPROP_YDISTANCE,up_downShift+157);

         if(showPipProfit==true) 
           {
            total=OrdersTotal();
            ordersTotal=total;
            j=0;
            double lots;;
            for(i=0; i<total; i++) 
              {
               bool orderSelect=OrderSelect(i,SELECT_BY_POS,MODE_TRADES);
               if(Symbol()==OrderSymbol()) 
                 {
                  if(OrderType()==OP_BUYSTOP || OrderType()==OP_BUYLIMIT || OrderType()==OP_SELLSTOP || OrderType()==OP_SELLLIMIT) continue;
                  j++;
                  if(OrderType()==OP_BUY) 
                    {
                     lots=OrderLots();
                     profit+=OrderProfit()+OrderSwap()+OrderCommission();
                     tradeValue=(Bid-OrderOpenPrice())/Point/multiplier;
                     if(tradeValue>0) tradeValueColor=Lime;
                     else tradeValueColor=Red;
                     if(profit>0) profitColor=Lime;
                     else profitColor=Red;

                     ObjectCreate("profitLabel",OBJ_LABEL,0,0,0);
                     ObjectSetText("profitLabel","Current Profit/Loss",10,"Arial Bold",ProfitLossColor);
                     ObjectSet("profitLabel",OBJPROP_CORNER,showOnRightTop);
                     ObjectSet("profitLabel",OBJPROP_XDISTANCE,sideAdjustment+58);
                     ObjectSet("profitLabel",OBJPROP_YDISTANCE,up_downShift+172);

                     ObjectCreate("profitValue",OBJ_LABEL,0,0,0);
                     ObjectSetText("profitValue",DoubleToStr(profit,2),10,"Arial Bold",profitColor);
                     ObjectSet("profitValue",OBJPROP_CORNER,showOnRightTop);
                     ObjectSet("profitValue",OBJPROP_XDISTANCE,sideAdjustment+10);
                     ObjectSet("profitValue",OBJPROP_YDISTANCE,up_downShift+172);

                     ObjectCreate("openTradeLabel"+IntegerToString(i),OBJ_LABEL,0,0,0);
                     ObjectSetText("openTradeLabel"+IntegerToString(i),"Trade"+IntegerToString(j)+",BUY,Lots:"+DoubleToStr(lots,2)+",Pips: ",10,"Arial",commentColor);
                     ObjectSet("openTradeLabel"+IntegerToString(i),OBJPROP_CORNER,showOnRightTop);
                     ObjectSet("openTradeLabel"+IntegerToString(i),OBJPROP_XDISTANCE,sideAdjustment+50);
                     ObjectSet("openTradeLabel"+IntegerToString(i),OBJPROP_YDISTANCE,15*j+157+up_downShift+15);
                     ObjectCreate("pipProfitValue"+IntegerToString(i),OBJ_LABEL,0,0,0);
                     ObjectSetText("pipProfitValue"+IntegerToString(i),DoubleToStr(tradeValue,1),10,"Arial",tradeValueColor);
                     ObjectSet("pipProfitValue"+IntegerToString(i),OBJPROP_CORNER,showOnRightTop);
                     ObjectSet("pipProfitValue"+IntegerToString(i),OBJPROP_XDISTANCE,sideAdjustment+10);
                     ObjectSet("pipProfitValue"+IntegerToString(i),OBJPROP_YDISTANCE,15*j+157+up_downShift+15);

                     continue;
                    }
                  if(OrderType()==OP_SELL) 
                    {
                     lots=OrderLots();
                     profit+=OrderProfit()+OrderSwap()+OrderCommission();
                     tradeValue=(OrderOpenPrice()-Ask)/Point/multiplier;
                     if(tradeValue>0) tradeValueColor=Lime;
                     else tradeValueColor=Red;
                     if(profit>0) profitColor=Lime;
                     else profitColor=Red;

                     ObjectCreate("profitLabel",OBJ_LABEL,0,0,0);
                     ObjectSetText("profitLabel","Current Profit/Loss",10,"Arial Bold",ProfitLossColor);
                     ObjectSet("profitLabel",OBJPROP_CORNER,showOnRightTop);
                     ObjectSet("profitLabel",OBJPROP_XDISTANCE,sideAdjustment+58);
                     ObjectSet("profitLabel",OBJPROP_YDISTANCE,up_downShift+172);

                     ObjectCreate("profitValue",OBJ_LABEL,0,0,0);
                     ObjectSetText("profitValue",DoubleToStr(profit,2),10,"Arial Bold",profitColor);
                     ObjectSet("profitValue",OBJPROP_CORNER,showOnRightTop);
                     ObjectSet("profitValue",OBJPROP_XDISTANCE,sideAdjustment+10);
                     ObjectSet("profitValue",OBJPROP_YDISTANCE,up_downShift+172);

                     ObjectCreate("openTradeLabel"+IntegerToString(i),OBJ_LABEL,0,0,0);
                     ObjectSetText("openTradeLabel"+IntegerToString(i),"Trade"+IntegerToString(j)+",SELL,Lots:"+DoubleToStr(lots,2)+",Pips: ",10,"Arial",commentColor);
                     ObjectSet("openTradeLabel"+IntegerToString(i),OBJPROP_CORNER,showOnRightTop);
                     ObjectSet("openTradeLabel"+IntegerToString(i),OBJPROP_XDISTANCE,sideAdjustment+50);
                     ObjectSet("openTradeLabel"+IntegerToString(i),OBJPROP_YDISTANCE,15*j+157+up_downShift+15);
                     ObjectCreate("pipProfitValue"+IntegerToString(i),OBJ_LABEL,0,0,0);
                     ObjectSetText("pipProfitValue"+IntegerToString(i),DoubleToStr(tradeValue,1),10,"Arial",tradeValueColor);
                     ObjectSet("pipProfitValue"+IntegerToString(i),OBJPROP_CORNER,showOnRightTop);
                     ObjectSet("pipProfitValue"+IntegerToString(i),OBJPROP_XDISTANCE,sideAdjustment+10);
                     ObjectSet("pipProfitValue"+IntegerToString(i),OBJPROP_YDISTANCE,15*j+157+up_downShift+15);

                    }
                 }
              }
           }
        }
     }

   if(showMoreInfo==true) 
     {
      if(showMagnifiedPrice==false) 
        {
         ObjectCreate("spreadLabel",OBJ_LABEL,0,0,0);
         ObjectSetText("spreadLabel","Spread",10,"Arial",commentColor);
         ObjectSet("spreadLabel",OBJPROP_CORNER,showOnRightTop);
         ObjectSet("spreadLabel",OBJPROP_XDISTANCE,sideAdjustment+58);
         ObjectSet("spreadLabel",OBJPROP_YDISTANCE,up_downShift+25);
         ObjectCreate("spreadValue",OBJ_LABEL,0,0,0);
         ObjectSetText("spreadValue",""+spreadValue+"",10,"Arial",spreadColor);
         ObjectSet("spreadValue",OBJPROP_CORNER,showOnRightTop);
         ObjectSet("spreadValue",OBJPROP_XDISTANCE,sideAdjustment+10);
         ObjectSet("spreadValue",OBJPROP_YDISTANCE,up_downShift+25);
         ObjectCreate("dayHighLabel",OBJ_LABEL,0,0,0);
         ObjectSetText("dayHighLabel","DayHigh",10,"Arial",commentColor);
         ObjectSet("dayHighLabel",OBJPROP_CORNER,showOnRightTop);
         ObjectSet("dayHighLabel",OBJPROP_XDISTANCE,sideAdjustment+58);
         ObjectSet("dayHighLabel",OBJPROP_YDISTANCE,up_downShift+40);
         ObjectCreate("dayHighValue",OBJ_LABEL,0,0,0);
         ObjectSetText("dayHighValue",""+dayHighValue+"",10,"Arial",colorPriceUp);
         ObjectSet("dayHighValue",OBJPROP_CORNER,showOnRightTop);
         ObjectSet("dayHighValue",OBJPROP_XDISTANCE,sideAdjustment+10);
         ObjectSet("dayHighValue",OBJPROP_YDISTANCE,up_downShift+40);
         ObjectCreate("dayLowLabel",OBJ_LABEL,0,0,0);
         ObjectSetText("dayLowLabel","DayLow",10,"Arial",commentColor);
         ObjectSet("dayLowLabel",OBJPROP_CORNER,showOnRightTop);
         ObjectSet("dayLowLabel",OBJPROP_XDISTANCE,sideAdjustment+58);
         ObjectSet("dayLowLabel",OBJPROP_YDISTANCE,up_downShift+55);
         ObjectCreate("dayLowValue",OBJ_LABEL,0,0,0);
         ObjectSetText("dayLowValue",""+dayLowValue+"",10,"Arial",colorPriceDown);
         ObjectSet("dayLowValue",OBJPROP_CORNER,showOnRightTop);
         ObjectSet("dayLowValue",OBJPROP_XDISTANCE,sideAdjustment+10);
         ObjectSet("dayLowValue",OBJPROP_YDISTANCE,up_downShift+55);
         ObjectCreate("candleTimeLabel",OBJ_LABEL,0,0,0);
         ObjectSetText("candleTimeLabel","Candle will close in",10,"Arial",commentColor);
         ObjectSet("candleTimeLabel",OBJPROP_CORNER,showOnRightTop);
         ObjectSet("candleTimeLabel",OBJPROP_XDISTANCE,sideAdjustment+58);
         ObjectSet("candleTimeLabel",OBJPROP_YDISTANCE,up_downShift+70);
         ObjectCreate("candleRestTimeValue",OBJ_LABEL,0,0,0);
         ObjectSetText("candleRestTimeValue",""+IntegerToString(candeleRestTime)+":"+IntegerToString(candleRestTimeM)+"",10,"Arial",spreadColor);
         ObjectSet("candleRestTimeValue",OBJPROP_CORNER,showOnRightTop);
         ObjectSet("candleRestTimeValue",OBJPROP_XDISTANCE,sideAdjustment+10);
         ObjectSet("candleRestTimeValue",OBJPROP_YDISTANCE,up_downShift+70);
         ObjectCreate("swapLongLabel",OBJ_LABEL,0,0,0);
         ObjectSetText("swapLongLabel","Swap Long",10,"Arial",commentColor);
         ObjectSet("swapLongLabel",OBJPROP_CORNER,showOnRightTop);
         ObjectSet("swapLongLabel",OBJPROP_XDISTANCE,sideAdjustment+58);
         ObjectSet("swapLongLabel",OBJPROP_YDISTANCE,up_downShift+85);
         ObjectCreate("swapLongValue",OBJ_LABEL,0,0,0);
         ObjectSetText("swapLongValue",""+longSwap+"",10,"Arial",spreadColor);
         ObjectSet("swapLongValue",OBJPROP_CORNER,showOnRightTop);
         ObjectSet("swapLongValue",OBJPROP_XDISTANCE,sideAdjustment+10);
         ObjectSet("swapLongValue",OBJPROP_YDISTANCE,up_downShift+85);
         ObjectCreate("swapShortLabel",OBJ_LABEL,0,0,0);
         ObjectSetText("swapShortLabel","Swap Short",10,"Arial",commentColor);
         ObjectSet("swapShortLabel",OBJPROP_CORNER,showOnRightTop);
         ObjectSet("swapShortLabel",OBJPROP_XDISTANCE,sideAdjustment+58);
         ObjectSet("swapShortLabel",OBJPROP_YDISTANCE,up_downShift+100);
         ObjectCreate("swapShortValue",OBJ_LABEL,0,0,0);
         ObjectSetText("swapShortValue",""+shortSwap+"",10,"Arial",spreadColor);
         ObjectSet("swapShortValue",OBJPROP_CORNER,showOnRightTop);
         ObjectSet("swapShortValue",OBJPROP_XDISTANCE,sideAdjustment+10);
         ObjectSet("swapShortValue",OBJPROP_YDISTANCE,up_downShift+100);
         ObjectCreate("maDisstanceLabel",OBJ_LABEL,0,0,0);
          ObjectSetText("maDisstanceLabel","Distance from MA"+IntegerToString(MA_Period),10,"Arial",commentColor);
         ObjectSet("maDisstanceLabel",OBJPROP_CORNER,showOnRightTop);
         ObjectSet("maDisstanceLabel",OBJPROP_XDISTANCE,sideAdjustment+58);
         ObjectSet("maDisstanceLabel",OBJPROP_YDISTANCE,up_downShift+115);
         ObjectCreate("maDisstanceValue",OBJ_LABEL,0,0,0);
         ObjectSetText("maDisstanceValue",""+ma240Distance+"",10,"Arial",spreadColor);
         ObjectSet("maDisstanceValue",OBJPROP_CORNER,showOnRightTop);
         ObjectSet("maDisstanceValue",OBJPROP_XDISTANCE,sideAdjustment+10);
         ObjectSet("maDisstanceValue",OBJPROP_YDISTANCE,up_downShift+115);

         if(showPipProfit==true) 
           {
            total=OrdersTotal();
            ordersTotal=total;
            j=0;
            for(i=0; i<total; i++) 
              {
               bool orderSelect=OrderSelect(i,SELECT_BY_POS,MODE_TRADES);
               if(!orderSelect)  return(rates_total);
               if(Symbol()==OrderSymbol()) 
                 {
                  if(OrderType()==OP_BUYSTOP || OrderType()==OP_BUYLIMIT || OrderType()==OP_SELLSTOP || OrderType()==OP_SELLLIMIT) continue;
                  j++;
                  if(OrderType()==OP_BUY) 
                    {

                     tradeValue=(Bid-OrderOpenPrice())/Point/multiplier;
                     if(tradeValue>0) tradeValueColor=Lime;
                     else tradeValueColor=Red;
                     ObjectCreate("openTradeLabel"+IntegerToString(i),OBJ_LABEL,0,0,0);
                     ObjectSetText("openTradeLabel"+IntegerToString(i),"OpenTrades: "+IntegerToString(j)+" Pips: ",10,"Arial",commentColor);
                     ObjectSet("openTradeLabel"+IntegerToString(i),OBJPROP_CORNER,showOnRightTop);
                     ObjectSet("openTradeLabel"+IntegerToString(i),OBJPROP_XDISTANCE,sideAdjustment+58);
                     ObjectSet("openTradeLabel"+IntegerToString(i),OBJPROP_YDISTANCE,15*j+115+up_downShift);
                     ObjectCreate("pipProfitValue"+IntegerToString(i),OBJ_LABEL,0,0,0);
                     ObjectSetText("pipProfitValue"+IntegerToString(i),DoubleToStr(tradeValue,1),10,"Arial",tradeValueColor);
                     ObjectSet("pipProfitValue"+IntegerToString(i),OBJPROP_CORNER,showOnRightTop);
                     ObjectSet("pipProfitValue"+IntegerToString(i),OBJPROP_XDISTANCE,sideAdjustment+10);
                     ObjectSet("pipProfitValue"+IntegerToString(i),OBJPROP_YDISTANCE,15*j+115+up_downShift);

                    }
                  if(OrderType()==OP_SELL) 
                    {
                     tradeValue =(OrderOpenPrice()-Ask)/Point/multiplier;
                     if(tradeValue>0) tradeValueColor=Lime;
                     else tradeValueColor=Red;
                     ObjectCreate("openTradeLabel"+IntegerToString(i),OBJ_LABEL,0,0,0);
                     ObjectSetText("openTradeLabel"+IntegerToString(i),"OpenTrades: "+IntegerToString(j)+" Pips: ",10,"Arial",commentColor);
                     ObjectSet("openTradeLabel"+IntegerToString(i),OBJPROP_CORNER,showOnRightTop);
                     ObjectSet("openTradeLabel"+IntegerToString(i),OBJPROP_XDISTANCE,sideAdjustment+58);
                     ObjectSet("openTradeLabel"+IntegerToString(i),OBJPROP_YDISTANCE,15*j+115+up_downShift);
                     ObjectCreate("pipProfitValue"+IntegerToString(i),OBJ_LABEL,0,0,0);
                     ObjectSetText("pipProfitValue"+IntegerToString(i),DoubleToStr(tradeValue,1),10,"Arial",tradeValueColor);
                     ObjectSet("pipProfitValue"+IntegerToString(i),OBJPROP_CORNER,showOnRightTop);
                     ObjectSet("pipProfitValue"+IntegerToString(i),OBJPROP_XDISTANCE,sideAdjustment+10);
                     ObjectSet("pipProfitValue"+IntegerToString(i),OBJPROP_YDISTANCE,15*j+115+up_downShift);

                    }
                 }
              }
           }
        }
     }


   return(rates_total);
  }
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
string PeriodToStr(int period)
  {

   if(period == NULL) return(PeriodToStr(Period()));
   int p[9]={1,5,15,30,60,240,1440,10080,43200};
   string sp[9]={"M1","M5","M15","M30","H1","H4","D1","W1","MN1"};
   for(int i= 0; i < 9; i++) if(p[i] == period) return(sp[i]);
   return("--");

  }
//+------------------------------------------------------------------+
