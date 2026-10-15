const MaxValues = 100_000

proc siftDown(values: var array[MaxValues, int64], rootStart, endExclusive: int) =
  var root = rootStart
  while root < endExclusive div 2:
    var child = root * 2 + 1
    if child + 1 < endExclusive and values[child] < values[child + 1]: inc child
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

proc mex*(input: ptr UncheckedArray[int64], length: csize_t): int64
    {.cdecl, exportc: "mex".} =
  if input.isNil or length < 1 or length > MaxValues + 1: return -1
  let countValue = input[0]
  if countValue < 0 or countValue > MaxValues or length != csize_t(countValue) + 1: return -1
  let count = int(countValue)
  var values: array[MaxValues, int64]
  for index in 0 ..< count:
    let value = input[index + 1]
    if value < int64(low(int32)) or value > int64(high(int32)): return -1
    values[index] = value
  heapSort(values, count)
  var candidate = 0'i64
  for index in 0 ..< count:
    if values[index] == candidate: inc candidate
  candidate
