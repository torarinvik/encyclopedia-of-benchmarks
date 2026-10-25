const MaxRows = 8
const MaxCols = 8
const MaxCells = MaxRows * MaxCols
const MaxInputLength = 2 + 2 * MaxCells
const BytesPerValue = 8

proc storeI64Le(output: ptr UncheckedArray[uint8], position: int, value: int64) =
  let bits = cast[uint64](value)
  for byte in 0 ..< BytesPerValue:
    output[position + byte] = uint8((bits shr (byte * 8)) and 255'u64)

proc tsvc_s343_column_major_compaction*(input: ptr UncheckedArray[int64], length: csize_t,
    output: ptr UncheckedArray[uint8], outputCapacity: csize_t): int64
    {.cdecl, exportc: "tsvc_s343_column_major_compaction".} =
  if input == nil or length < 4 or length > csize_t(MaxInputLength): return -1
  let rowsValue = input[0]
  let colsValue = input[1]
  if rowsValue < 1 or rowsValue > MaxRows or colsValue < 1 or colsValue > MaxCols: return -1
  let rows = int(rowsValue)
  let cols = int(colsValue)
  let cells = rows * cols
  if int(length) != 2 + 2 * cells: return -1
  if output == nil or outputCapacity < csize_t(cells * BytesPerValue): return -2

  let dataStart = 2
  let maskStart = dataStart + cells
  var written = 0
  for col in 0 ..< cols:
    for row in 0 ..< rows:
      let index = row * cols + col
      if input[maskStart + index] > 0:
        storeI64Le(output, written * BytesPerValue, input[dataStart + index])
        inc written
  int64(written)
