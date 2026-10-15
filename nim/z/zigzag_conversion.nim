## Arrange ASCII letters in zigzag rows and read them row by row.
const MaxInputLength = 1025
const MaxRows = 1024

proc isAsciiLetter(value: int64): bool =
  (value >= 65 and value <= 90) or (value >= 97 and value <= 122)

proc zigzag_conversion*(values: ptr UncheckedArray[int64], length: csize_t,
    output: ptr UncheckedArray[uint8], outputCapacity: csize_t): int64
    {.cdecl, exportc: "zigzag_conversion".} =
  if length == 0 or length > csize_t(MaxInputLength) or values == nil: return -1
  let rowsValue = values[0]
  if rowsValue < 1 or rowsValue > MaxRows: return -1
  let textLength = length - 1
  for index in 0 ..< int(textLength):
    if not isAsciiLetter(values[index + 1]): return -1
  if outputCapacity < textLength or (textLength != 0 and output == nil): return -2
  if textLength == 0: return 0
  let rows = int(rowsValue)
  if rows == 1 or rows >= int(textLength):
    for index in 0 ..< int(textLength): output[index] = uint8(values[index + 1])
    return int64(textLength)
  let cycle = 2 * (rows - 1)
  var written = 0
  for row in 0 ..< rows:
    var index = row
    var step = if row == 0 or row + 1 == rows: cycle else: cycle - 2 * row
    while index < int(textLength):
      output[written] = uint8(values[index + 1])
      inc written
      index += step
      if row > 0 and row + 1 < rows: step = cycle - step
  int64(written)
