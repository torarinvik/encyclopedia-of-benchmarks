## Rotate an unsigned 53-bit integer left by 0 through 53 positions.
proc circular_left_shift*(value, shift: uint64): int64 {.cdecl, exportc: "circular_left_shift".} =
  const mask = 9007199254740991'u64
  if value > mask or shift > 53: return -1
  let low = (value and (mask shr shift)) shl shift
  let high = value shr (53'u64 - shift)
  return int64(low or high)
