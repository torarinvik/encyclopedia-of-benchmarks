const
  MaxInputLength = 130
  FnvOffset = 14695981039346656037'u64
  FnvPrime = 1099511628211'u64

proc fnvWord(hash: uint64, value: int64): uint64 =
  let bits = cast[uint64](value)
  var resultHash = hash
  for byte in 0 ..< 8:
    resultHash = (resultHash xor ((bits shr (8 * byte)) and 255'u64)) *% FnvPrime
  resultHash

proc positiveRemainder(key: int64, capacity: int): int =
  let magnitude = if key < 0: -key else: key
  let rem = magnitude mod int64(capacity)
  if key < 0 and rem != 0: capacity - int(rem) else: int(rem)

proc hash2(key: int64, capacity: int): int =
  let magnitude = if key < 0: -key else: key
  let quotientMagnitude = magnitude div int64(capacity)
  let quotient = if key < 0: -quotientMagnitude else: quotientMagnitude
  positiveRemainder(quotient, capacity)

proc hash_map_cuckoo_hashing*(values: ptr UncheckedArray[int64], length: csize_t): int64
    {.cdecl, exportc: "hash_map_cuckoo_hashing".} =
  if values.isNil or length < 2 or length > csize_t(MaxInputLength): return -1
  let capacityValue = values[0]
  let countValue = values[1]
  if capacityValue < 16 or capacityValue > 256 or countValue < 0 or countValue > 128: return -1
  let capacity = int(capacityValue)
  if (capacity and (capacity - 1)) != 0 or int(length) != int(countValue) + 2: return -1
  let count = int(countValue)
  var keys: array[128, int64]
  var buckets: array[128, int]
  for i in 0 ..< count:
    let key = values[2 + i]
    if key < -2_147_483_647'i64 or key > 2_147_483_647'i64: return -1
    keys[i] = key
    buckets[i] = positiveRemainder(key, capacity)
    for j in 0 ..< i:
      if keys[j] == key: return -1

  let classA = count == 2 and buckets[0] == buckets[1] and
    hash2(keys[0], capacity) != buckets[0]
  var classB = true
  for i in 0 ..< count:
    for j in 0 ..< i:
      if buckets[i] == buckets[j]: classB = false
  if not classA and not classB: return -1

  var positions: array[128, int64]
  var finalCapacity = capacity
  if classA:
    positions[0] = int64(hash2(keys[0], capacity))
    positions[1] = int64(buckets[0])
  else:
    while count * 10 > finalCapacity * 7: finalCapacity *= 2
    for i in 0 ..< count: positions[i] = int64(positiveRemainder(keys[i], finalCapacity))

  var hash = fnvWord(FnvOffset, countValue)
  for i in 0 ..< count: hash = fnvWord(hash, positions[i])
  int64(hash and 0x7fff_ffff_ffff_ffff'u64)
