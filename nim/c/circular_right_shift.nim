## Rotate an unsigned 53-bit integer right by 0 through 53 positions.
proc circular_right_shift*(value, shift: uint64): int64 {.cdecl, exportc: "circular_right_shift".} =
  const mask = 9007199254740991'u64
  if value > mask or shift > 53: return -1
  let lowMask = mask shr (53'u64 - shift)
  let low = (value and lowMask) shl (53'u64 - shift)
  let high = value shr shift
  return int64(low or high)
