proc powPositive(base: float64, exponent: int64): float64 =
  if exponent == 0: return 1.0
  var mask = 1'i64
  while mask <= exponent div 2: mask = mask shl 1
  result = base
  mask = mask shr 1
  while mask != 0:
    result *= result
    if (exponent and mask) != 0: result *= base
    mask = mask shr 1

proc powx_n*(base: float64, exponent: int32): float64 {.cdecl, exportc: "powx_n".} =
  if exponent == 0: return 1.0
  if exponent == low(int32): return 1.0 / (powPositive(base, high(int32).int64) * base)
  if exponent < 0: return 1.0 / powPositive(base, -(exponent.int64))
  powPositive(base, exponent.int64)
