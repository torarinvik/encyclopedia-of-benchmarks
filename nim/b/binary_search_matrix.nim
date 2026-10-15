## Recursive row search matching the pinned matrix-search source.
proc searchRow(values: ptr UncheckedArray[int64], base: csize_t,
    lower, upper, target: int64): int64 =
  let middle = (lower + upper) div 2
  let value = values[base + csize_t(middle)]
  if value == target: return middle
  if lower >= upper: return -1
  if value < target: return searchRow(values, base, middle + 1, upper, target)
  searchRow(values, base, lower, middle - 1, target)

proc binary_search_matrix*(values: ptr UncheckedArray[int64], length: csize_t): int64
    {.cdecl, exportc: "binary_search_matrix".} =
  if values == nil or length < 3: return -1
  let rowsValue = values[0]
  let columnsValue = values[1]
  let target = values[2]
  if rowsValue <= 0 or rowsValue > 32 or columnsValue <= 0 or columnsValue > 32: return -1
  let rows = csize_t(rowsValue)
  let columns = csize_t(columnsValue)
  if length != 3 + rows * columns: return -1
  if values[3] == target: return 0
  var row: csize_t = 0
  while row < rows and values[3 + row * columns] < target:
    let column = searchRow(values, 3 + row * columns, 0, int64(columns) - 1, target)
    if column != -1: return int64(row * columns) + column
    inc row
  -1
