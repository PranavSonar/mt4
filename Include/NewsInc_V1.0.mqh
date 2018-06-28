//+------------------------------------------------------------------+
//|                                                 NewsInc_V1.0.mqh |
//|                        Copyright 2015, MetaQuotes Software Corp. |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2015, MetaQuotes Software Corp."
#property link      "https://www.mql5.com"
#property strict


//+------------------------------------------------------------------+
//| Original source from FFCal
//| Most of the code is copied/stripped from FFCal                            
//| The result of the procedure call is a value between 0 and 3
//| 0= no blocking of pair
//| 1= blocking Low impact
//| 2= blocking Medium impact
//| 3= blocking High impact
//| First initialize the procedure     ExternalNewsInit();
//| Secondly call the procedure        GetNewsInfo( string pair, int minutes before news, minutes after news);
//+------------------------------------------------------------------+
//| defines                                                          |
//+------------------------------------------------------------------+
// #define MacrosHello   "Hello, world!"
// #define MacrosYear    2010
//+------------------------------------------------------------------+
//| DLL imports                                                      |
//+------------------------------------------------------------------+
// #import "user32.dll"
//   int      SendMessageA(int hWnd,int Msg,int wParam,int lParam);
// #import "my_expert.dll"
//   int      ExpertRecalculate(int wParam,int lParam);
// #import
//+------------------------------------------------------------------+
//| EX5 imports                                                      |
//+------------------------------------------------------------------+
// #import "stdlib.ex5"
//   string ErrorDescription(int error_code);
// #import
//+------------------------------------------------------------------+

/*-------------------------------------------------------------------------------------------------
                                                                        
---------------------------------------------------------------------------------------------------
ACKNOWLEDGEMENTS:

derkwehler and other contributors - the core code of the FFCal indicator,
                                    FFCal_v20 dated 07/07/2009, Copyright @ 2006 derkwehler
                                    http://www.forexfactory.com/showthread.php?t=19293
                                    email: derkwehler@gmail.com

deVries -      for his excellent donated work that significantly altered and streamlined the file
               handling coding to establish compatibility with the new release of MT4 Build 600+,
               (Jobs for deVries  www.mql5.com/en/job/new?prefered=deVries)
qFish -        for his generously given time and help during the effort to improve this indicator.
atstrader -    For the option controlling for what pair/pairs(s) news is shown, and for providing
               new file access coding in 2015.
traderathome - for the modification of the original work to show more and prioritized headlines.

---------------------------------------------------------------------------------------------------
Suggested Colors:                    White Charts          Black Charts

Panel_Title                          Black                 C'180,180,180'
News_Low_Impact                      C'000,125,029'        C'046,186,046'
News_Medium_Impact                   MediumBlue            C'098,147,238'
News_High_Impact                     Crimson               C'240,038,038'
Bank_Holiday_Color                   DarkOrchid            Orchid
Remarks_Color                        DarkGray              DimGray
Background_Color_                    White                 C'010,010,010''

-------------------------------------------------------------------------------------------------*/

#define READURL_BUFFER_SIZE   100

#define TITLE		0
#define COUNTRY   1
#define DATE		2
#define TIME		3
#define IMPACT		4
#define FORECAST	5
#define PREVIOUS	6

#import  "Wininet.dll"
   int InternetOpenW(string, int, string, string, int);
   int InternetConnectW(int, string, int, string, string, int, int, int);
   int HttpOpenRequestW(int, string, string, int, string, int, string, int);
//start 2015 atstrader revision
   //   int InternetOpenUrlW(int, string, string, int, int, int);
//end 2015 atstrader revision
   int InternetOpenUrlW(int, string, string, uint, uint, uint);
   int InternetReadFile(int, uchar & arr[], int, int & arr[]);
   int InternetCloseHandle(int);
#import

//global external inputs---------------------------------------------------------------------------
string NewsInc                         = "Indicator Display Controls:";
bool   Indicator_On                    = true;
int    Show_Impacts_H_HM_HML_123       = 3;
//extern bool   News_Panel_At_Chart_Right       = true;
//extern bool   News_Panel_In_Subwindow_1       = true;
int    Display_Min_TF                  = 1;
int    Display_Max_TF                  = 43200;
string TF_Choices                      = "1-5-15-30-60-240-1440-10080-43200";

string __                              = "";
string Part_2                          = "News Panel Settings:";
color  Panel_Title 	                  = C'180,180,180';
color  Low_Impact_News_Color           = clrPink;
color  Medium_Impact_News_Color        = clrBlue;
color  High_Impact_News_Color          = clrRed;
color  Bank_Holiday_Color              = clrOrchid;
color  Remarks_Color                   = DimGray;
color  Background_Color_               = C'010,010,010';
bool   Show_Panel_Background                  = false;

 string ___                             = "";
 string Part_3                          = "Other Currency Settings:";
 bool	  Show_USD_News                   = true;
 bool	  Show_EUR_News                   = true;
 bool	  Show_GBP_News                   = true;
 bool	  Show_NZD_News                   = true;
 bool	  Show_JPY_News                   = true;
 bool	  Show_AUD_News                   = true;
 bool	  Show_CAD_News                   = true;
 bool	  Show_CHF_News                   = true;
 bool	  Show_CNY_News                   = true;
 bool	  Ignore_Current_Symbol           = true;

 string ____                            = "";
 string Part_4                          = "Event #1 Alert Setting:";


//global buffers and variables---------------------------------------------------------------------
bool          Deinitialized, skip;

datetime      newsTime,calendardate;   //sundaydate calendar
int 	        xmlHandle, BoEvent, finalend, end, begin, minsTillNews, tmpMins, idxOfNext;
int           Minutes[8], newsIdx, next, dispMins, Days, Hours, Mins;
int           k,curX,curY,W,Box,x1,x2,index;
int           WebUpdateFreq = 240; // 240 Minutes between web updates to not overload FF server
int           TxtSize       = 7;
int           TitleSpacer   = 6; 
int           EventSpacer   = 4; 
static int	  PrevMinute    = -1;
string 		  xmlFileName;
string        xmlSearchName;
int           PrevTF        = 0;
static int	  UpdateRateSec = 10;

string	     sUrl = "http://www.forexfactory.com/ff_calendar_thisweek.xml"; //original
string   	  myEvent, mainData[1][7], sData, csvoutput, sinceUntil, TimeStr;
string    	  G,/*pair, cntry1, cntry2,*/ Title[8], Country[8], Impact[8],event[5],Color[5];
string 	     sTags[7] = { "<title>", "<country>", "<date><![CDATA[","<time><![CDATA[",
              "<impact><![CDATA[", "<forecast><![CDATA[", "<previous><![CDATA[" };
string 	     eTags[7] = { "</title>", "</country>", "]]></date>", "]]></time>",
              "]]></impact>", "]]></forecast>", "]]></previous>" };

string        header;
bool Alert_Allowed = true;
int timeFrame = 0;
string __symbol;

struct news_event
{
   string Title;
   string Country;
   string Impact;
   int Minutes;
};



//+-----------------------------------------------------------------------------------------------+
//| Indicator De-initialization                                                                   |
//+-----------------------------------------------------------------------------------------------+
int ExternalNewsDeInit()
   {
   int obj_total= ObjectsTotal();
   for (uchar i= obj_total; i>=0; i--) 
      {
      string name= ObjectName(i);
      if (StringSubstr(name,0,6)=="z[News") {ObjectDelete(name);}
      }
	return(0);
   }


//+-----------------------------------------------------------------------------------------------+
//| Indicator Initialization                                                                      |
//+-----------------------------------------------------------------------------------------------+
int ExternalNewsInit()
{

   
	//Make sure we are connected.  Otherwise exit.
   //With the first DLL call below, the program will exit (and stop) automatically after one alert.
   if ( !IsDllsAllowed() ) 
   {
      Alert(Symbol()," ",Period(),", FFCal: Allow DLL Imports");
   }

	//deVries: Management of FFCal.xml Files involves setting up a search to find and delete files
	//that are not of this Sunday date.  This search is limited to 10 weeks back (604800 seconds).
	//Files with Sunday dates that are older will not be purged by this search and will have to be
	//manually deleted by the user.
	xmlFileName = GetXmlFileName();
   for (k=calendardate;k>=calendardate-6048000;k=k-604800)
      {
      xmlSearchName =  (StringConcatenate(TimeYear(k),"-",
         PadString(DoubleToStr(TimeMonth(k),0),"0",2),"-",
         PadString(DoubleToStr(TimeDay(k),0),"0",2),"-FFCal-News",".xml"));
      xmlHandle = FileOpen(xmlSearchName, FILE_BIN|FILE_READ);
	   if(xmlHandle >= 0) //file exists.  A return of -1 means file does not exist.
	      {
	      FileClose(xmlHandle);
	      if(xmlSearchName != xmlFileName)FileDelete(xmlSearchName);
	      }
	      else
	      {
	         Alert("Filename does not exist;");
	         return -1;
	      }
	   }
	return(0);
}

int getNewsInfo(string _symbol, int minutesBefore, int minutesAfter)
{
   
   string base, quote;
   bool block = false;
   string savedImpact = "";
   
   __symbol = _symbol;
   base = StringSubstr(__symbol,0,3);
   quote = StringSubstr(__symbol,3,3);

   
   InitNews(sUrl);

   //deVries---------------------------------------------------------------------------------------
	//New xml file handling coding and revised parsing coding
	xmlHandle = FileOpen(xmlFileName, FILE_BIN|FILE_READ);
	if(xmlHandle>=0)
	{
	   int size = FileSize(xmlHandle);
	   sData = FileReadString(xmlHandle, size);
	   FileClose(xmlHandle);
	}
      
	//Parse the XML file looking for an event to report
	//newsIdx = 0;
	tmpMins = 10080;	// (a week)
	BoEvent = 0;
	savedImpact = "";
   block = false;
	while (true)
	{
   	BoEvent = StringFind(sData, "<event>", BoEvent);
   	if (BoEvent == -1) break;
   	BoEvent += 7;
   	next = StringFind(sData, "</event>", BoEvent);
   	if (next == -1) break;
   	myEvent = StringSubstr(sData, BoEvent, next - BoEvent);
   	BoEvent = next;
   	begin = 0;
   	skip = false;
   	for (uchar i=0; i < 7; i++)
	   {
   		mainData[0][i] = "";
   		next = StringFind(myEvent, sTags[i], begin);
   		// Within this event, if tag not found, then it must be missing; skip it
   		if (next == -1) continue;
   		else
   		   {
   			// We must have found the sTag okay...
   			begin = next + StringLen(sTags[i]);		   	// Advance past the start tag
   			end = StringFind(myEvent, eTags[i], begin);	// Find start of end tag
   			//Get data between start and end tag
   			if (end > begin && end != -1)
   			   {mainData[0][i] = StringSubstr(myEvent, begin, end - begin);}
   		   }
	   }//End "for" loop

   	//Test against filters that define whether we want to skip this particular announcement
   	if(!IsNewsCurrency(__symbol,mainData[0][COUNTRY]))	//deVries
   		{skip = true;}
   		
   	else if ((Show_Impacts_H_HM_HML_123 == 1) &&
   	   (mainData[0][IMPACT] == "Medium"))
   	   {skip = true;}
   
   	else if ((Show_Impacts_H_HM_HML_123 == 1 || Show_Impacts_H_HM_HML_123 == 2) &&
   	   (mainData[0][IMPACT] == "Low"))
   	   {skip = true;}

   	else if (!StringSubstr(mainData[newsIdx][TITLE],0,4)== "Bank")
   	    {skip = true;}
   
   	else if (!StringSubstr(mainData[newsIdx][TITLE],0,8)== "Daylight")
   	    {skip = true;}
   
   	else if ((mainData[newsIdx][TIME] == "All Day" && mainData[newsIdx][TIME] == "") ||
   	   (mainData[newsIdx][TIME] == "Tentative" && mainData[newsIdx][TIME] == "")  ||
   	  	(mainData[newsIdx][TIME] == ""))
   	  	{skip = true;}
   	  	
   	

   	//If not skipping this event, then log time to event it into ExtMapBuffer0
   	if (!skip)
   	{
   		//If we got this far then we need to calc the minutes until this event
   		//First, convert the announcement time to seconds (in GMT)
   		newsTime = MakeDateTime(mainData[0][DATE], mainData[0][TIME]);
   		// Now calculate the minutes until this announcement (may be negative)
   		minsTillNews = (newsTime - TimeGMT()) / 60;
   

   		
   		if ((minsTillNews > 0) && (minsTillNews <= minutesBefore))
   		{
   		   // set impact and minutes
   		   block = true;
   		   if (StringLen(savedImpact) == 0)
   		   {
   		      savedImpact = mainData[0][IMPACT];
   		   }
   		   else if ((savedImpact == "Low") && ((mainData[0][IMPACT] == "Medium") || (mainData[0][IMPACT] == "High")))
   		   {
   		      savedImpact = mainData[0][IMPACT];
   		   }
   		   else if ((savedImpact == "Medium") && (mainData[0][IMPACT] == "High"))
   		   {
   		      savedImpact = mainData[0][IMPACT];
   		   }
   		}
   		if ((minsTillNews < 0) && (MathAbs(minsTillNews) <= minutesAfter))
   		{
   		   // set impact and minutes
   		   block = true;
   		   if (StringLen(savedImpact) == 0)
   		   {
   		      savedImpact = mainData[0][IMPACT];
   		   }
   		   else if ((savedImpact == "Low") && ((mainData[0][IMPACT] == "Medium") || (mainData[0][IMPACT] == "High")))
   		   {
   		      savedImpact = mainData[0][IMPACT];
   		   }
   		   else if ((savedImpact == "Medium") && (mainData[0][IMPACT] == "High"))
   		   {
   		      savedImpact = mainData[0][IMPACT];
   		   }
   		}
   
   	} //End "skip" routine
   }  //End "while" routine      
      
	//----------------------------------------------------------------------------------------------
	
	if (block)
	{
	   if (savedImpact == "High")
	   {
	      return 3;
	   }
	   else if (savedImpact == "Medium")
	   {
	      return 2;
	   }
	   else if (savedImpact == "Low")
	   {
	      return 1;
	   }
	}
	else
	{         
      return 0; 
   }
   
   return 0;

}



//+-----------------------------------------------------------------------------------------------+
//| Subroutine: getting the name of the ForexFactory .xml file                                    |
//+-----------------------------------------------------------------------------------------------+
//deVries: one file for all charts!
string GetXmlFileName()
   {
   int adjustDays = 0;
   switch(TimeDayOfWeek(TimeLocal()))
      {
      case 0:
      adjustDays = 0;
      break;
      case 1:
      adjustDays = 1;
      break;
      case 2:
      adjustDays = 2;
      break;
      case 3:
      adjustDays = 3;
      break;
      case 4:
      adjustDays = 4;
      break;
      case 5:
      adjustDays = 5;
      break;
      case 6:
      adjustDays = 6;
      break;
      }
   calendardate =  TimeLocal() - (adjustDays  * 86400);
   string fileName =  (StringConcatenate(TimeYear(calendardate),"-",
          PadString(DoubleToStr(TimeMonth(calendardate),0),"0",2),"-",
          PadString(DoubleToStr(TimeDay(calendardate),0),"0",2),"-FFCal-News",".xml"));

   return (fileName); //Always a Sunday date
   }
   
//+-----------------------------------------------------------------------------------------------+
//| Subroutine: to pad string                                                                     |
//+-----------------------------------------------------------------------------------------------+
//deVries:
string PadString(string toBePadded, string paddingChar, int paddingLength)
   {
   while(StringLen(toBePadded) <  paddingLength)
      {
      toBePadded = StringConcatenate(paddingChar,toBePadded);
      }
   return (toBePadded);
   }
   
//+-----------------------------------------------------------------------------------------------+
//| Subroutines: recoded creation and maintenance of single xml file                              |
//+-----------------------------------------------------------------------------------------------+   
//deVries: void InitNews(string& mainData[][], string newsUrl)
void InitNews(string newsUrl)
   {
   if(DoFileDownLoad()) //Added to check if the CSV file already exists
      {
      DownLoadWebPageToFile(newsUrl); //downloading the xml file
      }
   }
   
//deVries: If we have recent file don't download again
bool DoFileDownLoad()
   {
   xmlHandle = 0;
   int size;
   datetime time = TimeCurrent();
   //datetime time = TimeLocal();

   if(GlobalVariableCheck("Update.FF_Cal") == false)return(true);
   if((time - GlobalVariableGet("Update.FF_Cal")) > WebUpdateFreq*60)return(true);

   xmlFileName = GetXmlFileName();
   xmlHandle=FileOpen(xmlFileName,FILE_BIN|FILE_READ);  //check if file exist
   if(xmlHandle>=0)//when the file exists we read data
      {
	   size = FileSize(xmlHandle);
	   sData = FileReadString(xmlHandle, size);
      FileClose(xmlHandle);//close it again check is done
      return(false);//file exists no need to download again
      }
   //File does not exist if FileOpen return -1 or if GetLastError = ERR_CANNOT_OPEN_FILE (4103)
   return(true); //commando true to download xml file
   }
   
//+-----------------------------------------------------------------------------------------------+
//| Subroutine: downloading the ForexFactory .xml file                                            |
//+-----------------------------------------------------------------------------------------------+
//2014 deVries: new coding replacing old "GrabWeb" coding
//2015 atstrader: revise file access coding
void DownLoadWebPageToFile(string url = "http://www.forexfactory.com/ff_calendar_thisweek.xml")
   {
   int HttpOpen = InternetOpenW(" ", 0, " ", " ", 0);
   int HttpConnect = InternetConnectW(HttpOpen, "", 80, "", "", 3, 0, 1);

//start 2015 atstrader revision
   // int HttpRequest = InternetOpenUrlW(HttpOpen, url, NULL, 0, 0, 0);
   // INTERNET_FLAG_PRAGMA_NOCACHE - 0x00000100 - do not try the cache or proxy
   // INTERNET_FLAG_NO_CACHE_WRITE - 0x04000000 - don't add this to the IE cache
   // INTERNET_FLAG_RELOAD         - 0x80000000 - Forces download of requested file, object, or
   //                                directory listing from the origin server, not from the cache.
   int HttpRequest = InternetOpenUrlW(HttpOpen, url, NULL, 0, 0x84000100, 0);
//end 2015 atstrader revision

   int read[1];
   uchar  Buffer[];
   ArrayResize(Buffer, READURL_BUFFER_SIZE + 1);
   string NEWS = "";

	   xmlFileName = GetXmlFileName();
	   xmlHandle = FileOpen(xmlFileName, FILE_BIN|FILE_READ|FILE_WRITE);
	   //File exists if FileOpen return >=0.
	   if (xmlHandle >= 0) {FileClose(xmlHandle); FileDelete(xmlFileName);}

		//Open new XML.  Write the ForexFactory page contents to a .htm file.  Close new XML.
		xmlHandle = FileOpen(xmlFileName, FILE_BIN|FILE_WRITE);

   while (true)
      {
      InternetReadFile(HttpRequest, Buffer, READURL_BUFFER_SIZE, read);
      string strThisRead = CharArrayToString(Buffer, 0, read[0], CP_UTF8);
      if (read[0] > 0)NEWS = NEWS + strThisRead;
      else
         {
         FileWriteString(xmlHandle, NEWS);
         FileClose(xmlHandle);
		   //Find the XML end tag to ensure a complete page was downloaded.
		   end = StringFind(NEWS, "</weeklyevents>", 0);
		   //If the end of file tag is not found, a return -1 (or, "end <=0" in this case),
		   //then return (false).
		   if (end == -1)
		      {
		      Alert(Symbol()," ",Period(),", FFCal Error: File download incomplete!");
		      return;
		      }
		   //Else, set global to time of last update
		   else {GlobalVariableSet("Update.FF_Cal", TimeCurrent());}
         break;
         }
      }
   if (HttpRequest > 0) InternetCloseHandle(HttpRequest);
   if (HttpConnect > 0) InternetCloseHandle(HttpConnect);
   if (HttpOpen > 0) InternetCloseHandle(HttpOpen);
   }


bool IsNewsCurrency(string cSymbol, string fSymbol)
   {
   if (StringFind(cSymbol,fSymbol) >= 0)
   {
      return true;
   }
   return(false);
   }
   
   
//+-----------------------------------------------------------------------------------------------+
//| Indicator Subroutine For Date/Time    changed by deVries                                      |
//+-----------------------------------------------------------------------------------------------+
datetime MakeDateTime(string strDate, string strTime)  //not string now datetime
   {
	int n1stDash = StringFind(strDate, "-");
	int n2ndDash = StringFind(strDate, "-", n1stDash+1);

	string strMonth = StringSubstr(strDate, 0, 2);
	string strDay = StringSubstr(strDate, 3, 2);
	string strYear = StringSubstr(strDate, 6, 4);

	int nTimeColonPos = StringFind(strTime, ":");
	string strHour = StringSubstr(strTime, 0, nTimeColonPos);
	string strMinute = StringSubstr(strTime, nTimeColonPos+1, 2);
	string strAM_PM = StringSubstr(strTime, StringLen(strTime)-2);

	int nHour24 = StrToInteger(strHour);
	if ((strAM_PM == "pm" || strAM_PM == "PM") && nHour24 != 12) {nHour24 += 12;}
	if ((strAM_PM == "am" || strAM_PM == "AM") && nHour24 == 12) {nHour24 = 0;}

	datetime newsevent = StringToTime(strYear+ "." + strMonth + "." +
	   strDay)+nHour24*3600+ (StringToInteger(strMinute)*60);
	return(newsevent);
   }
   
//+-----------------------------------------------------------------------------------------------+
//| Indicator Subroutine For Impact Color                                                         |
//+-----------------------------------------------------------------------------------------------+
double ImpactToColor (string impact)
   {
	if (impact == "High") return (High_Impact_News_Color);
	else {if (impact == "Medium") return (Medium_Impact_News_Color);
	else {if (impact == "Low") return (Low_Impact_News_Color);
	else {if (impact == "Holiday") return (Bank_Holiday_Color);
	else {return (Remarks_Color);} }}}
   }