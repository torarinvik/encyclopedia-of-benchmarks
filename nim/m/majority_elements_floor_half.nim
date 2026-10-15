const MaxInputLength = 256
const TableSize = 512

proc storeI32Le(value: int32, output: ptr UncheckedArray[uint8], offset: int) =
  let bits = cast[uint32](value)
  for byte in 0 ..< 4:
    output[offset + byte] = uint8((bits shr (byte * 8)) and 255)

proc majority_elements_floor_half*(input: ptr UncheckedArray[int64], length: csize_t,
    output: ptr UncheckedArray[uint8], capacity: csize_t): int64
    {.cdecl, exportc: "majority_elements_floor_half".} =
  if length > csize_t(MaxInputLength) or (length > 0 and input.isNil): return -1
  let count = int(length)
  var keys: array[TableSize, int32]
  var counts: array[TableSize, uint16]
  var used: array[TableSize, bool]
  var order: array[MaxInputLength, int]
  var uniqueCount = 0

  for index in 0 ..< count:
    let value = input[index]
    if value < -2_147_483_648'i64 or value > 2_147_483_647'i64: return -1
    var remainder = value mod int64(TableSize)
    if remainder < 0: remainder += int64(TableSize)
    var slot = int(remainder)
    while used[slot] and int64(keys[slot]) != value:
      slot = (slot + 1) mod TableSize
    if not used[slot]:
      used[slot] = true
      keys[slot] = int32(value)
      counts[slot] = 1
      order[uniqueCount] = slot
      inc uniqueCount
    else:
      inc counts[slot]

  let threshold = uint16(count div 2)
  var result: array[MaxInputLength, int32]
  var resultCount = 0
  for index in 0 ..< uniqueCount:
    let slot = order[index]
    if counts[slot] >= threshold:
      result[resultCount] = keys[slot]
      inc resultCount
  for index in 1 ..< resultCount:
    let value = result[index]
    var position = index
    while position > 0 and result[position - 1] > value:
      result[position] = result[position - 1]
      dec position
    result[position] = value

  let required = csize_t(resultCount * 4)
  if capacity < required or (required > 0 and output.isNil): return -2
  for index in 0 ..< resultCount:
    storeI32Le(result[index], output, index * 4)
  int64(resultCount)
