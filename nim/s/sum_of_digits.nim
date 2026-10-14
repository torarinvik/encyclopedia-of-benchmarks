## Iteratively add the decimal digits of a signed 32-bit integer's magnitude.
proc sum_of_digits*(input: int64): int64 {.cdecl, exportc: "sum_of_digits".} =
  if input < int64(low(int32)) or input > int64(high(int32)):
    return -1
  var remaining = uint64(if input < 0: -input else: input)
  var total = 0'i64
  while remaining != 0:
    total += int64(remaining mod 10)
    remaining = remaining div 10
  total
