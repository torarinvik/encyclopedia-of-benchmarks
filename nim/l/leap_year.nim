## Return 1 for a positive Gregorian leap year, 0 otherwise, or -1 for invalid years.
proc leap_year*(year: int64): int64 {.cdecl, exportc: "leap_year".} =
  if year <= 0: return -1
  if year mod 400 == 0 or (year mod 4 == 0 and year mod 100 != 0): return 1
  return 0
