## Bounded operation stream for the source MinHeap API.
type I64Input = ptr UncheckedArray[int64]
type U8Output = ptr UncheckedArray[uint8]

proc putI64Le(output: U8Output, slot: int, value: int64) =
  var bits = cast[uint64](value)
  for b in 0 ..< 8:
    output[slot * 8 + b] = uint8(bits and 255)
    bits = bits shr 8

proc siftDown(heap: var array[256, int64], size, start: int) =
  var i = start
  while true:
    var smallest = i
    let left = 2 * i + 1
    let right = left + 1
    if left < size and heap[left] < heap[smallest]: smallest = left
    if right < size and heap[right] < heap[smallest]: smallest = right
    if smallest == i: return
    swap(heap[i], heap[smallest])
    i = smallest

proc bubbleUp(heap: var array[256, int64], start: int) =
  var i = start
  while i > 0:
    let parent = (i - 1) div 2
    if heap[parent] <= heap[i]: break
    swap(heap[parent], heap[i])
    i = parent

proc binary_heap_indexed_operations*(values: I64Input, length: csize_t, output: U8Output,
    outputCapacity: csize_t): int64 {.cdecl, exportc: "binary_heap_indexed_operations".} =
  if values == nil or length < 2: return -1
  let rawCapacity = values[0]
  let rawCount = values[1]
  if rawCapacity < 1 or rawCapacity > 256 or rawCount < 0 or rawCount > 512 or
      length != csize_t(2 + rawCount * 3): return -1
  var heap: array[256, int64]
  var size = 0
  var outputCount = 0
  for i in 0 ..< int(rawCount):
    let op = values[2 + 3 * i]
    let a = values[3 + 3 * i]
    let b = values[4 + 3 * i]
    if op == 0:
      if a < -2_147_483_648 or a > 2_147_483_647 or b != 0: return -1
      if size < int(rawCapacity):
        heap[size] = a
        bubbleUp(heap, size)
        inc size
    elif op == 1 or op == 2:
      if a != 0 or b != 0 or (op == 1 and size == 0): return -1
      if output == nil or csize_t((outputCount + 1) * 8) > outputCapacity: return -2
      let result = if size == 0: 2_147_483_647'i64 else: heap[0]
      if op == 2 and size > 0:
        dec size
        heap[0] = heap[size]
        if size > 0: siftDown(heap, size, 0)
      putI64Le(output, outputCount, result)
      inc outputCount
    elif op == 3:
      if a < 0 or a >= size or b < -2_147_483_648 or b > 2_147_483_647 or b > heap[int(a)]: return -1
      heap[int(a)] = b
      bubbleUp(heap, int(a))
    elif op == 4:
      if a < 0 or a >= size or b != 0: return -1
      heap[int(a)] = -2_147_483_648
      bubbleUp(heap, int(a))
      dec size
      heap[0] = heap[size]
      if size > 0: siftDown(heap, size, 0)
    else:
      return -1
  int64(outputCount * 8)
