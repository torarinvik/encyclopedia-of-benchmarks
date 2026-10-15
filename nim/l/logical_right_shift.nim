const MaxU53 = 9_007_199_254_740_991'u64
const InvalidResult = -1'i64

proc logical_right_shift*(n, shift: uint64): int64 {.cdecl, exportc: "logical_right_shift".} =
  if n > MaxU53 or shift > 53'u64: return InvalidResult
  int64(n shr int(shift))
