const
  MaxN = 256
  MaxParseableLength = 258

proc siftDown(values: var array[MaxN, int64], rootStart, endExclusive: int) =
  var root = rootStart
  while root < endExclusive div 2:
    var child = root * 2 + 1
    if child + 1 < endExclusive and values[child] < values[child + 1]:
      inc child
    if values[root] >= values[child]:
      break
    swap(values[root], values[child])
    root = child

proc sortDescending(values: var array[MaxN, int64], count: int) =
  var start = count div 2
  while start > 0:
    dec start
    siftDown(values, start, count)
  var ending = count
  while ending > 1:
    dec ending
    swap(values[0], values[ending])
    siftDown(values, 0, ending)
  var left = 0
  var right = count - 1
  while left < right:
    swap(values[left], values[right])
    inc left
    dec right

proc erdos_gallai_graphical_sequence*(input: ptr UncheckedArray[int64],
                                     length: csize_t): int64
    {.cdecl, exportc: "erdos_gallai_graphical_sequence".} =
  if input.isNil or length < csize_t(1) or length > csize_t(MaxParseableLength):
    return -1
  let nWord = input[0]
  if nWord < 0 or nWord > int64(MaxN):
    return -1
  let n = int(nWord)
  if length != csize_t(n + 1):
    return -1

  var degrees: array[MaxN, int64]
  var sum = 0'i64
  for index in 0 ..< n:
    let degree = input[index + 1]
    if degree < 0 or degree >= nWord:
      return -1
    degrees[index] = degree
    sum += degree

  if sum mod 2 != 0:
    return 0
  if n == 0:
    return 1

  sortDescending(degrees, n)
  var prefix: array[MaxN + 1, int64]
  for index in 0 ..< n:
    prefix[index + 1] = prefix[index] + degrees[index]

  for k in 1 .. n:
    var low = k
    var high = n
    while low < high:
      let middle = low + (high - low) div 2
      if degrees[middle] >= int64(k):
        low = middle + 1
      else:
        high = middle
    let split = low
    let k64 = int64(k)
    let rhs = k64 * (k64 - 1) + int64(split - k) * k64 +
              (prefix[n] - prefix[split])
    if prefix[k] > rhs:
      return 0
  return 1
