const MaxLimit = 10_000

proc integerSqrt(value: int64): int64 =
  var low = 0'i64
  var high = value + 1
  while high - low > 1:
    let middle = low + (high - low) div 2
    if middle <= value div middle: low = middle
    else: high = middle
  low

proc periodLength(value, root: int64): int64 =
  var numerator = 0'i64
  var denominator = 1'i64
  var coefficient = root
  var period = 0'i64
  while true:
    numerator = denominator * coefficient - numerator
    denominator = (value - numerator * numerator) div denominator
    coefficient = (root + numerator) div denominator
    inc period
    if coefficient == 2 * root: break
  period

proc problem64*(inclusiveLimit: int64): int64 {.cdecl, exportc: "problem64".} =
  if inclusiveLimit < 0 or inclusiveLimit > MaxLimit: return -1
  if inclusiveLimit < 2: return 0
  var count = 0'i64
  for value in 2'i64 .. inclusiveLimit:
    let root = integerSqrt(value)
    if root * root != value and periodLength(value, root) mod 2 == 1:
      inc count
  count
