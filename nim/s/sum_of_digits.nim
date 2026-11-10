## Iteratively add the decimal digits of a signed 32-bit integer's magnitude.
proc sum_of_digits*(input: int64): int64 {.cdecl, exportc: "sum_of_digits".} =
  if input < int64(low(int32)) or input > int64(high(int32)):
    return -1
  let magnitude = uint32(if input < 0: -input else: input)
  var remaining = magnitude
  var total = 0'u32
  while remaining >= 10:
    let nextQuotient = remaining div 10
    remaining = remaining div 100
    total += nextQuotient + remaining
  int64(magnitude - 9 * total)
