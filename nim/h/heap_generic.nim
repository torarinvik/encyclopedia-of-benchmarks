const
  MaxOperations = 512
  MaxItems = 128
  IdCapacity = 4096
  MaxInputLength = 1537
  FnvOffset = 0xcbf29ce484222325'u64
  FnvPrime = 0x100000001b3'u64

proc hashByte(hash: uint64, byte: uint8): uint64 =
  (hash xor uint64(byte)) *% FnvPrime

proc hashI32(hashValue: uint64, value: int64): uint64 =
  var hash = hashValue
  let bits = cast[uint32](int32(value))
  for shift in countup(0, 24, 8):
    hash = hashByte(hash, uint8((bits shr shift) and 255))
  hash

proc swapItems(ids: var array[MaxItems, int64], priorities: var array[MaxItems, int64],
               positions: var array[IdCapacity, int], first, second: int) =
  swap(ids[first], ids[second])
  swap(priorities[first], priorities[second])
  positions[int(ids[first])] = first
  positions[int(ids[second])] = second

proc heapifyUp(ids: var array[MaxItems, int64], priorities: var array[MaxItems, int64],
               positions: var array[IdCapacity, int], start: int) =
  var index = start
  while index > 0:
    let parent = (index - 1) div 2
    if priorities[index] <= priorities[parent]:
      break
    swapItems(ids, priorities, positions, index, parent)
    index = parent

proc heapifyDown(ids: var array[MaxItems, int64], priorities: var array[MaxItems, int64],
                 positions: var array[IdCapacity, int], heapSize, start: int) =
  var index = start
  while true:
    var best = index
    let left = 2 * index + 1
    let right = left + 1
    if left < heapSize and priorities[left] > priorities[best]:
      best = left
    if right < heapSize and priorities[right] > priorities[best]:
      best = right
    if best == index:
      return
    swapItems(ids, priorities, positions, index, best)
    index = best

proc eraseItem(ids: var array[MaxItems, int64], priorities: var array[MaxItems, int64],
               positions: var array[IdCapacity, int], heapSize: var int, itemId: int) =
  let index = positions[itemId]
  let last = heapSize - 1
  positions[itemId] = -1
  if index != last:
    ids[index] = ids[last]
    priorities[index] = priorities[last]
    positions[int(ids[index])] = index
  heapSize = last
  if index < heapSize:
    heapifyUp(ids, priorities, positions, index)
    heapifyDown(ids, priorities, positions, heapSize, index)

proc heap_generic*(values: ptr UncheckedArray[int64], length: csize_t): int64
    {.cdecl, exportc: "heap_generic".} =
  if values == nil or length < 1 or length > csize_t(MaxInputLength):
    return -1
  let operationCountValue = values[0]
  if operationCountValue < 0 or operationCountValue > int64(MaxOperations) or
      length != csize_t(1 + 3 * operationCountValue):
    return -1

  var ids: array[MaxItems, int64]
  var priorities: array[MaxItems, int64]
  var positions: array[IdCapacity, int]
  var usedIds: array[IdCapacity, bool]
  for index in 0 ..< IdCapacity:
    positions[index] = -1
  var heapSize = 0
  var hash = FnvOffset

  for operation in 0 ..< int(operationCountValue):
    let opcode = values[1 + 3 * operation]
    let itemId = values[2 + 3 * operation]
    let priority = values[3 + 3 * operation]
    var present = false
    var returnedId = 0'i64
    var returnedPriority = 0'i64

    if opcode == 0:
      if itemId < 0 or itemId >= IdCapacity or priority < int64(low(int32)) or priority > int64(high(int32)) or
          usedIds[int(itemId)] or heapSize >= MaxItems:
        return -1
      for index in 0 ..< heapSize:
        if priorities[index] == priority:
          return -1
      usedIds[int(itemId)] = true
      ids[heapSize] = itemId
      priorities[heapSize] = priority
      positions[int(itemId)] = heapSize
      inc heapSize
      heapifyUp(ids, priorities, positions, heapSize - 1)
    elif opcode == 1 or opcode == 2:
      if itemId != 0 or priority != 0:
        return -1
      if heapSize > 0:
        present = true
        returnedId = ids[0]
        returnedPriority = priorities[0]
        if opcode == 2:
          eraseItem(ids, priorities, positions, heapSize, int(returnedId))
    elif opcode == 3:
      if itemId < 0 or itemId >= IdCapacity or priority < int64(low(int32)) or priority > int64(high(int32)) or
          positions[int(itemId)] < 0:
        return -1
      let index = positions[int(itemId)]
      for other in 0 ..< heapSize:
        if other != index and priorities[other] == priority:
          return -1
      priorities[index] = priority
      heapifyUp(ids, priorities, positions, index)
      heapifyDown(ids, priorities, positions, heapSize, index)
    elif opcode == 4:
      if itemId < 0 or itemId >= IdCapacity or priority != 0 or positions[int(itemId)] < 0:
        return -1
      eraseItem(ids, priorities, positions, heapSize, int(itemId))
    else:
      return -1

    hash = hashByte(hash, uint8(opcode))
    hash = hashByte(hash, uint8(ord(present)))
    if present:
      hash = hashI32(hash, returnedId)
      hash = hashI32(hash, returnedPriority)
  cast[int64](hash)
