## Sort signed i32 values by inserting into and draining a bounded min-heap.
const
  MaxCount = 128
  MaxParseableInputLength = 130

proc heapPush(heap: var array[MaxCount, int32], size: var int, value: int32) =
  var child = size
  inc size
  heap[child] = value
  while child > 0:
    let parent = (child - 1) div 2
    if heap[parent] <= heap[child]: break
    swap(heap[parent], heap[child])
    child = parent

proc heapPop(heap: var array[MaxCount, int32], size: var int): int32 =
  result = heap[0]
  dec size
  if size == 0: return
  heap[0] = heap[size]
  var parent = 0
  while true:
    let left = 2 * parent + 1
    if left >= size: break
    let right = left + 1
    let smaller = if right < size and heap[right] < heap[left]: right else: left
    if heap[parent] <= heap[smaller]: break
    swap(heap[parent], heap[smaller])
    parent = smaller

proc writeI32Le(output: ptr UncheckedArray[uint8], offset: int, value: int32) =
  let bits = cast[uint32](value)
  for byte in 0 ..< 4:
    output[offset + byte] = uint8((bits shr (8 * byte)) and 0xff'u32)

proc priority_queue_sort*(input: ptr UncheckedArray[int64], length: csize_t,
                          output: ptr UncheckedArray[uint8], outputCapacity: csize_t): int64
    {.cdecl, exportc: "priority_queue_sort".} =
  if input == nil or length < 1 or length > csize_t(MaxParseableInputLength): return -1
  let rawCount = input[0]
  if rawCount < 0 or rawCount > int64(MaxCount) or int(length) != 1 + int(rawCount): return -1
  let count = int(rawCount)
  for index in 0 ..< count:
    if input[index + 1] < int64(low(int32)) or input[index + 1] > int64(high(int32)):
      return -1
  let byteCount = 4 * count
  if output == nil or outputCapacity < csize_t(byteCount): return -2

  var heap: array[MaxCount, int32]
  var heapSize = 0
  for index in 0 ..< count:
    heapPush(heap, heapSize, int32(input[index + 1]))
  for index in 0 ..< count:
    writeI32Le(output, 4 * index, heapPop(heap, heapSize))
  int64(byteCount)
