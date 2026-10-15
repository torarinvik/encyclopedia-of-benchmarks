## Exact square-pyramidal sum within the pinned u64 intermediate range.
proc square_pyramidal_numbers*(n: int64): int64 {.cdecl, exportc: "square_pyramidal_numbers".} =
  if n < 0 or n > 2_097_151: return -1
  let value = uint64(n)
  let numerator = value * (value + 1'u64) * (2'u64 * value + 1'u64)
  int64(numerator div 6'u64)
