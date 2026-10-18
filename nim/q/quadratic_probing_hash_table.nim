const
  MaxOperations = 24
  MaxInitialCapacity = 8
  MaxTableCapacity = 64
  MaxInputLength = 51
  MaxOutputBytes = 600

type Table = object
  slots: array[MaxTableCapacity, int64]
  capacity: int
  size: int

proc probeInsert(table: Table, key: int64): int =
  for probe in 0 ..< table.capacity * 100:
    let index = (int(key) + probe * probe) mod table.capacity
    if table.slots[index] == 0 or table.slots[index] == -1:
      return index
  -1

proc probeFind(table: Table, key: int64): int =
  for probe in 0 ..< table.capacity * 100:
    let index = (int(key) + probe * probe) mod table.capacity
    let slot = table.slots[index]
    if slot == 0: return -1
    if slot == key: return index
  -1

proc insertKey(table: var Table, key: int64): bool

proc rehash(table: var Table): bool =
  let oldCapacity = table.capacity
  if oldCapacity > MaxTableCapacity div 2: return false
  let oldSlots = table.slots
  table.capacity = oldCapacity * 2
  for index in 0 ..< table.capacity: table.slots[index] = 0
  for index in 0 ..< oldCapacity:
    let key = oldSlots[index]
    if key == 0 or key == -1: continue
    if table.size == 0: return false
    dec table.size
    if not insertKey(table, key): return false
  true

proc insertKey(table: var Table, key: int64): bool =
  let index = probeInsert(table, key)
  if index < 0: return false
  table.slots[index] = key
  inc table.size
  if table.size * 2 >= table.capacity: return rehash(table)
  true

proc putI64Le(output: ptr UncheckedArray[uint8], offset: int, value: int64) =
  let bits = cast[uint64](value)
  for byte in 0 ..< 8:
    output[offset + byte] = uint8((bits shr (8 * byte)) and 0xff'u64)

proc quadraticProbingHashTable*(input: ptr UncheckedArray[int64], inputLength: csize_t,
    output: ptr UncheckedArray[uint8], capacity: csize_t): int64
    {.cdecl, exportc: "quadratic_probing_hash_table".} =
  if input == nil or inputLength < 2 or inputLength > MaxInputLength.csize_t: return -1
  if input[0] < 1 or input[0] > MaxInitialCapacity.int64 or
      input[1] < 0 or input[1] > MaxOperations.int64: return -1
  let operationCount = int(input[1])
  if inputLength != csize_t(2 + 2 * operationCount): return -1

  var table = Table(capacity: int(input[0]), size: 0)
  var active: array[MaxTableCapacity + 1, bool]
  var findResults: array[MaxOperations, int64]
  var findCount = 0

  for operationIndex in 0 ..< operationCount:
    let operation = input[2 + 2 * operationIndex]
    let key = input[3 + 2 * operationIndex]
    if operation < 0 or operation > 2 or key < 1 or key > 64: return -1
    let keyIndex = int(key)
    if operation == 0:
      if active[keyIndex] or not insertKey(table, key): return -1
      active[keyIndex] = true
    elif operation == 1:
      if not active[keyIndex]: return -1
      let index = probeFind(table, key)
      if index < 0: return -1
      table.slots[index] = -1
      active[keyIndex] = false
      dec table.size
    else:
      let index = probeFind(table, key)
      findResults[findCount] = if index <= 0: 0 else: table.slots[index]
      inc findCount

  let outputWords = 3 + findCount + table.capacity
  let outputBytes = outputWords * 8
  if outputBytes > MaxOutputBytes: return -1
  if output == nil or capacity < csize_t(outputBytes): return -2
  putI64Le(output, 0, int64(table.capacity))
  putI64Le(output, 8, int64(table.size))
  putI64Le(output, 16, int64(findCount))
  for index in 0 ..< findCount: putI64Le(output, (3 + index) * 8, findResults[index])
  for index in 0 ..< table.capacity:
    putI64Le(output, (3 + findCount + index) * 8, table.slots[index])
  int64(outputBytes)
