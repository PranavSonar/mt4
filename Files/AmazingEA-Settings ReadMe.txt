AmazingEA-Settings ReadMe

Installation

1) Copy the AmazingEA-Settings.csv and AmazingEA-Settings.xlsx files into the <MT4>\MQL4\Files folder.
2) Set AutoTradeNews=True and ReadSettings=True on AmazingEA
3) The EA will load the next upcoming News Event unless it is the end of the week, when you have to wait until Sunday for next week's calendar to come out.
4) If it finds a News Event, check that the EA has placed a number higher than 001 beside 'SettingsLine' and a currency pair by 'Symbol'. See Tip 4 below.

Tips and Tricks

1) The Excel file AmazingEA-Settings.xlsx is supplied for your convenience to help you edit the CSV but the EA doesn't actually use it.
   Open the XLSX file and edit it, then Save. Then choose Save As.... and choose 'CSV (Comma-delimited) *.csv'. Answer Yes to the question 'Are you sure you wish to save in this format'
   After saving changes I recommend you restart the EA.
2) Instead of entering a Currency Pair in the Symbol column, you can use the word 'Default'. The EA will pick up whatever Currency Pair is on the Chart. 
   This is also useful if you want to trade multiple pairs for the same News Event. Simply open all the charts for the pairs you want to trade and add AmazingEA to each one.
3) If the EA can't locate an entry for the upcoming news event it will use the SettingsLine=001 which contains the words 'Default' for Country, Title and Symbol.
   This Setting should have AllowBuys=False and AllowSells=False to prevent the EA trading unknown or unrecognised events.
   If you are expecting the EA to trade an event, check that the SettingsLine Number is not 001.
