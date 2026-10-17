const MaxCount = 64
const MaxInputLength = 66

proc pushMax(heap: var array[MaxCount, int32], count: var int, value: int32) =
  var i = count
  inc count
  while i > 0 and heap[(i - 1) div 2] < value:
    let parent = (i - 1) div 2
    heap[i] = heap[parent]
    i = parent
  heap[i] = value

proc popMax(heap: var array[MaxCount, int32], count: var int): int32 =
  result = heap[0]
  dec count
  let value = heap[count]
  if count == 0: return
  var i = 0
  while 2 * i + 1 < count:
    var child = 2 * i + 1
    if child + 1 < count and heap[child + 1] > heap[child]: inc child
    if heap[child] <= value: break
    heap[i] = heap[child]
    i = child
  heap[i] = value

proc pushMin(heap: var array[MaxCount, int32], count: var int, value: int32) =
  var i = count
  inc count
  while i > 0 and heap[(i - 1) div 2] > value:
    let parent = (i - 1) div 2
    heap[i] = heap[parent]
    i = parent
  heap[i] = value

proc popMin(heap: var array[MaxCount, int32], count: var int): int32 =
  result = heap[0]
  dec count
  let value = heap[count]
  if count == 0: return
  var i = 0
  while 2 * i + 1 < count:
    var child = 2 * i + 1
    if child + 1 < count and heap[child + 1] < heap[child]: inc child
    if heap[child] >= value: break
    heap[i] = heap[child]
    i = child
  heap[i] = value

proc median_of_running_array_byte*(input: ptr UncheckedArray[int32], length: csize_t,
    output: ptr UncheckedArray[uint8], capacity: csize_t): int64
    {.cdecl, exportc: "median_of_running_array_byte".} =
  if input.isNil or length < 1 or length > csize_t(MaxInputLength): return -1
  let countValue = input[0]
  if countValue < 1 or countValue > MaxCount or int(length) != 1 + int(countValue): return -1
  let count = int(countValue)
  var lower, upper: array[MaxCount, int32]
  var medians: array[MaxCount, uint8]
  var lowerCount = 0
  var upperCount = 0
  for i in 0 ..< count:
    let sample = input[i + 1]
    if sample < -128 or sample > 127: return -1
    if upperCount > 0 and sample < upper[0]: pushMax(lower, lowerCount, sample)
    else: pushMin(upper, upperCount, sample)
    if lowerCount > upperCount + 1:
      pushMin(upper, upperCount, popMax(lower, lowerCount))
    elif upperCount > lowerCount + 1:
      pushMax(lower, lowerCount, popMin(upper, upperCount))
    var median: int32
    if lowerCount > upperCount: median = lower[0]
    elif upperCount > lowerCount: median = upper[0]
    else:
      let sum = lower[0] + upper[0]
      if sum < 0: median = -((-sum) div 2) else: median = sum div 2
    medians[i] = cast[uint8](int8(median))
  if output.isNil or capacity < csize_t(count): return -2
  for i in 0 ..< count: output[i] = medians[i]
  int64(count)
