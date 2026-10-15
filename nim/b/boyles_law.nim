## Solve Boyle's law for one omitted variable, rounded to 3 decimals.
proc roundedMilli(numerator, denominator: int64): int64 =
  let scaled = numerator * 1000
  result = scaled div denominator
  let remainder = scaled mod denominator
  if 2 * remainder > denominator or (2 * remainder == denominator and result mod 2 != 0):
    inc result

proc boyles_law*(values: ptr UncheckedArray[int64], length: csize_t): float64
    {.cdecl, exportc: "boyles_law".} =
  if length != 4 or values == nil: return -1.0e300
  let target = values[0]
  let a = values[1]
  let b = values[2]
  let c = values[3]
  if target < 0 or target > 3 or a < 1 or a > 1000 or b < 1 or b > 1000 or c < 1 or c > 1000:
    return -1.0e300
  var numerator, denominator: int64
  case target
  of 0: numerator = c * a; denominator = b
  of 1: numerator = b * a; denominator = c
  of 2: numerator = c * b; denominator = a
  else: numerator = c * a; denominator = b
  float64(roundedMilli(numerator, denominator)) / 1000.0
