proc isLeapYear(year: int64): bool =
  year mod 4 == 0 and (year mod 100 != 0 or year mod 400 == 0)

proc decodeOffset(offset: int64): tuple[year, ordinal: int64] =
  let shifted = offset + 719468
  let era = shifted div 146097
  let dayOfEra = shifted - era * 146097
  let yearOfEra = (dayOfEra - dayOfEra div 1460 + dayOfEra div 36524
      - dayOfEra div 146096) div 365
  var year = yearOfEra + era * 400
  let dayOfYearMarch = dayOfEra - (365 * yearOfEra + yearOfEra div 4 - yearOfEra div 100)
  let monthMarch = (5 * dayOfYearMarch + 2) div 153
  let day = dayOfYearMarch - (153 * monthMarch + 2) div 5 + 1
  let month = monthMarch + (if monthMarch < 10: 3 else: -9)
  if month <= 2: inc year
  let daysBeforeMonth: array[12, int64] = [0'i64, 31, 59, 90, 120, 151, 181, 212, 243, 273, 304, 334]
  let leapAdjustment = (if month > 2 and isLeapYear(year): 1'i64 else: 0'i64)
  (year, daysBeforeMonth[int(month - 1)] + leapAdjustment + day)

proc storeI64Le(output: ptr UncheckedArray[uint8], offset: int, value: int64) =
  var bits = cast[uint64](value)
  for byte in 0 ..< 8:
    output[offset + byte] = uint8(bits and 255)
    bits = bits shr 8

proc gregorian_daycount_to_ordinal_date*(input: ptr UncheckedArray[int64],
    length: csize_t, output: ptr UncheckedArray[uint8], capacity: csize_t): int64 {.cdecl, exportc.} =
  if input.isNil or length < 1 or length > 2 or length != 1: return -1
  let offset = input[0]
  if offset < -146097 or offset > 146097: return -1
  if output.isNil or capacity < 16: return -2
  let (year, ordinal) = decodeOffset(offset)
  storeI64Le(output, 0, year)
  storeI64Le(output, 8, ordinal)
  16
