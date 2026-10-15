const MaxItems = 64
const MaxTriplets = 2048
const HashCapacity = 128
const BytesPerTriplet = 12

type I64Array = ptr UncheckedArray[int64]
type ByteArray = ptr UncheckedArray[uint8]

type HashKeys = array[HashCapacity, int64]
type HashOccupied = array[HashCapacity, bool]
type Triples = array[MaxTriplets * 3, int64]

proc hashSlot(value: int64): int = int(((value + 100_000) * 37 mod int64(HashCapacity)))

proc seenContains(keys: HashKeys, occupied: HashOccupied, value: int64): bool =
  var slot = hashSlot(value)
  for probes in 0 ..< HashCapacity:
    if not occupied[slot]: return false
    if keys[slot] == value: return true
    slot = (slot + 1) mod HashCapacity
  false

proc seenAdd(keys: var HashKeys, occupied: var HashOccupied, value: int64) =
  var slot = hashSlot(value)
  for probes in 0 ..< HashCapacity:
    if not occupied[slot]:
      keys[slot] = value
      occupied[slot] = true
      return
    if keys[slot] == value: return
    slot = (slot + 1) mod HashCapacity

proc alreadyOutput(triples: Triples, count: int, a, b, c: int64): bool =
  for i in 0 ..< count:
    if triples[i * 3] == a and triples[i * 3 + 1] == b and triples[i * 3 + 2] == c: return true
  false

proc writeI32Le(output: ByteArray, offset: int, value: int64) =
  let bits = cast[uint32](int32(value))
  for byte in 0 ..< 4:
    output[offset + byte] = uint8((bits shr (byte * 8)) and 255)

proc find_triplets_with_0_sum_hashing*(input: I64Array, length: csize_t, output: ByteArray, outputCapacity: csize_t): int64
    {.cdecl, exportc: "find_triplets_with_0_sum_hashing".} =
  if length > csize_t(MaxItems) or (length > 0 and input.isNil): return -1
  let n = int(length)
  for i in 0 ..< n:
    if input[i] < -100_000 or input[i] > 100_000: return -1
  var triples: Triples
  var count = 0
  for i in 0 ..< n:
    if i + 2 >= n: break
    var keys: HashKeys
    var occupied: HashOccupied
    for j in i + 1 ..< n:
      let other = input[j]
      let required = -input[i] - other
      if required >= -100_000 and required <= 100_000 and seenContains(keys, occupied, required):
        var a = input[i]
        var b = other
        var c = required
        if a > b: swap(a, b)
        if b > c: swap(b, c)
        if a > b: swap(a, b)
        if not alreadyOutput(triples, count, a, b, c) and count < MaxTriplets:
          triples[count * 3] = a
          triples[count * 3 + 1] = b
          triples[count * 3 + 2] = c
          inc count
      seenAdd(keys, occupied, other)
  if count == 0: return 0
  let needed = count * BytesPerTriplet
  if output.isNil or outputCapacity < csize_t(needed): return -2
  for i in 0 ..< count * 3: writeI32Le(output, i * 4, triples[i])
  int64(count)
