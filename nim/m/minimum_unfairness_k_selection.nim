const MaxN = 64
const MinValue = -1_000_000_000'i64
const MaxValue = 1_000_000_000'i64

proc muksSiftDown(values: var array[MaxN, int64], rootStart, ending: int) =
  var root = rootStart
  while root < ending div 2:
    var child = root * 2 + 1
    if child + 1 < ending and values[child] < values[child + 1]:
      inc child
    if values[root] >= values[child]:
      break
    swap(values[root], values[child])
    root = child

proc muksHeapSort(values: var array[MaxN, int64], length: int) =
  var start = length div 2
  while start > 0:
    dec start
    muksSiftDown(values, start, length)
  var ending = length
  while ending > 1:
    dec ending
    swap(values[0], values[ending])
    muksSiftDown(values, 0, ending)

proc minimum_unfairness_k_selection*(packed: ptr UncheckedArray[int64], length: csize_t): int64
    {.cdecl, exportc: "minimum_unfairness_k_selection".} =
  if packed.isNil or length < 4 or length > csize_t(MaxN + 2):
    return -1
  let nValue = packed[0]
  let kValue = packed[1]
  if nValue < 2 or nValue > int64(MaxN) or kValue < 2 or kValue > nValue or length != csize_t(nValue + 2):
    return -1

  let n = int(nValue)
  let k = int(kValue)
  var sorted: array[MaxN, int64]
  for index in 0 ..< n:
    let value = packed[index + 2]
    if value < MinValue or value > MaxValue:
      return -1
    sorted[index] = value
  muksHeapSort(sorted, n)

  var best = 2_000_000_001'i64
  for first in 0 .. n - k:
    let width = sorted[first + k - 1] - sorted[first]
    if width < best:
      best = width
  best
