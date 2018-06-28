//+------------------------------------------------------------------+
//|                                               Telegram_GetMe.mq5 |
//|                        Copyright 2014, MetaQuotes Software Corp. |
//|                                              http://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2014, MetaQuotes Software Corp."
#property link      "http://www.mql5.com"
#property version   "1.00"
#property strict

#include <Telegram.mqh>

input string InpToken="177791741:AAH0yB3YV7ywm80af_-AGqb7hzTR_Ud9DhQ";//Token

CCustomBot bot;
int getme_result;
//+------------------------------------------------------------------+
//|   OnInit                                                         |
//+------------------------------------------------------------------+
int OnInit()
  {
//--- set token
   bot.Token(InpToken);
//--- check token
   getme_result=bot.GetMe();
//--- run timer
   EventSetTimer(3);
   OnTimer();
//--- done
   return(INIT_SUCCEEDED);
  }
//+------------------------------------------------------------------+
//|   OnDeinit                                                       |
//+------------------------------------------------------------------+
void OnDeinit(const int reason)
  {
   Comment("");
  }
//+------------------------------------------------------------------+
//|   OnTimer                                                        |
//+------------------------------------------------------------------+
void OnTimer()
  {
//--- show error message end exit
   if(getme_result!=0)
     {
      Comment("Error: ",GetErrorDescription(getme_result));
      return;
     }
//--- show bot name
   Comment("Bot name: ",bot.Name());

//---{ insert your code here }
  }
//+------------------------------------------------------------------+