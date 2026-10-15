proc isLeapYear(year: int64): bool =
  year mod 400 == 0 or (year mod 100 != 0 and year mod 4 == 0)

## Return the pinned JavaScript helper's month length.
proc get_month_days*(month_number, year: int64): int64 {.cdecl, exportc: "get_month_days".} =
  if year < 0 or year > 9999: return -1
  case month_number
  of 1, 3, 5, 7, 8, 10, 12: 31
  of 4, 6, 9, 11: 30
  of 2: if isLeapYear(year): 29 else: 28
  else: -1
