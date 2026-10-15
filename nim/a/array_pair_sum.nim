## Sort signed 32-bit values and sum the first of every adjacent pair.
const MaxLength = 4096

proc siftDown(values: var array[MaxLength, int64], rootValue: int, count: int) =
  var root = rootValue
  while root * 2 + 1 < count:
    var child = root * 2 + 1
    if child + 1 < count and values[child] < values[child + 1]: inc child
    if values[root] >= values[child]: return
    swap(values[root], values[child])
    root = child

proc array_pair_sum*(input: ptr UncheckedArray[int64], length: csize_t): int64
    {.cdecl, exportc: "array_pair_sum".} =
  if length > csize_t(MaxLength) or length mod 2 != 0 or (length != 0 and input == nil): return -1
  var values: array[MaxLength, int64]
  for index in 0 ..< int(length):
    if input[index] < -2147483648'i64 or input[index] > 2147483647'i64: return -1
    values[index] = input[index]
  let count = int(length)
  for start in countdown(count div 2, 1): siftDown(values, start - 1, count)
  for ending in countdown(count, 2):
    swap(values[0], values[ending - 1])
    siftDown(values, 0, ending - 1)
  var total = 0'i64
  for index in countup(0, count - 1, 2): total += values[index]
  total
