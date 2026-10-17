const MaxInputLength = 99
const MaxOperations = 32
const MaxCapacity = 16
const MaxOutputFields = 114

proc append(records: var array[MaxOutputFields, int64], count: var int, value: int64) =
  records[count] = value
  inc count

proc writeI64Le(output: ptr UncheckedArray[uint8], offset: int, value: int64) =
  let bits = cast[uint64](value)
  for byte in 0 ..< 8:
    output[offset + byte] = uint8((bits shr (8 * byte)) and 0xFF'u64)

proc execute(input: ptr UncheckedArray[int64], length: int,
    records: var array[MaxOutputFields, int64]): int =
  if length < 2 or length > MaxInputLength: return -1
  let capacityValue = input[0]
  let operationCount = input[1]
  if capacityValue < 2 or capacityValue > MaxCapacity or
      operationCount < 0 or operationCount > MaxOperations or
      length != 2 + 3 * int(operationCount): return -1

  let cacheCapacity = int(capacityValue)
  var keys: array[MaxCapacity, int64]
  var values: array[MaxCapacity, int64]
  var seen: array[MaxOperations, int64]
  var order: array[MaxCapacity, int]
  var cacheCount = 0
  var seenCount = 0
  var recordCount = 0
  var cursor = 2
  for _ in 0 ..< int(operationCount):
    let opcode = input[cursor]
    let key = input[cursor + 1]
    let value = input[cursor + 2]
    cursor += 3
    if key < -1_000_000 or key > 1_000_000: return -1
    if opcode == 0:
      if value < -1_000_000 or value > 1_000_000: return -1
      for index in 0 ..< seenCount:
        if seen[index] == key: return -1
      seen[seenCount] = key
      inc seenCount
      var slot = cacheCount
      if cacheCount == cacheCapacity:
        slot = order[0]
        for index in 0 ..< (cacheCount - 1): order[index] = order[index + 1]
        dec cacheCount
      keys[slot] = key
      values[slot] = value
      order[cacheCount] = slot
      inc cacheCount
      append(records, recordCount, 0)
      append(records, recordCount, 0)
    elif opcode == 1:
      if value != 0: return -1
      var position = 0
      while position < cacheCount and keys[order[position]] != key:
        inc position
      if position == cacheCount: return -1
      let slot = order[position]
      let cachedValue = values[slot]
      for index in position ..< (cacheCount - 1): order[index] = order[index + 1]
      order[cacheCount - 1] = slot
      append(records, recordCount, 1)
      append(records, recordCount, 1)
      append(records, recordCount, cachedValue)
    else:
      return -1

  append(records, recordCount, 2)
  append(records, recordCount, int64(cacheCount))
  for index in 0 ..< cacheCount:
    let slot = order[index]
    append(records, recordCount, keys[slot])
    append(records, recordCount, values[slot])
  recordCount

proc lru*(input: ptr UncheckedArray[int64], length: csize_t,
    output: ptr UncheckedArray[uint8], outputCapacity: csize_t): int64
    {.cdecl, exportc: "lru".} =
  if input == nil or length < 2 or length > csize_t(MaxInputLength): return -1
  var records: array[MaxOutputFields, int64]
  let recordCount = execute(input, int(length), records)
  if recordCount < 0: return -1
  let outputBytes = recordCount * 8
  if output == nil or outputCapacity < csize_t(outputBytes): return -2
  for index in 0 ..< recordCount:
    writeI64Le(output, index * 8, records[index])
  int64(outputBytes)
