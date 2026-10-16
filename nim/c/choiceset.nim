const MaxOperations = 1024
const MaxElements = 256
const HashCapacity = 512
const MaxKey = 1_000_000_000'i64

type
  I64Array = ptr UncheckedArray[int64]
  ByteArray = ptr UncheckedArray[uint8]
  HashKeys = array[HashCapacity, int32]
  HashIndices = array[HashCapacity, int]
  HashStates = array[HashCapacity, uint8]
  ElementArray = array[MaxElements, int32]
  ResultArray = array[MaxOperations, int64]

proc hashSlot(value: int32): int =
  let mixed = uint64(cast[uint32](value)) * 2_654_435_761'u64
  int(cast[uint32](mixed) shr 23)

proc findSlot(keys: var HashKeys, states: var HashStates, value: int32): int =
  var slot = hashSlot(value)
  var deleted = HashCapacity
  for _ in 0 ..< HashCapacity:
    if states[slot] == 0:
      return (if deleted < HashCapacity: deleted else: slot)
    if states[slot] == 2:
      if deleted == HashCapacity: deleted = slot
    elif keys[slot] == value:
      return slot
    slot = (slot + 1) mod HashCapacity
  deleted

proc putI64Le(output: ByteArray, offset: int, value: int64) =
  let bits = cast[uint64](value)
  for byte in 0 ..< 8: output[offset + byte] = uint8((bits shr (8 * byte)) and 0xFF'u64)

proc choiceset*(values: I64Array, length: csize_t, output: ByteArray, capacity: csize_t): int64
    {.cdecl, exportc: "choiceset".} =
  if values.isNil or length < 1 or values[0] < 0 or values[0] > MaxOperations: return -1
  let operationCount = int(values[0])
  if length != csize_t(1 + 2 * operationCount): return -1
  let outputBytes = operationCount * 8

  var elements: ElementArray
  var mapKeys: HashKeys
  var mapIndices: HashIndices
  var states: HashStates
  var results: ResultArray
  var elementCount = 0
  for operationIndex in 0 ..< operationCount:
    let operation = values[1 + 2 * operationIndex]
    let argument = values[2 + 2 * operationIndex]
    if operation >= 1 and operation <= 3:
      if argument < -MaxKey or argument > MaxKey: return -1
      let key = int32(argument)
      let slot = findSlot(mapKeys, states, key)
      let found = states[slot] == 1 and mapKeys[slot] == key
      if operation == 1:
        if found:
          results[operationIndex] = 0
        else:
          if elementCount == MaxElements or slot >= HashCapacity: return -1
          elements[elementCount] = key
          mapKeys[slot] = key
          mapIndices[slot] = elementCount
          states[slot] = 1
          inc elementCount
          results[operationIndex] = 1
      elif operation == 2:
        results[operationIndex] = int64(found)
      elif not found:
        results[operationIndex] = 0
      else:
        let index = mapIndices[slot]
        let last = elementCount - 1
        if index != last:
          let moved = elements[last]
          let movedSlot = findSlot(mapKeys, states, moved)
          if states[movedSlot] != 1 or mapKeys[movedSlot] != moved: return -1
          elements[index] = moved
          mapIndices[movedSlot] = index
        dec elementCount
        states[slot] = 2
        results[operationIndex] = 1
    elif operation == 4:
      if argument < 1 or argument > int64(elementCount): return -1
      results[operationIndex] = int64(elements[int(argument) - 1])
    else:
      return -1
  if capacity < csize_t(outputBytes) or (outputBytes > 0 and output.isNil): return -2
  for index in 0 ..< operationCount: putI64Le(output, index * 8, results[index])
  int64(outputBytes)
