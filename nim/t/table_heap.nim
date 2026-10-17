import std/tables

const MaxItems = 64
const MaxOps = 256
const NilValue = low(int64)
type Entry = object
  priority: int32
  index: int

proc swapIds(heap: var array[MaxItems, int32], indices: var Table[int32, int], a, b: int, update: bool) =
  let value = heap[a]; heap[a] = heap[b]; heap[b] = value
  if update: indices[heap[a]] = a; indices[heap[b]] = b
proc heapifyDown(heap: var array[MaxItems, int32], count: int, entries: var Table[int32, Entry], indices: var Table[int32, int], start: int, update: bool) =
  var index = start
  while true:
    let left = index * 2 + 1
    if left >= count: return
    var child = left + 1
    if child >= count or entries[heap[left]].priority < entries[heap[child]].priority: child = left
    if entries[heap[child]].priority >= entries[heap[index]].priority: return
    swapIds(heap, indices, index, child, update); index = child
proc heapifyUp(heap: var array[MaxItems, int32], entries: var Table[int32, Entry], indices: var Table[int32, int], start: int) =
  var index = start
  while index > 0:
    let parent = (index - 1) div 2
    if entries[heap[index]].priority >= entries[heap[parent]].priority: return
    swapIds(heap, indices, index, parent, true); index = parent
proc storeI64(output: ptr UncheckedArray[uint8], offset: int, value: int64) =
  let bits = cast[uint64](value)
  for byte in 0 ..< 8: output[offset + byte] = uint8((bits shr (8 * byte)) and 255'u64)

proc table_heap*(input: ptr UncheckedArray[int64], inputLength: csize_t,
    output: ptr UncheckedArray[uint8], outputCapacity: csize_t): int64
    {.cdecl, exportc: "table_heap".} =
  if input.isNil or inputLength < csize_t(2) or inputLength > csize_t(1155): return -1
  if input[0] < 0 or input[0] > MaxItems: return -1
  let initial = int(input[0]); let operationIndex = 1 + 2 * initial
  if int(inputLength) <= operationIndex or input[operationIndex] < 0 or input[operationIndex] > MaxOps: return -1
  let operationCount = int(input[operationIndex])
  if int(inputLength) != 2 + 2 * initial + 4 * operationCount or inputLength > csize_t(1154): return -1

  var heap: array[MaxItems, int32]
  var entries = initTable[int32, Entry](MaxItems)
  var indices = initTable[int32, int](MaxItems)
  var count = initial
  for i in 0 ..< initial:
    let id = input[1 + 2 * i]; let priority = input[2 + 2 * i]
    if id < int64(low(int32)) or id > int64(high(int32)) or priority < int64(low(int32)) or priority > int64(high(int32)): return -1
    let item = int32(id)
    if entries.hasKey(item): return -1
    heap[i] = item; entries[item] = Entry(priority: int32(priority), index: 0)
  var parent = count div 2
  while parent > 0: dec parent; heapifyDown(heap, count, entries, indices, parent, false)
  for i in 0 ..< count: indices[heap[i]] = i; entries[heap[i]].index = i

  var answers: array[MaxOps, int64]; var cursor = operationIndex + 1
  for oi in 0 ..< operationCount:
    let op = input[cursor]; let a = input[cursor + 1]; let b = input[cursor + 2]; let c = input[cursor + 3]; cursor += 4
    if op < 0 or op > 9: return -1
    if op == 0:
      if a < int64(low(int32)) or a > int64(high(int32)) or b < int64(low(int32)) or b > int64(high(int32)) or c != 0 or count >= MaxItems: return -1
      let item = int32(a); if entries.hasKey(item): return -1
      heap[count] = item; entries[item] = Entry(priority: int32(b), index: count); indices[item] = count; inc count
      heapifyUp(heap, entries, indices, count - 1); answers[oi] = NilValue
    elif op == 1:
      if a != 0 or b != 0 or c != 0: return -1
      answers[oi] = if count == 0: NilValue else: int64(heap[0])
    elif op == 2:
      if a != 0 or b != 0 or c != 0 or count == 0: return -1
      let removed = heap[0]; answers[oi] = int64(removed); swapIds(heap, indices, 0, count - 1, true); dec count
      indices.del(removed); entries.del(removed)
      if count > 0: heapifyDown(heap, count, entries, indices, 0, true)
    elif op == 3 or op == 4:
      if a != 0 or b != 0 or c != 0: return -1
      answers[oi] = if op == 3: int64(count) elif count == 0: 1 else: 0
    elif op == 5:
      if a < int64(low(int32)) or a > int64(high(int32)) or b != 0 or c != 0: return -1
      let item = int32(a); answers[oi] = if indices.hasKey(item): int64(indices[item] + 1) else: NilValue
    elif op == 6 or op == 7:
      if a < int64(low(int32)) or a > int64(high(int32)) or b < int64(low(int32)) or b > int64(high(int32)) or c != 0: return -1
      let item = int32(a); if not entries.hasKey(item): return -1
      let old = entries[item].priority
      if (op == 6 and b > int64(old)) or (op == 7 and b < int64(old)): return -1
      let position = indices[item]; entries[item].priority = int32(b)
      if op == 6: heapifyUp(heap, entries, indices, position) else: heapifyDown(heap, count, entries, indices, position, true)
      answers[oi] = NilValue
    elif op == 8:
      if a < int64(low(int32)) or a > int64(high(int32)) or b < int64(low(int32)) or b > int64(high(int32)) or c < int64(low(int32)) or c > int64(high(int32)): return -1
      let oldId = int32(a); let newId = int32(b)
      if not entries.hasKey(oldId): return -1
      let oldPriority = entries[oldId].priority; let position = indices[oldId]
      if entries.hasKey(newId):
        if newId != oldId or c != int64(oldPriority): return -1
      else:
        entries.del(oldId); indices.del(oldId); heap[position] = newId
        entries[newId] = Entry(priority: int32(c), index: position); indices[newId] = position
        if int32(c) < oldPriority: heapifyUp(heap, entries, indices, position) else: heapifyDown(heap, count, entries, indices, position, true)
      answers[oi] = NilValue
    else:
      if a < int64(low(int32)) or a > int64(high(int32)) or b != 0 or c != 0: return -1
      let item = int32(a); if not entries.hasKey(item): return -1
      let position = indices[item]; let oldPriority = entries[item].priority; dec count
      if position != count:
        heap[position] = heap[count]; indices[heap[position]] = position; entries[heap[position]].index = position
        if entries[heap[position]].priority < oldPriority: heapifyUp(heap, entries, indices, position) else: heapifyDown(heap, count, entries, indices, position, true)
      indices.del(item); entries.del(item); answers[oi] = NilValue
  let outputBytes = csize_t(operationCount * 8)
  if output.isNil or outputCapacity < outputBytes: return -2
  for i in 0 ..< operationCount: storeI64(output, i * 8, answers[i])
  int64(outputBytes)
