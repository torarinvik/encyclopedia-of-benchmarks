## Gregorian weekday by the pinned Rust month-offset recurrence.
proc isLeapYear(year: int64): bool =
  year mod 400 == 0 or (year mod 4 == 0 and year mod 100 != 0)

proc monthOffset(month: int64): int64 =
  case month
  of 1: 0
  of 2: 3
  of 3: 2
  of 4: 5
  of 5: 0
  of 6: 3
  of 7: 5
  of 8: 1
  of 9: 4
  of 10: 6
  of 11: 2
  of 12: 4
  else: -1

proc weekday_by_month_offsets*(values: ptr UncheckedArray[int64], length: csize_t): int64
    {.cdecl, exportc: "weekday_by_month_offsets".} =
  if values.isNil or length != 3: return -1
  let year = values[0]
  let month = values[1]
  let day = values[2]
  if year < 100 or year > 9999 or month < 1 or month > 12: return -1
  let leap = isLeapYear(year)
  let daysInMonth = if month == 2: (if leap: 29'i64 else: 28'i64)
    elif month == 4 or month == 6 or month == 9 or month == 11: 30'i64
    else: 31'i64
  if day < 1 or day > daysInMonth: return -1

  let adjustedYear = year - (if month < 3: 1'i64 else: 0'i64)
  (adjustedYear + adjustedYear div 4 - adjustedYear div 100
    + adjustedYear div 400 + monthOffset(month) + day) mod 7
