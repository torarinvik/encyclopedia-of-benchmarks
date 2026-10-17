const MaxCount = 64
const MaxInputLength = 66
const MinSample = -4_611_686_018_427_387_904'i64
const MaxSample = 4_611_686_018_427_387_903'i64

proc storeI64Le(output: ptr UncheckedArray[uint8], offset: int, value: int64) =
  let bits = cast[uint64](value)
  for byte in 0 ..< 8: output[offset + byte] = uint8((bits shr (8 * byte)) and 255'u64)
proc pushMax(heap: var array[MaxCount, int64], count: var int, value: int64) =
  var position = count; inc count
  while position > 0 and heap[(position - 1) div 2] < value:
    let parent = (position - 1) div 2; heap[position] = heap[parent]; position = parent
  heap[position] = value
proc popMax(heap: var array[MaxCount, int64], count: var int): int64 =
  result = heap[0]; dec count; let value = heap[count]
  if count == 0: return
  var position = 0
  while 2 * position + 1 < count:
    var child = 2 * position + 1
    if child + 1 < count and heap[child + 1] > heap[child]: inc child
    if heap[child] <= value: break
    heap[position] = heap[child]; position = child
  heap[position] = value
proc pushMin(heap: var array[MaxCount, int64], count: var int, value: int64) =
  var position = count; inc count
  while position > 0 and heap[(position - 1) div 2] > value:
    let parent = (position - 1) div 2; heap[position] = heap[parent]; position = parent
  heap[position] = value
proc popMin(heap: var array[MaxCount, int64], count: var int): int64 =
  result = heap[0]; dec count; let value = heap[count]
  if count == 0: return
  var position = 0
  while 2 * position + 1 < count:
    var child = 2 * position + 1
    if child + 1 < count and heap[child + 1] < heap[child]: inc child
    if heap[child] >= value: break
    heap[position] = heap[child]; position = child
  heap[position] = value

proc median_of_running_array_long*(input: ptr UncheckedArray[int64], inputLength: csize_t,
    output: ptr UncheckedArray[uint8], outputCapacity: csize_t): int64
    {.cdecl, exportc: "median_of_running_array_long".} =
  if input.isNil or inputLength < csize_t(1) or inputLength > csize_t(MaxInputLength): return -1
  let countValue = input[0]
  if countValue < 1 or countValue > int64(MaxCount) or int(inputLength) != 1 + int(countValue): return -1
  let count = int(countValue)
  var lower, upper, medians: array[MaxCount, int64]
  var lowerCount = 0; var upperCount = 0
  for i in 0 ..< count:
    let sample = input[i + 1]
    if sample < MinSample or sample > MaxSample: return -1
    if upperCount > 0 and sample < upper[0]: pushMax(lower, lowerCount, sample)
    else: pushMin(upper, upperCount, sample)
    if lowerCount > upperCount + 1: pushMin(upper, upperCount, popMax(lower, lowerCount))
    elif upperCount > lowerCount + 1: pushMax(lower, lowerCount, popMin(upper, upperCount))
    if lowerCount > upperCount: medians[i] = lower[0]
    elif upperCount > lowerCount: medians[i] = upper[0]
    else:
      let sum = lower[0] + upper[0]
      if sum < 0:
        let magnitudeMinusOne = -(sum + 1)
        medians[i] = -(magnitudeMinusOne div 2 + magnitudeMinusOne mod 2)
      else: medians[i] = sum div 2
  let outputBytes = csize_t(count * 8)
  if output.isNil or outputCapacity < outputBytes: return -2
  for i in 0 ..< count: storeI64Le(output, i * 8, medians[i])
  int64(outputBytes)
