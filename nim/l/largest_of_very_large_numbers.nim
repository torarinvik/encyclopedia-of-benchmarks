const MaxValue = 1_000_000_000_000'i64

proc decimalExponent(base: int64): int64 =
  if base < 1: return -1
  var remaining = base
  var exponent = 0'i64
  while remaining > 1 and remaining mod 10 == 0:
    remaining = remaining div 10
    inc exponent
  if remaining == 1: exponent else: -1

proc validBase(base: int64): bool =
  base == 0 or decimalExponent(base) >= 0

proc sourceScore(base, exponent: int64): int64 =
  if base == 0: return 0
  if exponent == 0: return 1
  decimalExponent(base) * exponent

proc largest_of_very_large_numbers*(values: ptr UncheckedArray[int64], length: csize_t): int64
    {.cdecl, exportc: "largest_of_very_large_numbers".} =
  if values.isNil or length != 4: return -2
  for i in 0 ..< 4:
    if values[i] < 0 or values[i] > MaxValue: return -2
  if not validBase(values[0]) or not validBase(values[2]): return -2
  let a = sourceScore(values[0], values[1])
  let b = sourceScore(values[2], values[3])
  if a > b: return 1
  if a < b: return -1
  0
