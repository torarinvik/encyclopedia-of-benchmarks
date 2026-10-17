const
  MaxDimension = 16
  MaxParseableInputLength = 259
  MaxOutputBytes = 4 * MaxDimension * MaxDimension

proc storeI32Le(output: ptr UncheckedArray[uint8], offset: int, value: int32) =
  let bits = cast[uint32](value)
  for byte in 0 ..< 4:
    output[offset + byte] = uint8((bits shr (byte * 8)) and 255)

proc mirror_of_matrix*(values: ptr UncheckedArray[int64], length: csize_t,
    output: ptr UncheckedArray[uint8], outputCapacity: csize_t): int64
    {.cdecl, exportc: "mirror_of_matrix".} =
  if values == nil or length < 2 or length > csize_t(MaxParseableInputLength): return -1
  let rawRows = values[0]
  let rawColumns = values[1]
  if rawRows < 1 or rawRows > MaxDimension or rawColumns < 1 or rawColumns > MaxDimension: return -1
  let rows = int(rawRows)
  let columns = int(rawColumns)
  let cellCount = rows * columns
  if length != csize_t(2 + cellCount): return -1
  for index in 0 ..< cellCount:
    let cell = values[2 + index]
    if cell < -2147483648'i64 or cell > 2147483647'i64: return -1

  let byteCount = cellCount * 4
  if output == nil or outputCapacity < csize_t(byteCount): return -2
  for row in 0 ..< rows:
    for column in 0 ..< columns:
      let sourceIndex = 2 + row * columns + (columns - 1 - column)
      storeI32Le(output, 4 * (row * columns + column), int32(values[sourceIndex]))
  int64(byteCount)
