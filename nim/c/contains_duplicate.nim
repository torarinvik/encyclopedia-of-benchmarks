## Sort a private copy, then scan neighbors for duplicates.
const MaxValues = 1024

proc siftDown(values: var array[MaxValues, int64], rootStart, length: int) =
  var root = rootStart
  while root < length div 2:
    var child = root * 2 + 1
    if child + 1 < length and values[child] < values[child + 1]: inc child
    if values[root] >= values[child]: break
    swap(values[root], values[child])
    root = child

proc contains_duplicate*(input: ptr UncheckedArray[int64], length: csize_t): int64
    {.cdecl, exportc: "contains_duplicate".} =
  if length > csize_t(MaxValues) or (length != 0 and input == nil): return -1
  var values: array[MaxValues, int64]
  let count = int(length)
  for index in 0 ..< count:
    let value = input[index]
    if value < low(int32).int64 or value > high(int32).int64: return -1
    values[index] = value
  var start = count div 2
  while start > 0:
    dec start
    siftDown(values, start, count)
  var ending = count
  while ending > 1:
    dec ending
    swap(values[0], values[ending])
    siftDown(values, 0, ending)
  for index in 1 ..< count:
    if values[index - 1] == values[index]: return 1
  0
