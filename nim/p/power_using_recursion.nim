## Linear recursive integer power, with a bounded exact contract.
proc power_recursive(base: int64, exponent: uint64): int64 =
  if exponent == 0: return 1
  base * power_recursive(base, exponent - 1)

proc decodeSigned(value: uint64): int64 =
  if value <= uint64(high(int64)): return int64(value)
  -1'i64 - int64(not value)

proc power_using_recursion*(baseEncoded, exponent: uint64): int64 {.cdecl, exportc: "power_using_recursion".} =
  let base = decodeSigned(baseEncoded)
  if base < -10 or base > 10 or exponent > 15: return low(int64)
  power_recursive(base, exponent)
