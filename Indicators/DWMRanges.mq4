//+--------------------------------------------------------------------------------------------+
//|                                                                                            |
//|                                DWMRanges.mq4                                      | 
//|                                                                                            |
//+--------------------------------------------------------------------------------------------+ 
#property copyright "Copyright @ 2012 Zool"
#property link      "email: angyalzoltan@gmail.com" 
#property indicator_chart_window
#define  NL    "\n"

//Global External Inputs------------------------------------------------------------------------ 
extern bool   Daily_Range_On                  = true;
extern int    Daily_Range_Period              = 24;
extern bool   Weekly_Range_On                 = true;
extern int    Weekly_Range_Period             = 24;
extern bool   Monthly_Range_On                = true;
extern int    Monthly_Range_Period            = 24;
extern bool   Show_Comments                   = true;
extern string Lines_Settings                   = "Lines Settings:"; 
extern color  DRangeHigh_Color                 = Salmon;
extern color  DRangeLow_Color                  = SkyBlue;
extern color  WRangeHigh_Color                 = Crimson;
extern color  WRangeLow_Color                  = RoyalBlue;
extern color  MRangeHigh_Color                 = Maroon;
extern color  MRangeLow_Color                  = Navy;
extern int    LineStyle                       = 0;    
extern int    LineThickness              = 2;

extern color  Range_Labels_Color        = Gray;
extern string Range_Labels_FontStyle    = "Verdana"; 
extern int    Range_Labels_FontSize     = 6;  

//Deinit Section
int        obj_total,k;
string     name;

//Range Section
int        ii,iii,x,xx,TodayBar;
double     HiToday,LoToday,HiWeek,LoWeek,HiMonth,LoMonth;
double     DRangeAvg, DRangeHigh, DRangeLow, WRangeAvg, WRangeHigh, WRangeLow, MRangeAvg, MRangeHigh, MRangeLow;
double     DARg, WARg, MARg, TodayRange,WeekRange,MonthRange;  
int        Factor,i;

//Draw Lines
int        a,b,c,R2;  
string     line;
datetime   startline, stopline;

//Draw Labels
string     linelabel, spc, screeninfo;
datetime   startlabel; 

//+-------------------------------------------------------------------------------------------+
//| Indicator Initialization                                                                  |                                                        
//+-------------------------------------------------------------------------------------------+      
int init()
   {
   if (Digits == 5 || Digits == 3) {Factor = 10;} 
   else {Factor = 1;} //cater for 5 digits 
   }

//+-------------------------------------------------------------------------------------------+
//| Indicator De-initialization                                                               |                                                        
//+-------------------------------------------------------------------------------------------+       
int deinit()
   {   
   obj_total= ObjectsTotal();  
   for (k= obj_total; k>=0; k--)
      {
      name= ObjectName(k); 
      if (StringSubstr(name,0,11)=="[DWMRanges]"){ObjectDelete(name);}
      }
   Comment ("");
   return(0);
   }

//+-------------------------------------------------------------------------------------------+
//| Indicator Start                                                                           |                                                        
//+-------------------------------------------------------------------------------------------+         
int start()
   {

   //Panel and Range lines - Define today's bar/data                   
   TodayBar   = iBarShift(NULL,PERIOD_D1,Time[0]);
   HiToday    = iHigh (NULL,PERIOD_D1,TodayBar);
   LoToday    = iLow  (NULL,PERIOD_D1,TodayBar); 
   HiWeek    = iHigh (NULL,PERIOD_W1,0);
   LoWeek    = iLow  (NULL,PERIOD_W1,0); 
   HiMonth    = iHigh (NULL,PERIOD_MN1,0);
   LoMonth    = iLow  (NULL,PERIOD_MN1,0); 
   TodayRange = ((HiToday - LoToday)/Point)/Factor; 
   WeekRange = ((HiWeek - LoWeek)/Point)/Factor; 
   MonthRange = ((HiMonth - LoMonth)/Point)/Factor; 
   
   //Range High/Low lines----------------------------------------------------------------------
      Ranges();
      DRangeAvg = NormalizeDouble(DARg/Daily_Range_Period,4);                
      WRangeAvg = NormalizeDouble(WARg/Weekly_Range_Period,4);                
      MRangeAvg = NormalizeDouble(MARg/Monthly_Range_Period,4);                
      DRangeHigh =  DRangeAvg + iLow(NULL,PERIOD_D1,TodayBar);
      DRangeLow  = -DRangeAvg + iHigh(NULL,PERIOD_D1,TodayBar);
      WRangeHigh =  WRangeAvg + iLow(NULL,PERIOD_W1,0);
      WRangeLow  = -WRangeAvg + iHigh(NULL,PERIOD_W1,0);
      MRangeHigh =  MRangeAvg + iLow(NULL,PERIOD_MN1,0);
      MRangeLow  = -MRangeAvg + iHigh(NULL,PERIOD_MN1,0);
      if (HiToday - LoToday > DRangeAvg)
         {            
         if (Bid >= HiToday- (HiToday-LoToday)/2) {DRangeHigh = LoToday + DRangeAvg; DRangeLow  = LoToday;}
         else {DRangeHigh  = HiToday; DRangeLow = HiToday - DRangeAvg;}
         }

      if (HiWeek - LoWeek > WRangeAvg)
         {            
         if (Bid >= HiWeek- (HiWeek-LoWeek)/2) {WRangeHigh = LoWeek + WRangeAvg; WRangeLow  = LoWeek;}
         else {WRangeHigh  = HiWeek; WRangeLow = HiWeek - WRangeAvg;}
         }

      if (HiMonth - LoMonth > MRangeAvg)
         {            
         if (Bid >= HiMonth- (HiMonth-LoMonth)/2) {MRangeHigh = LoMonth + MRangeAvg; MRangeLow  = LoMonth;}
         else {MRangeHigh  = HiMonth; MRangeLow = HiMonth - MRangeAvg;}
         }

//Comments        
      if (Show_Comments)
         {
         screeninfo = "";
         screeninfo = StringConcatenate(screeninfo, NL);
         screeninfo = StringConcatenate(screeninfo,"        | Avg | Curr | RoomUP | RoomDWN ", NL);
         screeninfo = StringConcatenate(screeninfo,"Daily   |",DoubleToStr((DRangeAvg/Point)/Factor,0)," | ",DoubleToStr(TodayRange,0)," | ",DoubleToStr(((MathAbs(DRangeHigh-Close[0]))/Point)/Factor,0)," | ",DoubleToStr(((MathAbs(DRangeLow-Close[0]))/Point)/Factor,0), NL);
         screeninfo = StringConcatenate(screeninfo,"Weekly  |",DoubleToStr((WRangeAvg/Point)/Factor,0)," | ",DoubleToStr(WeekRange,0)," | ",DoubleToStr(((MathAbs(WRangeHigh-Close[0]))/Point)/Factor,0)," | ",DoubleToStr(((MathAbs(WRangeLow-Close[0]))/Point)/Factor,0), NL);
         screeninfo = StringConcatenate(screeninfo,"Monthly |",DoubleToStr((MRangeAvg/Point)/Factor,0)," | ",DoubleToStr(MonthRange,0)," | ",DoubleToStr(((MathAbs(MRangeHigh-Close[0]))/Point)/Factor,0)," | ",DoubleToStr(((MathAbs(MRangeLow-Close[0]))/Point)/Factor,0), NL);
         Comment (screeninfo);
         }

             
      //Range Lines data to subroutine                                                             
   if (Daily_Range_On && Period()< 1440)
      {         
      DrawLines("D Range High", 1, DRangeHigh, DRangeHigh_Color, LineStyle, LineThickness);   
      DrawLines("D Range Low", 1, DRangeLow,  DRangeLow_Color, LineStyle, LineThickness);
      }
   if (Weekly_Range_On && Period()< 10080)
      {         
      DrawLines("W Range High", 2, WRangeHigh, WRangeHigh_Color, LineStyle, LineThickness);   
      DrawLines("W Range Low", 2, WRangeLow,  WRangeLow_Color, LineStyle, LineThickness);
      }
   if (Monthly_Range_On && Period()< 43200)
      {         
      DrawLines("M Range High", 3, MRangeHigh, MRangeHigh_Color, LineStyle, LineThickness);   
      DrawLines("M Range Low", 3, MRangeLow,  MRangeLow_Color, LineStyle, LineThickness);
      }
   
   //End Ranges
  
   //End of program computations---------------------------------------------------------------        
   return(0);
   }

//+-------------------------------------------------------------------------------------------+
//| Indicator Subroutine To Compute Average Ranges                                            |                                                 
//+-------------------------------------------------------------------------------------------+ 
void Ranges ()
   {
   int ii, iii, x, xx;
   //Add ranges over period.  Count number of Sundays and exclude Sunday ranges.         
   DARg = 0; for(i=1; i<=Daily_Range_Period; i++)
       {
       if (TimeDayOfWeek(iTime(NULL,PERIOD_D1,i))!=0) {
       DARg = DARg + iHigh(NULL,PERIOD_D1,i)- iLow(NULL,PERIOD_D1,i);}
       else {x=x+1;}
       }
   //For number of Sundays, add additional days of range
   for(ii=i+1; ii<i+x+1; ii++) 
       {
       if (TimeDayOfWeek(iTime(NULL,PERIOD_D1,ii))!=0) {       
       DARg = DARg + iHigh(NULL,PERIOD_D1,ii)- iLow(NULL,PERIOD_D1,ii);}
       else {xx=xx+1;}       
       }      
   //If a Sunday reduced added days above, add additional day of range
   for(iii=ii+1; iii<ii+xx+1; iii++) 
       {
       DARg = DARg + iHigh(NULL,PERIOD_D1,iii)- iLow(NULL,PERIOD_D1,iii);
       }                     
   //Weekly ranges
   WARg = 0; for(i=1; i<=Weekly_Range_Period; i++)
       {
       WARg = WARg + iHigh(NULL,PERIOD_W1,i)- iLow(NULL,PERIOD_W1,i);
       }
   //Monthly ranges
   MARg = 0; for(i=1; i<=Monthly_Range_Period; i++)
       {
       MARg = MARg + iHigh(NULL,PERIOD_MN1,i)- iLow(NULL,PERIOD_MN1,i);
       }
  }
  
//+-------------------------------------------------------------------------------------------+
//| Subroutine To name and draw Range HL lines and line labels                |                                                                                  |
//+-------------------------------------------------------------------------------------------+
void DrawLines(string text, int Line_Selection_Number, double level, color Color, int linestyle, int thickness)
   {
   
   //Lines=====================================================================================  
   //Name lines 
   
   text = StringTrimLeft(text);       
   line = "[DWMRanges]  " + text + " Line";  

   //Define variables  
   a = linestyle; b = thickness; c =1; if (a==0)c=b;  
   //Where to Start lines
   if (Line_Selection_Number == 1) {startline = iTime(NULL, PERIOD_D1, 0);}
   else if(Line_Selection_Number == 2) {startline = iTime(NULL, PERIOD_W1, 0);}                  
   else if(Line_Selection_Number == 3) {startline = iTime(NULL, PERIOD_MN1, 0);}
                                                                   
   //Where to Stop Lines   
   stopline = Time[0]; R2 = true;
                       
   //Draw lines 
   if (ObjectFind(line) != 0)
      {
      ObjectCreate(line, OBJ_TREND, 0, startline, level, stopline, level);    
      ObjectSet(line, OBJPROP_STYLE, a);
      ObjectSet(line, OBJPROP_COLOR, Color);
      ObjectSet(line, OBJPROP_WIDTH, c);
      ObjectSet(line, OBJPROP_BACK, true); 
      ObjectSet(line, OBJPROP_RAY, R2);
      }
   else
      {
      ObjectMove(line, 0, startline, level);
      ObjectMove(line, 1, stopline, level);
      }
   
   //Labels===================================================================================
      //Name label       
      linelabel = "[DWMRanges]  " + StringTrimLeft(text) + " Label";
        
      //Where to put labels                          
           
         if (Time[WindowFirstVisibleBar()] < iTime(NULL, PERIOD_D1, 0)) //start at day separator
            {
            spc="       "; //07                           
            startlabel= iTime(NULL, PERIOD_D1, 0);  
            }          
         else //start start mid chart     
            {
         spc = ""; //00  
         startlabel = Time[WindowFirstVisibleBar()/2];                         
            }                        
                                    
      //Draw labels                            
      if (ObjectFind(linelabel) != 0)
         {
         ObjectCreate(linelabel, OBJ_TEXT, 0, startlabel, level);     
         ObjectSetText(linelabel, spc + text +" ("+ DoubleToStr(((level-Close[0])/Point)/Factor,0)+" pts)", Range_Labels_FontSize, Range_Labels_FontStyle, Range_Labels_Color);
         ObjectSet(linelabel, OBJPROP_BACK, false);
         }        
      else 
         {
         ObjectMove(linelabel, 0, startlabel, level);
         ObjectSetText(linelabel, spc + text +" ("+ DoubleToStr(((level-Close[0])/Point)/Factor,0)+" pts)", Range_Labels_FontSize, Range_Labels_FontStyle, Range_Labels_Color);
         }     
//      WindowRedraw();      
   }
   

//+-------------------------------------------------------------------------------------------+
//| Indicator End                                                                             |                                                        
//+-------------------------------------------------------------------------------------------+      

