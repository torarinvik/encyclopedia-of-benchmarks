## Return the signed 64-bit magnitude, or -1 when it cannot be represented.
proc abs_i64*(input: int64): int64 {.cdecl, exportc: "abs_i64".} =
  if input == low(int64):
    return -1
  if input < 0:
    return -input
  input
