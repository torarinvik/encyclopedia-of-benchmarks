## Complement only the significant binary digits of a nonnegative integer.
proc bitwise_complement*(n: int64): int64 {.cdecl, exportc: "bitwise_complement".} =
  if n < 0 or n > 2_147_483_647:
    return -1
  if n == 0:
    return 1
  var value = uint64(n)
  var mask = 0'u64
  while value != 0:
    mask = (mask shl 1) or 1'u64
    value = value shr 1
  n xor int64(mask)
