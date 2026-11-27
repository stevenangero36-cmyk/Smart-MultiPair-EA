if(fast[0] > slow[0])
{
    Print(Symbols[i], ": UP TREND");
    if(!IsTradeOpen(Symbols[i]))
        ExecuteTrade(Symbols[i], ORDER_TYPE_BUY);
}
else if(fast[0] < slow[0])
{
    Print(Symbols[i], ": DOWN TREND");
    if(!IsTradeOpen(Symbols[i]))
        ExecuteTrade(Symbols[i], ORDER_TYPE_SELL);
}
else
{
    Print(Symbols[i], ": NEUTRAL");
}
