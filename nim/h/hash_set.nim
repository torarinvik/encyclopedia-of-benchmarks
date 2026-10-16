## Bounded port of the pinned C hash set's ASCII-key insertion and lookup.
const MaxIds = 64
const MaxInputLength = 130
const Capacity = 1024
const FnvOffset = 14695981039346656037'u64
const FnvPrime = 1099511628211'u64

proc adlerKey(id: int64): uint64 =
  var a = 1'u64
  var b = 0'u64
  a = (a + 107'u64) mod 65521'u64
  b = (b + a) mod 65521'u64
  a = (a + 101'u64) mod 65521'u64
  b = (b + a) mod 65521'u64
  a = (a + 121'u64) mod 65521'u64
  b = (b + a) mod 65521'u64
  if id >= 10:
    a = (a + uint64(id div 10 + 48)) mod 65521'u64
    b = (b + a) mod 65521'u64
  a = (a + uint64(id mod 10 + 48)) mod 65521'u64
  b = (b + a) mod 65521'u64
  (b shl 16) or a

proc bucketForId(id: int64): int =
  let hash = adlerKey(id)
  int((uint64(Capacity - 1)) and (hash xor (hash shr 12)))

proc fnvWord(hash: uint64, value: int64): uint64 =
  let bits = cast[uint64](value)
  var resultHash = hash
  for byte in 0 ..< 8:
    resultHash = (resultHash xor ((bits shr (8 * byte)) and 255'u64)) * FnvPrime
  resultHash

proc hash_set*(input: ptr UncheckedArray[int64], length: csize_t): int64
    {.cdecl, exportc: "hash_set".} =
  if input.isNil or length < 2 or length > csize_t(MaxInputLength): return -1
  let addCountValue = input[0]
  if addCountValue < 0 or addCountValue > MaxIds: return -1
  let addCount = int(addCountValue)
  let queryCountIndex = 1 + addCount
  if queryCountIndex >= int(length): return -1
  let queryCountValue = input[queryCountIndex]
  if queryCountValue < 0 or queryCountValue > MaxIds: return -1
  let queryCount = int(queryCountValue)
  if int(length) != 2 + addCount + queryCount: return -1

  for index in 0 ..< addCount:
    if input[1 + index] < 0 or input[1 + index] >= MaxIds: return -1
  for index in 0 ..< queryCount:
    if input[queryCountIndex + 1 + index] < 0 or input[queryCountIndex + 1 + index] >= MaxIds: return -1

  var occupied: array[Capacity, bool]
  var slotIds: array[Capacity, int64]
  var setLength = 0'i64
  for index in 0 ..< addCount:
    let id = input[1 + index]
    let bucket = bucketForId(id)
    if not occupied[bucket]:
      occupied[bucket] = true
      slotIds[bucket] = id
      inc setLength
    elif slotIds[bucket] != id:
      return -1

  var resultHash = fnvWord(FnvOffset, setLength)
  for index in 0 ..< queryCount:
    let id = input[queryCountIndex + 1 + index]
    let bucket = bucketForId(id)
    let contains = occupied[bucket] and slotIds[bucket] == id
    resultHash = fnvWord(resultHash, if contains: 1'i64 else: 0'i64)
  int64(resultHash and 0x7fff_ffff_ffff_ffff'u64)
