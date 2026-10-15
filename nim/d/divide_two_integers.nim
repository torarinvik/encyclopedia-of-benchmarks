## Truncate signed 32-bit division toward zero using doubled divisor chunks.
const InvalidResult = -2147483649'i64

proc divide_two_integers*(values: ptr UncheckedArray[int64], length: csize_t): int64
    {.cdecl, exportc: "divide_two_integers".} =
  if values == nil or length != 2: return InvalidResult
  let dividend = values[0]
  let divisor = values[1]
  if dividend < int64(low(int32)) or dividend > int64(high(int32)) or
      divisor < int64(low(int32)) or divisor > int64(high(int32)) or divisor == 0:
    return InvalidResult

  var remaining = if dividend < 0: -dividend else: dividend
  let divisorMagnitude = if divisor < 0: -divisor else: divisor
  var quotient = 0'i64
  for shift in countdown(31, 0):
    if divisorMagnitude <= (remaining shr shift):
      remaining -= divisorMagnitude shl shift
      quotient += 1'i64 shl shift

  let negative = (dividend < 0) xor (divisor < 0)
  if negative:
    if quotient == 2147483648'i64: return int64(low(int32))
    return -quotient
  if quotient > int64(high(int32)): return int64(high(int32))
  quotient
