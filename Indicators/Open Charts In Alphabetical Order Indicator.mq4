//+-------------------------------------------------------------------+
//|  Copy template/period to selected new charts in alphabetical order|
//|                                                               Arts|
//+-------------------------------------------------------------------+
#property strict
#property indicator_chart_window

int INDEX[28];
string PAIRS[28]= {"AUDCAD","AUDCHF","AUDJPY","AUDNZD","AUDUSD","CADCHF","CADJPY","CHFJPY","EURAUD","EURCAD","EURCHF","EURGBP","EURJPY","EURNZD",
                   "EURUSD","GBPAUD","GBPCAD","GBPCHF","GBPJPY","GBPNZD","GBPUSD","NZDCAD","NZDCHF","NZDJPY","NZDUSD","USDCAD","USDCHF","USDJPY"};
int xx[28]={20,20,20,20,20,20,20,125,125,125,125,125,125,125,230,230,230,230,230,230,230,335,335,335,335,335,335,335};                     
int yy[28]={110,135,160,185,210,235,260,110,135,160,185,210,235,260,110,135,160,185,210,235,260,110,135,160,185,210,235,260};

int period; 
string FileName; 
long CurrentChart, cn;

//+------------------------------------------------------------------+
void OnInit()
  {
   Open_gui();
   ArrayInitialize(INDEX,1);  
   FileName = "temp_template";
   CurrentChart = ChartID();//get current chart ID
   ChartSaveTemplate(0, FileName);//save current template
   period=Period();
  }
//+------------------------------------------------------------------+
void deinit() {Close_gui();}

//+------------------------------------------------------------------+
void OnChartEvent(const int id,         // Event identifier  
                  const long& lparam,   // Event parameter of long type
                  const double& dparam, // Event parameter of double type
                  const string& sparam) // Event parameter of string type
  {
   if(id==CHARTEVENT_OBJECT_CLICK)
      { 
       for(int c=0; c<28; c++)
           {
            if(sparam=="gui_"+IntegerToString(c))
               {if(ObjectGet(sparam,OBJPROP_STATE))
                     {INDEX[c]=-1;
                      ObjectSetInteger(0,sparam,OBJPROP_COLOR,clrSlateGray);
                      ObjectSetInteger(0,sparam,OBJPROP_BORDER_COLOR,clrLightBlue);
                      ObjectSetInteger(0, sparam,OBJPROP_BGCOLOR,clrLightBlue);
                      ObjectSetInteger(0, sparam,OBJPROP_FONTSIZE,9);
                     }
                else {INDEX[c]=1;
                      ObjectSetInteger(0,sparam,OBJPROP_COLOR,clrNavy);
                      ObjectSetInteger(0,sparam,OBJPROP_BORDER_COLOR,clrOrangeRed);
                      ObjectSetInteger(0, sparam,OBJPROP_BGCOLOR,clrOrangeRed);
                      ObjectSetInteger(0, sparam,OBJPROP_FONTSIZE,11);
                     }  
               } 
           }
       if(sparam=="gui_ok" && ObjectGet(sparam,OBJPROP_STATE))
           {//create new charts in order
            for(int p=0; p<28; p++)
                {if(INDEX[p]>=0){cn=ChartOpen(PAIRS[p],period); ChartApplyTemplate(cn, FileName); ChartIndicatorDelete(cn,0,"Open Charts In Alphabetical Order Indicator"); Close_gui();} }  
            ChartClose(CurrentChart);   
           }    
      }
  }       
//+------------------------------------------------------------------+
void start()
   { }
//+------------------------------------------------------------------+
void Open_gui()
   {string name="gui_";
    int x=5, y=5;
    color clrtx=clrNavy, clrbg=clrOrangeRed;
    RectLabelCreate(0,name+"R", 0, x, y,445,290, clrBlue, BORDER_FLAT, CORNER_LEFT_UPPER, clrWhite, STYLE_SOLID, 4, false, false, true, 0) ;
    string tf; if(Period()<60)tf=IntegerToString(Period())+" Minutes"; if(Period()==60)tf="1 Hour";  if(Period()==240)tf="4 Hours"; if(Period()==1440)tf="1 Day";  
    if(Period()==10080)tf="1 Week";if(Period()==43200)tf="1 Month";
    objectCreate(name+"sc", CORNER_LEFT_UPPER,0, x+10, y+10,  "Open New Charts in Alphabetical Order", 12, "Arial Black", clrGold, false); 
    objectCreate(name+"sc1", CORNER_LEFT_UPPER,0, x+10, y+30,  "(using current chart timeframe and template)", 9, "Arial Black", clrGold, false); 
    objectCreate(name+"TF", CORNER_LEFT_UPPER,0, x+10, y+50,  "Time Frame : "+tf, 10, "Arial Black", clrAqua, false); 
    objectCreate(name+"Sl", CORNER_LEFT_UPPER,0, x+10, y+75,  "Click Pairs to ", 10, "Arial Black", clrWhite, false); 
    objectCreate(name+"S/", CORNER_LEFT_UPPER,0, x+198, y+75,  "/", 10, "Arial Black", clrWhite, false); 
    ButtonCreate(0,name+"se",0, x+125, y+75, 65, 20, CORNER_LEFT_UPPER, "Select", "Arial Black", 10, clrtx, clrbg, clrbg, false, false, false, false, 0) ; 
    ButtonCreate(0,name+"de",0, x+210, y+75, 65, 20, CORNER_LEFT_UPPER, "Deselect", "Arial Black", 9, clrSlateGray, clrLightBlue, clrLightBlue, false, false, false, false, 0) ; 
    ButtonCreate(0,name+"ok",0, x+350, y+50, 60, 30, CORNER_LEFT_UPPER, "OK", "Arial Black", 12, clrNavy, clrWhite, clrWhite, false, false, false, false, 0) ; 
    for(int c=0; c<28; c++)
        {ButtonCreate(0,name+IntegerToString(c),0, xx[c], yy[c], 100, 20, CORNER_LEFT_UPPER, PAIRS[c], "Arial Black", 11, clrtx, clrbg, clrbg, false, false, false, false, 0);}
   }
//------------------------------------------------------------------+
void Close_gui() 
   { int OBjTotal=ObjectsTotal();
      for (int i=OBjTotal-1; i>=0; i--) 
           {
            if(StringSubstr(ObjectName(i),0, 4)=="gui_")ObjectDelete(cn, ObjectName(i));
           }
   }   
//+------------------------------------------------------------------+
bool RectLabelCreate(const long             chart_ID=0,               // chart's ID
                     const string           name="RectLabel",         // label name
                     const int              sub_window=0,             // subwindow index
                     const int              x=0,                      // X coordinate
                     const int              y=0,                      // Y coordinate
                     const int              width=50,                 // width
                     const int              height=18,                // height
                     const color            back_clr=C'236,233,216',  // background color
                     const ENUM_BORDER_TYPE border=BORDER_SUNKEN,     // border type
                     const ENUM_BASE_CORNER crner=CORNER_LEFT_UPPER, // chart corner for anchoring
                     const color            clr=clrRed,               // flat border color (Flat)
                     const ENUM_LINE_STYLE  style=STYLE_SOLID,        // flat border style
                     const int              line_width=1,             // flat border width
                     const bool             back=false,               // in the background
                     const bool             selection=false,          // highlight to move
                     const bool             hidden=true,              // hidden in the object list
                     const long             z_order=0)                // priority for mouse click
  {
   ObjectCreate(chart_ID,name,OBJ_RECTANGLE_LABEL,sub_window,0,0);
   ObjectSetInteger(chart_ID,name,OBJPROP_XDISTANCE,x);
   ObjectSetInteger(chart_ID,name,OBJPROP_YDISTANCE,y);
   ObjectSetInteger(chart_ID,name,OBJPROP_XSIZE,width);
   ObjectSetInteger(chart_ID,name,OBJPROP_YSIZE,height);
   ObjectSetInteger(chart_ID,name,OBJPROP_BGCOLOR,back_clr);
   ObjectSetInteger(chart_ID,name,OBJPROP_BORDER_TYPE,border);
   ObjectSetInteger(chart_ID,name,OBJPROP_CORNER,crner);
   ObjectSetInteger(chart_ID,name,OBJPROP_COLOR,clr);
   ObjectSetInteger(chart_ID,name,OBJPROP_STYLE,style);
   ObjectSetInteger(chart_ID,name,OBJPROP_WIDTH,line_width);
   ObjectSetInteger(chart_ID,name,OBJPROP_BACK,back);
   ObjectSetInteger(chart_ID,name,OBJPROP_SELECTABLE,selection);
   ObjectSetInteger(chart_ID,name,OBJPROP_SELECTED,selection);
   ObjectSetInteger(chart_ID,name,OBJPROP_HIDDEN,hidden);
   ObjectSetInteger(chart_ID,name,OBJPROP_ZORDER,z_order);
   return(true);
  }   
//----------------------------------------------------------
bool ButtonCreate(const long              chart_ID=0,               // chart's ID
                  const string            name="Button",            // button name
                  const int               sub_window=0,             // subwindow index
                  const int               x=0,                      // X coordinate
                  const int               y=0,                      // Y coordinate
                  const int               width=50,                 // button width
                  const int               height=18,                // button height
                  const ENUM_BASE_CORNER  crner=CORNER_LEFT_UPPER,  // chart corner for anchoring
                  const string            text="Button",            // text
                  const string            font="Arial",             // font
                  const int               font_size=10,             // font size
                  const color             clr=clrBlack,             // text color
                  const color             back_clr=C'236,233,216',  // background color
                  const color             border_clr=clrNONE,       // border color
                  const bool              state=false,              // pressed/released
                  const bool              back=false,               // in the background
                  const bool              selection=false,          // highlight to move
                  const bool              hidden=true,              // hidden in the object list
                  const long              z_order=0)                // priority for mouse click
  {
   ObjectCreate(chart_ID,name,OBJ_BUTTON,sub_window,0,0);
   ObjectSetInteger(chart_ID,name,OBJPROP_XDISTANCE,x);
   ObjectSetInteger(chart_ID,name,OBJPROP_YDISTANCE,y);
   ObjectSetInteger(chart_ID,name,OBJPROP_XSIZE,width);
   ObjectSetInteger(chart_ID,name,OBJPROP_YSIZE,height);
   ObjectSetInteger(chart_ID,name,OBJPROP_CORNER,crner);
   ObjectSetString(chart_ID,name,OBJPROP_TEXT,text);
   ObjectSetString(chart_ID,name,OBJPROP_FONT,font);
   ObjectSetInteger(chart_ID,name,OBJPROP_FONTSIZE,font_size);
   ObjectSetInteger(chart_ID,name,OBJPROP_COLOR,clr);
   ObjectSetInteger(chart_ID,name,OBJPROP_BGCOLOR,back_clr);
   ObjectSetInteger(chart_ID,name,OBJPROP_BORDER_COLOR,border_clr);
   ObjectSetInteger(chart_ID,name,OBJPROP_BACK,back);
   ObjectSetInteger(chart_ID,name,OBJPROP_SELECTABLE,selection);
   ObjectSetInteger(chart_ID,name,OBJPROP_STATE,state);
   ObjectSetInteger(chart_ID,name,OBJPROP_HIDDEN,hidden);
   ObjectSetInteger(chart_ID,name,OBJPROP_ZORDER,z_order);
   return(true);
  }
//------------------------------------------------------------------+
void objectCreate(const string name, const ENUM_BASE_CORNER crner=CORNER_LEFT_UPPER, const int wn=0, const int xxx=0, const int yyy=0,
                  const string text="-", const int size=84, const string font="Arial", const color colourav=CLR_NONE, const bool bg=false)
  {
   ObjectCreate(name,OBJ_LABEL,wn,0,0);
   ObjectSet(name,OBJPROP_CORNER,crner);
   ObjectSet(name,OBJPROP_COLOR,colourav);
   ObjectSet(name,OBJPROP_XDISTANCE,xxx);
   ObjectSet(name,OBJPROP_YDISTANCE,yyy);
   ObjectSet(name,OBJPROP_BACK,bg);
   ObjectSetText(name,text,size,font,colourav);  
   ObjectSetInteger(0,name,OBJPROP_SELECTABLE,false);
  }
