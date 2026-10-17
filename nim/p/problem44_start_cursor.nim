const MAX_START = 2_166'i64
const MAX_HIGH_INDEX = 2_167'i64

proc pentagonal(index: int64): int64 =
  index * (3 * index - 1) div 2

proc integerSqrt(value: int64): int64 =
  var low = 0'i64
  var high = 20_000'i64
  while high - low > 1:
    let middle = (low + high) div 2
    if middle * middle <= value: low = middle
    else: high = middle
  low

proc isPentagonal(value: int64): bool =
  let discriminant = 24 * value + 1
  let root = integerSqrt(discriminant)
  root * root == discriminant and (root + 1) mod 6 == 0

proc problem44_start_cursor*(start: int64): int64 {.cdecl, exportc: "problem44_start_cursor".} =
  if start < 1 or start > MAX_START: return -1
  var high = start + 1
  while high <= MAX_HIGH_INDEX:
    let highValue = pentagonal(high)
    var low = high - 1
    while low > 0:
      let lowValue = pentagonal(low)
      let difference = highValue - lowValue
      let sum = highValue + lowValue
      if isPentagonal(difference) and isPentagonal(sum): return difference
      dec low
    inc high
  -1
