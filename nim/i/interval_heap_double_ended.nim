const MaxInitial = 64
const MaxOperations = 128
const MaxKeys = MaxInitial + MaxOperations
const MaxInput = MaxInitial + 2 + 2 * MaxOperations

type
  IntervalHeap = object
    keys: array[MaxKeys, int32]
    count: int

proc highIndex(heap: IntervalHeap, node: int): int =
  let high = 2 * node + 1
  if high < heap.count: high else: 2 * node

proc siftUpLow(heap: var IntervalHeap, start: int) =
  var node = start
  while node > 0:
    let parent = (node - 1) div 2
    let low = 2 * node
    let parentLow = 2 * parent
    if heap.keys[low] >= heap.keys[parentLow]: return
    swap(heap.keys[low], heap.keys[parentLow])
    node = parent

proc siftUpHigh(heap: var IntervalHeap, start: int) =
  var node = start
  while node > 0:
    let parent = (node - 1) div 2
    let high = highIndex(heap, node)
    let parentHigh = highIndex(heap, parent)
    if heap.keys[high] <= heap.keys[parentHigh]: return
    swap(heap.keys[high], heap.keys[parentHigh])
    node = parent

proc insert(heap: var IntervalHeap, value: int32) =
  let keyIndex = heap.count
  heap.keys[keyIndex] = value
  inc heap.count
  let node = keyIndex div 2
  if keyIndex mod 2 == 1 and heap.keys[keyIndex] < heap.keys[keyIndex - 1]:
    swap(heap.keys[keyIndex], heap.keys[keyIndex - 1])
  siftUpLow(heap, node)
  siftUpHigh(heap, node)

proc extractMin(heap: var IntervalHeap): int32 =
  result = heap.keys[0]
  dec heap.count
  let last = heap.keys[heap.count]
  if heap.count == 0: return
  heap.keys[0] = last
  var node = 0
  while true:
    let left = 2 * node + 1
    if 2 * left >= heap.count: return
    let right = left + 1
    var child = left
    if 2 * right < heap.count and heap.keys[2 * right] < heap.keys[2 * left]: child = right
    let nodeLow = 2 * node
    let childLow = 2 * child
    if heap.keys[childLow] >= heap.keys[nodeLow]: return
    swap(heap.keys[nodeLow], heap.keys[childLow])
    let childHigh = highIndex(heap, child)
    if heap.keys[childHigh] < heap.keys[childLow]: swap(heap.keys[childHigh], heap.keys[childLow])
    node = child

proc extractMax(heap: var IntervalHeap): int32 =
  if heap.count <= 2:
    dec heap.count
    return heap.keys[heap.count]
  result = heap.keys[1]
  dec heap.count
  heap.keys[1] = heap.keys[heap.count]
  var node = 0
  while true:
    let left = 2 * node + 1
    if 2 * left >= heap.count: return
    let right = left + 1
    var child = left
    if 2 * right < heap.count and heap.keys[highIndex(heap, left)] < heap.keys[highIndex(heap, right)]: child = right
    let nodeHigh = highIndex(heap, node)
    let childHigh = highIndex(heap, child)
    if heap.keys[nodeHigh] >= heap.keys[childHigh]: return
    swap(heap.keys[nodeHigh], heap.keys[childHigh])
    let childLow = 2 * child
    if heap.keys[childHigh] < heap.keys[childLow]: swap(heap.keys[childHigh], heap.keys[childLow])
    node = child

proc writeI64Le(output: ptr UncheckedArray[uint8], offset: int, value: int64) =
  let bits = cast[uint64](value)
  for byte in 0 ..< 8: output[offset + byte] = uint8((bits shr (8 * byte)) and 0xFF'u64)

proc sortI32(values: var array[MaxKeys, int32], count: int) =
  for index in 1 ..< count:
    let value = values[index]
    var position = index
    while position > 0 and values[position - 1] > value:
      values[position] = values[position - 1]
      dec position
    values[position] = value

proc interval_heap_double_ended*(input: ptr UncheckedArray[int64], length: csize_t,
    output: ptr UncheckedArray[uint8], capacity: csize_t): int64 {.cdecl, exportc: "interval_heap_double_ended".} =
  if input.isNil or length < csize_t(2) or length > csize_t(MaxInput): return -1
  if input[0] < 0 or input[0] > MaxInitial: return -1
  let initialCount = int(input[0])
  if int(length) < initialCount + 2: return -1
  if input[initialCount + 1] < 0 or input[initialCount + 1] > MaxOperations: return -1
  let operationCount = int(input[initialCount + 1])
  if int(length) != initialCount + 2 + 2 * operationCount: return -1
  for index in 0 ..< initialCount:
    if input[index + 1] < -2_147_483_648 or input[index + 1] > 2_147_483_647: return -1
  for op in 0 ..< operationCount:
    let opcode = input[initialCount + 2 + 2 * op]
    let argument = input[initialCount + 3 + 2 * op]
    if opcode < 0 or opcode > 5: return -1
    if opcode == 0:
      if argument < -2_147_483_648 or argument > 2_147_483_647: return -1
    elif argument != 0: return -1

  var heap = IntervalHeap()
  for index in 0 ..< initialCount: insert(heap, int32(input[index + 1]))
  var events: array[MaxOperations, int64]
  var eventCount = 0
  for op in 0 ..< operationCount:
    let opcode = input[initialCount + 2 + 2 * op]
    let argument = int32(input[initialCount + 3 + 2 * op])
    if opcode == 0: insert(heap, argument)
    elif opcode == 1:
      if heap.count == 0: return -1
      events[eventCount] = int64(heap.keys[0]); inc eventCount
    elif opcode == 2:
      if heap.count == 0: return -1
      events[eventCount] = int64(heap.keys[highIndex(heap, 0)]); inc eventCount
    elif opcode == 3:
      if heap.count == 0: return -1
      events[eventCount] = int64(extractMin(heap)); inc eventCount
    elif opcode == 4:
      if heap.count == 0: return -1
      events[eventCount] = int64(extractMax(heap)); inc eventCount
    else:
      events[eventCount] = int64(heap.count); inc eventCount
  var sorted = heap.keys
  sortI32(sorted, heap.count)
  let required = (2 + eventCount + heap.count) * 8
  if output.isNil or int(capacity) < required: return -2
  var offset = 0
  writeI64Le(output, offset, int64(eventCount)); offset += 8
  for index in 0 ..< eventCount: writeI64Le(output, offset, events[index]); offset += 8
  writeI64Le(output, offset, int64(heap.count)); offset += 8
  for index in 0 ..< heap.count: writeI64Le(output, offset, int64(sorted[index])); offset += 8
  int64(required)
