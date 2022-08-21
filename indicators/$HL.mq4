// Вот теперь может и сбудется...
#property copyright "Hohla"
#property link      "hohla@mail.ru"
#property strict // Указание компилятору на применение особого строгого режима проверки ошибок

#property indicator_chart_window
#property indicator_buffers 3
#property indicator_color1 Green
#property indicator_color2 Green
#property indicator_color3 Yellow

extern int HL=1;
extern int iHL=8;
//extern int PerCnt=2; // используется только для 1(способ расчета периода) и 8-го индюка
double HiBuf[], LoBuf[], SigBuf[], temp, hi, lo, Counter, Etalon;
int bar,b,Trend=0;  

int OnInit(void){//ЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖ
   string short_name;
   IndicatorBuffers(3);
   SetIndexStyle(0,DRAW_LINE);
   SetIndexStyle(1,DRAW_LINE);
   SetIndexStyle(2,DRAW_ARROW); SetIndexArrow(2,163);
   SetIndexBuffer(0,HiBuf);
   SetIndexBuffer(1,LoBuf);
   SetIndexBuffer(2,SigBuf);
   switch (HL){
         case 1:  short_name="1- HL_Classic ("  +DoubleToStr(iHL,0)+") ";break;
         case 2:  short_name="2- HL_DayBegin (" +DoubleToStr(iHL,0)+") ";break; // самый большой Hi/Lo  начиная с N часа текущего дня
         case 3:  short_name="3- HL_N ("        +DoubleToStr(iHL,0)+") ";break;  //  HL_N - отсчитываем N максимумов, превосходящих текущий хай
         case 4:  short_name="4- HL_Delta ("    +DoubleToStr(iHL,0)+") ";break; // формирование нового хая при удалении на заданную величину от последнего лоу
         case 5:  short_name="5- HL_ATR ("      +DoubleToStr(iHL,0)+") ";break;  // HL_ATR - L подтягивается за H на расстоянии x*ATR
         case 6:  short_name="6- HL_Fractal ("  +DoubleToStr(iHL,0)+") ";break; // экстремумы на фракталах
         case 7:  short_name="7- HL_Layers  ("  +DoubleToStr(iHL,0)+") ";break; // расчет  дискреционных уровней (индюк #Layers)
         case 8:  short_name="8- VolClaster ("  +DoubleToStr(iHL,0)+"%) ";break;
         }
   IndicatorShortName(short_name);
   SetIndexLabel(1,short_name);
   hi=High[Bars-IndicatorCounted()-1];
   lo=Low[Bars-IndicatorCounted()-1];
   return (INIT_SUCCEEDED); // "0"-Успешная инициализация.
   }
//ЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖ
//ЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖ
// 1(13)  2(2)  5(7)  6(2)
int start(){ 
   int CountBars=Bars-IndicatorCounted()-1;
   int k=0, BarTime=iHL;
   double H1=0,H2=0,H3=0,H4=0,L1=0,L2=0,L3=0,L4=0, O1=0,C1=0,ATR=0,porog=0;
   for (bar=CountBars; bar>0; bar--){
      switch (HL){
         case 1: // HL_Classic 
            if (bar>Bars-iHL) break;
            hi=High[bar]; lo=Low[bar];
            for (b=bar; b<bar+iHL; b++){
               if (High[b]>hi) hi=High[b];
               if (Low[b]<lo)  lo=Low[b];} 
         break;
         case 2: // HL_DayBegin самый большой Hi/Lo начиная с N часа
            if (Period()>60) BarTime=int(MathFloor((iHL*60)/Period())*Period()/60); // для ТФ>часа делаем период кратный ТФ. Для Н4:  при iHL=3 time=0;  при iHL=6 time=4;  при iHL=10 time=8;
            if (TimeHour(Time[bar])==BarTime) {hi=High[bar]; lo=Low[bar];}
            if (High[bar]>hi) hi=High[bar];
            if (Low[bar]<lo) lo=Low[bar];   
         break;
         case 3: // складываем тела свечей, пока сумма не достигнет эталонного значения
            Etalon=iHL*iATR(NULL,0,100,bar)*2; // величина, к которой с каждым баром приближается длина кривой цены
            Counter=0; // вначале обнуляем кривую цены
            b=bar;
            hi=High[b]; lo=Low[b];
            while(Counter<Etalon){
               b++; //if (b>Bars-1) break;
               Counter+=High[b]-Low[b];
               if (High[b]>hi) hi=High[b];
               if (Low[b]<lo)  lo=Low[b];}
                
         break;
         case 4: // HL_Delta-2 формирование нового хая при удалении на заданную величину от последнего лоу
            if (iHL<6){
               temp=(iHL)*iATR(NULL,0,100,bar);
               if (temp<=0) break;
               if (Trend<0){
                  if (High[bar]>lo+temp)  {Trend= 1;  hi=High[bar];}// отрыв от дна, обновляем значение hi                
               }else{
                  if (Low[bar]<hi-temp)   {Trend=-1;  lo=Low[bar];}
               }  }
            else{
               temp=(iHL-5)*2*iATR(NULL,0,100,bar);
               if (High[bar]>hi){hi=High[bar]; if (lo<hi-temp) lo=hi-temp;}
               if (Low[bar]<lo) {lo=Low[bar];  if (hi>lo+temp) hi=lo+temp;} 
               }  
         break; ////////////////////////////      
         case 5: // HL_Fractal 
            if (bar>Bars-iHL-1) break;
            if (High[bar+iHL]==High[iHighest(NULL,0,MODE_HIGH,iHL*2+1,bar)])  hi=High[bar+iHL];
            if (Low[bar+iHL] ==Low [iLowest (NULL,0,MODE_LOW ,iHL*2+1,bar)])  lo=Low[bar+iHL];
         break;
         case 6: // расчет  дискреционных уровней (индюк #Layers) 
            if (bar>Bars-iHL-1) break;
            if (High[bar]>hi || Low[bar]<lo){
               hi=High[iHighest(NULL,0,MODE_HIGH,iHL*2+1,bar)];   
               lo=Low [iLowest (NULL,0,MODE_LOW ,iHL*2+1,bar)];
               }
         break;    
         case 7: // расчет  дискреционных уровней (индюк #Layers) 
            
            if (High[bar]>hi){
               for (b=bar; b<Bars; b++){
                  if (b>Bars-iHL*2-1) break;
                  hi=High[iHighest(NULL,0,MODE_HIGH,iHL*2+1,b)];
                  if (hi>High[bar]) break;
               }  } 
            if (Low[bar]<lo){   
               lo=Low [iLowest (NULL,0,MODE_LOW ,iHL*2+1,bar)];
               }
         break;              
         case 8: // VolumeCluster
            porog=(13-iHL)*0.03; // при iHL=1..9, porog=36%-12%, (25% у автора) 
            C1=Close[bar];
            H1=High[bar];
            L1=Low [bar];
            ATR=iATR(NULL,0,100,bar)*1.5;
            if (bar>Bars-5) break;
            for (b=bar+1; b<bar+3; b++){
               if (High[b]>H1) H1=High[b];
               if (Low [b]<L1) L1=Low [b];
               O1=Open[b];
               if (H1-L1>ATR){//  Не работаем в узком диапазоне
                  if ((H1-O1)/(H1-L1)<porog && (H1-C1)/(H1-L1)<porog) {lo=L1; hi=H1;  SigBuf[bar]=L1;} // Нижний "Фрактал" (открытие и закрытие в верхней части Bar баров)
                  if ((O1-L1)/(H1-L1)<porog && (C1-L1)/(H1-L1)<porog) {lo=L1; hi=H1;  SigBuf[bar]=H1;} // верхний "фрактал"
               }  }
         break;        
         }
      if (hi<High[bar]) hi=High[bar];
      if (lo>Low[bar])  lo=Low[bar];   
      HiBuf[bar]=hi;
      LoBuf[bar]=lo; 
      }
   return(0);
   }
   
   /*
      case 44: // HL_N1   - после очередного пробоя лоу отсчитываем N минимумов назад от текущего хая
            if (Low[bar]<lo){  
               k=0; b=bar+1;
               hi=High[bar]; lo=Low[bar]; 
               while (k<iHL){
                  if (High[b]>hi){hi=High[b];k++;}
                  b++; if (b>=Bars-1) break;
               }  }
            if (High[bar]>hi){    // после очередного пробоя хая отсчитываем N минимумов назад от текущего лоу
               k=0; b=bar+1; 
               hi=High[bar]; lo=Low[bar];  
               while (k<iHL){   
                  if (Low[b]<lo){lo=Low[b];k++;}
                  b++; if (b>=Bars-1) break; 
               }  } 
         break;
         */