const
  MaxQ = 63
  MaxParseableInput = 128
  ValueOffset = 100
  ValueCount = 201

proc epqLess(left, right: int, values: array[MaxQ, int64]): bool =
  if values[left] < values[right]: return true
  if values[left] > values[right]: return false
  left < right

proc epqHeapPush(heap: var array[MaxQ, int], heapSize: var int,
    item: int, values: array[MaxQ, int64]) =
  var index = heapSize
  inc heapSize
  while index > 0:
    let parent = (index - 1) div 2
    if not epqLess(item, heap[parent], values): break
    heap[index] = heap[parent]
    index = parent
  heap[index] = item

proc epqHeapPop(heap: var array[MaxQ, int], heapSize: var int,
    values: array[MaxQ, int64]): int =
  result = heap[0]
  dec heapSize
  if heapSize == 0: return
  let last = heap[heapSize]
  var index = 0
  while true:
    let left = 2 * index + 1
    if left >= heapSize: break
    let right = left + 1
    var child = left
    if right < heapSize and epqLess(heap[right], heap[left], values):
      child = right
    if not epqLess(heap[child], last, values): break
    heap[index] = heap[child]
    index = child
  heap[index] = last

proc epqNormalize(live: var array[MaxQ, int], liveSize: var int,
    deleted: var array[MaxQ, int], deletedSize: var int,
    values: array[MaxQ, int64]) =
  while liveSize > 0 and deletedSize > 0 and live[0] == deleted[0]:
    discard epqHeapPop(live, liveSize, values)
    discard epqHeapPop(deleted, deletedSize, values)

proc erasablePriorityQueueTrace*(input: ptr UncheckedArray[int64],
    length: csize_t): int64 {.cdecl, exportc: "erasable_priority_queue_trace".} =
  if input.isNil or length < csize_t(1) or length > csize_t(MaxParseableInput): return -1
  let qValue = input[0]
  if qValue < 0 or qValue > MaxQ: return -1
  let q = int(qValue)
  if length != csize_t(1 + 2 * q): return -1

  var values: array[MaxQ, int64]
  var counts: array[ValueCount, int]
  var active: array[MaxQ, bool]
  var live: array[MaxQ, int]
  var deleted: array[MaxQ, int]
  var liveSize = 0
  var deletedSize = 0
  var inserted = 0
  var score = 0'i64

  for operation in 0 ..< q:
    let opcode = input[1 + 2 * operation]
    let operand = input[2 + 2 * operation]
    if opcode < 0 or opcode > 3 or operand < -100 or operand > 100: return -1
    epqNormalize(live, liveSize, deleted, deletedSize, values)

    var response = 0'i64
    if opcode == 0:
      let id = inserted
      values[id] = operand
      active[id] = true
      inc counts[int(operand + ValueOffset)]
      epqHeapPush(live, liveSize, id, values)
      inc inserted
      epqNormalize(live, liveSize, deleted, deletedSize, values)
    elif opcode == 1:
      let key = int(operand + ValueOffset)
      if counts[key] == 0: return -1
      var found = inserted
      for candidate in 0 ..< inserted:
        if active[candidate] and values[candidate] == operand:
          found = candidate
          break
      if found == inserted: return -1
      active[found] = false
      dec counts[key]
      epqHeapPush(deleted, deletedSize, found, values)
      response = 1
      epqNormalize(live, liveSize, deleted, deletedSize, values)
    elif opcode == 2:
      if operand != 0: return -1
      if liveSize == 0: response = -101
      else: response = values[live[0]]
    else:
      if operand != 0 or liveSize == 0: return -1
      let id = epqHeapPop(live, liveSize, values)
      active[id] = false
      dec counts[int(values[id] + ValueOffset)]
      response = values[id]

    let token = opcode * 202 + response + 101
    score += int64(operation + 1) * token
  score
