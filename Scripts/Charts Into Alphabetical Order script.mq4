//+------------------------------------------------------------------+
//|     Copy template/period and put all charts in alphabetical order|
//|                            (by deleting them and starting again!)|
//|                                                             Arts |
//+------------------------------------------------------------------+
#property strict

int INDEX[28];
string PAIRS[28]= {"AUDCAD","AUDCHF","AUDJPY","AUDNZD","AUDUSD","CADCHF","CADJPY","CHFJPY","EURAUD","EURCAD","EURCHF","EURGBP","EURJPY","EURNZD",
                    "EURUSD","GBPAUD","GBPCAD","GBPCHF","GBPJPY","GBPNZD","GBPUSD","NZDCAD","NZDCHF","NZDJPY","NZDUSD","USDCAD","USDCHF","USDJPY"};
//+------------------------------------------------------------------+
//| Script program start function                                    |
//+------------------------------------------------------------------+
void OnStart()
{
   ArrayInitialize(INDEX,-1);  
 
   string FileName = "temp_template"; //file name to save current template
   long CurrentChart = ChartID();//get current chart ID
   ChartSaveTemplate(0, FileName);//save current template
   int period=Period();
   int n=0;
 
   //record all charts
   long Chart = ChartFirst();
   while (Chart >= 0)
     {
      for(int p=0; p<28; p++) {if(PAIRS[p]==ChartSymbol(Chart)){INDEX[n]=p;}}
      n++;
      Chart = ChartNext(Chart); //get next chart
     }   
 
   ArraySort(INDEX,WHOLE_ARRAY,0, MODE_ASCEND);
 
   //delete existing charts
   Chart = ChartFirst();
   while (Chart >= 0)
     {
      long ChartCL=Chart;
      Chart = ChartNext(Chart); //get next chart
      if(ChartCL!=CurrentChart)ChartClose(ChartCL);
     }
   Sleep(2000);
   
   //create new charts in order
   for(int p=0; p<28; p++)
     {if(INDEX[p]>=0){long cn=ChartOpen(PAIRS[INDEX[p]],period); ChartApplyTemplate(cn, FileName);}
     }  
   ChartClose(CurrentChart);
    
}
//+------------------------------------------------------------------+