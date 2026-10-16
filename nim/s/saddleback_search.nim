## Top-right staircase search for a strictly increasing integer matrix.
proc saddleback_search*(values: ptr UncheckedArray[int64], length: csize_t): int64
    {.cdecl, exportc: "saddleback_search".} =
  if values == nil or length < 3: return -1
  let rowsValue = values[0]
  let columnsValue = values[1]
  let target = values[2]
  if rowsValue <= 0 or rowsValue > 32 or columnsValue <= 0 or columnsValue > 32: return -1
  if target < -2147483648'i64 or target > 2147483647'i64: return -1
  let rows = csize_t(rowsValue)
  let columns = csize_t(columnsValue)
  let cells = rows * columns
  if length != 3 + cells: return -1
  var index: csize_t = 0
  while index < cells:
    let value = values[3 + index]
    if value < -2147483648'i64 or value > 2147483647'i64: return -1
    inc index

  var row: csize_t = 0
  var column = columns - 1
  while row < rows:
    let value = values[3 + row * columns + column]
    if value == target:
      return int64(row * columns + column + 1)
    if value < target:
      inc row
    elif column == 0:
      break
    else:
      dec column
  0
