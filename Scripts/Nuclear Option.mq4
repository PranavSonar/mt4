//+-------------------------------------------------------------------+
//|                                                Nuclear Option.mq4 |
//|                                    Copyright 2012, Steve Hopwood  |
//|                              http://www.hopwood3.freeserve.co.uk  |
//+-------------------------------------------------------------------+

#property strict
#property show_inputs

extern int     MagicNumber=0;
bool           ForceTradeClosure=false;

void CloseAllTrades(int type)
{
   ForceTradeClosure= false;
   
   if (OrdersTotal() == 0) return;
   
   bool result = false;
   
      
   for (int cc = OrdersTotal() - 1; cc >= 0; cc--)
   {
      if (!OrderSelect(cc, SELECT_BY_POS, MODE_TRADES) ) continue;
      if (OrderMagicNumber() != MagicNumber) continue;
      //if (OrderSymbol() != Symbol() ) continue;
      
      while(IsTradeContextBusy()) Sleep(100);
      
      if (type < 2)
         if (OrderType() < 2)
         {
            result = OrderClose(OrderTicket(), OrderLots(), OrderClosePrice(), 1000, CLR_NONE);
            if (!result) ForceTradeClosure= true;
            if (result) cc++;
         }//if (OrderType() < 2)
      
      if (type > 1)   
         if (OrderType() > 1) 
         {
            result = OrderDelete(OrderTicket(), clrNONE);
            if (!result) ForceTradeClosure= true;
            if (result) cc++;
         }//if (OrderType() > 1) 
       
      
   }//for (int cc = OrdersTotal() - 1; cc >= 0; cc--)

   
}//End void CloseAllTrades()

//+------------------------------------------------------------------+
//| Script program start function                                    |
//+------------------------------------------------------------------+
void OnStart()
{
   
   //Close market orders
   CloseAllTrades(0);
   
   //Delete pending trades
   CloseAllTrades(2);
   
   //Try again if necessary
   if (ForceTradeClosure)
   {
      //Close market orders
      CloseAllTrades(0);
      
      //Delete pending trades
      CloseAllTrades(2);
   }//if (ForceTradeClosure)
   
   //And again if necessary
   if (ForceTradeClosure)
   {
      //Close market orders
      CloseAllTrades(0);
      
      //Delete pending trades
      CloseAllTrades(2);
   }//if (ForceTradeClosure)
   
   //Give up
   if (ForceTradeClosure)
      Alert("The script did not close/delete all trades. Please try again.");
   
}
