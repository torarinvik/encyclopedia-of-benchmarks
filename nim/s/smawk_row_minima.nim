const MaxRows = 16
const MaxColumns = 16
const MaxInputLength = 260

proc smawk(input: ptr UncheckedArray[int64], columnCount: int,
           rowWork: var array[2 * MaxRows, int32], rowOffset, rowCount: int,
           columnWork: var array[3 * MaxColumns, int32], inputColumnOffset,
           inputColumnCount, outputColumnOffset: int,
           minima: var array[MaxRows, int32]) =
  if rowCount == 0: return
  if rowCount == 1:
    let row = int(rowWork[rowOffset])
    var best = int(columnWork[inputColumnOffset])
    for j in 1 ..< inputColumnCount:
      let candidate = int(columnWork[inputColumnOffset + j])
      if input[2 + row * columnCount + candidate] < input[2 + row * columnCount + best]: best = candidate
    minima[row] = int32(best)
    return

  var reducedCount = 0
  for j in 0 ..< inputColumnCount:
    let candidate = int(columnWork[inputColumnOffset + j])
    while reducedCount > 0:
      let comparisonRow = int(rowWork[rowOffset + reducedCount - 1])
      let previous = int(columnWork[outputColumnOffset + reducedCount - 1])
      if input[2 + comparisonRow * columnCount + candidate] < input[2 + comparisonRow * columnCount + previous]: dec reducedCount
      else: break
    if reducedCount < rowCount:
      columnWork[outputColumnOffset + reducedCount] = int32(candidate)
      inc reducedCount

  let oddOffset = rowOffset + rowCount
  var oddCount = 0
  for i in countup(1, rowCount - 1, 2):
    rowWork[oddOffset + oddCount] = rowWork[rowOffset + i]
    inc oddCount
  let childOutputOffset = outputColumnOffset + reducedCount
  smawk(input, columnCount, rowWork, oddOffset, oddCount,
        columnWork, outputColumnOffset, reducedCount, childOutputOffset, minima)

  var startCursor = 0
  var endCursor = 0
  for i in countup(0, rowCount - 1, 2):
    var start = 0
    if i > 0:
      let target = minima[int(rowWork[rowOffset + i - 1])]
      while startCursor < reducedCount and columnWork[outputColumnOffset + startCursor] != target: inc startCursor
      start = min(startCursor, reducedCount - 1)
    var last = reducedCount - 1
    if i + 1 < rowCount:
      let target = minima[int(rowWork[rowOffset + i + 1])]
      if endCursor < start: endCursor = start
      while endCursor < reducedCount and columnWork[outputColumnOffset + endCursor] != target: inc endCursor
      last = min(endCursor, reducedCount - 1)
    let row = int(rowWork[rowOffset + i])
    var best = int(columnWork[outputColumnOffset + start])
    var position = start + 1
    while position <= last:
      let candidate = int(columnWork[outputColumnOffset + position])
      if input[2 + row * columnCount + candidate] < input[2 + row * columnCount + best]: best = candidate
      inc position
    minima[row] = int32(best)

proc storeI64Le(output: ptr UncheckedArray[uint8], offset: int, value: int64) =
  let bits = uint64(value)
  for byte in 0 ..< 8: output[offset + byte] = uint8((bits shr (byte * 8)) and 255)

proc smawk_row_minima*(input: ptr UncheckedArray[int64], length: csize_t,
    output: ptr UncheckedArray[uint8], capacity: csize_t): int64
    {.cdecl, exportc: "smawk_row_minima".} =
  if input == nil or length < 3 or length > csize_t(MaxInputLength): return -1
  if input[0] < 1 or input[0] > MaxRows or input[1] < 1 or input[1] > MaxColumns: return -1
  let rowCount = int(input[0])
  let columnCount = int(input[1])
  if length != csize_t(2 + rowCount * columnCount): return -1

  var rowWork: array[2 * MaxRows, int32]
  var columnWork: array[3 * MaxColumns, int32]
  var minima: array[MaxRows, int32]
  for i in 0 ..< rowCount: rowWork[i] = int32(i)
  for j in 0 ..< columnCount: columnWork[j] = int32(j)
  smawk(input, columnCount, rowWork, 0, rowCount, columnWork, 0, columnCount, MaxColumns, minima)

  let outputBytes = rowCount * 8
  if output == nil or capacity < csize_t(outputBytes): return -2
  var staged: array[8 * MaxRows, uint8]
  for i in 0 ..< rowCount: storeI64Le(cast[ptr UncheckedArray[uint8]](addr staged[0]), i * 8, int64(minima[i]))
  for i in 0 ..< outputBytes: output[i] = staged[i]
  int64(outputBytes)
