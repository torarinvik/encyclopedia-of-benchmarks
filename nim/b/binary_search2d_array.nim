proc searchRow(values: ptr UncheckedArray[int64], rowBase, low, high, target: int64): int64 =
  var lo = low
  var hi = high
  while lo <= hi:
    let middle = lo + (hi - lo) div 2
    let value = values[3 + rowBase + middle]
    if value == target: return middle
    if value < target: lo = middle + 1
    else: hi = middle - 1
  -1

proc binary_search2d_array*(values: ptr UncheckedArray[int64], length: csize_t): int64
    {.cdecl, exportc: "binary_search2d_array".} =
  if values == nil or length < 3: return -1
  let rows = values[0]
  let cols = values[1]
  let target = values[2]
  if rows < 2 or rows > 32 or cols < 3 or cols > 32: return -1
  if length != csize_t(3 + rows * cols): return -1
  let middleCol = cols div 2
  var startRow = 0'i64
  var endRow = rows - 1
  while startRow < endRow - 1:
    let middleRow = startRow + (endRow - startRow) div 2
    let value = values[3 + middleRow * cols + middleCol]
    if value == target: return middleRow * cols + middleCol
    if value < target: startRow = middleRow
    else: endRow = middleRow
  if values[3 + startRow * cols + middleCol] == target: return startRow * cols + middleCol
  if values[3 + endRow * cols + middleCol] == target: return endRow * cols + middleCol
  if target <= values[3 + startRow * cols + middleCol - 1]:
    let col = searchRow(values, startRow * cols, 0, middleCol - 1, target)
    return if col < 0: -1 else: startRow * cols + col
  if target >= values[3 + startRow * cols + middleCol + 1] and target <= values[3 + startRow * cols + cols - 1]:
    let col = searchRow(values, startRow * cols, middleCol + 1, cols - 1, target)
    return if col < 0: -1 else: startRow * cols + col
  if target <= values[3 + endRow * cols + middleCol - 1]:
    let col = searchRow(values, endRow * cols, 0, middleCol - 1, target)
    return if col < 0: -1 else: endRow * cols + col
  let col = searchRow(values, endRow * cols, middleCol + 1, cols - 1, target)
  if col < 0: -1 else: endRow * cols + col
