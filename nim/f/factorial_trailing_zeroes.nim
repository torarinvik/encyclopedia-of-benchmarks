## Count factors of five in n!, which determine its trailing decimal zeros.
const MaxN = 1_000_000_000'i64

proc factorial_trailing_zeroes*(n: int64): int64 {.cdecl, exportc: "factorial_trailing_zeroes".} =
  if n < 0 or n > MaxN:
    return -1
  var remaining = n
  var count = 0'i64
  while remaining > 0:
    remaining = remaining div 5
    count += remaining
  return count
