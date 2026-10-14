## One-pass two-sum with portable open addressing and first-pair ordering.
const TwoSumMaxValues = 256
const TwoSumTableSize = 512
const TwoSumIndexBase = 256
const TwoSumPrime = 2147483647'i64

proc hashSlot(key: int64, capacity: int): int =
  var normalized = key mod TwoSumPrime
  if normalized < 0:
    normalized += TwoSumPrime
  int((normalized * 48271'i64 mod TwoSumPrime) mod int64(capacity))

proc two_sum*(values: ptr UncheckedArray[int64], length: csize_t): int64 {.cdecl, exportc: "two_sum".} =
  if values.isNil or length == 0 or length > csize_t(TwoSumMaxValues + 1):
    return -2
  for index in 0 ..< int(length):
    if values[index] < -2147483648'i64 or values[index] > 2147483647'i64:
      return -2

  let target = values[0]
  let valueCount = int(length) - 1
  var capacity = 1
  while capacity < valueCount * 2:
    capacity *= 2
  var keys: array[TwoSumTableSize, int64]
  var firstIndices: array[TwoSumTableSize, int]
  var occupied: array[TwoSumTableSize, bool]

  for index in 0 ..< valueCount:
    let current = values[index + 1]
    let complement = target - current
    var slot = hashSlot(complement, capacity)
    while occupied[slot] and keys[slot] != complement:
      slot = (slot + 1) mod capacity
    if occupied[slot]:
      return int64(firstIndices[slot] * TwoSumIndexBase + index)

    slot = hashSlot(current, capacity)
    while occupied[slot] and keys[slot] != current:
      slot = (slot + 1) mod capacity
    if not occupied[slot]:
      occupied[slot] = true
      keys[slot] = current
      firstIndices[slot] = index
  -1
