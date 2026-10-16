const MaxCount = 64
const HeapCapacity = 32
const ValueLimit = 1_000_000'i64

proc heapPush(heap: var array[HeapCapacity, int64], size: var int, isMax: bool, value: int64) =
  var index = size
  inc size
  heap[index] = value
  while index > 0:
    let parent = (index - 1) div 2
    if (if isMax: heap[parent] >= heap[index] else: heap[parent] <= heap[index]): break
    swap(heap[parent], heap[index])
    index = parent

proc heapPop(heap: var array[HeapCapacity, int64], size: var int, isMax: bool): int64 =
  result = heap[0]
  dec size
  heap[0] = heap[size]
  var index = 0
  while true:
    let left = 2 * index + 1
    let right = left + 1
    var best = index
    if left < size and (if isMax: heap[left] > heap[best] else: heap[left] < heap[best]): best = left
    if right < size and (if isMax: heap[right] > heap[best] else: heap[right] < heap[best]): best = right
    if best == index: break
    swap(heap[index], heap[best])
    index = best

proc writeF64Le(output: ptr UncheckedArray[uint8], position: int, value: float64) =
  let bits = cast[uint64](value)
  for byte in 0 ..< 8:
    output[position + byte] = uint8((bits shr (8 * byte)) and 0xff'u64)

proc median_finder*(input: ptr UncheckedArray[int64], length: csize_t,
    output: ptr UncheckedArray[uint8], outputCapacity: csize_t): int64
    {.cdecl, exportc: "median_finder".} =
  if input.isNil or length < 2 or length > MaxCount + 1: return -1
  let countValue = input[0]
  if countValue < 1 or countValue > MaxCount or int(length) != int(countValue) + 1: return -1
  let count = int(countValue)
  for index in 0 ..< count:
    if input[index + 1] < -ValueLimit or input[index + 1] > ValueLimit: return -1
  let required = count * 8
  if output.isNil or outputCapacity < csize_t(required): return -2

  var lower, upper: array[HeapCapacity, int64]
  var lowerSize = 0
  var upperSize = 0
  for index in 0 ..< count:
    let value = input[index + 1]
    if lowerSize == HeapCapacity and lowerSize > upperSize and value <= lower[0]:
      heapPush(upper, upperSize, false, heapPop(lower, lowerSize, true))
      heapPush(lower, lowerSize, true, value)
    else:
      if lowerSize == 0 or value <= lower[0]: heapPush(lower, lowerSize, true, value)
      else: heapPush(upper, upperSize, false, value)
      if lowerSize > upperSize + 1:
        heapPush(upper, upperSize, false, heapPop(lower, lowerSize, true))
      elif upperSize > lowerSize:
        heapPush(lower, lowerSize, true, heapPop(upper, upperSize, false))
    let median = if lowerSize == upperSize:
      (float64(lower[0]) + float64(upper[0])) / 2.0
    else:
      float64(lower[0])
    writeF64Le(output, index * 8, median)
  int64(required)
