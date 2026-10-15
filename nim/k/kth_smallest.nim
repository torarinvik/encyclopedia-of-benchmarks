## One-based quickselect using the pinned last-element partition.
const MaxLength = 256
const InvalidResult = low(int64)

proc partitionValues(values: var array[MaxLength, int32], lowValue, highValue: int): int =
  let pivot = highValue
  var i = lowValue
  var j = highValue - 1
  while true:
    while values[i] < values[pivot]: inc i
    while j > 0 and values[j] > values[pivot]: dec j
    if j == 0 or i >= j: break
    if values[i] == values[j]:
      inc i
      dec j
    else:
      swap(values[i], values[j])
  swap(values[i], values[pivot])
  i

proc kth_smallest*(input: ptr UncheckedArray[int64], length: csize_t): int64
    {.cdecl, exportc: "kth_smallest".} =
  if input == nil or length < 3 or length > csize_t(MaxLength + 2): return InvalidResult
  let nValue = input[0]
  let kValue = input[1]
  if nValue < 1 or nValue > MaxLength or kValue < 1 or kValue > nValue or length != csize_t(nValue + 2): return InvalidResult
  let n = int(nValue)
  var values: array[MaxLength, int32]
  for index in 0 ..< n:
    let value = input[index + 2]
    if value < int64(low(int32)) or value > int64(high(int32)): return InvalidResult
    values[index] = int32(value)
  var lowIndex = 0
  var highIndex = n - 1
  var k = int(kValue)
  while lowIndex < highIndex:
    let pivot = partitionValues(values, lowIndex, highIndex)
    let pivotRank = pivot - lowIndex + 1
    if k == pivotRank: return int64(values[pivot])
    if k < pivotRank:
      highIndex = pivot - 1
    else:
      lowIndex = pivot + 1
      k -= pivotRank
  int64(values[lowIndex])
