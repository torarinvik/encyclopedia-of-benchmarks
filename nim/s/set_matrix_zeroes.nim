const MaxDimension = 8'i64
const MaxInputLength = 67
const MaxCells = 64
const MinCell = -1_000_000'i64
const MaxCell = 1_000_000'i64

proc writeI64Le(output: ptr UncheckedArray[uint8], position: int, value: int64) =
  let bits = cast[uint64](value)
  for byte in 0 ..< 8:
    output[position + byte] = uint8((bits shr (8 * byte)) and 0xff)

proc set_matrix_zeroes*(input: ptr UncheckedArray[int64], length: csize_t,
                        output: ptr UncheckedArray[uint8], capacity: csize_t): int64
    {.cdecl, exportc: "set_matrix_zeroes".} =
  if input.isNil or length < 2 or length > csize_t(MaxInputLength): return -1
  let rowsValue = input[0]
  let columnsValue = input[1]
  if rowsValue < 1 or rowsValue > MaxDimension or columnsValue < 1 or columnsValue > MaxDimension:
    return -1
  let rows = int(rowsValue)
  let columns = int(columnsValue)
  let cells = rows * columns
  if length != csize_t(2 + cells): return -1

  var matrix: array[MaxCells, int64]
  for index in 0 ..< cells:
    let value = input[2 + index]
    if value < MinCell or value > MaxCell: return -1
    matrix[index] = value

  let bytes = cells * 8
  if output.isNil or capacity < csize_t(bytes): return -2

  var firstColumnZero = false
  for row in 0 ..< rows:
    if matrix[row * columns] == 0: firstColumnZero = true
    for column in 1 ..< columns:
      if matrix[row * columns + column] == 0:
        matrix[row * columns] = 0
        matrix[column] = 0
  for row in 1 ..< rows:
    for column in 1 ..< columns:
      if matrix[row * columns] == 0 or matrix[column] == 0:
        matrix[row * columns + column] = 0
  if matrix[0] == 0:
    for column in 0 ..< columns: matrix[column] = 0
  if firstColumnZero:
    for row in 0 ..< rows: matrix[row * columns] = 0

  for index in 0 ..< cells: writeI64Le(output, index * 8, matrix[index])
  int64(bytes)
