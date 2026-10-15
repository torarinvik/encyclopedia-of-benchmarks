type I64Input = ptr UncheckedArray[int64]
type U8Output = ptr UncheckedArray[uint8]

proc siftDown(heap: var array[256, int64], count, start: int) =
  var index = start
  while true:
    var largest = index
    let left = index * 2 + 1
    let right = left + 1
    if left < count and heap[left] > heap[largest]: largest = left
    if right < count and heap[right] > heap[largest]: largest = right
    if largest == index: return
    swap(heap[index], heap[largest])
    index = largest

proc storeI64Le(output: U8Output, offset: int, value: int64) =
  var bits = cast[uint64](value)
  for byte in 0 ..< 8:
    output[offset + byte] = uint8(bits and 255)
    bits = bits shr 8

proc heap_max_push_peek_pop*(values: I64Input, length: csize_t, output: U8Output,
    outputCapacity: csize_t): int64 {.cdecl, exportc: "heap_max_push_peek_pop".} =
  if values == nil or length < 2 or length > 257: return -1
  let rawCount = values[0]
  if rawCount < 1 or rawCount > 256 or length != csize_t(rawCount + 1): return -1
  let count = int(rawCount)
  var heap: array[256, int64]
  for index in 0 ..< count:
    let value = values[index + 1]
    if value < 1 or value > 1_000_000_000: return -1
    var position = index
    heap[position] = value
    while position > 0:
      let parent = (position - 1) div 2
      if heap[parent] >= heap[position]: break
      swap(heap[parent], heap[position])
      position = parent
  let outputBytes = 8 * count
  if output == nil or outputCapacity < csize_t(outputBytes): return -2
  var remaining = count
  for index in 0 ..< count:
    storeI64Le(output, 8 * index, heap[0])
    dec remaining
    if remaining > 0:
      heap[0] = heap[remaining]
      siftDown(heap, remaining, 0)
  int64(outputBytes)
