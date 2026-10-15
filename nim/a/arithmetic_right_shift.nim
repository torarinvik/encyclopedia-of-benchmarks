const MaxU53 = 9_007_199_254_740_991'u64
const InvalidResult = -1'i64

proc arithmetic_right_shift*(n, shift: uint64): int64 {.cdecl, exportc: "arithmetic_right_shift".} =
  if n > MaxU53 or shift > 53'u64: return InvalidResult
  let count = int(shift)
  let lowMask = (1'u64 shl (53 - count)) - 1'u64
  let shifted = n shr count
  let fillMask = if (n shr 52) != 0'u64: MaxU53 xor lowMask else: 0'u64
  int64(fillMask or shifted)
