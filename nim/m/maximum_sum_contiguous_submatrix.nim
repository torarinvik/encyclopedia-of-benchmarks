import std/ffi

const MaxParseableInputLength = 67
const OutputBytes = 8

proc writeI64Le(output: ptr UncheckedArray[uint8], value: int64) =
  let bits = cast[uint64](value)
  for byte in 0 ..< 8:
    output[byte] = uint8((bits shr (byte * 8)) and 255'u64)

proc maximumSumContiguousSubmatrix*(input: ptr UncheckedArray[int64],
    length: csize_t, output: ptr UncheckedArray[uint8],
    outputCapacity: csize_t): int64
    {.cdecl, exportc: "maximum_sum_contiguous_submatrix".} =
  if input == nil or length < 2 or length > csize_t(MaxParseableInputLength): return -1
  let rowsValue = input[0]
  let columnsValue = input[1]
  if rowsValue < 1 or rowsValue > 8 or columnsValue < 1 or columnsValue > 8: return -1
  let rows = int(rowsValue)
  let columns = int(columnsValue)
  let cells = rows * columns
  if length != csize_t(2 + cells): return -1
  for index in 0 ..< cells:
    if input[index + 2] < -1000 or input[index + 2] > 1000: return -1

  var best = -64001'i64
  var columnSums: array[8, int64]
  for top in 0 ..< rows:
    for column in 0 ..< columns: columnSums[column] = 0
    for bottom in top ..< rows:
      let rowOffset = 2 + bottom * columns
      for column in 0 ..< columns:
        columnSums[column] += input[rowOffset + column]
      var current = columnSums[0]
      if current > best: best = current
      for column in 1 ..< columns:
        if current < 0: current = columnSums[column]
        else: current += columnSums[column]
        if current > best: best = current
  if output == nil or outputCapacity < csize_t(OutputBytes): return -2
  writeI64Le(output, best)
  int64(OutputBytes)
