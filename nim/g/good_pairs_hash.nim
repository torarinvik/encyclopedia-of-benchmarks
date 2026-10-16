## Count equal-value index pairs with a bounded open-addressed frequency table.
const MaxArrayLength = 256
const MaxInputLength = 258
const TableSize = 512

proc goodPairsHash*(input: ptr UncheckedArray[int64], length: csize_t): int64
    {.cdecl, exportc: "good_pairs_hash".} =
  if input == nil or length < 1 or length > csize_t(MaxInputLength): return -1
  let declared = input[0]
  if declared < 0 or declared > MaxArrayLength or length != csize_t(declared + 1): return -1
  let n = int(declared)
  var keys: array[TableSize, int64]
  var frequencies: array[TableSize, uint64]
  var occupied: array[TableSize, bool]
  for index in 0 ..< n:
    let value = input[index + 1]
    if value < -1_000_000 or value > 1_000_000: return -1
    var slot = int(((value + 1_000_000) * 2_654_435_761) mod TableSize)
    while occupied[slot] and keys[slot] != value: slot = (slot + 1) mod TableSize
    if not occupied[slot]:
      occupied[slot] = true
      keys[slot] = value
    inc frequencies[slot]
  var pairs: uint64 = 0
  for frequency in frequencies:
    if frequency > 1: pairs += frequency * (frequency - 1) div 2
  int64(pairs)
