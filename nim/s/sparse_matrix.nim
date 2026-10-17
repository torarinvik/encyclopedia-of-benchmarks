proc sparse_matrix*(values: ptr UncheckedArray[int64], length: csize_t): int64
    {.cdecl, exportc: "sparse_matrix".} =
  if values == nil or length < 2 or length > 4099: return -1
  let rowsValue = values[0]
  let columnsValue = values[1]
  if rowsValue < 1 or rowsValue > 64 or columnsValue < 1 or columnsValue > 64: return -1
  let rows = int(rowsValue)
  let columns = int(columnsValue)
  let cells = rows * columns
  if length != csize_t(2 + cells): return -1
  var zeroCount = 0
  for index in 0 ..< cells:
    let value = values[2 + index]
    if value < -2_147_483_648'i64 or value > 2_147_483_647'i64: return -1
    if value == 0: inc zeroCount
  int64(ord(zeroCount > cells div 2))
