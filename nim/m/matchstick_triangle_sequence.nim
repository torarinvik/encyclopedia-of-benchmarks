proc matchstick_triangle_sequence*(n: int64): int64 {.cdecl, exportc: "matchstick_triangle_sequence".} =
  if n < 0 or n > 1000000'i64: return -1
  return (n * (n + 2) * (2 * n + 1)) div 8
