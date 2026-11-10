## Count right/down paths through a packed obstacle grid.
const MaxRows = 20
const MaxColumns = 20

proc unique_paths_with_obstacles*(input: ptr UncheckedArray[int64],
                                  length: csize_t): int64
    {.cdecl, exportc: "unique_paths_with_obstacles".} =
  if input.isNil or length < 2: return -1
  let rowsValue = input[0]
  let columnsValue = input[1]
  if rowsValue < 1 or rowsValue > MaxRows or columnsValue < 1 or columnsValue > MaxColumns: return -1
  let rows = int(rowsValue)
  let columns = int(columnsValue)
  if length != csize_t(2 + rows * columns): return -1

  var paths: array[MaxColumns, uint64]
  paths[0] = 1
  var cellsSeen = 0'u64
  var left = 0'u64
  var index = 2
  while index < int(length):
    left = 0
    for column in 0 ..< columns:
      let obstacle = cast[uint64](input[index])
      cellsSeen = cellsSeen or obstacle
      left = if obstacle == 0: left + paths[column] else: 0'u64
      paths[column] = left
      inc index
  if cellsSeen > 1: return -1
  int64(left)
