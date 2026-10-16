const MaxRows = 15
const MaxValues = MaxRows * (MaxRows + 1) div 2
const ValueLimit = 1_000_000'i64

proc problem18*(input: ptr UncheckedArray[int64], length: csize_t): int64 {.cdecl, exportc: "problem18".} =
  if input == nil or length < 2 or length > (MaxValues + 1).csize_t: return -1
  let rows = input[0]
  if rows < 1 or rows > MaxRows.int64 or length.int != (rows * (rows + 1) div 2).int + 1: return -1
  var best: array[MaxValues, int64]
  let valueCount = length.int - 1
  for index in 0 ..< valueCount:
    let value = input[index + 1]
    if value < 0 or value > ValueLimit: return -1
    best[index] = value
  var row = rows - 1
  while row > 0:
    let parentStart = ((row - 1) * row div 2).int
    let childStart = (row * (row + 1) div 2).int
    for column in 0 ..< row.int:
      let parent = parentStart + column
      let child = childStart + column
      let left = best[child]
      let right = best[child + 1]
      best[parent] += max(left, right)
    row -= 1
  best[0]
