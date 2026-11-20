const BucketCount = 8
const BucketWidth = 4
const MaxOperations = 32
const MaxKicks = 8

proc delta(fingerprint: int64): int = 1 + ((5 * int(fingerprint) + 3) mod 7)

proc firstEmpty(table: ptr UncheckedArray[int64], bucket: int): int =
  for slot in 0 ..< BucketWidth:
    if table[bucket * BucketWidth + slot] == 0: return slot
  BucketWidth

proc insert(table: ptr UncheckedArray[int64], primary: int, fingerprint: int64): bool =
  let alternate = primary xor delta(fingerprint)
  var empty = firstEmpty(table, primary)
  if empty < BucketWidth:
    table[primary * BucketWidth + empty] = fingerprint
    return true
  empty = firstEmpty(table, alternate)
  if empty < BucketWidth:
    table[alternate * BucketWidth + empty] = fingerprint
    return true
  var current = primary
  var pending = fingerprint
  for _ in 0 ..< MaxKicks:
    let position = current * BucketWidth
    let evicted = table[position]
    table[position] = pending
    pending = evicted
    current = current xor delta(pending)
    empty = firstEmpty(table, current)
    if empty < BucketWidth:
      table[current * BucketWidth + empty] = pending
      return true
  false

proc writeI64Le(output: ptr UncheckedArray[uint8], index: int, value: int64) =
  let bits = cast[uint64](value)
  for byte in 0 ..< 8:
    output[index * 8 + byte] = uint8((bits shr (8 * byte)) and 255'u64)

proc cuckoo_filter_operation_trace*(input: ptr UncheckedArray[int64], length: csize_t,
    output: ptr UncheckedArray[uint8], capacity: csize_t): int64 {.cdecl, exportc.} =
  if input.isNil or length < 4 or length > 98: return -1
  let rawCount = input[0]
  if rawCount < 1 or rawCount > MaxOperations: return -1
  let count = int(rawCount)
  if int(length) != 1 + 3 * count: return -1
  for operation in 0 ..< count:
    let opcode = input[1 + 3 * operation]
    let primary = input[2 + 3 * operation]
    let fingerprint = input[3 + 3 * operation]
    if opcode < 0 or opcode > 2 or primary < 0 or primary >= BucketCount or
        fingerprint < 1 or fingerprint > 15: return -1
  let required = count * 8
  if output.isNil or int(capacity) < required: return -2

  var table: array[BucketCount * BucketWidth, int64]
  var statuses: array[MaxOperations, int64]
  for operation in 0 ..< count:
    let opcode = input[1 + 3 * operation]
    let primary = int(input[2 + 3 * operation])
    let fingerprint = input[3 + 3 * operation]
    let alternate = primary xor delta(fingerprint)
    if opcode == 0:
      if not insert(cast[ptr UncheckedArray[int64]](addr table[0]), primary, fingerprint): return -3
      statuses[operation] = 1
    elif opcode == 1:
      var found = false
      for bucket in [primary, alternate]:
        for slot in 0 ..< BucketWidth:
          if table[bucket * BucketWidth + slot] == fingerprint: found = true
      statuses[operation] = if found: 1 else: 0
    else:
      var removed = false
      for bucket in [primary, alternate]:
        for slot in 0 ..< BucketWidth:
          let position = bucket * BucketWidth + slot
          if table[position] == fingerprint:
            table[position] = 0
            removed = true
            break
        if removed: break
      statuses[operation] = if removed: 1 else: 0
  for operation in 0 ..< count: writeI64Le(output, operation, statuses[operation])
  int64(required)
