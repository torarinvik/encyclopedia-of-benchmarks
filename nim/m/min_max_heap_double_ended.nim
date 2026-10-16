const MaxInitial = 64
const MaxOperations = 128
const MaxHeapSize = MaxInitial + MaxOperations
const InvalidResult = -1'i64
const CapacityResult = -2'i64

type HeapData = array[MaxHeapSize, int64]

proc isMinLevel(index: int): bool =
  var value = index + 1
  var depth = 0
  while value > 1:
    value = value shr 1
    inc depth
  depth mod 2 == 0

proc bestDescendant(heap: var HeapData, count, index: int, findMin: bool): int =
  result = -1
  for offset in 0 ..< 6:
    let candidate = if offset < 2: 2 * index + 1 + offset else: 4 * index + 1 + offset
    if candidate >= count: break
    if result < 0 or (if findMin: heap[candidate] < heap[result] else: heap[candidate] > heap[result]): result = candidate

proc pushDown(heap: var HeapData, count: int, start: int, findMin: bool) =
  var index = start
  while index < count:
    let best = bestDescendant(heap, count, index, findMin)
    if best < 0: return
    let grandchild = best > 2 and (best - 3) div 4 == index
    let improves = if findMin: heap[best] < heap[index] else: heap[best] > heap[index]
    if grandchild:
      if not improves: return
      swap(heap[best], heap[index])
      let parent = (best - 1) div 2
      let violation = if findMin: heap[best] > heap[parent] else: heap[best] < heap[parent]
      if violation: swap(heap[best], heap[parent])
      index = best
    else:
      if improves: swap(heap[best], heap[index])
      return

proc pushUpMin(heap: var HeapData, start: int) =
  var index = start
  while index > 2:
    let grandparent = (index - 3) div 4
    if heap[index] >= heap[grandparent]: return
    swap(heap[index], heap[grandparent])
    index = grandparent

proc pushUpMax(heap: var HeapData, start: int) =
  var index = start
  while index > 2:
    let grandparent = (index - 3) div 4
    if heap[index] <= heap[grandparent]: return
    swap(heap[index], heap[grandparent])
    index = grandparent

proc pushUp(heap: var HeapData, index: int) =
  if index == 0: return
  let parent = (index - 1) div 2
  if isMinLevel(index):
    if heap[index] > heap[parent]:
      swap(heap[index], heap[parent])
      pushUpMax(heap, parent)
    else: pushUpMin(heap, index)
  elif heap[index] < heap[parent]:
    swap(heap[index], heap[parent])
    pushUpMin(heap, parent)
  else: pushUpMax(heap, index)

proc addValue(heap: var HeapData, count: var int, value: int64) =
  let index = count
  inc count
  heap[index] = value
  pushUp(heap, index)

proc maxIndex(heap: var HeapData, count: int): int =
  if count < 2: return 0
  if count == 2: return 1
  if heap[1] > heap[2]: 1 else: 2

proc extractAt(heap: var HeapData, count: var int, index: int): int64 =
  result = heap[index]
  dec count
  if index != count: heap[index] = heap[count]
  if count > 0 and index < count: pushDown(heap, count, index, isMinLevel(index))

proc writeI64Le(output: ptr UncheckedArray[uint8], offset: int, value: int64) =
  let bits = cast[uint64](value)
  for byte in 0 ..< 8: output[offset + byte] = uint8((bits shr (8 * byte)) and 0xFF'u64)

proc insertionSort(values: var HeapData, count: int) =
  for index in 1 ..< count:
    let value = values[index]
    var position = index
    while position > 0 and values[position - 1] > value:
      values[position] = values[position - 1]
      dec position
    values[position] = value

proc min_max_heap_double_ended*(input: ptr UncheckedArray[int64], length: csize_t,
    output: ptr UncheckedArray[uint8], capacity: csize_t): int64 {.cdecl, exportc: "min_max_heap_double_ended".} =
  if input.isNil or length < 2: return InvalidResult
  if input[0] < 0 or input[0] > MaxInitial: return InvalidResult
  let initialCount = int(input[0])
  if int(length) < initialCount + 2: return InvalidResult
  let operationValue = input[initialCount + 1]
  if operationValue < 0 or operationValue > MaxOperations: return InvalidResult
  let operationCount = int(operationValue)
  if int(length) != initialCount + 2 + 2 * operationCount: return InvalidResult
  for index in 0 ..< initialCount:
    if input[index + 1] < -2_147_483_648 or input[index + 1] > 2_147_483_647: return InvalidResult
  for op in 0 ..< operationCount:
    let opcode = input[initialCount + 2 + 2 * op]
    let argument = input[initialCount + 3 + 2 * op]
    if opcode < 0 or opcode > 5: return InvalidResult
    if opcode == 0:
      if argument < -2_147_483_648 or argument > 2_147_483_647: return InvalidResult
    elif argument != 0: return InvalidResult

  var heap: HeapData
  var count = initialCount
  for index in 0 ..< initialCount: heap[index] = input[index + 1]
  var buildIndex = initialCount div 2
  while buildIndex > 0:
    dec buildIndex
    pushDown(heap, count, buildIndex, isMinLevel(buildIndex))
  var events: array[MaxOperations, int64]
  var eventCount = 0
  for op in 0 ..< operationCount:
    let opcode = input[initialCount + 2 + 2 * op]
    let argument = input[initialCount + 3 + 2 * op]
    if opcode == 0: addValue(heap, count, argument)
    elif opcode == 1 or opcode == 3:
      if count == 0: return InvalidResult
      if opcode == 1: events[eventCount] = heap[0]
      else: events[eventCount] = extractAt(heap, count, 0)
      inc eventCount
    elif opcode == 2 or opcode == 4:
      if count == 0: return InvalidResult
      let index = maxIndex(heap, count)
      if opcode == 2: events[eventCount] = heap[index]
      else: events[eventCount] = extractAt(heap, count, index)
      inc eventCount
    else:
      events[eventCount] = int64(count)
      inc eventCount
  var sorted = heap
  insertionSort(sorted, count)
  let required = (2 + eventCount + count) * 8
  if output.isNil or int(capacity) < required: return CapacityResult
  var offset = 0
  writeI64Le(output, offset, int64(eventCount)); offset += 8
  for index in 0 ..< eventCount:
    writeI64Le(output, offset, events[index]); offset += 8
  writeI64Le(output, offset, int64(count)); offset += 8
  for index in 0 ..< count:
    writeI64Le(output, offset, sorted[index]); offset += 8
  int64(required)
