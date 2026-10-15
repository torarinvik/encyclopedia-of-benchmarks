const Int32MinValue = -2_147_483_648'i64
const Int32MaxValue = 2_147_483_647'i64

## Return the trailing-zero count of the signed 32-bit XOR.
proc first_different_bit*(x, y: int64): int64 {.cdecl, exportc: "first_different_bit".} =
  if x < Int32MinValue or x > Int32MaxValue or y < Int32MinValue or y > Int32MaxValue:
    return -1
  var difference = uint32(int32(x)) xor uint32(int32(y))
  var index = 0'i64
  while index < 32 and (difference and 1'u32) == 0:
    inc index
    difference = difference shr 1
  return index
