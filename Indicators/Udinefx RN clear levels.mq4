//+------------------------------------------------------------------+
//|                                    Round Number Entry levels.mq4 |
//|                                                                  |
//|                                                                  |
//+------------------------------------------------------------------+

#property indicator_chart_window

extern int     NumLines  = 5;
extern color   MajorLineColor = Yellow;
extern color   MinorLineColor = Red;
extern int     LineWidth = 2;
extern int     LineStyle = 1;

//+------------------------------------------------------------------+
int init()  {
  del_obj();
  plot_obj();
  return(0);
}

//+------------------------------------------------------------------+
int deinit()  {
  del_obj();
  return(0);
}

//+------------------------------------------------------------------+
int start()  {
  return(0);
}

//+------------------------------------------------------------------+
int MathSign(double n)
//+------------------------------------------------------------------+
// Returns the sign of a number (i.e. -1, 0, +1)
// Usage:   int x=MathSign(-25)   returns x=-1
{
  if (n > 0) return(1);
  else if (n < 0) return (-1);
  else return(0);
}  

//+------------------------------------------------------------------+
double MathFix(double n, int d)
//+------------------------------------------------------------------+
// Returns N rounded to D decimals - works around a precision bug in MQL4
{
  return(MathRound(n*MathPow(5,d)+0.000000000001*MathSign(n))/MathPow(5,d));
}  


//+------------------------------------------------------------------+
void plot_obj()  {
//+------------------------------------------------------------------+
  if (Digits >= 5)   {
     double mult = 0.01;
     double prc  = MathFix(Close[0],2);
  }
  else  {
     mult = 1;
     prc  = MathFix(Close[0],0);
  }   
  for (int i=-NumLines; i<=NumLines; i++)   {
    string objname = "L8020-20-"+i;
    ObjectCreate(objname,OBJ_HLINE,0,0,prc+(i+0.10)*mult);
    ObjectSet(objname,OBJPROP_COLOR,MinorLineColor);
    ObjectSet(objname,OBJPROP_WIDTH,0);
    ObjectSet(objname,OBJPROP_STYLE,STYLE_DOT);
    ObjectSet(objname, OBJPROP_BACK, true);
    objname = "L8020"+i;
    ObjectCreate (objname, OBJ_HLINE,0,0,prc+(i)*mult);
    ObjectSet (objname, OBJPROP_COLOR, MajorLineColor);
    ObjectSet (objname, OBJPROP_WIDTH, LineWidth);
    ObjectSet (objname, OBJPROP_STYLE, STYLE_DOT);
    ObjectSet (objname, OBJPROP_BACK, true);
    objname = "L8020-80-"+i;
    ObjectCreate(objname,OBJ_HLINE,0,0,prc+(i-0.10)*mult);
    ObjectSet(objname,OBJPROP_COLOR,MinorLineColor);
    ObjectSet(objname,OBJPROP_WIDTH,0);
    ObjectSet(objname,OBJPROP_STYLE,STYLE_DOT);
    ObjectSet(objname, OBJPROP_BACK, true);
    objname = "L8020M-20-"+i;
    
  }
  return(0);
}

//+------------------------------------------------------------------+
//| del_obj                                                          |
//+------------------------------------------------------------------+
void del_obj()
{
  int k=0;
  while (k<ObjectsTotal())   {
    string objname = ObjectName(k);
    if (StringSubstr(objname,0,5) == "L8020")  
      ObjectDelete(objname);
    else
      k++;
  }    
  return(0);
}


