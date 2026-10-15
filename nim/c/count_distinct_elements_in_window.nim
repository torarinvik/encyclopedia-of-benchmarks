const MaxN = 256
const HashCapacity = 512

type I64Array = ptr UncheckedArray[int64]
type ByteArray = ptr UncheckedArray[uint8]
type HashKeys = array[HashCapacity, int32]
type HashCounts = array[HashCapacity, int32]
type HashOccupied = array[HashCapacity, bool]

proc hashSlot(value: int32): int =
  let mixed = uint64(cast[uint32](value)) * 2_654_435_761'u64
  int(cast[uint32](mixed) shr 23)

proc findSlot(keys: var HashKeys, occupied: var HashOccupied, value: int32): int =
  var slot = hashSlot(value)
  for probes in 0 ..< HashCapacity:
    if not occupied[slot] or keys[slot] == value: return slot
    slot = (slot + 1) mod HashCapacity
  0

proc putI64Le(output: ByteArray, offset: int, value: int64) =
  let bits = cast[uint64](value)
  for byte in 0 ..< 8: output[offset + byte] = uint8((bits shr (8 * byte)) and 0xFF'u64)

proc count_distinct_elements_in_window*(input: I64Array, length: csize_t, output: ByteArray, capacity: csize_t): int64
    {.cdecl, exportc: "count_distinct_elements_in_window".} =
  if input.isNil or length < 3 or input[0] < 1 or input[0] > MaxN: return -1
  let n = int(input[0])
  if input[1] < 1 or input[1] > int64(n) or length != csize_t(n + 2): return -1
  let k = int(input[1])
  let outN = n - k + 1
  for i in 0 ..< n:
    if input[i + 2] < int64(low(int32)) or input[i + 2] > int64(high(int32)): return -1
  if output.isNil or capacity < csize_t(outN * 8): return -2

  var keys: HashKeys
  var counts: HashCounts
  var occupied: HashOccupied
  var distinct = 0'i64
  for i in 0 ..< k:
    let value = int32(input[i + 2])
    let slot = findSlot(keys, occupied, value)
    if not occupied[slot]:
      keys[slot] = value
      occupied[slot] = true
      counts[slot] = 0
    if counts[slot] == 0: inc distinct
    inc counts[slot]
  putI64Le(output, 0, distinct)
  for i in k ..< n:
    let incoming = int32(input[i + 2])
    var slot = findSlot(keys, occupied, incoming)
    if not occupied[slot]:
      keys[slot] = incoming
      occupied[slot] = true
      counts[slot] = 0
    if counts[slot] == 0: inc distinct
    inc counts[slot]
    let outgoing = int32(input[i - k + 2])
    slot = findSlot(keys, occupied, outgoing)
    dec counts[slot]
    if counts[slot] == 0: dec distinct
    putI64Le(output, (i - k + 1) * 8, distinct)
  int64(outN * 8)
