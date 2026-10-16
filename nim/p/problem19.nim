proc isLeapYear(year: int64): bool =
  year mod 400 == 0 or (year mod 4 == 0 and year mod 100 != 0)

proc problem19*(ignored: int64): int64 {.cdecl, exportc: "problem19".} =
  if ignored != 0: return -1
  var weekday = 2'i64 # 1 January 1901 was Tuesday; Sunday is 0.
  var count = 0'i64
  for year in 1901'i64..2000'i64:
    for month in 1'i64..12'i64:
      if weekday == 0: inc count
      var days = 31'i64
      if month == 4 or month == 6 or month == 9 or month == 11: days = 30
      if month == 2: days = (if isLeapYear(year): 29 else: 28)
      weekday = (weekday + days) mod 7
  count
