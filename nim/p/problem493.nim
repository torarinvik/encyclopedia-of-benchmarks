proc chooseTen(n: int64): int64 =
  var accumulator = 1'i64
  for i in 0'i64..<10: accumulator = accumulator * (n - i) div (i + 1)
  accumulator

proc problem493*(picks: int64): int64 {.cdecl, exportc: "problem493".} =
  if picks < 0 or picks > 70: return -1
  let denominator = chooseTen(70)
  let missing = if picks > 60: 0'i64 else: chooseTen(70 - picks)
  let numerator = 7 * (denominator - missing)
  let whole = numerator div denominator
  var remainder = numerator mod denominator
  var fraction = 0'i64
  for i in 0..<9:
    remainder *= 10
    fraction = fraction * 10 + remainder div denominator
    remainder = remainder mod denominator
  remainder *= 10
  let guardDigit = remainder div denominator
  remainder = remainder mod denominator
  var scaled = whole * 1_000_000_000 + fraction
  if guardDigit > 5 or (guardDigit == 5 and (remainder > 0 or scaled mod 2 != 0)): inc scaled
  scaled
