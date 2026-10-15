const Int32MinValue = -2_147_483_648'i64
const Int32MaxValue = 2_147_483_647'i64

## Return whether the signed 32-bit XOR has its sign bit set.
proc numbers_different_signs*(left, right: int64): int64
    {.cdecl, exportc: "numbers_different_signs".} =
  if left < Int32MinValue or left > Int32MaxValue or right < Int32MinValue or right > Int32MaxValue:
    return -1
  if (int32(left) xor int32(right)) < 0: 1 else: 0
