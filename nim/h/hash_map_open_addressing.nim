const
  MaxOperations = 256
  MaxKeys = 64
  MaxCapacity = 1024
  MaxInputLength = 769
  ValueOffset = 1_000_001'i64

type Entry = object
  state: int
  key: int64
  value: int64

proc place(table: var array[MaxCapacity, Entry], capacity: int, key, value: int64) =
  var index = int(key mod int64(capacity))
  for _ in 0 ..< capacity:
    if table[index].state != 1:
      table[index] = Entry(state: 1, key: key, value: value)
      return
    if table[index].key == key:
      table[index].value = value
      return
    index = (index + 1) mod capacity

proc resizeTable(table: var array[MaxCapacity, Entry], capacity: var int, next: int, size: var int) =
  let old = table
  let oldCapacity = capacity
  for i in 0 ..< next: table[i] = Entry()
  capacity = next
  size = 0
  for i in 0 ..< oldCapacity:
    if old[i].state == 1:
      place(table, next, old[i].key, old[i].value)
      inc size

proc findKey(table: array[MaxCapacity, Entry], capacity: int, key: int64): tuple[found, tombstone: int, tombBefore: bool] =
  var index = int(key mod int64(capacity))
  result.found = capacity
  result.tombstone = capacity
  for _ in 0 ..< capacity:
    if table[index].state == 0: return
    if table[index].state == 2:
      if result.tombstone == capacity: result.tombstone = index
    elif table[index].key == key:
      result.found = index
      result.tombBefore = result.tombstone != capacity
      return
    index = (index + 1) mod capacity

proc hash_map_open_addressing*(values: ptr UncheckedArray[int64], length: csize_t): int64
    {.cdecl, exportc: "hash_map_open_addressing".} =
  if values == nil or length < 1 or length > csize_t(MaxInputLength): return -1
  let q = values[0]
  if q < 0 or q > int64(MaxOperations) or length != csize_t(1 + 3 * q): return -1
  var table: array[MaxCapacity, Entry]
  var capacity = 8
  var size = 0
  var querySum = 0'i64
  var queryIndex = 0'i64
  for opi in 0 ..< int(q):
    let opcode = values[1 + 3 * opi]
    let key = values[2 + 3 * opi]
    let value = values[3 + 3 * opi]
    if opcode == 0:
      if key < 0 or key > 1_000_000 or value < -1_000_000 or value > 1_000_000: return -1
      let before = findKey(table, capacity, key)
      if before.found == capacity and size >= MaxKeys: return -1
      if size >= capacity * 3 div 4:
        if capacity * 2 > MaxCapacity: return -1
        resizeTable(table, capacity, capacity * 2, size)
      let found = findKey(table, capacity, key)
      if found.found != capacity:
        if found.tombBefore: return -1
        table[found.found].value = value
      else:
        var index = int(key mod int64(capacity))
        var target = found.tombstone
        for _ in 0 ..< capacity:
          if table[index].state == 0:
            if target == capacity: target = index
            break
          index = (index + 1) mod capacity
        if target == capacity: return -1
        table[target] = Entry(state: 1, key: key, value: value)
        inc size
    elif opcode == 1 or opcode == 2 or opcode == 3:
      if key < 0 or key > 1_000_000 or value != 0: return -1
      let found = findKey(table, capacity, key)
      if (opcode == 1 or opcode == 2) and found.found == capacity: return -1
      if opcode == 1:
        inc queryIndex
        querySum += queryIndex * (table[found.found].value + ValueOffset)
      elif opcode == 2:
        table[found.found].state = 2
        dec size
        if capacity > 8 and size < capacity * 3 div 8:
          resizeTable(table, capacity, capacity div 2, size)
      else:
        inc queryIndex
        querySum += queryIndex * ((if found.found != capacity: 1'i64 else: 0'i64) + ValueOffset)
    elif opcode == 4:
      if key != 0 or value != 0: return -1
      inc queryIndex
      querySum += queryIndex * (int64(size) + ValueOffset)
    else:
      return -1
  var keys: array[MaxKeys, int64]
  var vals: array[MaxKeys, int64]
  var count = 0
  for i in 0 ..< capacity:
    if table[i].state == 1:
      var at = count
      inc count
      while at > 0 and keys[at - 1] > table[i].key:
        keys[at] = keys[at - 1]
        vals[at] = vals[at - 1]
        dec at
      keys[at] = table[i].key
      vals[at] = table[i].value
  var finalState = 0'i64
  for i in 0 ..< count:
    finalState += int64(i + 1) * (keys[i] + 1) * (vals[i] + ValueOffset)
  querySum + finalState + int64(size)
