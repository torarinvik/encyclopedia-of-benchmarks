const
  MaxRows = 80
  MaxColumns = 80
  MaxCellValue = 9999'i64

proc problem82*(input: ptr UncheckedArray[int64], length: csize_t): int64 {.cdecl, exportc: "problem82".} =
  if input.isNil or length < 3: return -1
  let rowValue = input[0]
  let columnValue = input[1]
  if rowValue < 1 or rowValue > MaxRows or columnValue < 1 or columnValue > MaxColumns: return -1
  let rows = int(rowValue)
  let columns = int(columnValue)
  if length != csize_t(2 + rows * columns): return -1
  for index in 2 ..< int(length):
    if input[index] < 0 or input[index] > MaxCellValue: return -1

  var costs: array[MaxRows, int64]
  for row in 0 ..< rows: costs[row] = input[2 + row * columns]
  for column in 1 ..< columns:
    let offset = 2 + column
    for row in 0 ..< rows: costs[row] += input[offset + row * columns]
    for row in 1 ..< rows:
      let fromAbove = costs[row - 1] + input[offset + row * columns]
      if fromAbove < costs[row]: costs[row] = fromAbove
    var row = rows - 1
    while row > 0:
      let fromBelow = costs[row] + input[offset + (row - 1) * columns]
      if fromBelow < costs[row - 1]: costs[row - 1] = fromBelow
      dec row
  var best = costs[0]
  for row in 1 ..< rows:
    if costs[row] < best: best = costs[row]
  best
