const MaxMinTotal = 1_000_000_000_000'i64

proc problem100*(minTotal: int64): int64 {.cdecl, exportc: "problem100".} =
  if minTotal < 0 or minTotal > MaxMinTotal: return -1
  var previousNumerator = 1'i64
  var previousDenominator = 0'i64
  var numerator = 1'i64
  var denominator = 1'i64
  while numerator <= 2 * minTotal - 1:
    previousNumerator += 2 * numerator
    numerator += 2 * previousNumerator
    previousDenominator += 2 * denominator
    denominator += 2 * previousDenominator
  (denominator + 1) div 2
