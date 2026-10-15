const MaxDimension = 16
const InvalidResult = low(int64)

proc prefix_sum2_d*(input: ptr UncheckedArray[int64], length: csize_t): int64
    {.cdecl, exportc: "prefix_sum2_d".} =
  if input == nil or length < 7: return InvalidResult
  let rawRows = input[0]
  let rawCols = input[1]
  if rawRows < 1 or rawRows > MaxDimension.int64 or rawCols < 1 or rawCols > MaxDimension.int64:
    return InvalidResult
  let rows = int(rawRows)
  let cols = int(rawCols)
  if length != csize_t(2 + rows * cols + 4): return InvalidResult
  let query = 2 + rows * cols
  let row1v = input[query]
  let col1v = input[query + 1]
  let row2v = input[query + 2]
  let col2v = input[query + 3]
  if row1v < 0 or col1v < 0 or row2v < row1v or col2v < col1v or
      row2v >= int64(rows) or col2v >= int64(cols): return InvalidResult
  var prefix: array[MaxDimension + 1, array[MaxDimension + 1, int64]]
  for i in 0 ..< rows:
    for j in 0 ..< cols:
      let value = input[2 + i * cols + j]
      if value < -1000 or value > 1000: return InvalidResult
      prefix[i + 1][j + 1] = value + prefix[i][j + 1] + prefix[i + 1][j] - prefix[i][j]
  let row1 = int(row1v)
  let col1 = int(col1v)
  let row2 = int(row2v)
  let col2 = int(col2v)
  prefix[row2 + 1][col2 + 1] - prefix[row1][col2 + 1] -
    prefix[row2 + 1][col1] + prefix[row1][col1]
