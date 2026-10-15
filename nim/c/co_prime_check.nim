## Return whether two nonnegative int32 values have greatest common divisor one.
proc co_prime_check*(first, second: uint64): int64 {.cdecl, exportc: "co_prime_check".} =
  if first > uint64(high(int32)) or second > uint64(high(int32)): return -1
  var left = first
  var right = second
  while right != 0:
    let remainder = left mod right
    left = right
    right = remainder
  if left == 1: 1 else: 0
