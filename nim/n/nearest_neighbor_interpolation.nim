type I64Array = ptr UncheckedArray[int64]
type ByteArray = ptr UncheckedArray[uint8]

proc nearest_neighbor_interpolation*(input: I64Array, length: csize_t, output: ByteArray,
                                      outputCapacity: csize_t): int64
    {.cdecl, exportc: "nearest_neighbor_interpolation".} =
  if input.isNil or length < 3 or length > 258: return -1
  let rowsValue = input[0]
  let columnsValue = input[1]
  if rowsValue < 1 or rowsValue > 16 or columnsValue < 1 or columnsValue > 16: return -1
  let rows = int(rowsValue)
  let columns = int(columnsValue)
  let inputCells = rows * columns
  if length != csize_t(2 + inputCells): return -1
  for index in 0 ..< inputCells:
    if input[2 + index] < 0 or input[2 + index] > 255: return -1

  let outputRows = 3 * rows div 2
  let outputColumns = 3 * columns div 2
  let outputBytes = outputRows * outputColumns
  if output.isNil or outputCapacity < csize_t(outputBytes): return -2
  for y in 0 ..< outputRows:
    let sourceY = (4 * (y + 1) + 3) div 6 - 1
    for x in 0 ..< outputColumns:
      let sourceX = (4 * (x + 1) + 3) div 6 - 1
      output[y * outputColumns + x] = uint8(input[2 + sourceY * columns + sourceX])
  int64(outputBytes)
