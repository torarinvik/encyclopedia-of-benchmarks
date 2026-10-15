## Select the larger signed-32-bit nonnegative value with a sign bit.
const MaxValue = 2_147_483_647'i64

proc bitwisemax*(values: ptr UncheckedArray[int64], length: csize_t): int64
    {.cdecl, exportc: "bitwisemax".} =
  if length != 2 or values == nil: return -1
  let left = values[0]
  let right = values[1]
  if left < 0 or left > MaxValue or right < 0 or right > MaxValue: return -1
  let difference = left - right
  let chooseRight = (difference and 0xFFFF_FFFF'i64) shr 31
  left - chooseRight * difference
