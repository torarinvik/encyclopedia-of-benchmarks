## Sign of a signed 64-bit integer.
proc signum*(value: int64): int64 {.cdecl, exportc: "signum".} =
  if value > 0:
    return 1
  if value < 0:
    return -1
  return 0
