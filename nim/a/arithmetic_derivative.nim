const
  MaxN = 1_000_000_000_000'i64
  MaxParseableLength = 2

proc adFromFactors(value: int64): int64 =
  if value < 2: return 0
  let original = value
  var remaining = value
  var derivative = 0'i64
  var factor = 2'i64
  while factor <= remaining div factor:
    if remaining mod factor == 0:
      var exponent = 0'i64
      while remaining mod factor == 0:
        remaining = remaining div factor
        inc exponent
      derivative += (original div factor) * exponent
    if factor == 2: factor = 3
    else: factor += 2
  if remaining > 1: derivative += original div remaining
  derivative

proc arithmetic_derivative*(input: ptr UncheckedArray[int64],
                            length: csize_t): int64
    {.cdecl, exportc: "arithmetic_derivative".} =
  if input.isNil or length < 1 or length > csize_t(MaxParseableLength): return -1
  if length != 1: return -1
  let n = input[0]
  if n < 0 or n > MaxN: return -1
  adFromFactors(n)
