const MinYear = 1899'i64
const MaxYear = 2100'i64
const MaxOutputBytes = 181
const Header = "M   T   W   Th  F   S   Su\n"

proc isLeapYear(year: int64): bool =
  year mod 400 == 0 or (year mod 100 != 0 and year mod 4 == 0)

proc monthLength(year, month: int64): int =
  if month == 2 and isLeapYear(year): return 29
  if month == 2: return 28
  if month == 4 or month == 6 or month == 9 or month == 11: return 30
  31

proc startOffset(month, year: int64): int =
  var difference = 0'i64
  if year >= 1900:
    var currentYear = 1900'i64
    while currentYear < year:
      difference += (if isLeapYear(currentYear): 366'i64 else: 365'i64)
      inc currentYear
    var currentMonth = 1'i64
    while currentMonth < month:
      difference += int64(monthLength(year, currentMonth))
      inc currentMonth
    return int(difference mod 7)
  var currentYear = year
  while currentYear < 1900:
    difference += (if isLeapYear(currentYear): 366'i64 else: 365'i64)
    inc currentYear
  var currentMonth = 1'i64
  while currentMonth < month:
    difference -= int64(monthLength(1900, currentMonth))
    inc currentMonth
  int((7 - difference mod 7) mod 7)

proc writeByte(output: ptr UncheckedArray[uint8], position: var int, value: uint8) =
  output[position] = value
  inc position

proc writeCell(output: ptr UncheckedArray[uint8], position: var int, day: int) =
  if day == 0:
    for _ in 0 ..< 4: writeByte(output, position, uint8(32))
  elif day >= 10:
    writeByte(output, position, uint8(ord('0') + day div 10))
    writeByte(output, position, uint8(ord('0') + day mod 10))
    writeByte(output, position, uint8(32))
    writeByte(output, position, uint8(32))
  else:
    writeByte(output, position, uint8(ord('0') + day))
    writeByte(output, position, uint8(32))
    writeByte(output, position, uint8(32))
    writeByte(output, position, uint8(32))

proc find_month_calendar*(values: ptr UncheckedArray[int64], length: csize_t,
                          output: ptr UncheckedArray[uint8], outputCapacity: csize_t): int64
    {.cdecl, exportc: "find_month_calendar".} =
  if values == nil or length != 2: return -1
  let month = values[0]
  let year = values[1]
  if month < 1 or month > 12 or year < MinYear or year > MaxYear: return -1

  let offset = startOffset(month, year)
  let totalCells = offset + monthLength(year, month)
  let required = Header.len + totalCells * 4 + (totalCells + 6) div 7
  if required > MaxOutputBytes: return -1
  if output == nil or outputCapacity < csize_t(required): return -2

  var position = 0
  for byte in Header:
    writeByte(output, position, uint8(ord(byte)))
  var cursor = 0
  while cursor < totalCells:
    let cells = min(7, totalCells - cursor)
    for column in 0 ..< cells:
      let cell = cursor + column
      let day = if cell < offset: 0 else: cell - offset + 1
      writeCell(output, position, day)
    writeByte(output, position, uint8(10))
    cursor += cells
  int64(position)
