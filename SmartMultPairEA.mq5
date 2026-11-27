#property strict
#property version "1.00"
#property description "Smart Multi Pair EA - Trend Scanner"

input string PairsList = "EURUSD,GBPUSD,USDJPY,AUDUSD,USDCAD,EURJPY";
input ENUM_TIMEFRAMES TimeFrame = PERIOD_H1;
input int FastMA = 20;
input int SlowMA = 50;

// --- Vigezo vya Risk Management ---
input double LotSize = 0.01;   // Ukubwa wa Lot kwa kila trade
input int MagicNumber = 12345; // Namba ya kutambua trade zako
input int StopLoss = 300;      // Stop Loss kwa Points
input int TakeProfit = 600;    // Take Profit kwa Points

string Symbols[];
int FastHandles[];
int SlowHandles[];

int OnInit()
{
   int count = StringSplit(PairsList, ',', Symbols);

   if(count <= 0)
      return INIT_FAILED;

   ArrayResize(FastHandles, count);
   ArrayResize(SlowHandles, count);

   for(int i = 0; i < count; i++)
   {
      StringTrimLeft(Symbols[i]);
      StringTrimRight(Symbols[i]);

      SymbolSelect(Symbols[i], true);

      FastHandles[i] = iMA(Symbols[i], TimeFrame,
                           FastMA, 0, MODE_EMA, PRICE_CLOSE);

      SlowHandles[i] = iMA(Symbols[i], TimeFrame,
                           SlowMA, 0, MODE_EMA, PRICE_CLOSE);

      if(FastHandles[i] == INVALID_HANDLE ||
         SlowHandles[i] == INVALID_HANDLE)
      {
         Print("Indicator error: ", Symbols[i]);
         return INIT_FAILED;
      }
   }

   EventSetTimer(60);
   Print("Smart Multi Pair EA started.");

   return INIT_SUCCEEDED;
}

void OnTimer()
{
   for(int i = 0; i < ArraySize(Symbols); i++)
   {
      double fast[];
      double slow[];

      ArraySetAsSeries(fast, true);
      ArraySetAsSeries(slow, true);

      if(CopyBuffer(FastHandles[i], 0, 1, 1, fast) < 1)
         continue;

      if(CopyBuffer(SlowHandles[i], 0, 1, 1, slow) < 1)
         continue;

      // Logic ya kufungua trade
      if(fast[0] > slow[0])
      {
         Print(Symbols[i], " : UP TREND");
         if(!IsTradeOpen(Symbols[i]))
            ExecuteTrade(Symbols[i], ORDER_TYPE_BUY);
      }
      else if(fast[0] < slow[0])
      {
         Print(Symbols[i], " : DOWN TREND");
         if(!IsTradeOpen(Symbols[i]))
            ExecuteTrade(Symbols[i], ORDER_TYPE_SELL);
      }
      else
      {
         Print(Symbols[i], " : NEUTRAL");
      }
   }
}

void OnTick()
{
}

void OnDeinit(const int reason)
{
   EventKillTimer();

   for(int i = 0; i < ArraySize(Symbols); i++)
   {
      if(FastHandles[i] != INVALID_HANDLE)
         IndicatorRelease(FastHandles[i]);

      if(SlowHandles[i] != INVALID_HANDLE)
         IndicatorRelease(SlowHandles[i]);
   }
}

// --- Kazi za kutrade na kusimamia hatari ---

bool IsTradeOpen(string symbol)
{
   for(int i = PositionsTotal() - 1; i >= 0; i--)
   {
      if(PositionGetSymbol(i) == symbol && PositionGetInteger(POSITION_MAGIC) == MagicNumber)
         return true;
   }
   return false;
}

void ExecuteTrade(string symbol, ENUM_ORDER_TYPE type)
{
   MqlTradeRequest request = {0};
   MqlTradeResult result = {0};
   
   double point = SymbolInfoDouble(symbol, SYMBOL_POINT);
   int digits = (int)SymbolInfoInteger(symbol, SYMBOL_DIGITS);

   request.action = TRADE_ACTION_DEAL;
   request.symbol = symbol;
   request.volume = LotSize;
   request.type = type;
   request.magic = MagicNumber;
   request.deviation = 10;

   if(type == ORDER_TYPE_BUY)
   {
      request.price = SymbolInfoDouble(symbol, SYMBOL_ASK);
      if(StopLoss > 0) request.sl = NormalizeDouble(request.price - (StopLoss * point), digits);
      if(TakeProfit > 0) request.tp = NormalizeDouble(request.price + (TakeProfit * point), digits);
   }
   else if(type == ORDER_TYPE_SELL)
   {
      request.price = SymbolInfoDouble(symbol, SYMBOL_BID);
      if(StopLoss > 0) request.sl = NormalizeDouble(request.price + (StopLoss * point), digits);
      if(TakeProfit > 0) request.tp = NormalizeDouble(request.price - (TakeProfit * point), digits);
   }

   if(!OrderSend(request, result))
      Print("Kosa la Trade kwenye ", symbol, ": ", result.retcode);
   else
      Print("Trade imefanikiwa kwenye ", symbol, " na SL/TP zimewekwa.");
}
