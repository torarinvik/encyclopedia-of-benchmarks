const MaxDimension = 32

proc storeI64Le(output: ptr UncheckedArray[byte], offset: int, value: int64) =
  let bits = cast[uint64](value)
  for index in 0 ..< 8:
    output[offset + index] = byte((bits shr (index * 8)) and 255)

proc matrixCopy(values: ptr UncheckedArray[int64], length: csize_t,
                output: ptr UncheckedArray[byte], outputCapacity: csize_t): int64 {.cdecl, exportc: "matrix_copy".} =
  if values == nil or length < 2 or length > 2 + MaxDimension * MaxDimension: return -1
  let rowsValue = values[0]
  let columnsValue = values[1]
  if rowsValue < 0 or rowsValue > MaxDimension or columnsValue < 0 or columnsValue > MaxDimension: return -1
  let rows = int(rowsValue)
  let columns = int(columnsValue)
  let elementCount = rows * columns
  if int(length) != 2 + elementCount: return -1
  for index in 0 ..< elementCount:
    if values[2 + index] < int32.low or values[2 + index] > int32.high: return -1
  let resultRows = if rows == 0 or columns == 0: 0 else: rows
  let resultColumns = if rows == 0 or columns == 0: 0 else: columns
  let resultCount = resultRows * resultColumns
  let outputBytes = (2 + resultCount) * 8
  if output == nil or int(outputCapacity) < outputBytes: return -2
  storeI64Le(output, 0, int64(resultRows))
  storeI64Le(output, 8, int64(resultColumns))
  for index in 0 ..< resultCount:
    storeI64Le(output, 16 + index * 8, values[2 + index])
  int64(outputBytes)
