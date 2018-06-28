
#property copyright "Traderathome, Copyright @ 2010"
#property link      "email: traderathome@msn.com"

#property indicator_chart_window

extern string Part_1 = "Indicator Display Controls:";
extern bool Indicator_ON = TRUE;
extern string Indicator_Max_Display_TF = "M";
extern bool Range_HL_Lines_Show = TRUE;
extern string Range_HL_Lines_Max_Display_TF = "M";
extern bool vLines_Show = TRUE;
extern int vLines_Server_GMToffset = 1;
extern string vLines_Max_Display_TF = "H1";
extern int Prior_Sessions_To_Show = 6;
extern string TF_Choices = "M1, M5, M15, M30, H1, H4, D, W, M";
extern string __ = "";
extern string Part_2 = "Market Panel Settings:";
extern bool Use_For_Forex = TRUE;
extern bool Display_5_Digits_Forex = TRUE;
extern bool Platform_Is_4_Digits = FALSE;
extern int Digits_To_Show_In_Spread = 1;
extern int Days_For_Range_Average = 10;
extern color Market_Panel_Color = C'30,30,30';
extern color Symbol_And_TF_Color = BurlyWood;
extern color Spread_Color = BurlyWood;
extern color Time_To_New_Bar_Color = BurlyWood;
extern color PriceLabel_UPColor = Lime;
extern color PriceLabel_DOWNColor = Red;
extern color PriceLabel_StaticColor = Yellow;
extern string ___ = "";
extern string Part_3 = "Range Lines Start/Stop Settings:";
extern string note2 = "Start lines at Day Separator, enter \'2\'";
extern string note3 = "Start lines at current candle, enter \'3\'";
extern int StartLines_Number = 3;
extern bool StopLines_At_Current_Candle = FALSE;
extern string ____ = "";
extern string Part_4 = "Range Lines Configuration:";
extern color RangeHigh_Color = Maroon;
extern color RangeLow_Color = Green;
extern int RG_LineStyle_01234 = 0;
extern int RG_SolidLineThickness = 4;
extern string _____ = "";
extern string Part_5 = "Range Lines Label Settings:";
extern color RangeLabels_Color = Yellow;
extern bool RangeLabels_Shown = TRUE;
extern string RangeLabels_FontStyle = "Arial Black";
extern int RangeLabels_FontSize = 10;
extern bool RangeLabels_Prices = TRUE;
extern bool RangeLabels_MaxRight = FALSE;
extern bool RangeLabelsLines_Subordinate = TRUE;
extern string ______ = "";
extern string Part_6 = "vLines Configuration:";
extern color vLines_Color = C'0x53,0x53,0x00';
extern int vLines_LineStyle_01234 = 2;
extern int vLines_SolidLineThickness = 1;
extern string _______ = "";
extern string Part_7 = "vLines Selection and Time Settings:";
extern bool Session_Lines_Shown = FALSE;
extern string Session_Lines_Label = "day";
extern bool Sydney_Open_Shown = FALSE;
extern string Sydney_Open_Label = " <   ";
extern int Sydney_Open_Time = 5;
extern bool Tokyo_Open_Shown = True;
extern string Tokyo_Open_Label = "Tokyo";
extern int Tokyo_Open_Time = 0;
extern bool Moscow_Open_Shown = FALSE;
extern string Moscow_Open_Label = "    M";
extern int Moscow_Open_Time = 4;
extern bool FrankFurt_Open_Shown = TRUE;
extern string Frankfurt_Open_Label = "Frankfurt";
extern int Frankfurt_Open_Time = 8;
extern bool London_Open_Shown = TRUE;
extern string London_Open_Label = "London";
extern int London_Open_Time = 9;
extern bool NewYork_Open_Shown = TRUE;
extern string NewYork_Open_Label = "New York";
extern int NewYork_Open_Time = 14;
extern string ________ = "";
extern string Part_8 = "vLines Label Settings:";
extern color vLineLabels_Color = DimGray;
extern string vLineLabels_FontStyle = "Arial Black";
extern int vLineLabels_FontSize = 8;
extern bool vLineLabels_Chart_Top = TRUE;
extern int vLineLabels_Dist_To_Border = 1;
int g_objs_total_512;
int gi_516;
int gi_520;
color g_color_528;
int gi_532;
int g_style_536;
int gi_540;
int g_width_544;
int g_objs_total_548;
int g_count_552;
int gi_556;
int gi_560;
int gi_564;
int gi_568;
int gi_572;
bool g_bool_576;
bool g_bool_580;
int gi_584;
int g_shift_588;
int gi_unused_592;
double g_bid_596;
double gd_604;
double gd_612;
double gd_620;
double gd_628;
double gd_636;
double gd_644;
double gd_668;
double gd_676;
double gd_684;
double gd_692;
double gd_700;
double gd_708;
double g_ihigh_716;
double g_ilow_724;
double gd_748;
int g_datetime_756;
int g_time_760;
int g_datetime_764;
int gi_768;
int g_shift_772;
string g_name_776 = "[Market Panel] Box1";
string g_name_784 = "[Market Panel] Box2";
string g_name_792 = "[Market Panel] Data1";
string g_name_800 = "[Market Panel] Data2";
string g_name_808 = "[Market Panel] Data3";
string g_name_816 = "[Market Panel] Data4";
string g_name_824 = "[Market Panel] Data5";
string gs_832;
string g_name_840;
string g_dbl2str_848;
string g_text_856;
string g_name_864;
string g_name_872;
string gs_880;
string gs_888;
string gs_896;
string g_name_904;
string g_name_912;
string gs_920;
bool gi_928;

int init() {
   gi_unused_592 = 0;
   gi_928 = FALSE;
   if (Use_For_Forex) {
      gs_832 = StringSubstr(Symbol(), 3, 3);
      if (Display_5_Digits_Forex) {
         if (gs_832 == "JPY") gi_520 = 3;
         else gi_520 = 5;
      } else {
         if (gs_832 == "JPY") gi_520 = 2;
         else gi_520 = 4;
      }
   }
   if (Digits == 5 || Digits == 3) gi_532 = 10;
   else gi_532 = 1;
   return (0);
}

int deinit() {
   g_objs_total_512 = ObjectsTotal();
   for (g_objs_total_548 = g_objs_total_512; g_objs_total_548 >= 0; g_objs_total_548--) {
      g_name_840 = ObjectName(g_objs_total_548);
      if (StringSubstr(g_name_840, 0, 14) == "[Market Panel]") ObjectDelete(g_name_840);
   }
   Comment("");
   return (0);
}

int start() {
   string ls_8;
   string ls_16;
   string ls_24;
   if (!Indicator_ON) {
      if (!gi_928) {
         deinit();
         gi_928 = TRUE;
      }
      return (0);
   }
   deinit();
   gi_928 = FALSE;
   if (Indicator_Max_Display_TF == "M1") gi_516 = 1;
   else {
      if (Indicator_Max_Display_TF == "M5") gi_516 = 5;
      else {
         if (Indicator_Max_Display_TF == "M15") gi_516 = 15;
         else {
            if (Indicator_Max_Display_TF == "M30") gi_516 = 30;
            else {
               if (Indicator_Max_Display_TF == "H1") gi_516 = 60;
               else {
                  if (Indicator_Max_Display_TF == "H4") gi_516 = 240;
                  else {
                     if (Indicator_Max_Display_TF == "D") gi_516 = 1440;
                     else {
                        if (Indicator_Max_Display_TF == "W") gi_516 = 10080;
                        else
                           if (Indicator_Max_Display_TF == "M") gi_516 = 43200;
                     }
                  }
               }
            }
         }
      }
   }
   if (Period() > gi_516) {
      deinit();
      return (-1);
   }
   ObjectCreate(g_name_776, OBJ_LABEL, 0, 0, 0, 0, 0);
   ObjectSetText(g_name_776, "g", 69, "Webdings");
   ObjectSet(g_name_776, OBJPROP_CORNER, 0);
   ObjectSet(g_name_776, OBJPROP_XDISTANCE, 0);
   ObjectSet(g_name_776, OBJPROP_YDISTANCE, 0);
   ObjectSet(g_name_776, OBJPROP_COLOR, Market_Panel_Color);
   ObjectSet(g_name_776, OBJPROP_BACK, FALSE);
   ObjectCreate(g_name_784, OBJ_LABEL, 0, 0, 0, 0, 0);
   ObjectSetText(g_name_784, "g", 69, "Webdings");
   ObjectSet(g_name_784, OBJPROP_CORNER, 0);
   ObjectSet(g_name_784, OBJPROP_XDISTANCE, 58);
   ObjectSet(g_name_784, OBJPROP_YDISTANCE, 0);
   ObjectSet(g_name_784, OBJPROP_COLOR, Market_Panel_Color);
   ObjectSet(g_name_784, OBJPROP_BACK, FALSE);
   g_text_856 = " ";
   if (Symbol() != "GBPUSD" || Symbol() != "EURUSD") g_text_856 = g_text_856 + " ";
   if (Period() == PERIOD_M1) g_text_856 = g_text_856 + "     " + Symbol() + "   M1";
   else {
      if (Period() == PERIOD_M5) g_text_856 = g_text_856 + "     " + Symbol() + "   M5";
      else {
         if (Period() == PERIOD_M15) g_text_856 = g_text_856 + "    " + Symbol() + "   M15";
         else {
            if (Period() == PERIOD_M30) g_text_856 = g_text_856 + "    " + Symbol() + "   M30";
            else {
               if (Period() == PERIOD_H1) g_text_856 = g_text_856 + "     " + Symbol() + "   H1";
               else {
                  if (Period() == PERIOD_H4) g_text_856 = g_text_856 + "     " + Symbol() + "   H4";
                  else {
                     if (Period() == PERIOD_D1) g_text_856 = g_text_856 + "   " + Symbol() + "   Daily";
                     else {
                        if (Period() == PERIOD_W1) g_text_856 = g_text_856 + " " + Symbol() + "   Weekly";
                        else
                           if (Period() == PERIOD_MN1) g_text_856 = g_text_856 + "" + Symbol() + "   Monthly";
                     }
                  }
               }
            }
         }
      }
   }
   ObjectCreate(g_name_792, OBJ_LABEL, 0, 0, 0);
   ObjectSet(g_name_792, OBJPROP_CORNER, 0);
   ObjectSet(g_name_792, OBJPROP_XDISTANCE, 0);
   ObjectSet(g_name_792, OBJPROP_YDISTANCE, 3);
   ObjectSet(g_name_792, OBJPROP_COLOR, Symbol_And_TF_Color);
   ObjectSetText(g_name_792, g_text_856, 11, "Arial Black");
   gd_604 = MarketInfo(Symbol(), MODE_SPREAD);
   gd_604 /= gi_532;
   ObjectCreate(g_name_800, OBJ_LABEL, 0, 0, 0);
   ObjectSet(g_name_800, OBJPROP_CORNER, 0);
   ObjectSet(g_name_800, OBJPROP_XDISTANCE, 34);
   ObjectSet(g_name_800, OBJPROP_YDISTANCE, 20);
   ObjectSet(g_name_800, OBJPROP_COLOR, Spread_Color);
   ObjectSetText(g_name_800, "Spread   " + DoubleToStr(gd_604, Digits_To_Show_In_Spread), 9, "Arial Black");
   Ranges(Days_For_Range_Average);
   gd_620 = gd_612 / Days_For_Range_Average / Point / gi_532;
   g_shift_588 = iBarShift(NULL, PERIOD_D1, Time[0]);
   g_ihigh_716 = iHigh(NULL, PERIOD_D1, g_shift_588);
   g_ilow_724 = iLow(NULL, PERIOD_D1, g_shift_588);
   gd_748 = (g_ihigh_716 - g_ilow_724) / Point / gi_532;
   if (!Platform_Is_4_Digits) gd_620 /= 10.0;
   ObjectCreate(g_name_824, OBJ_LABEL, 0, 0, 0);
   ObjectSet(g_name_824, OBJPROP_CORNER, 0);
   ObjectSet(g_name_824, OBJPROP_XDISTANCE, 34);
   ObjectSet(g_name_824, OBJPROP_YDISTANCE, 34);
   ObjectSet(g_name_824, OBJPROP_COLOR, Spread_Color);
   ObjectSetText(g_name_824, "Range    " + DoubleToStr(gd_620, 0) + ", " + DoubleToStr(gd_748, 0), 9, "Arial Black");
   gi_568 = Time[0] + 60 * Period() - TimeCurrent();
   gi_564 = gi_568 % 60;
   string ls_0 = gi_564;
   if (gi_564 < 10) ls_0 = "0" + ls_0;
   gi_560 = (gi_568 - gi_568 % 60) / 60;
   g_count_552 = 0;
   for (gi_556 = 0; gi_556 < 24; gi_556++) {
      if (gi_560 >= 60) {
         gi_560 -= 60;
         g_count_552++;
      }
      ls_8 = gi_560;
      if (gi_560 < 10) ls_8 = "0" + ls_8;
      ls_16 = g_count_552;
      if (g_count_552 < 10) ls_16 = "0" + ls_16;
      ls_24 = ls_8 + ":" + ls_0;
      if (g_count_552 >= 1) ls_24 = ls_16 + ":" + ls_8 + ":" + ls_0;
      if (Period() > PERIOD_D1) ls_24 = " (OFF)";
   }
   ObjectCreate(g_name_808, OBJ_LABEL, 0, 0, 0);
   ObjectSet(g_name_808, OBJPROP_CORNER, 0);
   ObjectSet(g_name_808, OBJPROP_XDISTANCE, 34);
   ObjectSet(g_name_808, OBJPROP_YDISTANCE, 48);
   ObjectSet(g_name_808, OBJPROP_COLOR, Time_To_New_Bar_Color);
   ObjectSetText(g_name_808, "Candle   " + ls_24, 9, "Arial Black");
   g_color_528 = PriceLabel_StaticColor;
   if (Bid > g_bid_596) g_color_528 = PriceLabel_UPColor;
   if (Bid < g_bid_596) g_color_528 = PriceLabel_DOWNColor;
   g_bid_596 = Bid;
   gs_888 = "  ";
   gs_896 = " ";
   if (Display_5_Digits_Forex) {
      gs_888 = " ";
      gs_896 = "";
   }
   if (Symbol() == "USDMXN") gs_888 = gs_896 + "";
   else {
      if (Symbol() == "XAUUSD") gs_888 = gs_896 + "";
      else {
         if (Symbol() == "USDJPY") gs_888 = gs_896 + "  ";
         else {
            if (Symbol() == "CHFJPY") gs_888 = gs_896 + "  ";
            else {
               if (Symbol() == "AUDJPY") gs_888 = gs_896 + "  ";
               else {
                  if (Symbol() == "CADJPY") gs_888 = gs_896 + "  ";
                  else
                     if (Symbol() == "XAGUSD") gs_888 = gs_896 + "  ";
               }
            }
         }
      }
   }
   if (Use_For_Forex) {
      if (Symbol() == "XAGUSD" || Symbol() == "XAUUSD") {
         gi_520 = 2;
         if (Display_5_Digits_Forex) gi_520 = 3;
      }
      g_dbl2str_848 = DoubleToStr(Bid, gi_520);
   } else g_dbl2str_848 = DoubleToStr(Bid, Digits);
   ObjectCreate(g_name_816, OBJ_LABEL, 0, 0, 0);
   ObjectSet(g_name_816, OBJPROP_CORNER, 0);
   ObjectSet(g_name_816, OBJPROP_XDISTANCE, 11);
   ObjectSet(g_name_816, OBJPROP_YDISTANCE, 61);
   ObjectSet(g_name_816, OBJPROP_COLOR, g_color_528);
   ObjectSetText(g_name_816, gs_888 + g_dbl2str_848, 18, "Arial Black");
   if (Range_HL_Lines_Show) {
      if (Range_HL_Lines_Max_Display_TF == "M1") gi_516 = 1;
      else {
         if (Range_HL_Lines_Max_Display_TF == "M5") gi_516 = 5;
         else {
            if (Range_HL_Lines_Max_Display_TF == "M15") gi_516 = 15;
            else {
               if (Range_HL_Lines_Max_Display_TF == "M30") gi_516 = 30;
               else {
                  if (Range_HL_Lines_Max_Display_TF == "H1") gi_516 = 60;
                  else {
                     if (Range_HL_Lines_Max_Display_TF == "H4") gi_516 = 240;
                     else {
                        if (Range_HL_Lines_Max_Display_TF == "D") gi_516 = 1440;
                        else {
                           if (Range_HL_Lines_Max_Display_TF == "W") gi_516 = 10080;
                           else
                              if (Range_HL_Lines_Max_Display_TF == "M") gi_516 = 43200;
                        }
                     }
                  }
               }
            }
         }
      }
      if (Period() <= gi_516) {
         Ranges(Days_For_Range_Average);
         gd_628 = NormalizeDouble(gd_612 / Days_For_Range_Average, 4);
         gd_636 = gd_628 + iLow(NULL, PERIOD_D1, 0);
         gd_644 = (-gd_628) + iHigh(NULL, PERIOD_D1, 0);
         if (g_ihigh_716 - g_ilow_724 > gd_628) {
            if (Bid >= g_ihigh_716 - (g_ihigh_716 - g_ilow_724) / 2.0) {
               gd_636 = g_ilow_724 + gd_628;
               gd_644 = g_ilow_724;
            } else {
               gd_636 = g_ihigh_716;
               gd_644 = g_ihigh_716 - gd_628;
            }
         }
         if (RG_LineStyle_01234 > 0) RG_SolidLineThickness = FALSE;
         Pivots(" RgH", gd_636, RangeHigh_Color, RG_LineStyle_01234, RG_SolidLineThickness);
         Pivots(" RgL", gd_644, RangeLow_Color, RG_LineStyle_01234, RG_SolidLineThickness);
      }
   }
   if (vLines_Show) {
      if (vLines_Max_Display_TF == "M1") gi_516 = 1;
      else {
         if (vLines_Max_Display_TF == "M5") gi_516 = 5;
         else {
            if (vLines_Max_Display_TF == "M15") gi_516 = 15;
            else {
               if (vLines_Max_Display_TF == "M30") gi_516 = 30;
               else {
                  if (vLines_Max_Display_TF == "H1") gi_516 = 60;
                  else {
                     if (vLines_Max_Display_TF == "H4") gi_516 = 240;
                     else {
                        if (vLines_Max_Display_TF == "D") gi_516 = 1440;
                        else {
                           if (vLines_Max_Display_TF == "W") gi_516 = 10080;
                           else
                              if (vLines_Max_Display_TF == "M") gi_516 = 43200;
                        }
                     }
                  }
               }
            }
         }
      }
      if (Period() <= gi_516) {
         if (vLineLabels_Dist_To_Border < 1) vLineLabels_Dist_To_Border = 1;
         gd_668 = WindowPriceMax();
         gd_676 = WindowPriceMin();
         gd_684 = gd_668 - gd_676;
         gd_692 = gd_684 / (9000 / vLineLabels_FontSize);
         gd_692 += vLineLabels_Dist_To_Border * gd_692;
         gd_700 = gd_684 / (500 / vLineLabels_FontSize);
         gd_700 += vLineLabels_Dist_To_Border * gd_700 / 20.0;
         gd_708 = gd_668 - gd_692;
         if (!vLineLabels_Chart_Top) gd_708 = gd_676 + gd_700;
         if (Session_Lines_Shown) {
            OpenToday(Session_Lines_Label, 0, vLines_Color, vLines_LineStyle_01234, vLines_SolidLineThickness, gd_708);
            OpenToday(" " + Session_Lines_Label, 24, vLines_Color, vLines_LineStyle_01234, vLines_SolidLineThickness, gd_708);
         }
         if (Sydney_Open_Shown) OpenToday(Sydney_Open_Label, Sydney_Open_Time, vLines_Color, vLines_LineStyle_01234, vLines_SolidLineThickness, gd_708);
         if (Tokyo_Open_Shown) OpenToday(Tokyo_Open_Label, Tokyo_Open_Time, vLines_Color, vLines_LineStyle_01234, vLines_SolidLineThickness, gd_708);
         if (Moscow_Open_Shown) OpenToday(Moscow_Open_Label, Moscow_Open_Time, vLines_Color, vLines_LineStyle_01234, vLines_SolidLineThickness, gd_708);
         if (FrankFurt_Open_Shown) OpenToday(Frankfurt_Open_Label, Frankfurt_Open_Time, vLines_Color, vLines_LineStyle_01234, vLines_SolidLineThickness, gd_708);
         if (London_Open_Shown) OpenToday(London_Open_Label, London_Open_Time, vLines_Color, vLines_LineStyle_01234, vLines_SolidLineThickness, gd_708);
         if (NewYork_Open_Shown) OpenToday(NewYork_Open_Label, NewYork_Open_Time, vLines_Color, vLines_LineStyle_01234, vLines_SolidLineThickness, gd_708);
         if (Prior_Sessions_To_Show > 0) {
            if (Period() == PERIOD_M1) gi_584 = 1440;
            else {
               if (Period() == PERIOD_M5) gi_584 = 288;
               else {
                  if (Period() == PERIOD_M15) gi_584 = 96;
                  else {
                     if (Period() == PERIOD_M30) gi_584 = 48;
                     else
                        if (Period() == PERIOD_H1) gi_584 = 24;
                  }
               }
            }
            g_shift_772 = iBarShift(NULL, 0, iTime(NULL, PERIOD_D1, 0));
            for (gi_556 = g_shift_772; gi_556 <= g_shift_772 + gi_584 * Prior_Sessions_To_Show; gi_556++) {
               g_count_552 = TimeHour(Time[gi_556]);
               gi_560 = TimeMinute(Time[gi_556]);
               if (Session_Lines_Shown && g_count_552 == 0 && gi_560 == 0) OpenPrior(gi_556, Session_Lines_Label, vLines_Color, vLines_LineStyle_01234, vLines_SolidLineThickness, gd_708);
               if (Sydney_Open_Shown && g_count_552 == Sydney_Open_Time + vLines_Server_GMToffset && gi_560 == 0) OpenPrior(gi_556, Sydney_Open_Label, vLines_Color, vLines_LineStyle_01234, vLines_SolidLineThickness, gd_708);
               if (Tokyo_Open_Shown && g_count_552 == Tokyo_Open_Time + vLines_Server_GMToffset && gi_560 == 0) OpenPrior(gi_556, Tokyo_Open_Label, vLines_Color, vLines_LineStyle_01234, vLines_SolidLineThickness, gd_708);
               if (Moscow_Open_Shown && g_count_552 == Moscow_Open_Time + vLines_Server_GMToffset && gi_560 == 0) OpenPrior(gi_556, Moscow_Open_Label, vLines_Color, vLines_LineStyle_01234, vLines_SolidLineThickness, gd_708);
               if (FrankFurt_Open_Shown && g_count_552 == Frankfurt_Open_Time + vLines_Server_GMToffset && gi_560 == 0) OpenPrior(gi_556, Frankfurt_Open_Label, vLines_Color, vLines_LineStyle_01234, vLines_SolidLineThickness, gd_708);
               if (London_Open_Shown && g_count_552 == London_Open_Time + vLines_Server_GMToffset && gi_560 == 0) OpenPrior(gi_556, London_Open_Label, vLines_Color, vLines_LineStyle_01234, vLines_SolidLineThickness, gd_708);
               if (NewYork_Open_Shown && g_count_552 == NewYork_Open_Time + vLines_Server_GMToffset && gi_560 == 0) OpenPrior(gi_556, NewYork_Open_Label, vLines_Color, vLines_LineStyle_01234, vLines_SolidLineThickness, gd_708);
            }
         }
      }
   }
   return (0);
}

void Pivots(string as_0, double a_price_8, color a_color_16, int a_style_20, int ai_24) {
   g_name_864 = "[Market Panel]  " + StringTrimLeft(as_0) + " Line";
   gi_768 = Time[1];
   if (Time[0] > iTime(NULL, PERIOD_D1, 0)) gi_768 = iTime(NULL, PERIOD_D1, 0);
   g_time_760 = Time[0];
   g_style_536 = a_style_20;
   gi_540 = ai_24;
   g_width_544 = 1;
   if (g_style_536 == STYLE_SOLID) g_width_544 = gi_540;
   g_bool_576 = TRUE;
   g_bool_580 = TRUE;
   gi_572 = 2;
   if (!RangeLabelsLines_Subordinate) g_bool_580 = FALSE;
   if (StopLines_At_Current_Candle && StartLines_Number != 3) g_bool_576 = FALSE;
   if (StartLines_Number == 2) g_datetime_756 = gi_768;
   else g_datetime_756 = Time[1];
   if (ObjectFind(g_name_864) != 0) {
      ObjectCreate(g_name_864, gi_572, 0, g_datetime_756, a_price_8, g_time_760, a_price_8);
      ObjectSet(g_name_864, OBJPROP_STYLE, a_style_20);
      ObjectSet(g_name_864, OBJPROP_COLOR, a_color_16);
      ObjectSet(g_name_864, OBJPROP_WIDTH, g_width_544);
      ObjectSet(g_name_864, OBJPROP_BACK, g_bool_580);
      ObjectSet(g_name_864, OBJPROP_RAY, g_bool_576);
   } else {
      ObjectMove(g_name_864, 0, g_datetime_756, a_price_8);
      ObjectMove(g_name_864, 1, g_time_760, a_price_8);
   }
   if (StringSubstr(as_0, 1, 2) == "Rg" && !RangeLabels_Shown) return;
   g_name_872 = "[Market Panel]  " + StringTrimLeft(as_0) + " Label";
   if (RangeLabels_Prices && StrToInteger(as_0) == 0) {
      if (Use_For_Forex) g_dbl2str_848 = DoubleToStr(a_price_8, gi_520);
      else g_dbl2str_848 = DoubleToStr(a_price_8, Digits);
      as_0 = as_0 + "   " + g_dbl2str_848;
   }
   gs_880 = "   ";
   as_0 = gs_880 + as_0;
   g_bool_580 = TRUE;
   if (!RangeLabelsLines_Subordinate) g_bool_580 = FALSE;
   if (RangeLabels_MaxRight) {
      if (!RangeLabels_Prices) gs_888 = "                                ";
      else gs_888 = "                                              ";
      g_datetime_764 = Time[0];
   } else {
      if (StartLines_Number == 2) {
         if (!RangeLabels_Prices) gs_888 = "           ";
         else gs_888 = "                         ";
         g_datetime_764 = iTime(NULL, PERIOD_D1, 0);
      } else {
         if (!RangeLabels_Prices) gs_888 = "           ";
         else gs_888 = "                         ";
         g_datetime_764 = Time[0];
      }
   }
   if (ObjectFind(g_name_872) != 0) {
      ObjectCreate(g_name_872, OBJ_TEXT, 0, g_datetime_764, a_price_8);
      ObjectSetText(g_name_872, gs_888 + as_0, RangeLabels_FontSize, RangeLabels_FontStyle, RangeLabels_Color);
      ObjectSet(g_name_872, OBJPROP_BACK, g_bool_580);
      return;
   }
   ObjectMove(g_name_872, 0, g_datetime_764, a_price_8);
}

void Ranges(int ai_unused_0) {
   int li_12;
   int li_16;
   gd_612 = 0;
   for (gi_556 = 1; gi_556 <= Days_For_Range_Average; gi_556++) {
      if (TimeDayOfWeek(iTime(NULL, PERIOD_D1, gi_556)) != 0) gd_612 = gd_612 + iHigh(NULL, PERIOD_D1, gi_556) - iLow(NULL, PERIOD_D1, gi_556);
      else li_12++;
   }
   for (int li_4 = gi_556 + 1; li_4 < gi_556 + li_12 + 1; li_4++) {
      if (TimeDayOfWeek(iTime(NULL, PERIOD_D1, li_4)) != 0) gd_612 = gd_612 + iHigh(NULL, PERIOD_D1, li_4) - iLow(NULL, PERIOD_D1, li_4);
      else li_16++;
   }
   for (int li_8 = li_4 + 1; li_8 < li_4 + li_16 + 1; li_8++) gd_612 = gd_612 + iHigh(NULL, PERIOD_D1, li_8) - iLow(NULL, PERIOD_D1, li_8);
}

void OpenToday(string as_0, int a_datetime_8, color a_color_12, int ai_16, int ai_20, double a_price_24) {
   g_name_904 = "[Market Panel] " + StringTrimLeft(as_0) + " Current Session Line";
   g_name_912 = "[Market Panel] " + StringTrimLeft(as_0) + " Current Session Label";
   g_style_536 = ai_16;
   gi_540 = ai_20;
   g_width_544 = 1;
   if (g_style_536 == STYLE_SOLID) g_width_544 = gi_540;
   gi_568 = a_datetime_8;
   if (as_0 != Session_Lines_Label && as_0 != " " + Session_Lines_Label) a_datetime_8 += vLines_Server_GMToffset;
   gs_920 = TimeYear(iTime(NULL, 0, 0)) + "." + TimeMonth(iTime(NULL, 0, 0)) + "." + TimeDay(iTime(NULL, PERIOD_D1, 0)) + "." + a_datetime_8 + ":" + "00";
   if (a_datetime_8 == 24) gs_920 = TimeYear(iTime(NULL, 0, 0)) + "." + TimeMonth(iTime(NULL, 0, 0)) + "." + TimeDay(iTime(NULL, PERIOD_D1, 0)) + "." + a_datetime_8 + 23 + ":" + "60";
   a_datetime_8 = StrToTime(gs_920);
   if (gi_568 == 24) a_datetime_8 += 60;
   if (ObjectFind(g_name_904) != 0) {
      ObjectCreate(g_name_904, OBJ_TREND, 0, a_datetime_8, 0, a_datetime_8, 100);
      ObjectSet(g_name_904, OBJPROP_STYLE, g_style_536);
      ObjectSet(g_name_904, OBJPROP_WIDTH, g_width_544);
      ObjectSet(g_name_904, OBJPROP_COLOR, a_color_12);
      ObjectSet(g_name_904, OBJPROP_BACK, TRUE);
   } else {
      ObjectMove(g_name_904, 0, a_datetime_8, 0);
      ObjectMove(g_name_904, 1, a_datetime_8, 100);
   }
   if (ObjectFind(g_name_912) != 0) {
      ObjectCreate(g_name_912, OBJ_TEXT, 0, a_datetime_8, a_price_24);
      ObjectSetText(g_name_912, as_0, vLineLabels_FontSize, vLineLabels_FontStyle, vLineLabels_Color);
      ObjectSet(g_name_912, OBJPROP_BACK, TRUE);
      return;
   }
   ObjectMove(g_name_912, 0, a_datetime_8, a_price_24);
}

void OpenPrior(int ai_0, string as_4, color a_color_12, int ai_16, int ai_20, double a_price_24) {
   g_name_904 = "[Market Panel] " + StringTrimLeft(as_4) + " Prior Session  " + ((ai_0 - 1)) + " Line";
   g_name_912 = "[Market Panel] " + StringTrimLeft(as_4) + " Prior Session  " + ((ai_0 - 1)) + " Label";
   g_style_536 = ai_16;
   gi_540 = ai_20;
   g_width_544 = 1;
   if (g_style_536 == STYLE_SOLID) g_width_544 = gi_540;
   if (ObjectFind(g_name_904) != 0) {
      ObjectCreate(g_name_904, OBJ_TREND, 0, Time[ai_0], 0, Time[ai_0], 100);
      ObjectSet(g_name_904, OBJPROP_STYLE, g_style_536);
      ObjectSet(g_name_904, OBJPROP_WIDTH, g_width_544);
      ObjectSet(g_name_904, OBJPROP_COLOR, a_color_12);
      ObjectSet(g_name_904, OBJPROP_BACK, TRUE);
   } else {
      ObjectMove(g_name_904, 0, Time[ai_0], 0);
      ObjectMove(g_name_904, 1, Time[ai_0], 100);
   }
   if (ObjectFind(g_name_912) != 0) {
      ObjectCreate(g_name_912, OBJ_TEXT, 0, Time[ai_0], a_price_24);
      ObjectSetText(g_name_912, as_4, vLineLabels_FontSize, vLineLabels_FontStyle, vLineLabels_Color);
      ObjectSet(g_name_912, OBJPROP_BACK, TRUE);
      return;
   }
   ObjectMove(g_name_912, 0, Time[ai_0], a_price_24);
}