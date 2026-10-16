import std/math

const InvalidResult = -1.0e300
proc roundTwoPython(value: float64): float64 =
  if value == 0.0: return value
  let negative = value < 0.0
  var normalized = if negative: -value else: value
  var exponent = 0
  while normalized >= 1.0: normalized *= 0.5; inc exponent
  while normalized < 0.5: normalized *= 2.0; dec exponent
  let significand = uint64(normalized * 9_007_199_254_740_992.0)
  let numerator = significand * 100'u64
  let shift = 53 - exponent
  var cents = 0'u64
  if shift < 0: cents = numerator shl (-shift)
  elif shift == 0: cents = numerator
  elif shift < 64:
    let denominator = 1'u64 shl shift
    cents = numerator shr shift
    let remainder = numerator and (denominator - 1)
    let half = denominator shr 1
    if remainder > half or (remainder == half and (cents and 1'u64) != 0): inc cents
  let rounded = float64(cents) / 100.0
  if negative: -rounded else: rounded

proc present_value*(values: ptr UncheckedArray[int64], length: csize_t): float64
    {.cdecl, exportc: "present_value".} =
  if values == nil or length < 3 or length > 10: return InvalidResult
  let countValue = values[0]
  let ratePpm = values[1]
  if countValue < 1 or countValue > 8 or length != csize_t(2 + countValue) or ratePpm != 0 and ratePpm != 1_000_000: return InvalidResult
  let count = int(countValue)
  for i in 0 ..< count:
    if values[i + 2] < -1_000_000 or values[i + 2] > 1_000_000 or values[i + 2] mod 125 != 0: return InvalidResult
  let rate = float64(ratePpm) / 1_000_000.0
  var total = 0.0
  for i in 0 ..< count:
    let flow = float64(values[i + 2]) / 1000.0
    total += flow / pow(1.0 + rate, float64(i))
  roundTwoPython(total)
