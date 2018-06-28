//+-------------------------------------------------------------------+
//|                                           Nuclear Option FIFO.mq4 |
//|                                    Copyright 2012, Steve Hopwood  |
//|                              http://www.hopwood3.freeserve.co.uk  |
//+-------------------------------------------------------------------+

#property strict
#property show_inputs

extern int     MagicNumber=0;
bool           ForceTradeClosure=false;
int            FifoTicket[];//Array to store trade ticket numbers in FIFO mode, to cater for
                            //US citizens and to make iterating through the trade closure loop 
                            //quicker.

void CountOpenTrades()
{

   int OpenTrades = 0;
   //FIFO ticket resize
   ArrayResize(FifoTicket, 0);
 
   for (int cc = OrdersTotal() - 1; cc >= 0; cc--)
   {
      bool TradeWasClosed = false;//See 'check for possible trade closure'

      //Ensure the trade is still open
      if (!OrderSelect(cc, SELECT_BY_POS, MODE_TRADES) ) continue;
      //Ensure the EA 'owns' this trade
      //if (OrderSymbol() != Symbol() ) continue;
      if (OrderMagicNumber() != MagicNumber) continue;
      if (OrderCloseTime() > 0) continue; 
 
      OpenTrades++;
      //Store ticket numbers for FIFO
      ArrayResize(FifoTicket, OpenTrades + 1);
      FifoTicket[OpenTrades] = OrderTicket();
      
      
   }//for (int cc = OrdersTotal() - 1; cc >= 0; cc--)
   
   //Sort ticket numbers for FIFO
   if (OpenTrades > 0)
      ArraySort(FifoTicket, WHOLE_ARRAY, 0, MODE_DESCEND);
   
}//void CountOpenTrades()


void CloseAllTrades(int type)
{
   ForceTradeClosure= false;
   
   if (OrdersTotal() == 0) return;
   
   bool result = false;
   
      
   for (int cc = ArraySize(FifoTicket) - 1; cc >= 0; cc--)
   {
      if (!OrderSelect(FifoTicket[cc], SELECT_BY_TICKET, MODE_TRADES) ) continue;
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
       
      
   }//for (int cc = ArraySize(FifoTicket) - 1; cc >= 0; cc--)

   
}//End void CloseAllTrades()

//+------------------------------------------------------------------+
//| Script program start function                                    |
//+------------------------------------------------------------------+
void OnStart()
{
   //Construct the ticket numbers array
   CountOpenTrades();
   
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
