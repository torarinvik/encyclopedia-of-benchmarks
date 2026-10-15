## Integer binary exponentiation with Java int wraparound semantics.
proc mul32(x, y: int64): int64 =
  let xLow = x mod 65536
  let xHigh = x div 65536
  let yLow = y mod 65536
  let yHigh = y div 65536
  let cross = (xLow * yHigh + xHigh * yLow) mod 65536
  (xLow * yLow + cross * 65536) mod 4294967296

proc binary_pow*(first, second: int64): int64 {.cdecl, exportc: "binary_pow".} =
  if first < -2147483648'i64 or first > 2147483647'i64 or second < -2147483648'i64 or second > 2147483647'i64: return -2147483649'i64
  if second <= 0: return 1
  var base = first
  if base < 0: base += 4294967296'i64
  var exponent = second
  var power = 1'i64
  while exponent > 0:
    if exponent mod 2 == 1: power = mul32(power, base)
    base = mul32(base, base)
    exponent = exponent div 2
  if power >= 2147483648'i64: power - 4294967296'i64 else: power
