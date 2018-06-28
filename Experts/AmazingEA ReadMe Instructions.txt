AmazingEA Read-Me Instructions

Please check the following Thread on Forex Factory for News and Updates:-
http://www.forexfactory.com/showthread.php?t=597450

AmazingEA Installation

From Build 600 onwards, within MT4 you choose 'File, Open Data Directory'. Windows Explorer will open with the current directory set to where all your MT4 data directories and logfiles are. In these instructions, I am going to refer to this directory as <MT4>.

The first time you run Build 600, it copies the contents of the <MT4>\experts directory into <MT4>\MQL4 sub-directory. After that the 'experts' directory isn't used and can be deleted, but the MQL4 one is used instead. The Data directories that were under the Program Files area where you installed MT4 are no longer used at all.

To install the EA, copy the AmazingEA.ex4 file into the <MT4>\MQL4\Experts folder.
Also, copy the AmazingEA-Settings.csv and AmazingEA-Settings.xlsx files into the <MT4>\MQL4\Files folder.

If you are new to using the EA I would step through the following instructions from the top. First, get the EA to run manually, next automatically but without using the Settings File and then finally using the Settings File.

How do I make AmazingEA work manually?
1) Drop AmazingEA onto a Chart. Ensure there is a Smiley Face beside the name AmazingEA in the top-right corner of the chart.
2) Change setting AutoTradeNews to false.
3) Lookup the Time of a (preferably High Impact) News Event on Forex Factory Calendar.
4) Ensure UseBrokerTime is set to false.
5) Convert the News Time to the equivalent local time 
6) Set NYear, NMonth, NDay, NHour, NMin and NSec to what the clock will say when the News hits.
7) The Default Settings are adequate for Testing on Demo
8) If the EA doesn't place orders check the 'AmazingEA Troubleshooter' Text File

How do I make AmazingEA work automatically?
1) In MT4, Tools, Options, Expert Advisors, make sure 'Allow DLL Imports' is ticked.
2) Drop AmazingEA onto a Chart. Ensure there is a Smiley Face beside the name AmazingEA in the top-right corner of the chart.
3) The EA works on any Demo account, but only paid for versions can be coded to a Live Account Name or Number for use on a Real Account
4) Licenses are available through the AmazingEA website, please see https://amazingea.wordpress.com/purchase for details.
5) Change setting ReadSettings to False and set FilterByCurrency to True
6) You can also force it to filter to one specific countries News Events by setting FFSymbol to a specific country (e.g. FFSymbol=AUD)
7) The EA will fetch the next News Event which is relevant for that currency pair and country from the Forex Factory Calendar
8) The Default Settings are adequate for Testing on Demo
9) If the EA doesn't place orders check the 'AmazingEA Troubleshooter' Text File

How do I make AmazingEA work automatically and pickup settings automatically from a CSV file?
1) In MT4, Tools, Options, Expert Advisors, make sure 'Allow DLL Imports' is ticked.
2) Drop AmazingEA onto a Chart. Ensure there is a Smiley Face beside the name AmazingEA in the top-right corner of the chart.
3) The EA works on any Demo account, but only paid for versions can be coded to a Live Account Name or Number for use on a Real Account
4) Licenses are available through the AmazingEA website, please see https://amazingea.wordpress.com/purchase for details.
5) Copy the AmazingEA-Settings.csv file into MQL4/Files. The Excel file AmazingEA-Settings.xlsx is supplied for your convenience to help you edit the CSV but the EA doesn't use it.
6) Change setting ReadSettings to True and check the News Event listed is matched by an entry in the AmazingEA-Settings.csv file. 
7) A number should appear next to the SettingsLine and this is the line number of the AmazingEA-Settings.csv file excluding the Header Line
8) The EA will fetch the next News Event which is relevant for that currency pair from the Forex Factory Calendar
9) The Default Settings are adequate for Testing on Demo
10) If the EA doesn't place orders check the 'AmazingEA Troubleshooter' Text File

PointsAway - Stop Order Distance in Points 
Distance above the current ask price and below the current bid price where the Stop Orders will be placed, unless CTCBN > 0.
If CTCBN > 0, the PointsAway distance will be added to the High and Low figure from CTCBN.
If PointsAway is set to 0, the EA will use the broker's minimum distance for Pending Orders.

PointsGap - Orders are opened initially further away so they don't trigger accidentally and moved into position SecBAO seconds before News Time. This used to be hard-coded to 10000 but caused issues with 4-digit brokers. Please set to what is comfortable but please make it more than 1000 points. Set to 0 to disable.

ModifyGap - The EA modifies orders to keep the straddle positioned around current price, but each modification takes 1-2 seconds which is obviously much slower than price can move. ModifyGap sets the minimum distance that price has to move before generating an order modification. The idea is to stop the EA modifying orders for 0.00001 change in price, so it is ready for the larger price movements that might occur later. A value of 5 would mean EURUSD @ 1.32010 would need to be 1.32015 or 1.32005 before modifying. Set to 0 to disable. Maximum Value Allowed is 20.

TP - Take Profit amount in Points.
When the order gets into profit this amount of Points, it will be closed automatically. Set to 0 to disable.

SL - Stop Loss amount in Points. Plus the Spread if you set AddSpreadToSL=true. Set to 0 to disable.

These following six parameters (NYear, NMonth, NDay, NHour, NMin and NSec) are the broker's date and time. If UseBrokerTime is set to false, then they represent the PC Time.
If NYear, NMonth and NDay are all set to 0, then the EA will trade Monday to Friday day at NHour, NMin and NSec. (Brokers do not allow Pending Orders to be entered over weekends). Also, any trade management will stop working after Midnight. Use this option for Breakout Trades and Short Term Trades. The Clock will only show the Time.
From Version 7.00, if NYear, NMonth and NDay are all set correctly the EA will only trade on that date. The trades will not interfere with the same trade setup on the same pair at the same time but for a different date. Trade management will continue to work until the trades are closed. The Clock will show both Date and Time.
NYear - News Year.
NMonth - News Month.
NDay - News Day.
NHour - News Hour.
NMin - News Minute.
NSec - News Seconds.

CTCBN - Candles To Check Before News.
For determining High & Lows , when it is 1 it checks the current candle, when it is 2 it checks the current candle and the previous one. If CTCBN = 0, PointsAway is used from Bid price for Sells and Ask price for Buys. If CTCBN > 0, PointsAway is used from the Low for Sells and High for Buys, where the Low and High are the lowest and highest price reached within the number of candles specified. Set to 1 for default, 0 to disable.

SecBPO - Seconds Before Pending Orders
How many seconds before News Time should the EA place Pending Orders. There is a trade-off here. If set too high, the pending orders may go live early. So, set this as low as possible. But if it's too low, there may not be enough time for MT4 to open the orders. Running 6 charts on 3 brokers, expect to set this to at least 60. Most traders will find the default setting of 20 adequate. This is not going to happen at the exact second specified, because EA code is executed only when a tick signal comes from the broker, but around the news price movements are frequent. If you set SecBAO, a special technique will be employed where the orders are opened 1000 points away + PointsAway setting from current price, which allows you to open orders earlier but safely. See SecBAO setting.

SecBAO - Seconds Before Adjacent Orders
If you set SecBAO, a special technique will be employed where the orders are opened 'PointsGap' points away + PointsAway setting from current price, which allows you to open orders earlier but safely. If PointsGap is 0 (or SecBAO=SecBPO or SecBAO=0), then SecBAO is ignored. When the time reaches SecBAO seconds before the news, the orders will be moved into place. If you set this to the same value as SecBPO, the code is ignored and the EA just opens the orders at the normal distance and doesn't move them. On Live, during news you may be able to set as low as 3 seconds. Default Setting is 5. Set to 0 to disable.

SecBMO - Seconds Before Modify Orders
Once the orders are placed, the EA will follow the price movement and modify orders accordingly so that they are always the correct distance away from the current price. With some volatile news this can be quite often, so if that creates a problem with your broker you can set this to half of the value you put for SecBPO, if you put this to be equal as SecBPO than EA will not modify the orders at all. If set to 0, then the EA will keep modifying right up to the news time. Default Setting is 0.

STWAN - Seconds To Wait After News
This is the timer to cancel the orders that did not get triggered. Default Setting is 5.

OCO - Order Cancel Other
If this is set to true, when your order gets hit the corresponding opposite order will be cancelled but without waiting for STWAN time. This is only effective after News Time, not before.

STOCO - Seconds To Wait After OCO
This is the timer to cancel all the orders that did not get triggered when using OCO=false. Default Setting is 3600 (1 hour). 

BEPoints - Break Even Points
Points In profit which EA will Move SL to Break Even + BEOffset; a nice way to lock in some profit. If you leave it at 0 nothing will happen.

BEOffset - Break Even Offset
Number of points to move beyond Break Even (allows to cover Broker Commissions etc.) Set to 0 to disable.

TrailPoints - Trailing Stop
Enter the amount of Points you want to trail by. If you set this to 20 points, the EA will maintain a distance of 20 points behind current price. Setting to 0 disables trailing stops.

TrailOffset - Trailing Stop Offset
Enter the amount of Points after which you want Trailing to start. Setting to 0 enables Trailing to start as soon as the trade is in profit. If you set this to 150, and TrailPoints is 50, then after 200 points in profit, your Stop will jump to 150 points and maintain a distance 50 points behind current price as long as price keeps moving in the correct direction of course.

TrailImmediate - Start Trailing Immediately
If set to true, the EA will start moving the Stop Loss even when the trade is not in profit. Only do this on brokers where the spread is kept low. If the broker is prone to spike the spread, then this will cause early stop outs. The advantage of using this is that if the news comes out as expected and the trade moves a little bit in your favour, but then reverses, you may capture a few pips.

MM - Money Management
If you set MM to true, the EA will automatically determine the number of lots for your orders, according to the risk you are willing to take

RiskPercent - The risk you are willing to take on any single order.
Risk Percentage is worked out as a percentage of the available margin. The calculation now uses 2 decimal places instead of 1, which will allow the trading of micro-lots. The calculation currently now takes into account Stop Loss distance. If you set MaxSpread, then the Risk calculation will be based on Stop Loss distance + MaxSpread. However, please don't assume that is your maximum risk because brokers can and will slip stop-loss orders.

Lots - Number of Lots for your orders
If you set MM to false, than you have to tell the EA how many lots to use for the orders; so if you put here 1, every order will be placed with 1 lot

MaxSpread - The maximum spread in points you wish to allow for your orders. 
If the spread grows higher than this level, the EA deletes any Pending Orders and will not open new ones until the Spread lowers below this Setting for at least 5 seconds. Don't worry if your orders go live just prior to deletion, the EA will still manage them. Set to 0 to disable.

AddSpreadToSL - Whether to include the spread in Stop Loss settings
If you set AddSpreadToSL to True, then the EA will automatically add the spread to the Stop Loss, so 10 pips will actually become 10 pips plus the spread which could be 20 pips during NFP. If you set AddSpreadToSL to False, the EA will set hard stops based on this setting only, which is good for knowing your max risk etc. You can also use MaxSpread to limit the stop level required for the Spread.

SlipCheck - Whether to perform Stop Loss Reset and Slippage Check
If you set SlipCheck to true, the EA will check for Slippage and reset Stop Losses and Take Profit levels. SlipCheck also works out the Slippage value and outputs it to the Logfile. If you set it to false, the EA will behave more like the original (around v1.2.2) and only run the Break Even and Trailing Stop routines, not the Slippage Check or Stop Loss Reset routines.

MaxSlippage - The maximum slippage in points you wish to allow for your orders.
Unfortunately, this value cannot prevent orders going live and being slipped in the first place. But if the slippage on an 'opened' order exceeds the value set here, the trade will have it's stop loss set to the minimum distance allowed by the broker. If the trade goes against you, it will be closed quickly. If it doesn't, then there is a chance to recoup some losses. This parameter requires Take Profit to be set. If you don't want to use Take Profit, then set TP to a very high value.
If you set SlipCheck=true and MaxSlippage=0, then your SL and TP will be reset to allow for Slippage, but the MaxSlippage routine won't be activated.

AllowBuys - Whether Long Orders are allowed or not.
Default is true. Set to false to disable Long Orders.

AllowSells - Whether Short Orders are allowed or not.
Default is true. Set to false to disable Short Orders.

UseBrokerTime - UseBrokerTime=true is how the EA used to work, UseBrokerTime=false uses the Local PC Time instead. If you use the Local PC time, I highly recommend using a program like 'Net Time' from http://www.timesynctool.com to ensure your PC clock is accurate.

DeleteOnShutdown - Whether to remove orders when Shutting Down the EA or Changing Timeframe on the Chart.
Default is true. Set to false to keep your orders when changing Timeframe on the Chart. In this case, any leftover orders must be manually removed.

AutoTradeNews - Enable to automatically download the News Calendar from Forex Factory and set up the News Time for Trades automatically. The Forex Factory calendar omly covers the current week so when it gets towards the end of the week the EA may show "Unable to retrieve next calendar event for ?????? from www.forexfactory.com". This is not an error and is normal as it means there are no more events available in the current week's calendar. In AutoTradeNews mode, new events are not checked while previous orders / trades (for the same pair and Magic Number) are still open. This may mean you miss some News Events for this reason.

TradeNewsImpact - Choose LOW, MEDIUM or HIGH. You can also use 0,1 or 2 respectively. If you choose LOW, the EA will trade Low, Medium and High Events. If you choose HIGH, the EA will only trade High Events. 

FilterByCurrency - If true, the EA chooses the next News based on what Currency Pair you place the EA on. So for USD news, use a USD based pair e.g. USDJPY and for GBP News, use GBPUSD or GBPJPY for example. If false, it will trade every event.

ExcludeSpeeches - If true, the EA will avoid events with 'Speaks' in the title. So 'Fed Yellen Speaks' would not be traded.

FFSymbol - If the calendar event uses a non standard Currency symbol, use this to override. For example, to trade CNY events use FFSymbol=CNY and place the EA on the desired Currency pair e.g. AUDUSD.

ReadSettings - If true, the EA will search the file specified by SettingsFile below for an entry matching the NewsCountry and NewsTitle. If an antry is found, a Settings Line Number will be displayed in the Comments on the Chart. If an entry is not found, AmazingEA will use the entry marked 'Default' which is the first line in the file and the Settings Line Number will display 001. It is advisable to set this Default entry to AllowBuys=false and AllowSells=false. This will prevent the EA from trading events that are not specifically setup in the Settings File.

SettingsFile - Normally named AmazingEA-Settings.csv in <Data Folder>\MQL4\Files. There is an Excel version (AmazingEA-Settings.xlsx) which you can save to CSV format to create AmazingEA-Settings.csv. If you set the Currency for any entry in the Settings File to 'Default', the EA will trade whatever currency pair is on the chart.

TradeLog - EA will use this to create a name for the log file. If you set this to 'AmazingEA', the Logfile will be called 'AmazingEA-Log-2015-02-24.log'. A TickFile called 'AmazingEA-Ticks-2015-02-24.csv' will also be created containing Bid and Ask Prices and Spread Data. You will find these files in the <Data Folder>\MQL4\files folder of your MT4 platform, with detailed explanations what took place while EA was running. For Version 8.01 onwards, the Magic Number is appended to the file name.

So, when you attach AmazingEA to your chart and set it the way you want, it will monitor what is happening, place buy and sell orders, modify them, move hard stops to break even, trail stop them ... and do the best it can to help you make some $$$$$. Test it on demo before you go live, to make yourself comfortable with it and to see how it will interact with your broker.

A new safety function has been added to delete any pending orders when the EA is removed from the chart. However, if you disable the EA, and you have pending orders already placed, the EA will no longer adjust the straddle, with the consequence that your pending orders may go live before news time. The safest way to disable the EA is to remove it from the chart. Another quick way is to disable EAs and change the time-frame. When setting up, one should always save the settings used in a .set file - this makes it easier to setup again on the same or another broker.

Good Luck !
