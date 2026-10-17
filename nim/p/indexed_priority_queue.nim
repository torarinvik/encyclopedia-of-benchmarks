const
  MaxEvents = 256
  MaxActive = 64
  MaxInputValues = 1538

proc storeI64Le(output: ptr UncheckedArray[uint8], position: int, value: int64) =
  let bits = uint64(value)
  for byte in 0 ..< 8:
    output[position + byte] = uint8((bits shr (byte * 8)) and 0xFF'u64)

proc keyInUse(heapIds: var array[MaxActive, int64], heapKeys: var array[MaxActive, int64],
    size: int, key, exceptId: int64): bool =
  for index in 0 ..< size:
    if heapIds[index] != exceptId and heapKeys[index] == key: return true
  false

proc siftUp(heapIds: var array[MaxActive, int64], heapKeys: var array[MaxActive, int64],
    positions: var array[MaxActive, int], indexValue: int): bool =
  var index = indexValue
  let original = index
  let itemId = heapIds[index]
  let itemKey = heapKeys[index]
  while index > 0:
    let parent = (index - 1) div 2
    if itemKey >= heapKeys[parent]: break
    heapIds[index] = heapIds[parent]
    heapKeys[index] = heapKeys[parent]
    positions[int(heapIds[index])] = index
    index = parent
  heapIds[index] = itemId
  heapKeys[index] = itemKey
  positions[int(itemId)] = index
  index != original

proc siftDown(heapIds: var array[MaxActive, int64], heapKeys: var array[MaxActive, int64],
    positions: var array[MaxActive, int], size, indexValue: int) =
  var index = indexValue
  let itemId = heapIds[index]
  let itemKey = heapKeys[index]
  let half = size div 2
  while index < half:
    var child = index * 2 + 1
    let right = child + 1
    if right < size and heapKeys[child] > heapKeys[right]: child = right
    if itemKey <= heapKeys[child]: break
    heapIds[index] = heapIds[child]
    heapKeys[index] = heapKeys[child]
    positions[int(heapIds[index])] = index
    index = child
  heapIds[index] = itemId
  heapKeys[index] = itemKey
  positions[int(itemId)] = index

proc removeAt(size: var int, heapIds: var array[MaxActive, int64], heapKeys: var array[MaxActive, int64],
    positions: var array[MaxActive, int], index: int) =
  let newSize = size - 1
  let removedId = heapIds[index]
  let movedId = heapIds[newSize]
  let movedKey = heapKeys[newSize]
  size = newSize
  positions[int(removedId)] = -1
  if index == newSize: return
  heapIds[index] = movedId
  heapKeys[index] = movedKey
  positions[int(movedId)] = index
  if not siftUp(heapIds, heapKeys, positions, index):
    siftDown(heapIds, heapKeys, positions, size, index)

proc indexed_priority_queue*(values: ptr UncheckedArray[int64], length: csize_t,
    output: ptr UncheckedArray[uint8], outputCapacity: csize_t): int64
    {.cdecl, exportc: "indexed_priority_queue".} =
  if values.isNil or length < 1 or length > MaxInputValues: return -1
  if values[0] < 0 or values[0] > int64(MaxEvents): return -1
  let eventCount = int(values[0])
  if int(length) != 1 + 6 * eventCount: return -1
  if eventCount == 0: return 0

  var heapIds: array[MaxActive, int64]
  var heapKeys: array[MaxActive, int64]
  var positions: array[MaxActive, int]
  var records: array[MaxEvents, array[6, int64]]
  for id in 0 ..< MaxActive: positions[id] = -1
  var size = 0

  for eventIndex in 0 ..< eventCount:
    let start = 1 + eventIndex * 6
    let opcode = values[start]
    let elementId = values[start + 1]
    let key = values[start + 2]
    if values[start + 3] != 0 or values[start + 4] != 0 or values[start + 5] != 0: return -1
    var status = 1'i64
    var resultId = 0'i64
    var resultKey = 0'i64

    if opcode == 0:
      if elementId < 0 or elementId >= int64(MaxActive) or key < int64(low(int32)) or key > int64(high(int32)):
        return -1
      let id = int(elementId)
      if positions[id] >= 0 or size >= MaxActive or keyInUse(heapIds, heapKeys, size, key, -1): return -1
      heapIds[size] = elementId
      heapKeys[size] = key
      positions[id] = size
      inc size
      discard siftUp(heapIds, heapKeys, positions, size - 1)
    elif opcode == 1 or opcode == 2:
      if elementId != 0 or key != 0: return -1
      if size == 0: status = 0
      else:
        resultId = heapIds[0]
        resultKey = heapKeys[0]
        if opcode == 2: removeAt(size, heapIds, heapKeys, positions, 0)
    elif opcode == 3 or opcode == 4:
      if elementId < 0 or elementId >= int64(MaxActive) or key != 0: return -1
      let id = int(elementId)
      let position = positions[id]
      status = if position >= 0: 1 else: 0
      if opcode == 3 and position >= 0: removeAt(size, heapIds, heapKeys, positions, position)
    elif opcode >= 5 and opcode <= 7:
      if elementId < 0 or elementId >= int64(MaxActive) or key < int64(low(int32)) or key > int64(high(int32)):
        return -1
      let id = int(elementId)
      let position = positions[id]
      if position < 0: return -1
      let oldKey = heapKeys[position]
      if (opcode == 6 and key >= oldKey) or (opcode == 7 and key <= oldKey) or
          keyInUse(heapIds, heapKeys, size, key, elementId): return -1
      heapKeys[position] = key
      if opcode == 6: discard siftUp(heapIds, heapKeys, positions, position)
      elif opcode == 7: siftDown(heapIds, heapKeys, positions, size, position)
      elif not siftUp(heapIds, heapKeys, positions, position): siftDown(heapIds, heapKeys, positions, size, position)
    elif opcode == 8 or opcode == 9 or opcode == 10:
      if elementId != 0 or key != 0: return -1
      if opcode == 8:
        for index in 0 ..< size: positions[int(heapIds[index])] = -1
        size = 0
      elif opcode == 9: resultId = int64(size)
      else: resultId = if size == 0: 1 else: 0
    else: return -1

    records[eventIndex] = [status, resultId, resultKey, int64(size),
      (if size == 0: 0'i64 else: heapIds[0]),
      (if size == 0: 0'i64 else: heapKeys[0])]

  let required = eventCount * 48
  if output.isNil or int(outputCapacity) < required: return -2
  for eventIndex in 0 ..< eventCount:
    for field in 0 ..< 6: storeI64Le(output, eventIndex * 48 + field * 8, records[eventIndex][field])
  int64(required)
