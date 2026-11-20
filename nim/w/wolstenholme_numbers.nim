const
  MaxN = 22'i64
  MaxParseableLength = 2

proc wnGcd(aValue, bValue: int64): int64 =
  var left = aValue
  var right = bValue
  while right != 0:
    let remainder = left mod right
    left = right
    right = remainder
  left

proc wnNumerator(n: int64): int64 =
  var numerator = 0'i64
  var denominator = 1'i64
  var k = 1'i64
  while k <= n:
    let square = k * k
    let common = wnGcd(denominator, square)
    let scale = square div common
    numerator = numerator * scale + denominator div common
    denominator *= scale
    let factor = wnGcd(numerator, denominator)
    numerator = numerator div factor
    denominator = denominator div factor
    inc k
  numerator

proc wolstenholme_numbers*(input: ptr UncheckedArray[int64], length: csize_t): int64
    {.cdecl, exportc: "wolstenholme_numbers".} =
  if input.isNil or length < 1 or length > csize_t(MaxParseableLength): return -1
  if length != 1 or input[0] < 1 or input[0] > MaxN: return -1
  wnNumerator(input[0])
