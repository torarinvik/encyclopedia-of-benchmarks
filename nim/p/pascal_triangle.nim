const MaxRows = 30
const HashMod = 1_000_000_007'i64

proc pascal_triangle_benchmark*(values: ptr UncheckedArray[int64], length: csize_t): int64
    {.cdecl, exportc: "pascal_triangle_benchmark".} =
  if length != 1: return -1
  let rowCountValue = values[0]
  if rowCountValue < 0 or rowCountValue > MaxRows.int64: return -1
  let rowCount = rowCountValue.int
  var row: array[MaxRows, int64]
  row[0] = 1
  var hash = 0'i64
  for rowIndex in 0 ..< rowCount:
    var column = rowIndex
    while column > 0:
      row[column] += row[column - 1]
      dec column
    for col in 0 .. rowIndex:
      hash = (hash * 31 + row[col] mod HashMod) mod HashMod
  hash
