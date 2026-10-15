## Return the Gregorian weekday for [year, month, day]; Sunday is zero.
proc isLeapYear(year: int64): bool =
  year mod 4 == 0 and (year mod 100 != 0 or year mod 400 == 0)

proc zellers_congruence*(date: ptr UncheckedArray[int64], length: csize_t): int64
    {.cdecl, exportc: "zellers_congruence".} =
  if length != 3 or date.isNil: return -1
  var year = date[0]
  var month = date[1]
  let day = date[2]
  if year < 46 or year > 8499 or month < 1 or month > 12 or day < 1: return -1
  var maximumDay = 31'i64
  if month == 4 or month == 6 or month == 9 or month == 11: maximumDay = 30
  if month == 2: maximumDay = if isLeapYear(year): 29 else: 28
  if day > maximumDay: return -1

  if month <= 2:
    dec year
    month += 12
  let century = year div 100
  let yearOfCentury = year mod 100
  let monthTerm = (260 * month - 539) div 100
  let total = day + yearOfCentury + monthTerm + century div 4 + yearOfCentury div 4 - 2 * century
  ((total mod 7) + 7) mod 7
