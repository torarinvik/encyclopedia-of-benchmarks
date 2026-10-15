## Count three-array occurrences and emit keys with total count exactly three.
const ArrayCount = 3
const MaxArrayLength = 64
const MaxInputLength = 3 * (MaxArrayLength + 1)
const MaxOccurrences = ArrayCount * MaxArrayLength
const TableSize = 257

proc addOccurrence(value: int64, keys: var array[TableSize, int64],
    counts: var array[TableSize, int], occupied: var array[TableSize, bool],
    order: var array[MaxOccurrences, int], orderLength: var int) =
  var remainder = value mod int64(TableSize)
  if remainder < 0: remainder += int64(TableSize)
  var slot = int(remainder)
  while occupied[slot] and keys[slot] != value:
    slot = (slot + 1) mod TableSize
  if not occupied[slot]:
    occupied[slot] = true
    keys[slot] = value
    counts[slot] = 0
    order[orderLength] = slot
    inc orderLength
  inc counts[slot]

proc storeI32Le(output: ptr UncheckedArray[uint8], position: int, value: int64) =
  let bits = cast[uint32](int32(value))
  for byte in 0 ..< 4:
    output[position + byte] = uint8((bits shr (byte * 8)) and 255)

proc arrays_intersection*(input: ptr UncheckedArray[int64], length: csize_t,
    output: ptr UncheckedArray[uint8], outputCapacity: csize_t): int64
    {.cdecl, exportc: "arrays_intersection".} =
  if input == nil or length < ArrayCount or length > csize_t(MaxInputLength): return -1
  var starts: array[ArrayCount, int]
  var sizes: array[ArrayCount, int]
  var position = 0
  for arrayIndex in 0 ..< ArrayCount:
    if position >= int(length) or input[position] < 0 or input[position] > MaxArrayLength: return -1
    let size = int(input[position])
    inc position
    if size > int(length) - position: return -1
    starts[arrayIndex] = position
    sizes[arrayIndex] = size
    for index in 0 ..< size:
      if input[position + index] < int64(low(int32)) or input[position + index] > int64(high(int32)): return -1
    position += size
  if position != int(length): return -1

  var keys: array[TableSize, int64]
  var counts: array[TableSize, int]
  var occupied: array[TableSize, bool]
  var order: array[MaxOccurrences, int]
  var orderLength = 0
  for arrayIndex in 0 ..< ArrayCount:
    for index in 0 ..< sizes[arrayIndex]:
      addOccurrence(input[starts[arrayIndex] + index], keys, counts, occupied, order, orderLength)

  var matchCount = 0
  for index in 0 ..< orderLength:
    if counts[order[index]] == ArrayCount: inc matchCount
  let required = matchCount * 4
  if int(outputCapacity) < required or (matchCount > 0 and output == nil): return -2
  var written = 0
  for index in 0 ..< orderLength:
    let slot = order[index]
    if counts[slot] == ArrayCount:
      storeI32Le(output, written * 4, keys[slot])
      inc written
  int64(written)
