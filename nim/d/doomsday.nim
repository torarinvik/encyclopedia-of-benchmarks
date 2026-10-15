## Gregorian weekday from Conway's Doomsday rule.
proc isLeapYear(year: int64): bool =
  year mod 400 == 0 or (year mod 4 == 0 and year mod 100 != 0)

proc monthAnchor(month: int64, leap: bool): int64 =
  case month
  of 1: (if leap: 4'i64 else: 3'i64)
  of 2: (if leap: 1'i64 else: 7'i64)
  of 3: 7
  of 4: 4
  of 5: 2
  of 6: 6
  of 7: 4
  of 8: 1
  of 9: 5
  of 10: 3
  of 11: 7
  of 12: 5
  else: -1

proc doomsday*(values: ptr UncheckedArray[int64], length: csize_t): int64
    {.cdecl, exportc: "doomsday".} =
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

  let withinCentury = year mod 100
  let centuryAnchor = (5 * ((year div 100) mod 4) + 2) mod 7
  let doom = (withinCentury div 12 + withinCentury mod 12
    + (withinCentury mod 12) div 4 + centuryAnchor) mod 7
  var weekday = (doom + day - monthAnchor(month, leap)) mod 7
  if weekday < 0: weekday += 7
  weekday
