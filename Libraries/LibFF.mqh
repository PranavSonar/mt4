//+------------------------------------------------------------------+
//|                                                        LibFF.mqh |
//|                                                         renexxxx |
//|                                http://www.stevehopwoodforex.com/ |
//| This library was developed by renexxxx from the                  |
//|    http://www.stevehopwoodforex.com/ forum.                      |
//|                                                                  |
//| version 0.1   initial release (RZ)                               |
//|------------------------------------------------------------------+
#property copyright "renexxxx"
#property link      "http://www.stevehopwoodforex.com/"
#property version   "1.00"
#property strict

#include <mql4-http.mqh>
#include <Object.mqh>
#include <Arrays\ArrayObj.mqh>

enum IMPACT {
   UNKNOWN=-1,
   LOW=1,
   MEDIUM=2,
   HIGH=3 };

#define capacity  1000

class CNEWS_ITEM : public CObject {
public:
   string ni_title;
   string ni_country;
   datetime ni_datetime;
   IMPACT ni_impact;
   string ni_forecast;
   string ni_previous;
   
   /*--------------------------------------------------------------------------------
   Ok, here we go for my rant ...
   These fucking russian clowns, who came up with this STANDARD library, have apparently
   never done a class in Object Oriented Programming. The idea of this Compare() method is good:
   It allows for the container object to sort its elements, by being able to compare two nodes. 
   The nodes can be derivative classes from CObject. However, since the Compare() method of the 
   base class (CObject) was defined as int Compare(const CObject *node, const int mode=0) (i.e. with 
   a 'const' pointer), the derivative class (CNEWS_ITEM), can not downcast the (CObject *) pointer to (CNEWS_ITEM *),
   and therefore, access to the specific data of CNEWS_ITEM is not allowed. Therefore, it is not
   possible to overwrite the Compare() method, and therefore the whole fucking library is useless.
   
   We have to create our own sorting routines, as the code below does not work: In fact it compiles
   but it hangs MT4 ... Welcome to my world!
   /*--------------------------------------------------------------------------------
   //--- method of comparing the objects
   int   Compare(const CObject *node, const int mode=0 ) const {
      PrintFormat("Calling Compare(): sortMode = %d", mode );
      CNEWS_ITEM *special_node = (CNEWS_ITEM *)node;
      switch(mode) {
         case 1: return( ( this.ni_pubDate < special_node.ni_pubDate ) ? -1 : 1 );
         case -1: return( ( this.ni_pubDate > special_node.ni_pubDate ) ? -1 : 1 );
         case 2: return( ( this.ni_title < special_node.ni_title ) ? -1 : 1 );
         case -2:return( ( this.ni_title > special_node.ni_title ) ? -1 : 1 );
         default: return( ( this.ni_pubDate < special_node.ni_pubDate ) ? -1 : 1 );
      }
      return(0);
   }*/
};

void getNews( CArrayObj* news, string ffURL ) {

   int i;
   string webData[];   
   string webFF = httpGET(ffURL);
   
   // Clear news array
   news.Shutdown();

   int stringsCount = StringSplit( webFF, StringGetCharacter(">",0), webData );
   // Re-Add the ">"-character that was regarded as a divider, but it part of the data
   for(i=0; i<stringsCount;i++) webData[i] = webData[i]+">";
            
   string tags[];    // array for storing the tags
   int startPos[][2];// tag begin coordinates
   int endPos[][2];  // tag end coordinates
   
   FillTagStructure(tags, startPos, endPos, webData);
   int tagsNumber = ArraySize(tags);
   
   string text = "";
   string currTag;
   int begin[1][2];
   int end[1][2];
   
   CNEWS_ITEM* a_news_item;

   string my_title, my_country, my_forecast, my_previous, my_impact, my_date, my_time;
   
   for (i = 0; i < tagsNumber; i++) {
      currTag = tags[i];     

      if (currTag == "<weeklyevents>") {
            //Print("Calendar data begin;");
      }
      else if (currTag == "<event>") {
         my_title = " ";
         my_country = " ";
         my_forecast = " ";
         my_previous = " ";
         my_date = " ";
         my_time = " ";
         my_impact = " ";
         begin[0][0] = -1;
         begin[0][1] = -1;
      }
      else if (currTag == "<title>") {
         begin[0][0] = endPos[i][0];
         begin[0][1] = endPos[i][1];
      }
      else if (currTag == "</title>") {
         end[0][0] = startPos[i][0];
         end[0][1] = startPos[i][1];
         my_title = GetContent(webData, begin, end);
      }
      else if (currTag == "<country>") {
         begin[0][0] = endPos[i][0];
         begin[0][1] = endPos[i][1];
      }
      else if (currTag == "</country>") {
         end[0][0] = startPos[i][0];
         end[0][1] = startPos[i][1];
         my_country =  GetContent(webData, begin, end);
      }
      else if (currTag == "<date>") {
         begin[0][0] = endPos[i][0];
         begin[0][1] = endPos[i][1];
      }
      else if (currTag == "</date>") {
         end[0][0] = startPos[i][0];
         end[0][1] = startPos[i][1];
         my_date =  GetContent(webData, begin, end);
      }
      else if (currTag == "<time>") {
         begin[0][0] = endPos[i][0];
         begin[0][1] = endPos[i][1];
      }
      else if (currTag == "</time>") {
         end[0][0] = startPos[i][0];
         end[0][1] = startPos[i][1];
         my_time =  GetContent(webData, begin, end);
      }
      else if (currTag == "<impact>") {
         begin[0][0] = endPos[i][0];
         begin[0][1] = endPos[i][1];
      }
      else if (currTag == "</impact>") {
         end[0][0] = startPos[i][0];
         end[0][1] = startPos[i][1];
         my_impact =  GetContent(webData, begin, end);
      }
      else if (currTag == "<forecast>") {
         begin[0][0] = endPos[i][0];
         begin[0][1] = endPos[i][1];
      }
      else if (currTag == "</forecast>") {
         end[0][0] = startPos[i][0];
         end[0][1] = startPos[i][1];
         my_forecast =  GetContent(webData, begin, end);
      }
      else if (currTag == "<previous>") {
         begin[0][0] = endPos[i][0];
         begin[0][1] = endPos[i][1];
      }
      else if (currTag == "</previous>") {
         end[0][0] = startPos[i][0];
         end[0][1] = startPos[i][1];
         my_previous =  GetContent(webData, begin, end);
      }
      else if (currTag == "</event>") {
         a_news_item = new CNEWS_ITEM;
         a_news_item.ni_title = my_title;
         a_news_item.ni_country = my_country;
         a_news_item.ni_forecast = my_forecast;
         a_news_item.ni_previous = my_previous;
         a_news_item.ni_datetime = FFStrToDate(my_date,my_time);
         a_news_item.ni_impact = FFStrToImpact(my_impact);
         news.Add( a_news_item );
      }
      else if (currTag == "</weeklyevents>") {
         //Print("end of the news;");
      }
   }
}

//+------------------------------------------------------------------+
//|  fill the structure of tags                                      |
//+------------------------------------------------------------------+
void FillTagStructure(string  & structure[],// created structure of tags
                      int     & begin[][],  // tag begin (string, position)
                      int     & end[][],    // tag end (string, position)
                      string  & array[]) {  // source html text
//----
   int array_Size = ArraySize(array);
   
   ArrayResize(structure, capacity);
   ArrayResize(begin, capacity);
   ArrayResize(end, capacity);
   
   int i=0, line, posOpen, pos_, posClose, tagCounter = 0, currPos = 0;
   string currString;
   string tag;
   int curCapacity = capacity;
   while (i < array_Size) {
      if (tagCounter >= curCapacity) {                   //  if the number of tags has exceeded 
         ArrayResize(structure, curCapacity + capacity); //  increase storage capacity
         ArrayResize(begin, curCapacity + capacity);     //  increase the size of the starting positions' array
         ArrayResize(end, curCapacity + capacity);       //  increase the size of the end positions' array       
         curCapacity += capacity;                        //  remember the new capacity
      }
      
      currString = array[i];                             // take the current string
      //Print(currString);
      posOpen = StringFind(currString, "<", currPos);    // look for the first "<" occurrence from currPos position
      if (posOpen == -1) {                               // not found
         line = i;                                       // move to the next string
         currPos = 0;                                    //  search from the begin in the new string
         i++;
         continue;                                       // return to the loop begin
      }
         
      //  if this point is reached, "<" has been found     
      pos_ = StringFind(currString, " ", posOpen);       //  then search for space
      posClose = StringFind(currString, ">", posOpen);   //  search for the closing bracket 
      if ((pos_ == -1) && (posClose != -1)) {            //  there is no space but the bracket has been found
         tag = StringSubstr(currString, posOpen, posClose - posOpen) + ">";
         // tag created
         structure[tagCounter] = tag;                    //  write it to the tags array
         setPositions(begin, end, tagCounter, i, posOpen, i, posClose+1);
         tagCounter++;                                   //  increase the counter of found tags
         currPos = posClose;                             //  next search for the new tag starts here
         continue;                                       //   from posClose position where the closing bracket has been found
      }

      //   if we reached this place, both space and closing bracket have been found
      if ((pos_ != -1) && (posClose != -1)) {

         if (pos_ > posClose) {                          //  space located after the brackets
            tag = StringSubstr(currString, posOpen, posClose - posOpen) + ">";
            // tag created
            structure[tagCounter] = tag;                 //  write it to the tags array
            setPositions(begin, end, tagCounter, i, posOpen, i, posClose+1);
            tagCounter++;                                //  increase the counter of found tags
            currPos = posClose;                          //  next search for the new tag starts here
            continue;                                    //   from posClose position where the closing bracket has been found
         }

         //  space is located before the closing bracket
         if (pos_ < posClose) {
            tag = StringSubstr(currString, posOpen, pos_ - posOpen) + ">";
            // tag created
            structure[tagCounter] = tag;                 //  write it to the tags array
            setPositions(begin, end, tagCounter, i, posOpen, i, posClose+1);
            tagCounter++;                                //  increase the counter of found tags
            currPos = posClose;                          //  next search for the new tag starts here
            continue;                                    //   from posClose position where the closing bracket has been found
         }
      }

      //   if we reached this place, neither space nor closing bracket have been found
      if ((pos_ == -1) && (posClose == -1)) {
         tag = StringSubstr(currString, posOpen) + ">";  //  create the tag using present elements
         structure[tagCounter] = tag;                    //  write it to the tags array
         while (posClose == -1) {                        //  and arrange the loop of searching for
            i++;                                         //  increase the string counter
            currString = array[i];                       //  calculate the new string
            posClose = StringFind(currString, ">");      //  and search for the closing bracket in it
         }
         setPositions(begin, end, tagCounter, i, posOpen, i, posClose+1);
         tagCounter++;                                   //  increase the counter of found tags
         currPos = posClose;                             //  it has probably been found, set the initial position
      }                                                  //  for searching for the new tag
   }
   ArrayResize(structure, tagCounter);                   //  cut the size of the tags array down to the number of the found
//----                                                   //  tags
   return;   
}
  
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
string GetContent(string &array[], int &begin[1][2],int  &end[1][2]) {
   string res = "";
   //----
   int startLine = begin[0][0];
   int startPos = begin[0][1];

   int endtLine = end[0][0];
   int endPos = end[0][1];
   string currString;
   
   for (int i = startLine; i<=endtLine; i++) {

      currString = array[i];

      if (i == startLine && endtLine > startLine) {
         res = res + StringSubstr(currString, startPos);
      }

      if (i > startLine && i < endtLine) {
         res = res + currString;
      }
         
      if (endtLine > startLine && i == endtLine) {
         if (endPos > 0) res = res + StringSubstr(currString, 0, endPos);
      }
         
      if (endtLine == startLine && i == endtLine) {
         if (endPos - startPos > 0) res = res + StringSubstr(currString, startPos, endPos - startPos);
      }
   }

   //Remove <![CDATA[ stuff, if present
   if ( StringFind(res, "<![CDATA[") == 0 ) {
      res = StringSubstr( res, 9, StringLen(res)-12 );
   }
   
   return(res);   
}  

//+------------------------------------------------------------------+
//| write tag coordinates to the appropriate arrays                  |
//+------------------------------------------------------------------+
void setPositions(int &st[][], int &en[][], int counter,int stLine, int stPos, int enLine, int enPos) {
//----
   st[counter][0] = stLine;
   st[counter][1] = stPos;

   en[counter][0] = enLine;
   en[counter][1] = enPos;

//----
   return;
}

datetime FFStrToDate(string ffDate, string ffTime) {

   // ffDate is in the format: mm-dd-yyyy
   // ffTime is in the format: hh:mm[am|pm]
   
   static datetime gmtOffSet = TimeGMTOffset();

   MqlDateTime dateStruct;
   
   string tempStr = ffDate;
   StringReplace(tempStr," ",""); // Remove the spaces

   if ( StringLen(tempStr) >= 10 ) {
      // Set the month
      dateStruct.mon  = StrToInteger( StringSubstr(tempStr, 0, 2) );
      
      // Set the day
      dateStruct.day  = StrToInteger( StringSubstr(tempStr, 3, 2) );
      
      // Set the year
      dateStruct.year = StrToInteger( StringSubstr(tempStr, 6, 4) );
   }

   tempStr = ffTime;
   StringReplace(tempStr," ",""); // Remove the spaces
   if ( StringFind(tempStr,":") == 1 ) tempStr = "0" + tempStr;    // Add a leading '0' for times like '9:05' -> '09:05'

   bool isPM = false;
   bool isAM = false;
   if ( StringLen(tempStr) > 5 ) {
   
      string ampm = StringSubstr(tempStr,5,2);
      StringToUpper(ampm);
      
      if ( ampm == "PM" ) isPM = true;
      else if ( ampm == "AM" ) isAM = true;
   }
   
   if ( StringLen(tempStr) >= 5 ) {
   
      // Set the hour
      dateStruct.hour = StrToInteger(StringSubstr(tempStr,0,2) );
      if ( isPM && ( (dateStruct.hour > 0) && (dateStruct.hour < 12) ) ) {
         dateStruct.hour += 12;
      }
      if ( isAM &&  (dateStruct.hour == 12) ) {
         dateStruct.hour -= 12;
      }
      
      // Set the minute
      dateStruct.min = StrToInteger(StringSubstr(tempStr,3,2) );
   }
   
   return( StructToTime(dateStruct) );
}

IMPACT FFStrToImpact(string impact) {

   IMPACT result = UNKNOWN;

   string tempStr = impact;
   StringReplace(tempStr," ",""); // Remove the spaces
   StringToUpper(tempStr);        // Upper case
   
   if ( tempStr == "LOW" ) result = LOW;
   else if ( tempStr == "MEDIUM" ) result = MEDIUM;
   else if ( tempStr == "HIGH" ) result = HIGH;
   
   return(result);
}