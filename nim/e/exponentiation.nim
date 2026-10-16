proc exponentiation*(base, exponent: int64): int64
    {.cdecl, exportc: "exponentiation".} =
  if base < 0 or base > 255 or exponent < 0 or exponent > 7: return -1
  var result = 1'i64
  for _ in 0'i64 ..< exponent: result *= base
  result
