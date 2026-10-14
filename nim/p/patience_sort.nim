## Patience sorting with lower-bound piles and a binary min-heap merge.
const MaxInputLength = 1024

proc nodeLess(keys: ptr UncheckedArray[int64], left, right: int): bool =
  keys[left] < keys[right] or (keys[left] == keys[right] and left < right)

proc siftDown(keys: ptr UncheckedArray[int64], heap: ptr UncheckedArray[int],
              heapLength, startRoot: int) =
  var root = startRoot
  while root < heapLength div 2:
    var child = root * 2 + 1
    if child + 1 < heapLength and nodeLess(keys, heap[child + 1], heap[child]): inc child
    if not nodeLess(keys, heap[child], heap[root]): break
    swap(heap[root], heap[child])
    root = child

proc patience_sort*(values: ptr UncheckedArray[int64], length: csize_t)
    {.cdecl, exportc: "patience_sort".} =
  if length < 2 or length > csize_t(MaxInputLength): return
  let n = int(length)
  var keys: array[MaxInputLength, int64]
  var pileTops: array[MaxInputLength, int]
  var nextInPile: array[MaxInputLength, int]
  var heap: array[MaxInputLength, int]
  for index in 0 ..< n:
    keys[index] = values[index]
    nextInPile[index] = n
  let keysPtr = cast[ptr UncheckedArray[int64]](addr keys[0])
  let heapPtr = cast[ptr UncheckedArray[int]](addr heap[0])
  let nextPtr = cast[ptr UncheckedArray[int]](addr nextInPile[0])
  var pileCount = 0
  for index in 0 ..< n:
    var low = 0
    var high = pileCount
    while low < high:
      let middle = low + (high - low) div 2
      if keys[pileTops[middle]] >= keys[index]: high = middle
      else: low = middle + 1
    if low == pileCount:
      pileTops[pileCount] = index
      inc pileCount
    else:
      nextPtr[index] = pileTops[low]
      pileTops[low] = index
  for pile in 0 ..< pileCount: heap[pile] = pileTops[pile]
  var heapLength = pileCount
  var start = heapLength div 2
  while start > 0:
    dec start
    siftDown(keysPtr, heapPtr, heapLength, start)
  var output = 0
  while heapLength > 0:
    let node = heap[0]
    values[output] = keys[node]
    inc output
    let successor = nextInPile[node]
    if successor < n:
      heap[0] = successor
    else:
      dec heapLength
      if heapLength > 0: heap[0] = heap[heapLength]
    if heapLength > 0: siftDown(keysPtr, heapPtr, heapLength, 0)
