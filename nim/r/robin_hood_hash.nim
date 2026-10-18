const TableCapacity = 16
const MaxActiveEntries = 14
const MaxOperations = 64
const MaxInputLength = 1 + 3 * MaxOperations
const MaxOutputBytes = 8 * MaxOperations
const MaxProbeDistance = 64
const GoldenRatio = 0x9E3779B97F4A7C15'u64

type
  Entry = object
    key: uint32
    value: uint32
    psl: uint32
    occupied: bool
  RobinHoodMap = object
    entries: array[TableCapacity, Entry]
    count: int
  I64Input = ptr UncheckedArray[int64]
  U8Output = ptr UncheckedArray[uint8]

proc hashKey(key: uint32): int =
  int(((uint64(key) *% GoldenRatio) shr 32) and uint64(TableCapacity - 1))

proc mapPut(table: var RobinHoodMap, key, value: uint32): bool =
  if (table.count * 100) div TableCapacity >= 90: return false
  var entry = Entry(key: key, value: value, psl: 0, occupied: true)
  var index = hashKey(key)
  var probes = 0'u32
  while probes < MaxProbeDistance:
    if not table.entries[index].occupied:
      table.entries[index] = entry
      inc table.count
      return true
    if table.entries[index].key == key:
      table.entries[index].value = value
      return true
    if entry.psl > table.entries[index].psl:
      swap(entry, table.entries[index])
    inc entry.psl
    index = (index + 1) and (TableCapacity - 1)
    inc probes
  false

proc mapGet(table: RobinHoodMap, key: uint32): int64 =
  var index = hashKey(key)
  var psl = 0'u32
  while psl < MaxProbeDistance:
    let resident = table.entries[index]
    if not resident.occupied: return -1
    if resident.key == key: return int64(resident.value)
    if psl > resident.psl: return -1
    index = (index + 1) and (TableCapacity - 1)
    inc psl
  -1

proc mapBackshift(table: var RobinHoodMap, start: int) =
  var index = start
  for _ in 0 ..< TableCapacity:
    let next = (index + 1) and (TableCapacity - 1)
    if not table.entries[next].occupied or table.entries[next].psl == 0:
      table.entries[index].occupied = false
      table.entries[index].psl = 0
      return
    table.entries[index] = table.entries[next]
    dec table.entries[index].psl
    index = next

proc mapRemove(table: var RobinHoodMap, key: uint32): bool =
  var index = hashKey(key)
  var psl = 0'u32
  while psl < MaxProbeDistance:
    let resident = table.entries[index]
    if not resident.occupied: return false
    if resident.key == key:
      table.mapBackshift(index)
      dec table.count
      return true
    if psl > resident.psl: return false
    index = (index + 1) and (TableCapacity - 1)
    inc psl
  false

proc mapClear(table: var RobinHoodMap) =
  for index in 0 ..< TableCapacity:
    table.entries[index].occupied = false
    table.entries[index].psl = 0
  table.count = 0

proc mapMaxPsl(table: RobinHoodMap): uint32 =
  var maximum = 0'u32
  for entry in table.entries:
    if entry.occupied and entry.psl > maximum: maximum = entry.psl
  maximum

proc putI64Le(output: U8Output, offset: int, value: int64) =
  var bits = cast[uint64](value)
  for byte in 0 ..< 8:
    output[offset + byte] = uint8(bits and 0xff'u64)
    bits = bits shr 8

proc robin_hood_hash*(input: I64Input, inputLength: csize_t, output: U8Output,
    outputCapacity: csize_t): int64
    {.cdecl, exportc: "robin_hood_hash".} =
  if input == nil or inputLength < 1 or inputLength > csize_t(MaxInputLength): return -1
  if input[0] < 0 or input[0] > MaxOperations: return -1
  let operationCount = int(input[0])
  if int(inputLength) != 1 + 3 * operationCount: return -1

  var table: RobinHoodMap
  var results: array[MaxOperations, int64]
  for operation in 0 ..< operationCount:
    let offset = 1 + 3 * operation
    let opcode = input[offset]
    let rawKey = input[offset + 1]
    let rawValue = input[offset + 2]
    if opcode == 0:
      if rawKey < 0 or rawKey > int64(high(uint32)) or rawValue < 100 or rawValue > 1_000_000: return -1
      if not table.mapPut(uint32(rawKey), uint32(rawValue)) or table.count > MaxActiveEntries: return -1
      results[operation] = -2
    elif opcode == 1 or opcode == 2:
      if rawKey < 0 or rawKey > int64(high(uint32)) or rawValue != 0: return -1
      let key = uint32(rawKey)
      if opcode == 1:
        results[operation] = table.mapGet(key)
      elif table.mapRemove(key):
        results[operation] = 1'i64
      else:
        results[operation] = 0'i64
    elif opcode >= 3 and opcode <= 7:
      if rawKey != 0 or rawValue != 0: return -1
      if opcode == 3: results[operation] = int64(table.count)
      elif opcode == 4: results[operation] = int64((table.count * 100) div TableCapacity)
      elif opcode == 5: results[operation] = int64(table.mapMaxPsl())
      elif opcode == 6:
        table.mapClear()
        results[operation] = -3
      else: results[operation] = if table.count == 0: 1 else: 0
    else:
      return -1

  let outputBytes = operationCount * 8
  if output == nil or outputCapacity < csize_t(outputBytes): return -2
  var staged: array[MaxOutputBytes, uint8]
  for operation in 0 ..< operationCount:
    putI64Le(cast[U8Output](addr staged[0]), operation * 8, results[operation])
  for byte in 0 ..< outputBytes: output[byte] = staged[byte]
  int64(outputBytes)
