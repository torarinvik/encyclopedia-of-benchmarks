proc solve(n: int64): int64 =
  if n == 0: return 2
  if n == 1: return 1
  solve(n - 1) + solve(n - 2)
proc lucas_series_recursive*(n: int64): int64 {.cdecl, exportc: "lucas_series_recursive".} =
  if n < 0 or n > 25: return -1
  solve(n)
