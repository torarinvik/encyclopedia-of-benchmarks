## Maximum profit from one buy followed by one sell.
proc best_time_to_buy_and_sell_stock*(prices: ptr UncheckedArray[int64], length: csize_t): int64
    {.cdecl, exportc: "best_time_to_buy_and_sell_stock".} =
  if length > 4096: return -1
  if length == 0: return 0
  var minimum = prices[0]
  var best: int64 = 0
  for day in 0 ..< length:
    let price = prices[day]
    if price < 0 or price > 1000000000: return -1
    minimum = min(minimum, price)
    best = max(best, price - minimum)
  best
