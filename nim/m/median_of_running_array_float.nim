import std/math

const MaxCount = 64
const MaxInputLength = 66

proc lessFloat(left, right: float32): bool =
  left < right or (left == 0.0'f32 and right == 0.0'f32 and
    (cast[uint32](left) shr 31) != 0'u32 and (cast[uint32](right) shr 31) == 0'u32)

proc pushMax(heap: var array[MaxCount, float32], count: var int, value: float32) =
  var position = count
  inc count
  while position > 0 and lessFloat(heap[(position - 1) div 2], value):
    let parent = (position - 1) div 2
    heap[position] = heap[parent]
    position = parent
  heap[position] = value

proc popMax(heap: var array[MaxCount, float32], count: var int): float32 =
  result = heap[0]
  dec count
  let value = heap[count]
  if count == 0: return
  var position = 0
  while 2 * position + 1 < count:
    var child = 2 * position + 1
    if child + 1 < count and lessFloat(heap[child], heap[child + 1]): inc child
    if not lessFloat(value, heap[child]): break
    heap[position] = heap[child]
    position = child
  heap[position] = value

proc pushMin(heap: var array[MaxCount, float32], count: var int, value: float32) =
  var position = count
  inc count
  while position > 0 and lessFloat(value, heap[(position - 1) div 2]):
    let parent = (position - 1) div 2
    heap[position] = heap[parent]
    position = parent
  heap[position] = value

proc popMin(heap: var array[MaxCount, float32], count: var int): float32 =
  result = heap[0]
  dec count
  let value = heap[count]
  if count == 0: return
  var position = 0
  while 2 * position + 1 < count:
    var child = 2 * position + 1
    if child + 1 < count and lessFloat(heap[child + 1], heap[child]): inc child
    if not lessFloat(heap[child], value): break
    heap[position] = heap[child]
    position = child
  heap[position] = value

proc median_of_running_array_float*(input: ptr UncheckedArray[float64], inputLength: csize_t,
    output: ptr UncheckedArray[float64], outputCapacity: csize_t): int64
    {.cdecl, exportc: "median_of_running_array_float".} =
  if input.isNil or inputLength < csize_t(1) or inputLength > csize_t(MaxInputLength): return -1
  let countValue = input[0]
  if countValue != countValue or abs(countValue) > 1e308 or countValue < 1.0 or countValue > float64(MaxCount): return -1
  let count = int(countValue)
  if float64(count) != countValue or int(inputLength) != 1 + count: return -1
  var lower, upper, medians: array[MaxCount, float32]
  var lowerCount = 0
  var upperCount = 0
  for i in 0 ..< count:
    let sample = input[i + 1]
    if sample != sample or abs(sample) > 1e308 or sample < -1_000_000.0 or sample > 1_000_000.0: return -1
    let narrowed = float32(sample)
    if float64(narrowed) != sample or
       (sample == 0.0 and (cast[uint64](sample) shr 63) != uint64(cast[uint32](narrowed) shr 31)): return -1
    if upperCount > 0 and lessFloat(narrowed, upper[0]): pushMax(lower, lowerCount, narrowed)
    else: pushMin(upper, upperCount, narrowed)
    if lowerCount > upperCount + 1: pushMin(upper, upperCount, popMax(lower, lowerCount))
    elif upperCount > lowerCount + 1: pushMax(lower, lowerCount, popMin(upper, upperCount))
    if lowerCount > upperCount: medians[i] = lower[0]
    elif upperCount > lowerCount: medians[i] = upper[0]
    else:
      let sum: float32 = lower[0] + upper[0]
      let average: float32 = sum / 2.0'f32
      medians[i] = average
  if output.isNil or outputCapacity < csize_t(count): return -2
  for i in 0 ..< count: output[i] = float64(medians[i])
  int64(count)
