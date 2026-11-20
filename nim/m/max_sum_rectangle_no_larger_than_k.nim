const MaxRows = 8
const MaxColumns = 8
const NoFeasible = -1025'i64
const InvalidInput = -1026'i64

proc bestSubarrayAtMost(values: array[MaxColumns, int64], count: int, limit: int64): int64 =
  var prefixes: array[MaxColumns + 1, int64]
  var prefixCount = 1
  var running = 0'i64
  result = NoFeasible
  for i in 0 ..< count:
    running += values[i]
    let threshold = running - limit
    var low = 0
    var high = prefixCount
    while low < high:
      let middle = low + (high - low) div 2
      if prefixes[middle] < threshold: low = middle + 1
      else: high = middle
    if low < prefixCount:
      let candidate = running - prefixes[low]
      if result == NoFeasible or candidate > result: result = candidate
    var insert = prefixCount
    while insert > 0 and prefixes[insert - 1] > running:
      prefixes[insert] = prefixes[insert - 1]
      dec insert
    prefixes[insert] = running
    inc prefixCount

proc max_sum_rectangle_no_larger_than_k*(input: ptr UncheckedArray[int64], length: csize_t): int64
    {.cdecl, exportc: "max_sum_rectangle_no_larger_than_k".} =
  if input == nil or length < 3 or length > 68: return InvalidInput
  let rowsValue = input[0]
  let columnsValue = input[1]
  let limit = input[2]
  if rowsValue < 1 or rowsValue > MaxRows or columnsValue < 1 or columnsValue > MaxColumns
      or limit < -1024 or limit > 1024: return InvalidInput
  let rows = int(rowsValue)
  let columns = int(columnsValue)
  if length != 3 + rows * columns: return InvalidInput
  var matrix: array[MaxRows, array[MaxColumns, int64]]
  for row in 0 ..< rows:
    for column in 0 ..< columns:
      let value = input[3 + row * columns + column]
      if value < -16 or value > 16: return InvalidInput
      matrix[row][column] = value
  let shortDimension = min(rows, columns)
  let longDimension = max(rows, columns)
  var best = NoFeasible
  for first in 0 ..< shortDimension:
    var compressed: array[MaxColumns, int64]
    for last in first ..< shortDimension:
      for offset in 0 ..< longDimension:
        compressed[offset] += (if rows <= columns: matrix[last][offset] else: matrix[offset][last])
      let candidate = bestSubarrayAtMost(compressed, longDimension, limit)
      if candidate != NoFeasible and (best == NoFeasible or candidate > best):
        best = candidate
        if best == limit: return best
  best
