//+------------------------------------------------------------------+
//|                                                OrderReliable.mqh |
//|                                 http://www.stevehopwoodforex.com |
//+------------------------------------------------------------------+
#property copyright "mbkennel,derkwehler"
#property link      "http://www.stevehopwoodforex.com"
#property strict

//=============================================================================
//                            LibOrderReliable4.mq4
//
//         Copyright © 2006, Matthew Kennel  (mbkennelfx@gmail.com)
//         Copyright © 2007, Derk Wehler     (derkwehler@gmail.com)
//         Copyright © 2007, Jack Tomlinson  (jack.tomlinson@gmail.com)
//         Copyright © 2010, Matthew Kennel  (mbkennelfx@gmail.com)
//
//  In order to read this code most clearly in the Metaeditor, it is advised
//  that you set your tab settings to 4 (instead of the default 3):
//  Tools->Options->General Tab, set Tab Size to 4, uncheck "Insert spaces"
//
//                        CURRENT REVISION STATUS (Inserted by SOS):
//                       |$Workfile:: LibOrderReliable.mq4                $|
//                       |$Revision:: 39                                  $|
//                       |$Author  :: Derk                                $|
//                       |$Date    :: 12/21/07 4:18p                      $|
//
// ***************************************************************************
// ***************************************************************************
//  LICENSING:  This is free, open source software, licensed under
//              Version 2 of the GNU General Public License (GPL).
//
//  In particular, this means that distribution of this software in a binary
//  format, e.g. as compiled in as part of a .ex4 format, must be accompanied
//  by the non-obfuscated source code of both this file, AND the .mq4 source
//  files which it is compiled with, or you must make such files available at
//  no charge to binary recipients.	If you do not agree with such terms you
//  must not use this code.  Detailed terms of the GPL are widely available
//  on the Internet.  The Library GPL (LGPL) was intentionally not used,
//  therefore the source code of files which link to this are subject to
//  terms of the GPL if binaries made from them are publicly distributed or
//  sold.
//
//  ANY USE OF THIS CODE NOT CONFORMING TO THIS LICENSE MUST FIRST RECEIVE
//  PRIOR AUTHORIZATION FROM THE AUTHOR(S).  ANY COMMERCIAL USE MUST FIRST
//  OBTAIN A COMMERCIAL LICENSE FROM THE AUTHOR(S).
//
//  Copyright (2006), Matthew Kennel, mbkennelfx@gmail.com
//  Copyright (2007), Derk Wehler, derkwehler@gmail.com
// ***************************************************************************
// ***************************************************************************
//
//  A library for MT4 expert advisors, intended to give more reliable
//  order handling.	This library only concerns the mechanics of sending
//  orders to the Metatrader server, dealing with transient connectivity
//  problems better than the standard order sending functions.  It is
//  essentially an error-checking wrapper around the existing transaction
//  functions. This library provides nothing to help actual trade strategies,
//  but ought to be valuable for nearly all expert advisors which trade 'live'.
//
//
//                             Instructions:
//
//  Put this file in the experts/libraries directory.  Put the header
//  file (LibOrderReliable.mqh) in the experts/include directory
//
//  Include the line:
//
//     #include <LibOrderReliable.mqh>
//
//  ...in the beginning of your EA with the question marks replaced by the
//  actual version number (in file name) of the header file.
//
//  YOU MUST EDIT THE EA MANUALLY IN ORDER TO USE THIS LIBRARY, BY BOTH
//  SPECIFYING THE INCLUDE FILE AND THEN MODIFYING THE EA CODE TO USE
//  THE FUNCTIONS.
//
//  In particular you must change, in the EA, OrderSend() commands to
//  OrderSendReliable() and OrderModify() commands to OrderModifyReliable(),
//  or any others which are appropriate.
//
//=============================================================================
//
//  Partial Contents:
//
//		OrderSendReliable()
//			This is intended to be a drop-in replacement for OrderSend()
//			which, one hopes is more resistant to various forms of errors
//			prevalent with MetaTrader.
//
//		OrderSendReliableMKT()
//			This function is intended for immediate market-orders ONLY,
//			the principal difference that in its internal retry-loop,
//			it uses the new "Bid" and "Ask" real-time variables as opposed
//			to the OrderSendReliable() which uses only the price given upon
//			entry to the routine.  More likely to get off orders, and more
//			likely they are further from desired price.
//
//
//		OrderModifyReliable()
//			A replacement for OrderModify with more error handling.
//
//		OrderCloseReliable()
//			A replacement for OrderClose with more error handling.
//
//		OrderCloseReliableMKT()
//			This function is intended for closing orders ASAP; the
//			principal difference is that in its internal retry-loop,
//			it uses the new "Bid" and "Ask" real-time variables as opposed
//			to the OrderCloseReliable() which uses only the price given upon
//			entry to the routine.  More likely to get the order closed if
//          price moves, but more likely to "slip"
//
//		OrderDeleteReliable()
//			A replacement for OrderDelete with more error handling.
//
//      O_R_Config_Use2Step(bool twostep)
//          call with parameter set to true if you want to use 2-step
//          order handling, as is usually needed with ECN's.
//
//   GetLastErrorReliable()
//       Return the last error encountered by the LibOrderReliable subroutines
//===========================================================================

/*  Version 5.0
    Major rewrite to comply with #property strict and the 8xx-series compiler
*/

/*  New for Version 4.1

        * GetLastErrorReliable() is a replacement for GetLastError()

*/

/*
    New for version 4.0!

        * Some functions/variables renamed, everything except external begins with
          OrderReliable, or O_R_.  The latter is only because MT4
          has a stupid limit on maximum variable/function name lengths.

        * A single OrderSendReliable() will do 1 step or 2-step order sends,
          depending on a global configuration variable set with
          O_R_Config_Use2Step(bool twostep). Makes it easy to adapt any EA
          to ECN without much extra work.

        * VERY IMPORTANT! This library now checks that any recently opened
          order shows up in the OrderHistory!  There is a horrible bug/problem
          in MT4 whereby a recently sent order can fail to show up in the history
          for a few seconds, even though it exists according to ticket number.
          This means that some naive EA's which count open positions from history
          can send many multiple orders when they intended only one!  You can
          solve this problem by using this library.

*/


/*
            ADDITIONAL TIPS FOR RELIABLE EXPERT ADVISORS
            (Matthew Kennel, 7-31-06)

	*  *  *  *  *  *  *  *  *  *  *  *  *  *  *  *  *  *  *  *  *  *  *  *
	First bit of advice: In your metaeditor, open the options window
	(Tools -> Options).  By default you will see that the tab level is
	set to 3.  I'm not sure why those wacky Russians use 3-space tabs,
	but 4 is much more common.  I advise you set to 4, and also that you
	DISable the checkbox below ("Insert spaces").  Once you change to that,
	all this code will look much more readable, and so will the code that
	you write.
	*  *  *  *  *  *  *  *  *  *  *  *  *  *  *  *  *  *  *  *  *  *  *  *

	Here are some "good practices" which some people have found by experience
	to be a good idea for EA programming.

	The first thing to remember is that programming EA's, which work in
	an unreliable client-server environment, is not like ordinary software
	development.  In "regular" programming you can be pretty sure that
	operations will work as long as the computer is functioning.   This is
	not the case with transactions over the network, and you have to be
	quite careful and almost "paranoid" in the sense of checking for
	anything which might go wrong.  You must assume a possibility that all
	transactions might fail, and that much information may become unavailable,
	often transiently so. These failure modes will NOT be visible on a
	back-test, and are significantly more severe in a live "real-money"
	account than even real-time demo accounts.

	The problem is that many EA's use the existence of orders (or nonexistence
	thereof) as a trigger for additional events, like setting up additional
	trades, in same direction or not.   If you assume that trades will be
	successful, or otherwise instantly visible to OrderSelect(), for example,
	you may be in for a shock as this information may be unavailable during a
	trade, or during the interval the dealing desk is 'holding' the order.
	This may result in duplicate trades which shouldn't be there, in bad
	circumstances, a loop of a sequence of zillions of trades placed
	inappropriately.  If this is real money this could mean inappropriate
	risk to a catastrophe and the dealers will NOT bail you out as your
	bugs are your own problem.

	Other problem is that Metatrader is somewhat amateurish in its design,
	and a real "pro" level financial system would have transaction-oriented
	multiple-phase commits and event queues.  On the downside this would be
	significantly more difficult to program.

	Unfortunately if you want to use Metatrader EA's there is no real
	alternative to learning how to write software fairly well.  A little bit
	of knowledge and over-confidence (and a buggy EA) is a very quick way to
	go bankrupt.  If you have never or almost never written software before,
	please go learn on something which will not cost you money.

	Specific suggestions:

	*	Learn how to use the "MagicNumber" function in your EA's.  Remember
		that multiple EA's on the same symbol (perhaps even if different
		chart time frame's) will have ALL their orders visible to one another.
		This is not the case in back-testing.   Many EA's which work fine in
		backtesting will totally get fried when there are multiple EA's
		working at once. Hence, if you want to see if an order is "owned"
		by an EA---which is ESSENTIAL!!!---you must check the MagicNumber
		variable in addition to the OrderSymbol() to ensure it is one of
		"yours".

	*	Manage your existing orders with the *ticket number*, i.e. the value
		returned by OrderSend() (and OrderSendReliable()).   This has proven
		by people's experience to be more reliable, in terms of getting
		status of existing orders with OrderSelect(), i.e. SELECT_BY_TICKET.
		Sometimes people have found that orders have become invisible
		to SELECT_BY_POS for a short time, perhaps while the dealing desk has
		them, but remain visible to SELECT_BY_TICKET.  The ticket number is,
		by definition, the truly unique identifier of the order in the
		server's data base.  Use it.

	*	Often you may combine the use of ticket numbers and magic numbers.
		For instance, suppose you have potentially four different order kinds
		in your EA, two long orders (i.e. for scaling out), and two short
		orders. You would then define that each had a magic number *offset*
		from the magic number base.  E.g. you may have something like this:

			extern int MN = 123456;
			int Magic_long1, int Magic_long2, int Magic_short1, int Magic_short2
			int Ticket_long1, int Ticket_long2, int Ticket_short1, int Ticket_short2;

		and in the init() function:

			init()
			{
				Magic_long1 = MN;
				Magic_long2 = MN+1;
				Magic_short1 = MN+2;
				Magic_short2 = MN+3;
			}

		And then when you send the order you use the appropriate magic number---and
		you save the ticket value in the appropriate variable.  When you see if an
		order is owned by you then you have to check the range of magic numbers.

		Of course this can be generalized to arrays of each.

	*	Put the magic number in the "Comment" field so you can see it on the
		Metatrader terminal.  This way you can figure out what is what as magic
		numbers are not available in the user-interface. For example:

			string overall_comment = "My_EA_name"

			void foo()
			{
				yadda yadda
				int my_MN = MN + k;
				string cstr = overall_comment + " magic:"+my_mn;

				OrderSendReliable(  yadda yadda yadda,   my_MN, cstr,   yadda yadda )
			}


		If you are in a loop checking existing orders with an OrderSelect()
		and a SELECT_BY_POS,  if you delete an order or close an order, then
		all other entries may become invalid!  By deleting then you have
		totally changed the list, and you ought to start over with a new
		loop once you have executed one client-server transaction.  For
		instance the OrdersTotal() can change.

		Generally hence do loops with OrdersTotal() like this,

			int i;
			bool do_again = false;
			for (i = OrdersTotal()-1; !do_again && i >= 0; i--)
			{
				if (OrderSelect(i,SELECT_BY_POS,MODE_TRADES)
				{
					if (condition)
					{
						if {OrderDelete(OrderTicket())
							Print("Successful delete")
						else
							Print("Failed delete")
						do_again = true;
						break; // VERY IMPORTANT TO QUIT ENTIRE FOR LOOP IF ORDER IS DELETED
					}
					if (othercondition)
					{
						OrderCloseReliable( yadda yadda )
						do_again = true;
						break;
					}
				}
			}

		and if "do_again == true" then there is a possibility that more may yet
		remain in the list for processing so you ought to restart the loop over.
		One way to do that is to have something like a "DeleteOneOrder()" function
		which has that core loop, and returns the "do_again" variable.  And then
		the calling function will keep on calling it until do_again is false---
		and of course you will also have a maximum loop count in case something
		gets screwed up.

		Not good:

			for (i=0; i < OrdersTotal(); i++)
			{
				//
				// maybe delete an order in here
				//
			}

	*	Note also the error checking of the return value of OrderSelect().
		Most people forget to do that.  I am not sure what it means if
		an OrderSelect() fails, whether to continue or to abort.

	*	Put time-outs between the time you send an order, and you
		later query them to let it "settle".

	*	If you have a condition that you think specifies a new order, then
		ensure that it stays "OK" for a certain number of seconds/minutes.  You
		do this by saving in a static or global int variable, the "TimeCurrent()"
		when it last occurred (and setting that to zero if the condition is
		false) and then only if it has remained true until
		(TimeCurrent() - saved_time) >= some_interval of seconds.

	*	Try to query orders to check their status, using ticket numbers, if you
		have them before assuming they have executed.

	*	Orders can go from pending to active any time during the execution
		of your EA and you might not know it unless you check.

		*	Check to see that there are not an excessive number of 'open orders'
		'owned' by the EA, either active or pending.  THIS CAN BE A KEY
		SANITY CHECK WHICH PREVENTS A FINANCIAL MELTDOWN!!!

		And if there are, do not open more, there is probably
		a bug, and you do not want to send too many real-money orders.   Here
		you will probably do a SELECT_BY_POS and not SELECT_BY_TICKET because
		you have to account for the possibility that due to a bug (or restart
		of the EA!) you have "forgotten" some of the ticket numbers.

	*	Do not assume that in a real-money EA that a stop or take profit will actually
		be executed if the price has gone through that value.  Yes, they are
		unethical and mean.

	*	Assume that the EA could be stopped and restarted at any time due to
		external factors, like a power failure.  In other words, do not
		assume in the init() that there are no orders outstanding owned
		by the EA!!!     If your EA depends on this to be true, then
		check first, and if it isn't the case, put up a big Alert
		box or something and tell the human to delete them.

		Or, better, if you are able to 'pick up where you left off' then do so
		and write your EA with that possibility in mind.

	*	Write your EA's with a "SetNewOrders" type of boolean variable
		which, if false, means that the EA will not set new orders, but
		will continue to manage open orders and close them.  This variable
		may be changed "in flight" by the user to allow him to
		'safely' go flat.

	*	Use global variables---i.e. the ones you set with GlobalVariableSet()
		as these can stay persistent over restarts of the trading station,
		and maybe even upgrades of the Metatrader software version.
		Here you may want to store ticket numbers or other vital information
		to enable a "warm restart" of the strategy after an EA is stopped
		or started.

	*	In a more advanced usage, you can approximate some kinds of
		"semaphores" and lock-outs which are the computer-science
		ways of dealing with the multithreading problems.
		See GlobalVariableSetOnCondition() documentation.

		This OrderReliable library may preclude the need for *some* of that
		but don't necessarily count on it.


*/
//===========================================================================

#include <stdlib.mqh>
#include <stderror.mqh>

string 	OrderReliableVersion       = "v5.0";
string 	OrderReliable_Fname        = "OrderReliable fname unset";

int 	   O_R_Setting_max_retries 	= 10;
double 	O_R_Setting_sleep_time     = 4.0;   /* seconds */
double 	O_R_Setting_sleep_max 	   = 15.0;  /* seconds */

int 	   O_R_ErrorLevel 			   = 3;
int      O_R_LastErr                = 0;     // save last error

bool     O_R_Setting_use2step       = true ; /* use 2 step orders for ECN? */
bool	   O_R_Setting_limit2market 	= false;
bool	   O_R_Setting_UseForTesting 	= false;


//=============================================================================
//							 OrderSendReliable()
//
//  This is intended to be a drop-in replacement for OrderSend() which,
//  one hopes, is more resistant to various forms of errors prevalent
//  with MetaTrader.
//
//	RETURN VALUE:
//     Ticket number or -1 under some error conditions.
//
//  FEATURES:
//     * Re-trying under some error conditions, sleeping a random
//       time defined by an exponential probability distribution.
//
//     * Automatic normalization of Digits
//
//     * Automatically makes sure that stop levels are more than
//       the minimum stop distance, as given by the server. If they
//       are too close, they are adjusted.
//
//     * Automatically converts stop orders to market orders
//       when the stop orders are rejected by the server for
//       being to close to market.  NOTE: This intentionally
//       applies only to OP_BUYSTOP and OP_SELLSTOP,
//       OP_BUYLIMIT and OP_SELLLIMIT are not converted to market
//       orders and so for prices which are too close to current
//       this function is likely to loop a few times and return
//       with the "invalid stops" error message.
//       Note, the commentary in previous versions erroneously said
//       that limit orders would be converted.  Note also
//       that entering a BUYSTOP or SELLSTOP new order is distinct
//       from setting a stoploss on an outstanding order; use
//       OrderModifyReliable() for that.
//
//     * Displays various error messages on the log for debugging.
//
//  ORIGINAL AUTHOR AND DATE:
//     Matt Kennel, 2006-05-28
//
//=============================================================================
int OrderSendReliable(string symbol, int cmd, double volume, double price,
                      int slippage, double stoploss, double takeprofit,
                      string comment, int magic, datetime expiration = 0,
                      color arrow_color = CLR_NONE) {
   if (O_R_Setting_use2step) {
      return(OrderSendReliable2Step(symbol,cmd,volume,price,slippage,stoploss,takeprofit,
                                    comment,magic,expiration,arrow_color));

   } else {
      return(OrderSendReliable1Step(symbol,cmd,volume,price,slippage,stoploss,takeprofit,
                                    comment,magic,expiration,arrow_color));
   }

}

int OrderSendReliableMKT(string symbol, int cmd, double volume, double price,
                         int slippage, double stoploss, double takeprofit,
                         string comment, int magic, datetime expiration = 0,
                         color arrow_color = CLR_NONE) {
   if (O_R_Setting_use2step) {
      return(OrderSendReliableMKT2Step(symbol,cmd,volume,price,slippage,stoploss,takeprofit,
                                       comment,magic,expiration,arrow_color));

   } else {
      return(OrderSendReliableMKT1Step(symbol,cmd,volume,price,slippage,stoploss,takeprofit,
                                       comment,magic,expiration,arrow_color));
   }

}



int OrderSendReliable1Step(string symbol, int cmd, double volume, double price,
                           int slippage, double stoploss, double takeprofit,
                           string comment, int magic, datetime expiration = 0,
                           color arrow_color = CLR_NONE) {
   int ticket = -1;
   // ========================================================================
   // If testing or optimizing, there is no need to use this lib, as the
   // orders are not real-world, and always get placed optimally.  By
   // refactoring this option to be in this library, one no longer needs
   // to create similar code in each EA.
   if (!O_R_Setting_UseForTesting) {
      if (IsOptimization()  ||  IsTesting()) {
         O_R_EnsureValidStops( symbol,  cmd,  price, stoploss, takeprofit, true);

         ticket = OrderSend(symbol, cmd, volume, price, slippage, stoploss,
                            takeprofit, comment, magic, expiration, arrow_color);
         return(ticket);
      }
   }
   // ========================================================================

   OrderReliable_Fname = "OrderSendReliable";
   OrderReliablePrint("•  •  •  •  •  •  •  •  •  •  •  •  •  •  •  •  •  •  •  •  •  •  •  •  •  •  •  •  •  •  •  •  •  •  •  •  •  •  •  •  •  •  •");
   OrderReliablePrint(StringFormat( "Attempted %s %5.2f lots @ %5.5f + sl: %5.5f, tp: %5.5f",OrderType2String(cmd), volume, price, stoploss, takeprofit ) );

   // - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
   // Get information about this order
   double realPoint = MarketInfo(symbol, MODE_POINT);
   int digits;
   double point;
   double bid, ask;
   double sl, tp;
   O_R_GetOrderDetails(0, symbol, cmd, digits, point, sl, tp, bid, ask, false);
   // - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -


   // Normalize all price / stoploss / takeprofit to the proper # of digits.
   price = NormalizeDouble(price, digits);
   stoploss = NormalizeDouble(stoploss, digits);
   takeprofit = NormalizeDouble(takeprofit, digits);

   // Check stop levels, adjust if necessary
   O_R_EnsureValidStops(symbol, cmd, price, stoploss, takeprofit);

   int cnt;
   int err = GetLastError(); // clear the global variable.
   err = 0;
   bool exit_loop = false;
   bool limit_to_market = false;

   // limit/stop order.
   bool fixed_invalid_price = false;
   if (cmd == OP_BUYSTOP  ||  cmd == OP_SELLSTOP  ||  cmd == OP_BUYLIMIT  ||  cmd == OP_SELLLIMIT) {
      cnt = 0;
      while (!exit_loop) {
         int maxTries = 100;
         while( !IsTradeAllowed() && (maxTries > 0) ) {
            Sleep(10);
            maxTries--;
         }
         if (maxTries > 0) {
            ticket = OrderSend(symbol, cmd, volume, price, slippage, stoploss,
                               takeprofit, comment, magic, expiration, arrow_color);
            err = GetLastError();
         }
         else {
            err = ERR_TRADE_CONTEXT_BUSY;
         }

         switch (err) {
         case ERR_NO_ERROR:
            exit_loop = true;
            break;

         // retryable errors
         case ERR_SERVER_BUSY:
         case ERR_NO_CONNECTION:
         case ERR_OFF_QUOTES:
         case ERR_BROKER_BUSY:
         case ERR_TRADE_CONTEXT_BUSY:
         case ERR_TRADE_TIMEOUT:
            cnt++;
            break;

         case ERR_PRICE_CHANGED:
         case ERR_REQUOTE:
            RefreshRates();
            continue;	// we can apparently retry immediately according to MT docs.

         case ERR_INVALID_PRICE:
         case ERR_INVALID_STOPS: {
            cnt++;
            double servers_min_stop = MarketInfo(symbol, MODE_STOPLEVEL) * realPoint;
            double old_price;
            if (cmd == OP_BUYSTOP || cmd == OP_BUYLIMIT) {
               // If we are too close to put in a limit/stop order so go to market.
               if (MathAbs(ask - price) <= servers_min_stop) {
                  if (O_R_Setting_limit2market) {
                     limit_to_market = true;
                     exit_loop = true;
                  } else {
                     if (fixed_invalid_price) {
                        if (cmd == OP_BUYSTOP) {
                           price += point;
                           if (stoploss > 0) {
                              stoploss += point;
                           }
                           if (takeprofit > 0) {
                              takeprofit += point;
                           }
                           OrderReliablePrint(StringFormat("Pending BuyStop Order still has ERR_INVALID_STOPS, adding 1 pip; new price = %5.5f",price));
                           if (stoploss > 0  ||  takeprofit > 0) {
                              OrderReliablePrint(StringFormat("NOTE: SL (now %5.5f) & TP (now %5.5f) were adjusted proportionately",stoploss,takeprofit));
                           }
                        } else if (cmd == OP_BUYLIMIT) {
                           price -= point;
                           if (stoploss > 0) {
                              stoploss -= point;
                           }
                           if (takeprofit > 0) {
                              takeprofit -= point;
                           }
                           OrderReliablePrint(StringFormat("Pending BuyLimit Order still has ERR_INVALID_STOPS, subtracting 1 pip; new price = %5.5f",price));
                           if (stoploss > 0  ||  takeprofit > 0) {
                              OrderReliablePrint(StringFormat("NOTE: SL (now %5.5f) & TP (now %5.5f) were adjusted proportionately",stoploss,takeprofit));
                           }
                        }
                     } else {
                        if (cmd == OP_BUYLIMIT) {
                           old_price = price;
                           price = ask - servers_min_stop;
                           if (stoploss > 0) {
                              stoploss += (price - old_price);
                           }
                           if (takeprofit > 0) {
                              takeprofit += (price - old_price);
                           }
                           OrderReliablePrint(StringFormat("Pending BuyLimit has ERR_INVALID_STOPS; new price = %5.5f",price));
                           if (stoploss > 0  ||  takeprofit > 0) {
                              OrderReliablePrint(StringFormat("NOTE: SL (now %5.5f) & TP (now %5.5f) were adjusted proportionately",stoploss,takeprofit));
                           }
                        } else if (cmd == OP_BUYSTOP) {
                           old_price = price;
                           price = ask + servers_min_stop;
                           if (stoploss > 0) {
                              stoploss += (price - old_price);
                           }
                           if (takeprofit > 0) {
                              takeprofit += (price - old_price);
                           }
                           OrderReliablePrint(StringFormat("Pending BuyStop has ERR_INVALID_STOPS; new price = %5.5f",price));
                           if (stoploss > 0  ||  takeprofit > 0) {
                              OrderReliablePrint(StringFormat("NOTE: SL (now %5.5f) & TP (now %5.5f) were adjusted proportionately",stoploss,takeprofit));
                           }
                        }
                        fixed_invalid_price = true;
                     }
                     O_R_EnsureValidStops(symbol, cmd, price, stoploss, takeprofit);
                  }
               }
            } else if (cmd == OP_SELLSTOP || cmd == OP_SELLLIMIT) {
               // If we are too close to put in a limit/stop order so go to market.
               if (MathAbs(bid - price) <= servers_min_stop) {
                  if (O_R_Setting_limit2market) {
                     limit_to_market = true;
                     exit_loop = true;
                  } else {
                     if (fixed_invalid_price) {
                        if (cmd == OP_SELLSTOP) {
                           price -= point;
                           if (stoploss > 0) {
                              stoploss -= point;
                           }
                           if (takeprofit > 0) {
                              takeprofit -= point;
                           }
                           OrderReliablePrint(StringFormat("Pending SellStop Order still has ERR_INVALID_STOPS, subtracting 1 pip; new price = %5.5f",price));
                           if (stoploss > 0  ||  takeprofit > 0) {
                              OrderReliablePrint(StringFormat("NOTE: SL (now %5.5f) & TP (now %5.5f) were adjusted proportionately",stoploss,takeprofit));
                           }
                        } else if (cmd == OP_SELLLIMIT) {
                           price += point;
                           if (stoploss > 0) {
                              stoploss += point;
                           }
                           if (takeprofit > 0) {
                              takeprofit += point;
                           }
                           OrderReliablePrint(StringFormat("Pending SellLimit Order still has ERR_INVALID_STOPS, adding 1 pip; new price = %5.5f",price));
                           if (stoploss > 0  ||  takeprofit > 0) {
                              OrderReliablePrint(StringFormat("NOTE: SL (now %5.5f) & TP (now %5.5f) were adjusted proportionately",stoploss,takeprofit));
                           }
                        }
                     } else {
                        if (cmd == OP_SELLSTOP) {
                           old_price = price;
                           price = bid - servers_min_stop;
                           if (stoploss > 0) {
                              stoploss -= (old_price - price);
                           }
                           if (takeprofit > 0) {
                              takeprofit -= (old_price - price);
                           }
                           OrderReliablePrint(StringFormat("Pending SellStop has ERR_INVALID_STOPS; new price = %5.5f",price));
                           if (stoploss > 0  ||  takeprofit > 0) {
                              OrderReliablePrint(StringFormat("NOTE: SL (now %5.5f) & TP (now %5.5f) were adjusted proportionately",stoploss,takeprofit));
                           }
                        } else if (cmd == OP_SELLLIMIT) {
                           old_price = price;
                           price = bid + servers_min_stop;
                           if (stoploss > 0) {
                              stoploss -= (old_price - price);
                           }
                           if (takeprofit > 0) {
                              takeprofit -= (old_price - price);
                           }
                           OrderReliablePrint(StringFormat("Pending SellLimit has ERR_INVALID_STOPS; new price = %5.5f",price));
                           if (stoploss > 0  ||  takeprofit > 0) {
                              OrderReliablePrint(StringFormat("NOTE: SL (now %5.5f) & TP (now %5.5f) were adjusted proportionately",stoploss,takeprofit));
                           }
                        }
                        fixed_invalid_price = true;
                     }
                     O_R_EnsureValidStops(symbol, cmd, price, stoploss, takeprofit);
                  }
               }
            }
            break;
         }
         case ERR_INVALID_TRADE_PARAMETERS:
         default:
            // an apparently serious error.
            exit_loop = true;
            break;

         }  // end switch

         if (cnt > O_R_Setting_max_retries) {
            exit_loop = true;
         }

         if (exit_loop) {
            if (err != ERR_NO_ERROR  &&  err != ERR_NO_RESULT) {
               OrderReliablePrint("Non-retryable error: " + OrderReliableErrTxt(err));
            }
            if (cnt > O_R_Setting_max_retries) {
               OrderReliablePrint(StringFormat("Retry attempts maxed at %d", O_R_Setting_max_retries));
            }
         } else {
            OrderReliablePrint(StringFormat("Result of attempt %d of %d: Retryable error: %s", cnt, O_R_Setting_max_retries,OrderReliableErrTxt(err) ) );
            OrderReliablePrint("~  ~  ~  ~  ~  ~  ~  ~  ~  ~  ~  ~  ~  ~  ~  ~  ~  ~  ~  ~  ~  ~  ~  ~  ~  ~  ~  ~  ~  ~  ~  ~  ~  ~  ~");
            O_R_Sleep(O_R_Setting_sleep_time, O_R_Setting_sleep_max);
            RefreshRates();
         }
      }
      O_R_LastErr = err;


      // We have now exited from loop.
      if (err == ERR_NO_ERROR  ||  err == ERR_NO_RESULT) {
         OrderReliablePrint(StringFormat("Ticket #%d: Successful %s order placed, details follow.",ticket, OrderType2String(cmd)));
         if (OrderSelect(ticket, SELECT_BY_TICKET, MODE_TRADES)) {
            OrderPrint();
         }
         OrderReliablePrint("•  •  •  •  •  •  •  •  •  •  •  •  •  •  •  •  •  •  •  •  •  •  •  •  •  •  •  •  •  •  •  •  •  •  •  •  •  •  •  •  •  •  •");
         O_R_CheckForHistory(ticket);
         return(ticket); // SUCCESS!
      }
      if (!limit_to_market) {
         OrderReliablePrint(StringFormat("Failed to execute stop or limit order after %d retries.", O_R_Setting_max_retries));
         OrderReliablePrint(StringFormat("Failed trade: %s %5.2f lots %s @ %5.5f, tp@:%5.5f, sl@%5.5f",OrderType2String(cmd),volume,symbol,price,takeprofit,stoploss));
         OrderReliablePrint("Last error: " + OrderReliableErrTxt(err));
         OrderReliablePrint("•  •  •  •  •  •  •  •  •  •  •  •  •  •  •  •  •  •  •  •  •  •  •  •  •  •  •  •  •  •  •  •  •  •  •  •  •  •  •  •  •  •  •");
         return(-1);
      }
   }  // end

   if (limit_to_market) {
      OrderReliablePrint("Going from stop/limit order to market order because market is too close.");
      if ((cmd == OP_BUYSTOP) || (cmd == OP_BUYLIMIT)) {
         cmd = OP_BUY;
         price = ask;
      } else if ((cmd == OP_SELLSTOP) || (cmd == OP_SELLLIMIT)) {
         cmd = OP_SELL;
         price = bid;
      }
   }

   // we now have a market order.
   err = GetLastError(); // so we clear the global variable.
   err = 0;
   ticket = -1;
   exit_loop = false;

   if ((cmd == OP_BUY) || (cmd == OP_SELL)) {
      cnt = 0;
      while (!exit_loop) {
         int maxTries = 100;
         while( !IsTradeAllowed() && (maxTries > 0) ) {
            Sleep(10);
            maxTries--;
         }
         if (maxTries > 0) {
            ticket = OrderSend(symbol, cmd, volume, price, slippage,
                               stoploss, takeprofit, comment, magic,
                               expiration, arrow_color);
            err = GetLastError();
         }
         else {
            err = ERR_TRADE_CONTEXT_BUSY;
         }

         switch (err) {
         case ERR_NO_ERROR:
            exit_loop = true;
            break;

         case ERR_SERVER_BUSY:
         case ERR_NO_CONNECTION:
         case ERR_INVALID_PRICE:
         case ERR_OFF_QUOTES:
         case ERR_BROKER_BUSY:
         case ERR_TRADE_CONTEXT_BUSY:
         case ERR_TRADE_TIMEOUT:
            cnt++; // a retryable error
            break;

         case ERR_PRICE_CHANGED:
         case ERR_REQUOTE:
            RefreshRates();
            continue; // we can apparently retry immediately according to MT docs.

         default:
            // an apparently serious, unretryable error.
            exit_loop = true;
            break;
         }

         if (cnt > O_R_Setting_max_retries) {
            exit_loop = true;
         }

         if (!exit_loop) {
            OrderReliablePrint(StringFormat("Result of attempt %d of %d: Retryable error: %s", cnt, O_R_Setting_max_retries,OrderReliableErrTxt(err) ) );
            OrderReliablePrint("~  ~  ~  ~  ~  ~  ~  ~  ~  ~  ~  ~  ~  ~  ~  ~  ~  ~  ~  ~  ~  ~  ~  ~  ~  ~  ~  ~  ~  ~  ~  ~  ~  ~  ~");
            O_R_Sleep(O_R_Setting_sleep_time, O_R_Setting_sleep_max);
            RefreshRates();
         } else {
            if (err != ERR_NO_ERROR  &&  err != ERR_NO_RESULT) {
               OrderReliablePrint("Non-retryable error: " + OrderReliableErrTxt(err));
            }
            if (cnt > O_R_Setting_max_retries) {
               OrderReliablePrint(StringFormat("Retry attempts maxed at %d", O_R_Setting_max_retries));
            }
         }
      }
      O_R_LastErr = err;

      // we have now exited from loop.
      if (err == ERR_NO_ERROR  ||  err == ERR_NO_RESULT) {
         OrderReliablePrint(StringFormat("Ticket #%d: Successful %s order placed, details follow.",ticket, OrderType2String(cmd)));
         if ( OrderSelect(ticket, SELECT_BY_TICKET, MODE_TRADES) ) OrderPrint();
         OrderReliablePrint("•  •  •  •  •  •  •  •  •  •  •  •  •  •  •  •  •  •  •  •  •  •  •  •  •  •  •  •  •  •  •  •  •  •  •  •  •  •  •  •  •  •  •");
         O_R_CheckForHistory(ticket);
         return(ticket); // SUCCESS!
      }
      OrderReliablePrint(StringFormat("Failed to execute OP_BUY/OP_SELL, after %d retries", + O_R_Setting_max_retries));
      OrderReliablePrint(StringFormat("Failed trade: %s %5.2f lots %s @%5.5f, tp@:%5.5f, sl@%5.5f",OrderType2String(cmd),volume,symbol,price,takeprofit,stoploss));
      OrderReliablePrint("Last error: " + OrderReliableErrTxt(err));
      OrderReliablePrint("•  •  •  •  •  •  •  •  •  •  •  •  •  •  •  •  •  •  •  •  •  •  •  •  •  •  •  •  •  •  •  •  •  •  •  •  •  •  •  •  •  •  •");
      return(-1);
   }
   return(-1);
}


//=============================================================================
//							 OrderSendReliableMKT()
//
//  This is intended to be an alternative for OrderSendReliable() which
//  will update market-orders in the retry loop with the current Bid or Ask.
//  Hence with market orders there is a greater likelihood that the trade will
//  be executed versus OrderSendReliable(), and a greater likelihood it will
//  be executed at a price worse than the entry price due to price movement.
//
//  RETURN VALUE:
//     Ticket number or -1 under some error conditions.  Check
//     final error returned by Metatrader with OrderReliableLastErr().
//     This will reset the value from GetLastError(), so in that sense it cannot
//     be a total drop-in replacement due to Metatrader flaw.
//
//  FEATURES:
//     * Most features of OrderSendReliable() but for market orders only.
//       Command must be OP_BUY or OP_SELL, and specify Bid or Ask at
//       the time of the call.
//
//     * If price moves in an unfavorable direction during the loop,
//       e.g. from requotes, then the slippage variable it uses in
//       the real attempt to the server will be decremented from the passed
//       value by that amount, down to a minimum of zero.   If the current
//       price is too far from the entry value minus slippage then it
//       will not attempt an order, and it will signal, manually,
//       an ERR_INVALID_PRICE (displayed to log as usual) and will continue
//       to loop the usual number of times.
//
//     * Displays various error messages on the log for debugging.
//
//  ORIGINAL AUTHOR AND DATE:
//	   Matt Kennel, 2006-08-16
//
//=============================================================================
int OrderSendReliableMKT1Step(string symbol, int cmd, double volume, double price,
                              int slippage, double stoploss, double takeprofit,
                              string comment, int magic, datetime expiration = 0,
                              color arrow_color = CLR_NONE) {
   int ticket = -1;
   // ========================================================================
   // If testing or optimizing, there is no need to use this lib, as the
   // orders are not real-world, and always get placed optimally.  By
   // refactoring this option to be in this library, one no longer needs
   // to create similar code in each EA.
   if (!O_R_Setting_UseForTesting) {
      if (IsOptimization()  ||  IsTesting()) {
         ticket = OrderSend(symbol, cmd, volume, price, slippage, stoploss,
                            takeprofit, comment, magic, expiration, arrow_color);
         return(ticket);
      }
   }
   // ========================================================================

   // Cannot use this function for pending orders
   if (cmd > OP_SELL) {
      ticket = OrderSendReliable(symbol, cmd, volume, price, slippage, 0, 0,
                                 comment, magic, expiration, arrow_color);
      return(ticket);
   }

   OrderReliable_Fname = "OrderSendReliableMKT";
   OrderReliablePrint("•  •  •  •  •  •  •  •  •  •  •  •  •  •  •  •  •  •  •  •  •  •  •  •  •  •  •  •  •  •  •  •  •  •  •  •  •  •  •  •  •  •  •");
   OrderReliablePrint(StringFormat("Attempted %s %5.2f lots @%5.5f, sl:%5.5f, tp:%5.5f", OrderType2String(cmd),volume,price,stoploss,takeprofit));

   // - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
   // Get information about this order
   int digits;
   double point;
   double bid, ask;
   double sl, tp;
   O_R_GetOrderDetails(0, symbol, cmd, digits, point, sl, tp, bid, ask, false);
   // - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

   price = NormalizeDouble(price, digits);
   stoploss = NormalizeDouble(stoploss, digits);
   takeprofit = NormalizeDouble(takeprofit, digits);
   O_R_EnsureValidStops(symbol, cmd, price, stoploss, takeprofit);

   int cnt;
   int err = GetLastError(); // clear the global variable.
   err = 0;
   bool exit_loop = false;

   if ((cmd == OP_BUY) || (cmd == OP_SELL)) {
      cnt = 0;
      while (!exit_loop) {
         double pnow = price;
         int slippagenow = slippage;
         if (cmd == OP_BUY) {
            // modification by Paul Hampton-Smith to replace RefreshRates()
            pnow = NormalizeDouble(MarketInfo(symbol, MODE_ASK), (int)MarketInfo(symbol, MODE_DIGITS)); // we are buying at Ask
            if (pnow > price) {
               slippagenow = slippage - (int)MathCeil((pnow - price) / point);
            }
         } else if (cmd == OP_SELL) {
            // modification by Paul Hampton-Smith to replace RefreshRates()
            pnow = NormalizeDouble(MarketInfo(symbol, MODE_BID), (int)MarketInfo(symbol, MODE_DIGITS)); // we are buying at Ask
            if (pnow < price) {
               // moved in an unfavorable direction
               slippagenow = slippage - (int)MathCeil((pnow - price) / point);
            }
         }
         if (slippagenow > slippage) {
            slippagenow = slippage;
         }
         if (slippagenow >= 0) {

            int maxTries = 100;
            while( !IsTradeAllowed() && (maxTries > 0) ) {
               Sleep(10);
               maxTries--;
            }
            if (maxTries > 0) {
               ticket = OrderSend(symbol, cmd, volume, pnow, slippagenow,
                                  stoploss, takeprofit, comment, magic,
                                  expiration, arrow_color);
               err = GetLastError();
            }
            else {
               err = ERR_TRADE_CONTEXT_BUSY;
            }
         } else {
            // too far away, manually signal ERR_INVALID_PRICE, which
            // will result in a sleep and a retry.
            err = ERR_INVALID_PRICE;
         }

         switch (err) {
         case ERR_NO_ERROR:
            exit_loop = true;
            break;

         case ERR_SERVER_BUSY:
         case ERR_NO_CONNECTION:
         case ERR_INVALID_PRICE:
         case ERR_OFF_QUOTES:
         case ERR_BROKER_BUSY:
         case ERR_TRADE_CONTEXT_BUSY:
         case ERR_TRADE_TIMEOUT:
            cnt++; // a retryable error
            break;

         case ERR_PRICE_CHANGED:
         case ERR_REQUOTE:
            // Paul Hampton-Smith removed RefreshRates() here and used MarketInfo() above instead
            continue; // we can apparently retry immediately according to MT docs.

         default:
            // an apparently serious, unretryable error.
            exit_loop = true;
            break;

         }  // end switch

         if (cnt > O_R_Setting_max_retries) {
            exit_loop = true;
         }

         if (!exit_loop) {
            OrderReliablePrint(StringFormat("Result of attempt %d of %d: Retryable error: %s", cnt, O_R_Setting_max_retries,OrderReliableErrTxt(err) ) );
            OrderReliablePrint("~  ~  ~  ~  ~  ~  ~  ~  ~  ~  ~  ~  ~  ~  ~  ~  ~  ~  ~  ~  ~  ~  ~  ~  ~  ~  ~  ~  ~  ~  ~  ~  ~  ~  ~");
            O_R_Sleep(O_R_Setting_sleep_time, O_R_Setting_sleep_max);
         } else {
            if (err != ERR_NO_ERROR  &&  err != ERR_NO_RESULT) {
               OrderReliablePrint("Non-retryable error: " + OrderReliableErrTxt(err));
            }
            if (cnt > O_R_Setting_max_retries) {
               OrderReliablePrint(StringFormat("Retry attempts maxed at %d",O_R_Setting_max_retries));
            }
         }
      }
      O_R_LastErr = err;

      // we have now exited from loop.
      if (err == ERR_NO_ERROR  ||  err == ERR_NO_RESULT) {
         OrderReliablePrint(StringFormat("Ticket #%d: Successful %s order placed, details follow.",ticket, OrderType2String(cmd)));
         if (OrderSelect(ticket, SELECT_BY_TICKET, MODE_TRADES)) OrderPrint();
         OrderReliablePrint("•  •  •  •  •  •  •  •  •  •  •  •  •  •  •  •  •  •  •  •  •  •  •  •  •  •  •  •  •  •  •  •  •  •  •  •  •  •  •  •  •  •  •");
         O_R_CheckForHistory(ticket);
         return(ticket); // SUCCESS!
      }
      OrderReliablePrint(StringFormat("Failed to execute OP_BUY/OP_SELL, after %d retries",O_R_Setting_max_retries));
      OrderReliablePrint(StringFormat("Failed trade: %s %5.2f lots %s @%5.5f, tp@:%5.5f, sl@%5.5f",OrderType2String(cmd),volume,symbol,price,takeprofit,stoploss));
      OrderReliablePrint("Last error: " + OrderReliableErrTxt(err));
      OrderReliablePrint("•  •  •  •  •  •  •  •  •  •  •  •  •  •  •  •  •  •  •  •  •  •  •  •  •  •  •  •  •  •  •  •  •  •  •  •  •  •  •  •  •  •  •");
      return(-1);
   }
   return(-1);
}


//=============================================================================
//							 OrderSendReliable2Step()
//
//  Some brokers don't allow the SL and TP settings as part of the initial
//  market order (Water House Capital).  Therefore, this routine will first
//  place the market order with no stop-loss and take-profit but later
//  update the order accordingly
//
//	RETURN VALUE:
//     Same as OrderSendReliable; the ticket number
//
//  NOTES:
//     Order will not be updated if an error continues during
//     OrderSendReliableMKT.  No additional information will be logged
//     since OrderSendReliableMKT would have already logged the error
//     condition
//
//  ORIGINAL AUTHOR AND DATE:
//     Jack Tomlinson, 2007-05-29
//
//=============================================================================
int OrderSendReliable2Step(string symbol, int cmd, double volume, double price,
                           int slippage, double stoploss, double takeprofit,
                           string comment, int magic, datetime expiration = 0,
                           color arrow_color = CLR_NONE) {
   int ticket = -1;
   // ========================================================================
   // If testing or optimizing, there is no need to use this lib, as the
   // orders are not real-world, and always get placed optimally.  By
   // refactoring this option to be in this library, one no longer needs
   // to create similar code in each EA.
   if (!O_R_Setting_UseForTesting) {
      if (IsOptimization()  ||  IsTesting()) {
         ticket = OrderSend(symbol, cmd, volume, price, slippage, 0, 0, comment, magic, expiration, arrow_color);

         if (ticket > 0) {
            if (OrderModify(ticket, 0, stoploss, takeprofit, 0, arrow_color) ) return(ticket);
         }
         return(-1);
      }
   }
   // ========================================================================

   OrderReliable_Fname = "OrderSendReliable2Step";
   OrderReliablePrint("");
   OrderReliablePrint("Doing OrderSendReliable, followed by OrderModifyReliable:");

   ticket = OrderSendReliable1Step(symbol, cmd, volume, price, slippage, 0, 0, comment, magic, expiration, arrow_color);

   if (stoploss != 0 || takeprofit != 0) {
      if (ticket >= 0) {
         OrderModifyReliable(ticket, price,	stoploss, takeprofit, 0, arrow_color);
      }
   } else {
      OrderReliablePrint("Skipping OrderModifyReliable because no SL or TP specified.");
   }

   return(ticket);
}

//=============================================================================
//							 OrderSendReliableMKT2Step()
//
//  Some brokers don't allow the SL and TP settings as part of the initial
//  market order (Water House Capital).  Therefore, this routine will first
//  place the market order with no stop-loss and take-profit but later
//  update the order accordingly
//
//	RETURN VALUE:
//     Same as OrderSendReliable; the ticket number
//
//=============================================================================
int OrderSendReliableMKT2Step(string symbol, int cmd, double volume, double price,
                              int slippage, double stoploss, double takeprofit,
                              string comment, int magic, datetime expiration = 0,
                              color arrow_color = CLR_NONE) {
   int ticket = -1;
   // ========================================================================
   // If testing or optimizing, there is no need to use this lib, as the
   // orders are not real-world, and always get placed optimally.  By
   // refactoring this option to be in this library, one no longer needs
   // to create similar code in each EA.
   if (!O_R_Setting_UseForTesting) {
      if (IsOptimization()  ||  IsTesting()) {
         ticket = OrderSend(symbol, cmd, volume, price, slippage, 0, 0, comment, magic, expiration, arrow_color);

         if (ticket > 0) {
            if (OrderModify(ticket, 0, stoploss, takeprofit, 0, arrow_color) ) return(ticket);
         }
         return(-1);
      }
   }
   // ========================================================================

   OrderReliable_Fname = "OrderSendReliable2Step";
   OrderReliablePrint("");
   OrderReliablePrint("Doing OrderSendReliable, followed by OrderModifyReliable:");

   ticket = OrderSendReliableMKT1Step(symbol, cmd, volume, price, slippage,
                                      0, 0, comment, magic, expiration, arrow_color);

   if (stoploss != 0 || takeprofit != 0) {
      if (ticket >= 0) {
         OrderModifyReliable(ticket, price,	stoploss, takeprofit, 0, arrow_color);
      }
   } else {
      OrderReliablePrint("Skipping OrderModifyReliable because no SL or TP specified.");
   }

   return(ticket);
}


//=============================================================================
//							 OrderModifyReliable()
//
//  This is intended to be a drop-in replacement for OrderModify() which,
//  one hopes, is more resistant to various forms of errors prevalent
//  with MetaTrader.
//
//  RETURN VALUE:
//     TRUE if successful, FALSE otherwise
//
//  FEATURES:
//     * Re-trying under some error conditions, sleeping a random
//       time defined by an exponential probability distribution.
//
//     * Displays various error messages on the log for debugging.
//
//
//  ORIGINAL AUTHOR AND DATE:
//     Matt Kennel, 2006-05-28
//
//=============================================================================
bool OrderModifyReliable(int ticket, double price, double stoploss,
                         double takeprofit, datetime expiration,
                         color arrow_color = CLR_NONE) {
   bool result = false;
   bool non_retryable_error = false;

   // ========================================================================
   // If testing or optimizing, there is no need to use this lib, as the
   // orders are not real-world, and always get placed optimally.  By
   // refactoring this option to be in this library, one no longer needs
   // to create similar code in each EA.
   if (!O_R_Setting_UseForTesting) {
      if (IsOptimization()  ||  IsTesting()) {
         result = OrderModify(ticket, price, stoploss,
                              takeprofit, expiration, arrow_color);
         return(result);
      }
   }
   // ========================================================================

   OrderReliable_Fname = "OrderModifyReliable";
   OrderReliablePrint("•  •  •  •  •  •  •  •  •  •  •  •  •  •  •  •  •  •  •  •  •  •  •  •  •  •  •  •  •  •  •  •  •  •  •  •  •  •  •  •  •  •  •");
   OrderReliablePrint(StringFormat("Attempted modify of #%d price %5.5f, sl:%5.5f, tp:%5.5f",ticket,price,stoploss,takeprofit));

   // - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
   // Get information about this order
   string symbol = "ALLOCATE";		// This is so it has memory space allocated
   int type;
   int digits;
   double point;
   double bid, ask;
   double sl, tp;
   O_R_GetOrderDetails(ticket, symbol, type, digits, point, sl, tp, bid, ask);
   // - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

   // Below, we call "O_R_EnsureValidStops".  If the order we are modifying
   // is a pending order, then we should use the price passed in.  But
   // if it's an open order, the price passed in is irrelevant; we need
   // to use the appropriate bid or ask, so get those...
   double prc = price;
   if (type == OP_BUY) {
      prc = bid;
   } else if (type == OP_SELL)	{
      prc = ask;
   }

   // With the requisite info, we can do error checking on SL & TP
   prc = NormalizeDouble(prc, digits);
   price = NormalizeDouble(price, digits);
   stoploss = NormalizeDouble(stoploss, digits);
   takeprofit = NormalizeDouble(takeprofit, digits);

   // If SL/TP are not changing then send in zeroes to O_R_EnsureValidStops(),
   // so that it does not bother to try to change them
   double newSL = stoploss;
   double newTP = takeprofit;
   if (stoploss == sl) {
      newSL = 0;
   }
   if (takeprofit == tp)	{
      newTP = 0;
   }
   O_R_EnsureValidStops(symbol, type, prc, newSL, newTP, false);
   if (stoploss != sl) {
      stoploss = newSL;
   }
   if (takeprofit != tp)	{
      takeprofit = newTP;
   }


   int cnt = 0;
   int err = GetLastError(); // so we clear the global variable.
   err = 0;
   bool exit_loop = false;

   while (!exit_loop) {
      result = OrderModify(ticket, price, stoploss,
                           takeprofit, expiration, arrow_color);
      err = GetLastError();

      if (result == true) {
         exit_loop = true;
      } else {
         switch (err) {
         case ERR_NO_ERROR:
            exit_loop = true;
            OrderReliablePrint("ERR_NO_ERROR received, but OrderClose() returned false; exiting");
            break;

         case ERR_NO_RESULT:
            // Modification to same value as before
            // See below for reported result
            exit_loop = true;
            result=true;  // this is a good exit.
            break;

         // Shouldn't be any reason stops are invalid (and yet I've seen it); try again
         case ERR_INVALID_STOPS:
            OrderReliablePrint("OrderModifyReliable, ERR_INVALID_STOPS, should not happen; stops already adjusted");
         //	O_R_EnsureValidStops(symbol, price, stoploss, takeprofit);
         case ERR_COMMON_ERROR:
         case ERR_SERVER_BUSY:
         case ERR_NO_CONNECTION:
         case ERR_TOO_FREQUENT_REQUESTS:
         case ERR_TRADE_TIMEOUT:		// for modify this is a retryable error, I hope.
         case ERR_INVALID_PRICE:
         case ERR_OFF_QUOTES:
         case ERR_BROKER_BUSY:
         case ERR_TOO_MANY_REQUESTS:
         case ERR_TRADE_CONTEXT_BUSY:
            cnt++; 	// a retryable error
            break;

         case ERR_TRADE_MODIFY_DENIED:
            // This one may be important; have to Ensure Valid Stops AND valid price (for pends)
            break;

         case ERR_PRICE_CHANGED:
         case ERR_REQUOTE:
            RefreshRates();
            continue; 	// we can apparently retry immediately according to MT docs.

         default:
            // an apparently serious, unretryable error.
            exit_loop = true;
            non_retryable_error = true;
            break;

         }  // end switch
      }

      if (cnt >= O_R_Setting_max_retries) {
         exit_loop = true;
      }

      if (!exit_loop) {
         OrderReliablePrint(StringFormat("Result of attempt %d of %d: Retryable error: %s", cnt, O_R_Setting_max_retries,OrderReliableErrTxt(err)));
         OrderReliablePrint("~  ~  ~  ~  ~  ~  ~  ~  ~  ~  ~  ~  ~  ~  ~  ~  ~  ~  ~  ~  ~  ~  ~  ~  ~  ~  ~  ~  ~  ~  ~  ~  ~  ~  ~");
         O_R_Sleep(O_R_Setting_sleep_time, O_R_Setting_sleep_max);
         RefreshRates();
      } else {
         if (cnt > O_R_Setting_max_retries) {
            OrderReliablePrint(StringFormat("Retry attempts maxed at %d",O_R_Setting_max_retries));
         } else if (non_retryable_error) {
            OrderReliablePrint("Non-retryable error: "  + OrderReliableErrTxt(err));
         }
      }
   }

   // we have now exited from loop.
   O_R_LastErr = err;

   if (result) {
      if (err == ERR_NO_RESULT) {
         OrderReliablePrint(StringFormat("Server reported OrderModify() did not change TP or SL: %d %s @%5.5f, tp@%5.5f, sl@%5.5f",ticket,symbol,price,takeprofit,stoploss));
         OrderReliablePrint("Suggest modifying code logic to avoid.");

      } else {
         OrderReliablePrint(StringFormat("Ticket #%d: Modification successful, updated trade details follow.",ticket));
         if (OrderSelect(ticket, SELECT_BY_TICKET, MODE_TRADES)) OrderPrint();
      }
   } else {
      OrderReliablePrint(StringFormat("Failed to execute modify after %d retries",cnt));
      OrderReliablePrint(StringFormat("Failed modification: %d %s @%5.5f, tp@%5.5f, sl@%5.5f",ticket, symbol, price, takeprofit, stoploss));
      OrderReliablePrint("Last error: " + OrderReliableErrTxt(err));
   }
   OrderReliablePrint("•  •  •  •  •  •  •  •  •  •  •  •  •  •  •  •  •  •  •  •  •  •  •  •  •  •  •  •  •  •  •  •  •  •  •  •  •  •  •  •  •  •  •");
   return(result);
}


//=============================================================================
//                            OrderCloseReliable()
//
//  This is intended to be a drop-in replacement for OrderClose() which,
//  one hopes, is more resistant to various forms of errors prevalent
//  with MetaTrader.
//
//  RETURN VALUE:
//     TRUE if successful, FALSE otherwise
//
//  FEATURES:
//     * Re-trying under some error conditions, sleeping a random
//       time defined by an exponential probability distribution.
//
//     * Displays various error messages on the log for debugging.
//
//  ORIGINAL AUTHOR AND DATE:
//     Derk Wehler, 2006-07-19
//
//=============================================================================
bool OrderCloseReliable(int ticket, double volume, double price,
                        int slippage, color arrow_color = CLR_NONE) {
   bool result = false;
   bool non_retryable_error = false;

   // ========================================================================
   // If testing or optimizing, there is no need to use this lib, as the
   // orders are not real-world, and always get placed optimally.  By
   // refactoring this option to be in this library, one no longer needs
   // to create similar code in each EA.
   if (!O_R_Setting_UseForTesting) {
      if (IsOptimization()  ||  IsTesting()) {
         result = OrderClose(ticket, volume, price, slippage, arrow_color);
         return(result);
      }
   }
   // ========================================================================

   OrderReliable_Fname = "OrderCloseReliable";
   OrderReliablePrint("•  •  •  •  •  •  •  •  •  •  •  •  •  •  •  •  •  •  •  •  •  •  •  •  •  •  •  •  •  •  •  •  •  •  •  •  •  •  •  •  •  •  •");
   OrderReliablePrint(StringFormat("Attempted close of #%d price: %5.5f lots: %5.2f slippage: %d",ticket,price,volume,slippage));


   // - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
   // Get information about this order
   string symbol = "ALLOCATE";		// This is so it has memory space allocated
   int type;
   int digits;
   double point;
   double bid, ask;
   double sl, tp;
   O_R_GetOrderDetails(ticket, symbol, type, digits, point, sl, tp, bid, ask);
   // - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

   if (type != OP_BUY && type != OP_SELL) {
      OrderReliablePrint(StringFormat("Error: Trying to close ticket #%d, which is %s, not OP_BUY or OP_SELL", ticket,OrderType2String(type)));
      return(false);
   }


   int cnt = 0;
   int err = GetLastError(); // so we clear the global variable.
   err = 0;
   bool exit_loop = false;

   while (!exit_loop) {
      result = OrderClose(ticket, volume, price, slippage, arrow_color);
      err = GetLastError();

      if (result == true) {
         exit_loop = true;
      } else {
         switch (err) {
         case ERR_NO_ERROR:
            exit_loop = true;
            OrderReliablePrint("ERR_NO_ERROR received, but OrderClose() returned false; exiting");
            break;

         case ERR_NO_RESULT:
            exit_loop = true;
            OrderReliablePrint("ERR_NO_RESULT received, but OrderClose() returned false; exiting");
            break;

         case ERR_COMMON_ERROR:
         case ERR_SERVER_BUSY:
         case ERR_NO_CONNECTION:
         case ERR_TOO_FREQUENT_REQUESTS:
         case ERR_TRADE_TIMEOUT:		// for close this is a retryable error, I hope.
         case ERR_TRADE_DISABLED:
         case ERR_PRICE_CHANGED:
         case ERR_INVALID_PRICE:
         case ERR_OFF_QUOTES:
         case ERR_BROKER_BUSY:
         case ERR_REQUOTE:
         case ERR_TOO_MANY_REQUESTS:
         case ERR_TRADE_CONTEXT_BUSY:
            cnt++; 	// a retryable error
            break;

         default:
            // Any other error is an apparently serious, unretryable error.
            exit_loop = true;
            non_retryable_error = true;
            break;

         }  // end switch
      }

      if (cnt > O_R_Setting_max_retries) {
         exit_loop = true;
      }

      if (!exit_loop) {
         OrderReliablePrint(StringFormat("Result of attempt %d of %d: Retryable error: %s",cnt,O_R_Setting_max_retries,OrderReliableErrTxt(err)));
         OrderReliablePrint("~  ~  ~  ~  ~  ~  ~  ~  ~  ~  ~  ~  ~  ~  ~  ~  ~  ~  ~  ~  ~  ~  ~  ~  ~  ~  ~  ~  ~  ~  ~  ~  ~  ~  ~");
         O_R_Sleep(O_R_Setting_sleep_time, O_R_Setting_sleep_max);
      }

      if (exit_loop) {
         if (cnt > O_R_Setting_max_retries) {
            OrderReliablePrint(StringFormat("Retry attempts maxed at %d",O_R_Setting_max_retries));
         } else if (non_retryable_error) {
            OrderReliablePrint("Non-retryable error: " + OrderReliableErrTxt(err));
         }
      }
   }

   O_R_LastErr = err;
   // we have now exited from loop.
   if (result) {
      /*		if (OrderStillOpen(ticket))
      		{
      			OrderReliablePrint("Close result reported success, but order remains!  Must re-try close from EA logic!");
      			OrderReliablePrint("Close Failed: Ticket #" + ticket + ", Price: " +
      		                   		price + ", Slippage: " + slippage);
      			OrderReliablePrint("Last error: " + OrderReliableErrTxt(err));
      			result = false;
      		}
      		else
      */
      OrderReliablePrint(StringFormat("Successful close of Ticket #%d     [ Last error: %s ]",ticket,OrderReliableErrTxt(err)));
   } else {
      OrderReliablePrint(StringFormat("Failed to execute close after %d retries",O_R_Setting_max_retries));
      OrderReliablePrint(StringFormat("Failed close: Ticket #%d, Price: %5.5f, Slippage: %d",ticket,price,slippage));
      OrderReliablePrint("Last error: " + OrderReliableErrTxt(err));
   }
   OrderReliablePrint("•  •  •  •  •  •  •  •  •  •  •  •  •  •  •  •  •  •  •  •  •  •  •  •  •  •  •  •  •  •  •  •  •  •  •  •  •  •  •  •  •  •  •");
   return(result);
}


//=============================================================================
//                           OrderCloseReliableMKT()
//
//	This function is intended for closing orders ASAP; the principal
//  difference is that in its internal retry-loop, it uses the new "Bid"
//  and "Ask" real-time variables as opposed to the OrderCloseReliable(),
//  which uses only the price given upon entry to the routine.  More likely
//  to get the order closed if price moves, but more likely to "slip"
//
//  RETURN VALUE:
//     TRUE if successful, FALSE otherwise
//
//  FEATURES:
//     * Re-trying under some error conditions, sleeping a random
//       time defined by an exponential probability distribution.
//
//     * Displays various error messages on the log for debugging.
//
//  ORIGINAL AUTHOR AND DATE:
//     Derk Wehler, 2009-04-03
//
//=============================================================================
bool OrderCloseReliableMKT(int ticket, double volume, double price,
                           int slippage, color arrow_color = CLR_NONE) {
   bool result = false;
   bool non_retryable_error = false;

   // ========================================================================
   // If testing or optimizing, there is no need to use this lib, as the
   // orders are not real-world, and always get placed optimally.  By
   // refactoring this option to be in this library, one no longer needs
   // to create similar code in each EA.
   if (!O_R_Setting_UseForTesting) {
      if (IsOptimization()  ||  IsTesting()) {
         result = OrderClose(ticket, volume, price, slippage, arrow_color);
         return(result);
      }
   }
   // ========================================================================

   OrderReliable_Fname = "OrderCloseReliableMKT";
   OrderReliablePrint("•  •  •  •  •  •  •  •  •  •  •  •  •  •  •  •  •  •  •  •  •  •  •  •  •  •  •  •  •  •  •  •  •  •  •  •  •  •  •  •  •  •  •");
   OrderReliablePrint(StringFormat("Attempted close of #%d initial price: %5.5f lots: %5.2f slippage: %d",ticket,price,volume,slippage));


   // - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
   // Get information about this order
   string symbol = "ALLOCATE";		// This is so it has memory space allocated
   int type;
   int digits;
   double point;
   double bid, ask;
   double sl, tp;
   O_R_GetOrderDetails(ticket, symbol, type, digits, point, sl, tp, bid, ask);
   // - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

   if (type != OP_BUY && type != OP_SELL) {
      OrderReliablePrint(StringFormat("Error: Trying to close ticket #%d, which is %s, not OP_BUY or OP_SELL",ticket,OrderType2String(type)));
      return(false);
   }


   int cnt = 0;
   int err = GetLastError(); // so we clear the global variable.
   err = 0;
   bool exit_loop = false;
   double pnow = -1.0;
   int slippagenow = 0;

   while (!exit_loop) {
      if (type == OP_BUY) {
         pnow = NormalizeDouble(MarketInfo(symbol, MODE_ASK), (int)MarketInfo(symbol, MODE_DIGITS)); // we are buying at Ask
         if (pnow > price) {
            // Do not allow slippage to go negative; will cause error
            slippagenow = (int)MathMax(0, slippage - (pnow - price) / point);
         }
      } else if (type == OP_SELL) {
         pnow = NormalizeDouble(MarketInfo(symbol, MODE_BID), (int)MarketInfo(symbol, MODE_DIGITS)); // we are buying at Ask
         if (pnow < price) {
            // Do not allow slippage to go negative; will cause error
            slippagenow = (int)MathMax(0, slippage - (price - pnow) / point);
         }
      }

      result = OrderClose(ticket, volume, pnow, slippagenow, arrow_color);
      err = GetLastError();

      if (result == true) {
         exit_loop = true;
      } else {
         switch (err) {
         case ERR_NO_ERROR:
            exit_loop = true;
            OrderReliablePrint("ERR_NO_ERROR received, but OrderClose() returned false; exiting");
            break;

         case ERR_NO_RESULT:
            exit_loop = true;
            OrderReliablePrint("ERR_NO_RESULT received, but OrderClose() returned false; exiting");
            break;

         case ERR_COMMON_ERROR:
         case ERR_SERVER_BUSY:
         case ERR_NO_CONNECTION:
         case ERR_TOO_FREQUENT_REQUESTS:
         case ERR_TRADE_TIMEOUT:		// for close this is a retryable error, I hope.
         case ERR_TRADE_DISABLED:
         case ERR_PRICE_CHANGED:
         case ERR_INVALID_PRICE:
         case ERR_OFF_QUOTES:
         case ERR_BROKER_BUSY:
         case ERR_REQUOTE:
         case ERR_TOO_MANY_REQUESTS:
         case ERR_TRADE_CONTEXT_BUSY:
            cnt++; 	// a retryable error
            break;

         default:
            // Any other error is an apparently serious, unretryable error.
            exit_loop = true;
            non_retryable_error = true;
            break;

         }  // end switch
      }

      if (cnt > O_R_Setting_max_retries) {
         exit_loop = true;
      }

      if (!exit_loop) {
         OrderReliablePrint(StringFormat("Result of attempt %d of %d: Retryable error: %s",cnt,O_R_Setting_max_retries,OrderReliableErrTxt(err)));
         OrderReliablePrint("~  ~  ~  ~  ~  ~  ~  ~  ~  ~  ~  ~  ~  ~  ~  ~  ~  ~  ~  ~  ~  ~  ~  ~  ~  ~  ~  ~  ~  ~  ~  ~  ~  ~  ~");
         O_R_Sleep(O_R_Setting_sleep_time, O_R_Setting_sleep_max);
      }

      if (exit_loop) {
         if (cnt > O_R_Setting_max_retries) {
            OrderReliablePrint(StringFormat("Retry attempts maxed at %d",O_R_Setting_max_retries));
         } else if (non_retryable_error) {
            OrderReliablePrint("Non-retryable error: " + OrderReliableErrTxt(err));
         }
      }
   }

   O_R_LastErr = err;
   // we have now exited from loop.
   if (result) {
      OrderReliablePrint(StringFormat("Successful close of Ticket #%d @ %5.5f     [ Last error: %s ]",ticket,pnow,OrderReliableErrTxt(err)));
   } else {
      OrderReliablePrint(StringFormat("Failed to execute close after %d retries",O_R_Setting_max_retries));
      OrderReliablePrint(StringFormat("Failed close: Ticket #%d @ Price: %5.5f (Initial Price: %5.5f), Slippage: %d (Initial Slippage: %d)",ticket,pnow,price,slippagenow,slippage));
      OrderReliablePrint("Last error: " + OrderReliableErrTxt(err));
   }
   OrderReliablePrint("•  •  •  •  •  •  •  •  •  •  •  •  •  •  •  •  •  •  •  •  •  •  •  •  •  •  •  •  •  •  •  •  •  •  •  •  •  •  •  •  •  •  •");
   return(result);
}


//=============================================================================
//                            OrderDeleteReliable()
//
//  This is intended to be a drop-in replacement for OrderDelete() which,
//  one hopes, is more resistant to various forms of errors prevalent
//  with MetaTrader.
//
//  RETURN VALUE:
//     TRUE if successful, FALSE otherwise
//
//
//  FEATURES:
//     * Re-trying under some error conditions, sleeping a random
//       time defined by an exponential probability distribution.
//
//     * Displays various error messages on the log for debugging.
//
//  ORIGINAL AUTHOR AND DATE:
//     Derk Wehler, 2006-12-21
//
//=============================================================================
bool OrderDeleteReliable(int ticket) {
   bool result = false;
   bool non_retryable_error = false;

   // ========================================================================
   // If testing or optimizing, there is no need to use this lib, as the
   // orders are not real-world, and always get placed optimally.  By
   // refactoring this option to be in this library, one no longer needs
   // to create similar code in each EA.
   if (!O_R_Setting_UseForTesting) {
      if (IsOptimization()  ||  IsTesting()) {
         result = OrderDelete(ticket);
         return(result);
      }
   }
   // ========================================================================

   OrderReliable_Fname = "OrderDeleteReliable";
   OrderReliablePrint("•  •  •  •  •  •  •  •  •  •  •  •  •  •  •  •  •  •  •  •  •  •  •  •  •  •  •  •  •  •  •  •  •  •  •  •  •  •  •  •  •  •  •");
   OrderReliablePrint(StringFormat("Attempted deletion of pending order #%d",ticket));


   // - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
   // Get information about this order
   string symbol = "ALLOCATE";		// This is so it has memory space allocated
   int type;
   int digits;
   double point;
   double bid, ask;
   double sl, tp;
   O_R_GetOrderDetails(ticket, symbol, type, digits, point, sl, tp, bid, ask);
   // - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

   if (type == OP_BUY || type == OP_SELL) {
      OrderReliablePrint(StringFormat("error: Trying to close ticket #%d, which is %s, not OP_BUYSTOP, OP_SELLSTOP, OP_BUYLIMIT, or OP_SELLLIMIT",ticket,OrderType2String(type)));
      return(false);
   }


   int cnt = 0;
   int err = GetLastError(); // so we clear the global variable.
   err = 0;
   bool exit_loop = false;

   while (!exit_loop) {
      result = OrderDelete(ticket);
      err = GetLastError();

      if (result == true) {
         exit_loop = true;
      } else {
         switch (err) {
         case ERR_NO_ERROR:
            exit_loop = true;
            OrderReliablePrint("ERR_NO_ERROR received, but OrderDelete() returned false; exiting");
            break;

         case ERR_NO_RESULT:
            exit_loop = true;
            OrderReliablePrint("ERR_NO_RESULT received, but OrderDelete() returned false; exiting");
            break;

         case ERR_COMMON_ERROR:
         case ERR_SERVER_BUSY:
         case ERR_NO_CONNECTION:
         case ERR_TOO_FREQUENT_REQUESTS:
         case ERR_TRADE_TIMEOUT:		// for delete this is a retryable error, I hope.
         case ERR_TRADE_DISABLED:
         case ERR_OFF_QUOTES:
         case ERR_PRICE_CHANGED:
         case ERR_BROKER_BUSY:
         case ERR_REQUOTE:
         case ERR_TOO_MANY_REQUESTS:
         case ERR_TRADE_CONTEXT_BUSY:
            cnt++; 	// a retryable error
            break;

         default:	// Any other error is an apparently serious, unretryable error.
            exit_loop = true;
            non_retryable_error = true;
            break;

         }  // end switch
      }

      if (cnt > O_R_Setting_max_retries) {
         exit_loop = true;
      }

      if (!exit_loop) {
         OrderReliablePrint(StringFormat("Result of attempt %d of %d: Retryable error: %s",cnt,O_R_Setting_max_retries,OrderReliableErrTxt(err)));
         OrderReliablePrint("~  ~  ~  ~  ~  ~  ~  ~  ~  ~  ~  ~  ~  ~  ~  ~  ~  ~  ~  ~  ~  ~  ~  ~  ~  ~  ~  ~  ~  ~  ~  ~  ~  ~  ~");
         O_R_Sleep(O_R_Setting_sleep_time, O_R_Setting_sleep_max);
      } else {
         if (cnt > O_R_Setting_max_retries) {
            OrderReliablePrint(StringFormat("Retry attempts maxed at %d",O_R_Setting_max_retries));
         } else if (non_retryable_error) {
            OrderReliablePrint("Non-retryable error: " + OrderReliableErrTxt(err));
         }
      }
   }

   O_R_LastErr = err;
   // we have now exited from loop.
   if (result) {
      OrderReliablePrint(StringFormat("Successful deletion of Ticket #%d",ticket));
      return(true); // SUCCESS!
   } else {
      OrderReliablePrint(StringFormat("Failed to execute delete after %d retries",O_R_Setting_max_retries));
      OrderReliablePrint(StringFormat("Failed deletion: Ticket #%d",ticket));
      OrderReliablePrint("Last error: " + OrderReliableErrTxt(err));
   }
   OrderReliablePrint("•  •  •  •  •  •  •  •  •  •  •  •  •  •  •  •  •  •  •  •  •  •  •  •  •  •  •  •  •  •  •  •  •  •  •  •  •  •  •  •  •  •  •");
   return(result);
}



//=============================================================================
//                           O_R_CheckForHistory()
//
//  This function is to work around a very annoying and dangerous bug in MT4:
//      immediately after you send a trade, the trade may NOT show up in the
//      order history, even though it exists according to ticket number.
//      As a result, EA's which count history to check for trade entries
//      may give many multiple entries, possibly blowing your account!
//
//  This function will take a ticket number and loop until
//  it is seen in the history.
//
//  RETURN VALUE:
//     TRUE if successful, FALSE otherwise
//
//
//  FEATURES:
//     * Re-trying under some error conditions, sleeping a random
//       time defined by an exponential probability distribution.
//
//     * Displays various error messages on the log for debugging.
//
//  ORIGINAL AUTHOR AND DATE:
//     Matt Kennel, 2010
//
//=============================================================================
bool O_R_CheckForHistory(int ticket) {
   int lastTicket = OrderTicket();

   int cnt = 0;
   int err = GetLastError(); // so we clear the global variable.
   err = 0;
   bool exit_loop = false;
   bool success=false;

   while (!exit_loop) {
      /* loop through open trades */
      int total=OrdersTotal();
      for(int c = 0; c < total; c++) {
         if(OrderSelect(c,SELECT_BY_POS,MODE_TRADES) == true) {
            if (OrderTicket() == ticket) {
               success = true;
               exit_loop = true;
            }
         }
      }
      if (cnt > 3) {
         /* look through history too, as order may have opened and closed immediately */
         total=OrdersHistoryTotal();
         for(int c = 0; c < total; c++) {
            if(OrderSelect(c,SELECT_BY_POS,MODE_HISTORY) == true) {
               if (OrderTicket() == ticket) {
                  success = true;
                  exit_loop = true;
               }
            }
         }
      }

      cnt = cnt+1;
      if (cnt > O_R_Setting_max_retries) {
         exit_loop = true;
      }
      if (!(success || exit_loop)) {
         OrderReliablePrint(StringFormat("Did not find #%d in history, sleeping, then doing retry #%d",ticket,cnt));
         O_R_Sleep(O_R_Setting_sleep_time, O_R_Setting_sleep_max);
      }
   }
   // Select back the prior ticket num in case caller was using it.
   if (lastTicket >= 0) {
      if (OrderSelect(lastTicket, SELECT_BY_TICKET, MODE_TRADES)) {}
   }
   if (!success) {
      OrderReliablePrint(StringFormat("Never found #%d in history! crap!",ticket));
   }
   return(success);
}



//=============================================================================
//=============================================================================
//								Utility Functions
//=============================================================================
//=============================================================================

string OrderReliableErrTxt(int err) {
   return (StringFormat("%d  ::  %s",err,ErrorDescription(err)));
}


// Defaut level is 3
// Use level = 1 to Print all but "Retry" messages
// Use level = 0 to Print nothing
void OrderReliableSetO_R_ErrorLevel(int level) {
   O_R_ErrorLevel = level;
}


void OrderReliablePrint(string s) {
   // Print to log prepended with stuff;
   if (O_R_ErrorLevel >= 99 || (!(IsTesting() || IsOptimization()))) {
      if (O_R_ErrorLevel > 0) {
         Print(OrderReliable_Fname + " " + OrderReliableVersion + ":     " + s);
      }
   }
}


string OrderType2String(int type) {
   if (type == OP_BUY) {
      return("BUY");
   }
   if (type == OP_SELL) {
      return("SELL");
   }
   if (type == OP_BUYSTOP) {
      return("BUY STOP");
   }
   if (type == OP_SELLSTOP)	{
      return("SELL STOP");
   }
   if (type == OP_BUYLIMIT) {
      return("BUY LIMIT");
   }
   if (type == OP_SELLLIMIT)	{
      return("SELL LIMIT");
   }
   return(StringFormat("None (%d)",type));
}



//=============================================================================
//                        O_R_EnsureValidStops()
//
//  Most MQ4 brokers have a minimum stop distance, which is the number of
//  pips from price where a pending order can be placed or where a SL & TP
//  can be placed.  THe purpose of this function is to detect when the
//  requested SL or TP is too close, and to move it out automatically, so
//  that we do not get ERR_INVALID_STOPS errors.
//
//  FUNCTION COMPLETELY OVERHAULED:
//     Derk Wehler, 2008-11-08
//
//=============================================================================
void O_R_EnsureValidStops(string symbol, int cmd, double price, double& sl, double& tp, bool isNewOrder=true) {
   string prevName = OrderReliable_Fname;
   OrderReliable_Fname = "O_R_EnsureValidStops";

   double point = MarketInfo(symbol, MODE_POINT);

   // We only use point for StopLevel, and StopLevel is reported as 10 times
   // what you expect on a 5-digit broker, so leave it as is.
   //if (point == 0.001  ||  point == 0.00001)
   //	point *= 10;

   double 	orig_sl = sl;
   double 	orig_tp = tp;
   double 	new_sl, new_tp;
   int 	min_stop_level = (int)MarketInfo(symbol, MODE_STOPLEVEL);
   double 	servers_min_stop = min_stop_level * point;
   double 	spread = MarketInfo(symbol, MODE_ASK) - MarketInfo(symbol, MODE_BID);
   //Print("        O_R_EnsureValidStops: Symbol = " + symbol + ",  servers_min_stop = " + servers_min_stop);

   // Skip if no S/L (zero)
   if (sl != 0) {
      if (cmd % 2 == 0) {	// we are long
         // for pending orders, sl/tp can bracket price by servers_min_stop
         new_sl = price - servers_min_stop;
         //Print("        O_R_EnsureValidStops: new_sl [", new_sl, "] = price [", price, "] - servers_min_stop [", servers_min_stop, "]");

         // for market order, sl/tp must bracket bid/ask
         if (cmd == OP_BUY  &&  isNewOrder) {
            new_sl -= spread;
            //Print("        O_R_EnsureValidStops: Minus spread [", spread, "]");
         }
         sl = MathMin(sl, new_sl);
      } else {	// we are short
         new_sl = price + servers_min_stop;	// we are short
         //Print("        O_R_EnsureValidStops: new_sl [", new_sl, "] = price [", price, "] + servers_min_stop [", servers_min_stop, "]");

         // for market order, sl/tp must bracket bid/ask
         if (cmd == OP_SELL  &&  isNewOrder) {
            new_sl += spread;
            //Print("        O_R_EnsureValidStops: Plus spread [", spread, "]");
         }

         sl = MathMax(sl, new_sl);
      }
      sl = NormalizeDouble(sl, (int)MarketInfo(symbol, MODE_DIGITS));
   }


   // Skip if no T/P (zero)
   if (tp != 0) {
      // check if we have to adjust the stop
      if (MathAbs(price - tp) <= servers_min_stop) {
         if (cmd % 2 == 0) {	// we are long
            new_tp = price + servers_min_stop;	// we are long
            tp = MathMax(tp, new_tp);
         } else {	// we are short
            new_tp = price - servers_min_stop;	// we are short
            tp = MathMin(tp, new_tp);
         }
         tp = NormalizeDouble(tp, (int)MarketInfo(symbol, MODE_DIGITS));
      }
   }

   // notify if changed
   if (sl != orig_sl) {
      OrderReliablePrint(StringFormat("SL was too close to brokers min distance (%5.2f); Moved SL to: %5.5f",min_stop_level,sl));
   }
   if (tp != orig_tp) {
      OrderReliablePrint(StringFormat("TP was too close to brokers min distance (%5.2f); Moved TP to: %5.5f",min_stop_level,tp));
   }

   OrderReliable_Fname = prevName;
}

//=============================================================================
//                              GetLastErrorReliable()
//
// return the saved error from OrderReliable library,
//      a replacement for GetLastError()
int GetLastErrorReliable() {
   return(O_R_LastErr);
}


//=============================================================================
//                              O_R_Sleep()
//
//  This sleeps a random amount of time defined by an exponential
//  probability distribution. The mean time, in Seconds is given
//  in 'mean_time'.
//  This returns immediately if we are backtesting
//  and does not sleep.
//
//=============================================================================
void O_R_Sleep(double mean_time, double max_time) {
   if (IsTesting()) {
      return;   // return immediately if backtesting.
   }

   double p = (MathRand()+1) / 32768.0;
   double t = -MathLog(p)*mean_time;
   t = MathMin(t,max_time);
   int ms = (int)MathCeil(t*1000);
   if (ms < 10) {
      ms=10;
   }
   Sleep(ms);
}


//=============================================================================
//                              O_R_Config_use2step()
//
//  Setting to toggle if OrderReliable does 1 step (setting SL and TP) or
//  2-step orders (open, then modify, as needed by many ECN's)
//
//
void O_R_Config_use2step(bool twostep) {
   O_R_Setting_use2step = twostep;
}



//=============================================================================
//                              O_R_Config_LimitToMarket()
//
//  Setting to toggle what OrderSendReliable does with Stop or Limit orders
//  that are requested to be placed too close to the current price.
//
//  When set True, it will turn any such conundrum from a stop/limit order
void O_R_Config_limit2mkt(bool limit2market) {
   O_R_Setting_limit2market = limit2market;
}


//=============================================================================
//                      O_R_Config_UseForTesting()
//
//  Setting to toggle whether this OrderReliable library is used in testing
//  and optimization.  By default, it is set to false, and will thus just pass
//  orders straight through to MT4, because those are simulated, not real-time.
//
//  When set true, it will use the full functions as normally all the time,
//  including testing / optimization.
//
//=============================================================================
void O_R_Config_UseInBacktest(bool use) {
   O_R_Setting_UseForTesting = use;
}


//=============================================================================
//                              O_R_GetOrderDetails()()
//
//  For some OrderReliable functions (such as Modify), we need to know some
//  things about the order (such as direction and symbol).  To do this, we
//  need to select the order.  However, the caller may already have an order
//  selected so we need to be responsible and put it back when done.
//
//  Return false if there is a problem, true otherwise.
//
//=============================================================================
bool O_R_GetOrderDetails(int ticket, string& symb, int& type, int& digits,
                         double& point, double& sl, double& tp, double& bid,
                         double& ask, bool exists=true) {
   // If this is existing order, select it and get symbol and type
   if (exists) {
      int lastTicket = OrderTicket();
      if (!OrderSelect(ticket, SELECT_BY_TICKET, MODE_TRADES)) {
         OrderReliablePrint("OrderSelect() error: " + ErrorDescription(GetLastError()));
         return(false);
      }
      symb = OrderSymbol();
      type = OrderType();
      tp = OrderTakeProfit();
      sl = OrderStopLoss();

      // Select back the prior ticket num in case caller was using it.
      if (lastTicket >= 0) {
         if (OrderSelect(lastTicket, SELECT_BY_TICKET, MODE_TRADES)) {}
      }
   }

   // Get bid, ask, point & digits
   bid = NormalizeDouble(MarketInfo(symb, MODE_BID), (int)MarketInfo(symb, MODE_DIGITS));
   ask = NormalizeDouble(MarketInfo(symb, MODE_ASK), (int)MarketInfo(symb, MODE_DIGITS));
   point = MarketInfo(symb, MODE_POINT);
   if (point == 0.001  ||  point == 0.00001) {
      point *= 10;
   }

   digits = (int)MarketInfo(symb, MODE_DIGITS);

   if (digits == 0) {
      string prevName = OrderReliable_Fname;
      OrderReliable_Fname = "GetDigits";
      OrderReliablePrint("error: MarketInfo(symbol, MODE_DIGITS) == 0");
      OrderReliable_Fname = prevName;
      return(false);
   } else if (exists) {
      tp = NormalizeDouble(tp, digits);
      sl = NormalizeDouble(sl, digits);
      bid = NormalizeDouble(bid, digits);
      ask = NormalizeDouble(ask, digits);
   }

   return(true);
}