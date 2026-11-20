const
  Generations = 4
  Buckets = 8
  MaxKeys = 32
  MaxOperations = 64
  MaxWords = 1 + 3 * MaxOperations + 1
  Miss = -2_147_483_648'i64

proc findInTable(heads, keys, links: openArray[int16], table, key: int): int =
  var node = int(heads[table * Buckets + key mod Buckets])
  while node >= 0:
    let record = table * MaxKeys + node
    if int(keys[record]) == key: return node
    node = int(links[record])
  -1

proc findKey(heads, keys, links: openArray[int16], newest, key: int,
             foundTable: var int): int =
  for age in 0 ..< Generations:
    let table = (newest + age) mod Generations
    let node = findInTable(heads, keys, links, table, key)
    if node >= 0:
      foundTable = table
      return node
  foundTable = -1
  -1

proc put(heads: var array[Generations * Buckets, int16],
         keys: var array[Generations * MaxKeys, int16],
         values: var array[Generations * MaxKeys, int16],
         links: var array[Generations * MaxKeys, int16],
         used: var array[Generations, int16], newest, key, value: int) =
  let node = findInTable(heads, keys, links, newest, key)
  if node >= 0:
    values[newest * MaxKeys + node] = int16(value)
    return
  var fresh = -1
  for slot in 0 ..< MaxKeys:
    if keys[newest * MaxKeys + slot] < 0:
      fresh = slot
      break
  if fresh < 0: return
  used[newest] = int16(int(used[newest]) + 1)
  let bucket = key mod Buckets
  let record = newest * MaxKeys + fresh
  keys[record] = int16(key)
  values[record] = int16(value)
  links[record] = heads[newest * Buckets + bucket]
  heads[newest * Buckets + bucket] = int16(fresh)

proc remove(heads: var array[Generations * Buckets, int16],
            keys: var array[Generations * MaxKeys, int16],
            values: var array[Generations * MaxKeys, int16],
            links: var array[Generations * MaxKeys, int16],
            used: var array[Generations, int16], table, key, target: int) =
  let bucket = key mod Buckets
  var previous = -1
  var node = int(heads[table * Buckets + bucket])
  while node >= 0 and node != target:
    previous = node
    node = int(links[table * MaxKeys + node])
  if node < 0: return
  if previous < 0:
    heads[table * Buckets + bucket] = links[table * MaxKeys + node]
  else:
    links[table * MaxKeys + previous] = links[table * MaxKeys + node]
  keys[table * MaxKeys + node] = -1
  values[table * MaxKeys + node] = 0
  links[table * MaxKeys + node] = -1
  used[table] = int16(int(used[table]) - 1)

proc writeI64Le(output: ptr UncheckedArray[uint8], word: int, value: int64) =
  let bits = cast[uint64](value)
  for byte in 0 ..< 8:
    output[word * 8 + byte] = uint8((bits shr (byte * 8)) and 255'u64)

proc hashbelt_aging_hash_table*(input: ptr UncheckedArray[int64], length: csize_t,
    output: ptr UncheckedArray[uint8], capacity: csize_t): int64 {.cdecl, exportc.} =
  if input.isNil or length < 1 or length > csize_t(MaxWords): return -1
  let countValue = input[0]
  if countValue < 0 or countValue > MaxOperations: return -1
  let count = int(countValue)
  if int(length) != 1 + 3 * count: return -1
  for op in 0 ..< count:
    let opcode = input[1 + 3 * op]
    let key = input[2 + 3 * op]
    let argument = input[3 + 3 * op]
    if opcode == 0:
      if key < 0 or key >= MaxKeys or argument < -1000 or argument > 1000: return -1
    elif opcode == 1:
      if key < 0 or key >= MaxKeys or argument != 0: return -1
    elif opcode == 2:
      if key != 0 or argument != 0: return -1
    else:
      return -1
  let required = count * 8
  if output.isNil or capacity < csize_t(required): return -2

  var heads: array[Generations * Buckets, int16]
  var keys: array[Generations * MaxKeys, int16]
  var values: array[Generations * MaxKeys, int16]
  var links: array[Generations * MaxKeys, int16]
  var used: array[Generations, int16]
  var trace: array[MaxOperations, int64]
  for head in 0 ..< heads.len: heads[head] = -1
  for key in 0 ..< keys.len: keys[key] = -1
  var newest = 0
  for op in 0 ..< count:
    let opcode = int(input[1 + 3 * op])
    let key = int(input[2 + 3 * op])
    let argument = int(input[3 + 3 * op])
    if opcode == 0:
      var foundTable = -1
      let oldNode = findKey(heads, keys, links, newest, key, foundTable)
      trace[op] = if foundTable < 0: 1 else: 0
      if foundTable >= 0 and foundTable != newest:
        remove(heads, keys, values, links, used, foundTable, key, oldNode)
      put(heads, keys, values, links, used, newest, key, argument)
    elif opcode == 1:
      var foundTable = -1
      let node = findKey(heads, keys, links, newest, key, foundTable)
      if node < 0:
        trace[op] = Miss
      else:
        let value = int(values[foundTable * MaxKeys + node])
        trace[op] = int64(value)
        if foundTable != newest:
          remove(heads, keys, values, links, used, foundTable, key, node)
          put(heads, keys, values, links, used, newest, key, value)
    else:
      let oldest = (newest + Generations - 1) mod Generations
      trace[op] = int64(used[oldest])
      for bucket in 0 ..< Buckets: heads[oldest * Buckets + bucket] = -1
      for key in 0 ..< MaxKeys: keys[oldest * MaxKeys + key] = -1
      used[oldest] = 0
      newest = oldest
  for op in 0 ..< count: writeI64Le(output, op, trace[op])
  int64(required)
