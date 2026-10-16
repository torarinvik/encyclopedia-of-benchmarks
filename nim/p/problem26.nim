proc problem26*(limit: int64): int64 {.cdecl, exportc: "problem26".} =
  if limit < 0 or limit > 1000: return -1
  var bestDenominator = 1'i64
  var longestRemainderList = 0'i64
  var denominator = 1'i64
  while denominator <= limit:
    var seen: array[1001, bool]
    var remainder = 1'i64
    var remainderCount = 0'i64
    var step = 0'i64
    while step < limit:
      if seen[int(remainder)]:
        if remainderCount > longestRemainderList:
          longestRemainderList = remainderCount
          bestDenominator = denominator
        break
      seen[int(remainder)] = true
      remainderCount += 1
      remainder = (remainder * 10) mod denominator
      step += 1
    denominator += 1
  bestDenominator
