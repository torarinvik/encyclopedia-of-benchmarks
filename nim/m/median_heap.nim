const MaxOperations = 256
const MaxInputLength = 514
const MaxLiveValues = 64
const NilSentinel = low(int64)

proc storeI64Le(output: ptr UncheckedArray[uint8], offset: int, value: int64) =
  let bits = cast[uint64](value)
  for byte in 0 ..< 8: output[offset + byte] = uint8((bits shr (8 * byte)) and 255'u64)
proc pushMax(heap: var array[MaxLiveValues, int32], count: var int, value: int32) =
  var position = count; inc count
  while position > 0 and heap[(position - 1) div 2] < value:
    let parent = (position - 1) div 2; heap[position] = heap[parent]; position = parent
  heap[position] = value
proc popMax(heap: var array[MaxLiveValues, int32], count: var int): int32 =
  result = heap[0]; dec count; let value = heap[count]
  if count == 0: return
  var position = 0
  while 2 * position + 1 < count:
    var child = 2 * position + 1
    if child + 1 < count and heap[child + 1] > heap[child]: inc child
    if heap[child] <= value: break
    heap[position] = heap[child]; position = child
  heap[position] = value
proc pushMin(heap: var array[MaxLiveValues, int32], count: var int, value: int32) =
  var position = count; inc count
  while position > 0 and heap[(position - 1) div 2] > value:
    let parent = (position - 1) div 2; heap[position] = heap[parent]; position = parent
  heap[position] = value
proc popMin(heap: var array[MaxLiveValues, int32], count: var int): int32 =
  result = heap[0]; dec count; let value = heap[count]
  if count == 0: return
  var position = 0
  while 2 * position + 1 < count:
    var child = 2 * position + 1
    if child + 1 < count and heap[child + 1] < heap[child]: inc child
    if heap[child] >= value: break
    heap[position] = heap[child]; position = child
  heap[position] = value

proc median_heap*(input: ptr UncheckedArray[int64], inputLength: csize_t,
    output: ptr UncheckedArray[uint8], outputCapacity: csize_t): int64
    {.cdecl, exportc: "median_heap".} =
  if input.isNil or inputLength < csize_t(1) or inputLength > csize_t(MaxInputLength): return -1
  let opValue = input[0]
  if opValue < 0 or opValue > MaxOperations or int(inputLength) != 1 + 2 * int(opValue): return -1
  let operationCount = int(opValue)
  var lower, upper: array[MaxLiveValues, int32]
  var lowerCount = 0; var upperCount = 0
  var results: array[MaxOperations, int64]
  for i in 0 ..< operationCount:
    let opcode = input[1 + 2 * i]; let argument = input[2 + 2 * i]
    if opcode == 0:
      if argument < int64(low(int32)) or argument > int64(high(int32)) or lowerCount + upperCount >= MaxLiveValues: return -1
      let value = int32(argument)
      if lowerCount == 0: pushMax(lower, lowerCount, value)
      elif value < lower[0]:
        pushMax(lower, lowerCount, value)
        if lowerCount - upperCount > 1: pushMin(upper, upperCount, popMax(lower, lowerCount))
      else:
        pushMin(upper, upperCount, value)
        if lowerCount < upperCount: pushMax(lower, lowerCount, popMin(upper, upperCount))
      results[i] = NilSentinel
    elif opcode >= 1 and opcode <= 4:
      if argument != 0: return -1
      if opcode == 1: results[i] = if lowerCount > 0: int64(lower[0]) else: NilSentinel
      elif opcode == 2:
        if lowerCount == 0: results[i] = NilSentinel
        else:
          results[i] = int64(popMax(lower, lowerCount))
          if lowerCount < upperCount: pushMax(lower, lowerCount, popMin(upper, upperCount))
      elif opcode == 3: results[i] = int64(lowerCount + upperCount)
      else: results[i] = if lowerCount == 0: 1 else: 0
    else: return -1
  let outputBytes = csize_t(operationCount * 8)
  if output.isNil or outputCapacity < outputBytes: return -2
  for i in 0 ..< operationCount: storeI64Le(output, i * 8, results[i])
  int64(outputBytes)
