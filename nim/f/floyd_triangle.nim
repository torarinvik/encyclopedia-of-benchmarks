## Generate Floyd's triangle as flattened little-endian 16-bit values.
const MaxRows = 90

proc floyd_triangle*(rows: int64, output: ptr UncheckedArray[uint8],
    outputCapacity: csize_t): int64 {.cdecl, exportc: "floyd_triangle".} =
  if rows < 0 or rows > MaxRows: return -1
  let count = int(rows) * (int(rows) + 1) div 2
  let outputLength = count * 2
  if outputCapacity < csize_t(outputLength) or (outputLength > 0 and output == nil): return -2
  var index = 0
  var number = 1
  var row = 1
  while row <= int(rows):
    var column = 0
    while column < row:
      output[index * 2] = uint8(number and 255)
      output[index * 2 + 1] = uint8((number shr 8) and 255)
      inc number
      inc index
      inc column
    inc row
  int64(outputLength)
