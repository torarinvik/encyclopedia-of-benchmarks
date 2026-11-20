const
  Slots = 16
  Neighborhood = 4
  MaxOperations = 32
  MaxWords = 1 + 3 * MaxOperations

proc hsDistance(first, last: int): int =
  (last - first + Slots) mod Slots

proc hsContains(keys: array[Slots, int16], hops: array[Slots, uint8],
                key, home: int): bool =
  for offset in 0 ..< Neighborhood:
    if (hops[home] and (1'u8 shl offset)) != 0:
      if keys[(home + offset) mod Slots] == int16(key): return true
  false

proc hsInsert(keys: var array[Slots, int16], homes: var array[Slots, uint8],
              hops: var array[Slots, uint8], key, home: int): uint8 =
  if hsContains(keys, hops, key, home): return 2'u8
  var hole = -1
  for step in 0 ..< Slots:
    let slot = (home + step) mod Slots
    if keys[slot] < 0:
      hole = slot
      break
  if hole < 0: return 0'u8

  var reach = hsDistance(home, hole)
  while reach >= Neighborhood:
    var shifted = false
    for back in countdown(Neighborhood - 1, 1):
      let bucket = (hole - back + Slots) mod Slots
      let newOffset = hsDistance(bucket, hole)
      if hsDistance(home, bucket) >= reach: continue
      for oldOffset in 0 ..< newOffset:
        if (hops[bucket] and (1'u8 shl oldOffset)) == 0: continue
        let oldSlot = (bucket + oldOffset) mod Slots
        if keys[oldSlot] < 0 or int(homes[oldSlot]) != bucket: continue
        if hsDistance(home, oldSlot) >= reach: continue
        keys[hole] = keys[oldSlot]
        homes[hole] = homes[oldSlot]
        keys[oldSlot] = -1
        homes[oldSlot] = 0
        hops[bucket] = hops[bucket] and not (1'u8 shl oldOffset)
        hops[bucket] = hops[bucket] or (1'u8 shl newOffset)
        hole = oldSlot
        reach = hsDistance(home, hole)
        shifted = true
        break
      if shifted: break
    if not shifted: return 0'u8

  keys[hole] = int16(key)
  homes[hole] = uint8(home)
  hops[home] = hops[home] or (1'u8 shl reach)
  1'u8

proc hash_map_hopscotch_hashing*(input: ptr UncheckedArray[int64], length: csize_t,
    output: ptr UncheckedArray[uint8], capacity: csize_t): int64
    {.cdecl, exportc: "hash_map_hopscotch_hashing".} =
  if input.isNil or length < 1 or length > csize_t(MaxWords): return -1
  let countValue = input[0]
  if countValue < 0 or countValue > MaxOperations: return -1
  let count = int(countValue)
  if int(length) != 1 + 3 * count: return -1

  var knownHome: array[64, int8]
  for key in 0 ..< 64: knownHome[key] = -1
  for op in 0 ..< count:
    let opcode = input[1 + 3 * op]
    let key = input[2 + 3 * op]
    let home = input[3 + 3 * op]
    if (opcode != 1 and opcode != 2) or key < 0 or key >= 64 or home < 0 or home >= Slots:
      return -1
    if knownHome[int(key)] >= 0 and int64(knownHome[int(key)]) != home: return -1
    knownHome[int(key)] = int8(home)

  let required = count + 2 * Slots
  if output.isNil or capacity < csize_t(required): return -2
  var keys: array[Slots, int16]
  var homes: array[Slots, uint8]
  var hops: array[Slots, uint8]
  var statuses: array[MaxOperations, uint8]
  for slot in 0 ..< Slots: keys[slot] = -1
  for op in 0 ..< count:
    let opcode = int(input[1 + 3 * op])
    let key = int(input[2 + 3 * op])
    let home = int(input[3 + 3 * op])
    if opcode == 1:
      statuses[op] = hsInsert(keys, homes, hops, key, home)
    else:
      statuses[op] = uint8(ord(hsContains(keys, hops, key, home)))
  var cursor = 0
  for op in 0 ..< count:
    output[cursor] = statuses[op]
    inc cursor
  for key in keys:
    output[cursor] = if key < 0: 0'u8 else: uint8(key + 1)
    inc cursor
  for mask in hops:
    output[cursor] = mask
    inc cursor
  int64(required)
