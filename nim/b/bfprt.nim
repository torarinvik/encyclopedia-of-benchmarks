const MaxSize = 1024
const Invalid = -2_147_483_649'i64

proc swapValues(values: var array[MaxSize, int32], left, right: int) =
  let temporary = values[left]
  values[left] = values[right]
  values[right] = temporary

proc insertionSort(values: var array[MaxSize, int32], left, right: int) =
  var index = left + 1
  while index <= right:
    var cursor = index
    while cursor > left and values[cursor - 1] > values[cursor]:
      swapValues(values, cursor - 1, cursor)
      dec cursor
    inc index

proc selectBfprt(values: var array[MaxSize, int32], left, right, rank: int): int32

proc medianOfMedians(values: var array[MaxSize, int32], left, right: int): int32 =
  let count = right - left + 1
  let groups = (count + 4) div 5
  for group in 0 ..< groups:
    let groupLeft = left + group * 5
    let groupRight = min(right, groupLeft + 4)
    insertionSort(values, groupLeft, groupRight)
    let median = groupLeft + (groupRight - groupLeft + 1) div 2
    swapValues(values, left + group, median)
  if groups == 1:
    return values[left]
  selectBfprt(values, left, left + groups - 1, left + groups div 2)

proc selectBfprt(values: var array[MaxSize, int32], leftValue, rightValue, rank: int): int32 =
  var left = leftValue
  var right = rightValue
  while left < right:
    let pivot = medianOfMedians(values, left, right)
    var less = left
    var current = left
    var greater = right + 1
    while current < greater:
      if values[current] < pivot:
        swapValues(values, less, current)
        inc less
        inc current
      elif values[current] > pivot:
        dec greater
        swapValues(values, current, greater)
      else:
        inc current
    if rank < less:
      right = less - 1
    elif rank >= greater:
      left = greater
    else:
      return values[rank]
  values[left]

proc bfprt*(input: ptr UncheckedArray[int64], length: csize_t): int64
    {.cdecl, exportc: "bfprt".} =
  if input.isNil or length < 2: return Invalid
  let countValue = input[0]
  let rankValue = input[1]
  if countValue < 1 or countValue > MaxSize: return Invalid
  let count = int(countValue)
  if length != csize_t(count + 2) or rankValue < 1 or rankValue > countValue: return Invalid

  var values: array[MaxSize, int32]
  for index in 0 ..< count:
    let value = input[index + 2]
    if value < int64(low(int32)) or value > int64(high(int32)): return Invalid
    values[index] = int32(value)
  int64(selectBfprt(values, 0, count - 1, int(rankValue - 1)))
