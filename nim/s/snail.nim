const MaxCells = 16 * 16
const MaxInputLength = 259

proc writeI32Le(output: ptr UncheckedArray[uint8], index: int, value: int32) =
  let bits = cast[uint32](value)
  let offset = index * 4
  for byte in 0 ..< 4:
    output[offset + byte] = uint8((bits shr (byte * 8)) and 0xff'u32)

proc snail*(values: ptr UncheckedArray[int32], length: csize_t,
    output: ptr UncheckedArray[uint8], outputCapacity: csize_t): int64
    {.cdecl, exportc: "snail".} =
  if values.isNil or length < 2 or length > MaxInputLength: return -1
  let rowsValue = values[0]
  let columnsValue = values[1]
  if rowsValue < 0 or rowsValue > 16 or columnsValue < 0 or columnsValue > 16: return -1
  if rowsValue == 0 and columnsValue != 0: return -1
  if columnsValue == 1 and rowsValue != 1: return -1

  let rows = int(rowsValue)
  let columns = int(columnsValue)
  let cellCount = rows * columns
  if int(length) != 2 + cellCount: return -1

  let requiredBytes = cellCount * 4
  if output.isNil or outputCapacity < csize_t(requiredBytes): return -2
  if cellCount == 0: return 0

  var matrix: array[MaxCells, int32]
  for index in 0 ..< cellCount:
    matrix[index] = values[2 + index]

  var top = 0
  var bottom = rows - 1
  var left = 0
  var right = columns - 1
  var written = 0
  while top <= bottom and left <= right:
    for column in left .. right:
      writeI32Le(output, written, matrix[top * columns + column])
      inc written
    inc top

    for row in top .. bottom:
      writeI32Le(output, written, matrix[row * columns + right])
      inc written
    dec right

    if top <= bottom and left <= right:
      var column = right
      while true:
        writeI32Le(output, written, matrix[bottom * columns + column])
        inc written
        if column == left: break
        dec column
      dec bottom

    if top <= bottom and left <= right:
      var row = bottom
      while true:
        writeI32Le(output, written, matrix[row * columns + left])
        inc written
        if row == top: break
        dec row
      inc left

  int64(requiredBytes)
