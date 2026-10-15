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
  for index in 2 ..< int(length):
    if input[index] != 0 and input[index] != 1: return -1

  var paths: array[MaxColumns, int64]
  for column in 0 ..< columns: paths[column] = 0
  paths[0] = 1
  for row in 0 ..< rows:
    for column in 0 ..< columns:
      let obstacle = input[2 + row * columns + column]
      if obstacle == 1: paths[column] = 0
      elif column > 0: paths[column] += paths[column - 1]
  paths[columns - 1]
