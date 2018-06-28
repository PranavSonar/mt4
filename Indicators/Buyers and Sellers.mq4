//|   Buyers and Sellers_TRO_MODIFIED_VERSION                        |
//| MODIFIED BY AVERY T. HORTON, JR. AKA THERUMPLEDONE@GMAIL.COM     |
//| I am NOT the ORIGINAL author                                     |
//  and I am not claiming authorship of this indicator.              |
//  All I did was modify it. I hope you find my modifications useful.|
//|                                                                  |
//|   GIFTS AND DONATIONS ACCEPTED                                   | 
//|                                                                  |
//|   Gifts or Donations also keep me motivated in producing more    |
//|   great free indicators. :-)                                     |
//|                                                                  |
//|   PayPal - THERUMPLEDONE@GMAIL.COM                               |  
//+------------------------------------------------------------------+
//----
#property indicator_chart_window

int init()
  {
   return(0);
  }

int deinit()
  {
   return(0);
  }

int start()
  {
   

double bullp = (iBullsPower(NULL, 0, 13,PRICE_CLOSE,0));
double bearp = (iBearsPower(NULL, 0, 13,PRICE_CLOSE,0));
double vol = iVolume(Symbol(),0,0);
double Buyers = (bullp * vol) / (bullp + bearp);
double Sellers = (bearp * vol) / (bullp + bearp);

string lbl[4], lbl2[4];
int n=80;
lbl[0] = "L1";
lbl2[0] = "B: "+DoubleToStr(Buyers,0);
lbl[1] = "L2";
lbl2[1] = "S: "+DoubleToStr(Sellers,0);
lbl[2] = "L3";
double pwr;
if (Buyers > Sellers) {pwr = Buyers / Sellers;}
if (Buyers < Sellers) {pwr = Sellers / Buyers;}
lbl2[2] = "Power: "+DoubleToStr(pwr,1);
lbl[3] = "L4";
lbl2[3] = "Margin: "+DoubleToStr((AccountMargin()/AccountEquity())*100,0)+"%";

for (int u=0;u<ArraySize(lbl);u++)
{
ObjectCreate(lbl[u],23,0,Time[0],PRICE_CLOSE);

ObjectSet(lbl[u],OBJPROP_XDISTANCE,20);
ObjectSet(lbl[u],OBJPROP_YDISTANCE,n);
ObjectSetText(lbl[u],lbl2[u],18,"Arial",LightGray);
ObjectSet(lbl[u],OBJPROP_CORNER,0);
n = n+22;
}   
   return(0);
  }

