const MaxInputLength = 3971
const MaxDimension = 63'i64
const MaxCellValue = 1000'i64

proc largest_product_in_a_grid*(values: ptr UncheckedArray[int64], length: csize_t): int64
    {.cdecl, exportc: "largest_product_in_a_grid".} =
  if values.isNil or length < 2 or length > csize_t(MaxInputLength): return -1
  let rows = values[0]
  let cols = values[1]
  if rows < 0 or rows > MaxDimension or cols < 0 or cols > MaxDimension: return -1

  let expectedLength = 2 + int(rows) * int(cols)
  if int(length) != expectedLength: return -1
  for index in 2 ..< expectedLength:
    if values[index] < 0 or values[index] > MaxCellValue: return -1

  let rowSteps = [0'i64, 1'i64, 1'i64, 1'i64]
  let colSteps = [1'i64, 0'i64, 1'i64, -1'i64]
  var best = 0'i64
  for row in 0 ..< int(rows):
    for col in 0 ..< int(cols):
      for direction in 0 ..< 4:
        var product = 1'i64
        for offset in 0 ..< 4:
          let nextRow = row.int64 + offset.int64 * rowSteps[direction]
          let nextCol = col.int64 + offset.int64 * colSteps[direction]
          if nextRow < 0 or nextRow >= rows or nextCol < 0 or nextCol >= cols:
            product = 0
            break
          let index = 2 + int(nextRow) * int(cols) + int(nextCol)
          product *= values[index]
        best = max(best, product)
  best
