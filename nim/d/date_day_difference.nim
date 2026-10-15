## Absolute difference between two validated Gregorian dates.
const MaxLength = 21
const InvalidOrdinal = -1_000_000_000'i64

proc floorDiv(value, divisor: int64): int64 =
  result = value div divisor
  if value mod divisor != 0 and value < 0: dec result

proc leapYear(year: int64): bool =
  year mod 400 == 0 or (year mod 100 != 0 and year mod 4 == 0)

proc monthLength(month, year: int64): int64 =
  case month
  of 2: (if leapYear(year): 29'i64 else: 28'i64)
  of 4, 6, 9, 11: 30
  else: 31

proc dateOrdinal(day, month, year: int64): int64 =
  let prior = year - 1
  let adjustment = if month <= 2: 0'i64 elif leapYear(year): -1'i64 else: -2'i64
  365 * prior + floorDiv(prior, 4) - floorDiv(prior, 100) + floorDiv(prior, 400) +
    day + floorDiv(367 * month - 362, 12) + adjustment

proc parseDate(values: ptr UncheckedArray[int64], start, finish: int): int64 =
  var pos = start
  var day, month, year: int64 = 0
  var digits = 0
  while pos < finish and values[pos] >= 48 and values[pos] <= 57 and digits < 3:
    day = day * 10 + values[pos] - 48
    inc digits
    inc pos
  if digits < 1 or digits > 2 or pos >= finish or values[pos] != 47: return InvalidOrdinal
  inc pos
  digits = 0
  while pos < finish and values[pos] >= 48 and values[pos] <= 57 and digits < 3:
    month = month * 10 + values[pos] - 48
    inc digits
    inc pos
  if digits < 1 or digits > 2 or pos >= finish or values[pos] != 47: return InvalidOrdinal
  inc pos
  if finish - pos != 4: return InvalidOrdinal
  while pos < finish:
    if values[pos] < 48 or values[pos] > 57: return InvalidOrdinal
    year = year * 10 + values[pos] - 48
    inc pos
  if month < 1 or month > 12 or day < 1 or day > monthLength(month, year): return InvalidOrdinal
  dateOrdinal(day, month, year)

proc date_day_difference*(values: ptr UncheckedArray[int64], length: csize_t): int64
    {.cdecl, exportc: "date_day_difference".} =
  if length < 17 or length > csize_t(MaxLength) or values == nil: return -1
  var separator = int(length)
  for index in 0 ..< int(length):
    if values[index] == 124:
      if separator != int(length): return -1
      separator = index
  if separator == int(length): return -1
  let first = parseDate(values, 0, separator)
  let second = parseDate(values, separator + 1, int(length))
  if first == InvalidOrdinal or second == InvalidOrdinal: return -1
  if first > second: return first - second
  second - first
