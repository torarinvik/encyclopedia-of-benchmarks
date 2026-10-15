## Return the total allowable increase while preserving row and column skylines.
const MaxGridSize = 50

proc max_increase_keeping_skyline*(values: ptr UncheckedArray[int64], length: csize_t): int64
    {.cdecl, exportc: "max_increase_keeping_skyline".} =
  if values.isNil or length < 2 or length > csize_t(1 + MaxGridSize * MaxGridSize): return -1
  if values[0] < 2 or values[0] > MaxGridSize: return -1
  let size = int(values[0])
  if length != csize_t(1 + size * size): return -1

  var rowMax: array[MaxGridSize, int64]
  var columnMax: array[MaxGridSize, int64]
  for row in 0 ..< size:
    for column in 0 ..< size:
      let height = values[1 + row * size + column]
      if height < 0 or height > 100: return -1
      if height > rowMax[row]: rowMax[row] = height
      if height > columnMax[column]: columnMax[column] = height

  var total = 0'i64
  for row in 0 ..< size:
    for column in 0 ..< size:
      let height = values[1 + row * size + column]
      total += min(rowMax[row], columnMax[column]) - height
  total
