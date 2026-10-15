## Convert a nonnegative integer to its binary-reflected Gray code.
proc binary_to_gray_code*(value: int64): int64 {.cdecl, exportc: "binary_to_gray_code".} =
  if value < 0: return -1
  value xor (value shr 1)
