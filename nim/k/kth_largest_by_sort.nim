## Sort a local copy with portable heapsort, then index from the end.
const MaxLength = 512

proc siftDown(values: var array[MaxLength, int32], rootStart, endExclusive: int) =
  var root = rootStart
  while root < endExclusive div 2:
    var child = root * 2 + 1
    if child + 1 < endExclusive and values[child] < values[child + 1]: inc child
    if values[root] >= values[child]: break
    swap(values[root], values[child])
    root = child

proc kth_largest_by_sort*(input: ptr UncheckedArray[int64], length: csize_t): int64
    {.cdecl, exportc: "kth_largest_by_sort".} =
  if input == nil or length < 2 or length > MaxLength + 1: return -1
  let n = int(length) - 1
  if input[0] < 1 or input[0] > int64(n): return -1
  var values: array[MaxLength, int32]
  for index in 0 ..< n:
    let value = input[index + 1]
    if value < int64(low(int32)) or value > int64(high(int32)): return -1
    values[index] = int32(value)
  for start in countdown(n div 2 - 1, 0):
    siftDown(values, start, n)
  var endExclusive = n
  while endExclusive > 1:
    swap(values[0], values[endExclusive - 1])
    dec endExclusive
    siftDown(values, 0, endExclusive)
  int64(values[n - int(input[0])])
