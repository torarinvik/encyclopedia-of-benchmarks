const MaxValues = 256
const MaxInputLength = MaxValues + 2

proc siftDown(values: var array[MaxValues, int64], rootStart, endValue: int) =
  var root = rootStart
  while root < endValue div 2:
    var child = root * 2 + 1
    if child + 1 < endValue and values[child] < values[child + 1]: inc child
    if values[root] >= values[child]: break
    swap(values[root], values[child])
    root = child

proc heapSort(values: var array[MaxValues, int64], length: int) =
  var start = length div 2
  while start > 0:
    dec start
    siftDown(values, start, length)
  var ending = length
  while ending > 1:
    dec ending
    swap(values[0], values[ending])
    siftDown(values, 0, ending)

proc two_pointers_pair_count*(input: ptr UncheckedArray[int64], length: csize_t): int64
    {.cdecl, exportc: "two_pointers_pair_count".} =
  if input.isNil or length < 2 or length > csize_t(MaxInputLength): return -1
  let target = input[0]
  let countValue = input[1]
  if countValue < 0 or countValue > MaxValues: return -1
  let count = int(countValue)
  if length != csize_t(2 + count): return -1
  if target < -2_000_000 or target > 2_000_000: return -1

  var values: array[MaxValues, int64]
  for index in 0 ..< count:
    let value = input[2 + index]
    if value < -1_000_000 or value > 1_000_000: return -1
    values[index] = value
  heapSort(values, count)
  if count < 2: return 0
  var index = 1
  while index < count:
    if values[index - 1] == values[index]: return -1
    inc index

  var left = 0
  var right = count - 1
  var pairs = 0'i64
  while left < right:
    let sum = values[left] + values[right]
    if sum < target:
      inc left
    elif sum > target:
      dec right
    else:
      inc pairs
      inc left
  pairs

