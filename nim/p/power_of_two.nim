## Return 1 when n is a positive power of two, otherwise 0.
proc power_of_two*(n: int64): int64 {.cdecl, exportc: "power_of_two".} =
  if n <= 0: return 0
  if (n and (n - 1)) == 0: return 1
  return 0
