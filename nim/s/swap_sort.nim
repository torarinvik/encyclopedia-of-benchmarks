## Count minimum swaps needed to order a distinct-value array.
const MaxValues = 256

proc positionLess(keys: ptr UncheckedArray[int64], order: ptr UncheckedArray[int],
                  left, right: int): bool =
  let a = order[left]
  let b = order[right]
  keys[a] < keys[b] or (keys[a] == keys[b] and a < b)

proc siftDown(keys: ptr UncheckedArray[int64], order: ptr UncheckedArray[int],
              heapLength, startRoot: int) =
  var root = startRoot
  while root < heapLength div 2:
    var child = root * 2 + 1
    if child + 1 < heapLength and positionLess(keys, order, child, child + 1): inc child
    if not positionLess(keys, order, root, child): break
    swap(order[root], order[child])
    root = child

proc swap_sort*(values: ptr UncheckedArray[int64], length: csize_t): int64
    {.cdecl, exportc: "swap_sort".} =
  if length > csize_t(MaxValues): return -1
  let n = int(length)
  var keys: array[MaxValues, int64]
  var order: array[MaxValues, int]
  var visited: array[MaxValues, bool]
  for index in 0 ..< n:
    keys[index] = values[index]
    order[index] = index
  let keysPtr = cast[ptr UncheckedArray[int64]](addr keys[0])
  let orderPtr = cast[ptr UncheckedArray[int]](addr order[0])
  var start = n div 2
  while start > 0:
    dec start
    siftDown(keysPtr, orderPtr, n, start)
  var finish = n
  while finish > 1:
    dec finish
    swap(order[0], order[finish])
    siftDown(keysPtr, orderPtr, finish, 0)
  for index in 1 ..< n:
    if keys[order[index - 1]] == keys[order[index]]: return -1
  var swaps = 0
  for first in 0 ..< n:
    if visited[first]: continue
    var node = first
    var cycleLength = 0
    while not visited[node]:
      visited[node] = true
      node = order[node]
      inc cycleLength
    if cycleLength > 0: swaps += cycleLength - 1
  int64(swaps)
