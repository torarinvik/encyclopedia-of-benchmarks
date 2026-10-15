const MaxU53 = 9_007_199_254_740_991'u64
const InvalidResult = -1'i64

proc arithmetic_left_shift*(n, shift: uint64): int64 {.cdecl, exportc: "arithmetic_left_shift".} =
  if n > MaxU53 or shift > 53'u64: return InvalidResult
  int64((n shl int(shift)) and MaxU53)
