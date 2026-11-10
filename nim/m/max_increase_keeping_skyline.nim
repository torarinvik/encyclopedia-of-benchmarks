## Return the total allowable increase while preserving row and column skylines.
const MaxGridSize = 50

proc max_increase_keeping_skyline*(values: ptr UncheckedArray[int64], length: csize_t): int64
    {.cdecl, exportc: "max_increase_keeping_skyline".} =
  if values.isNil or length < 2 or length > csize_t(1 + MaxGridSize * MaxGridSize): return -1
  if values[0] < 2 or values[0] > MaxGridSize: return -1
  let size = int(values[0])
  if length != csize_t(1 + size * size): return -1

  var rowMax, columnMax: array[MaxGridSize, uint8]
  var tallest: uint64
  var heightSum: uint32
  for row in 0 ..< size:
    var rowTallest: uint8
    let start = 1 + row * size
    for column in 0 ..< size:
      let value = cast[uint64](values[start + column])
      tallest = max(tallest, value)
      heightSum += uint32(value)
      let height = uint8(value)
      rowTallest = max(rowTallest, height)
      columnMax[column] = max(columnMax[column], height)
    rowMax[row] = rowTallest
  if tallest > 100: return -1

  var skylineSum: uint32
  if size <= 10:
    for row in 0 ..< size:
      for column in 0 ..< size:
        skylineSum += uint32(min(rowMax[row], columnMax[column]))
  else:
    var rowCounts, columnCounts: array[101, uint8]
    var lowest = 100
    for index in 0 ..< size:
      lowest = min(lowest, min(int(rowMax[index]), int(columnMax[index])))
      inc rowCounts[int(rowMax[index])]
      inc columnCounts[int(columnMax[index])]
    var rowsAbove = uint32(size)
    var columnsAbove = uint32(size)
    skylineSum = rowsAbove * columnsAbove * uint32(lowest)
    for height in lowest ..< int(tallest):
      rowsAbove -= uint32(rowCounts[height])
      columnsAbove -= uint32(columnCounts[height])
      skylineSum += rowsAbove * columnsAbove
  int64(skylineSum - heightSum)
