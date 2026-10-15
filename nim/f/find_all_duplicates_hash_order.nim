const MaxLength = 1024
const TableSize = 2048

proc storeI64Le(value: int64, output: ptr UncheckedArray[uint8], offset: int) =
  let bits = cast[uint64](value)
  for byte in 0 ..< 8:
    output[offset + byte] = uint8((bits shr (byte * 8)) and 255)

proc find_all_duplicates_hash_order*(values: ptr UncheckedArray[int64], length: csize_t,
    output: ptr UncheckedArray[uint8], outputCapacity: csize_t): int64
    {.cdecl, exportc: "find_all_duplicates_hash_order".} =
  if length > csize_t(MaxLength) or (length > 0 and values.isNil): return -1
  let count = int(length)
  var keys: array[TableSize, int64]
  var counts: array[TableSize, uint16]
  var insertionOrder: array[MaxLength, int]
  var uniqueCount = 0

  for index in 0 ..< count:
    let value = values[index]
    var slot = int(value mod int64(TableSize))
    if slot < 0: slot += TableSize
    while counts[slot] != 0 and keys[slot] != value:
      slot = (slot + 1) mod TableSize
    if counts[slot] == 0:
      keys[slot] = value
      counts[slot] = 1
      insertionOrder[uniqueCount] = slot
      inc uniqueCount
    else:
      inc counts[slot]

  var duplicateCount = 0
  for index in 0 ..< uniqueCount:
    if counts[insertionOrder[index]] > 1: inc duplicateCount
  if duplicateCount == 0: return 0
  let requiredBytes = csize_t(duplicateCount * 8)
  if output.isNil or outputCapacity < requiredBytes: return -2

  var written = 0
  for index in 0 ..< uniqueCount:
    let slot = insertionOrder[index]
    if counts[slot] > 1:
      storeI64Le(keys[slot], output, written * 8)
      inc written
  int64(duplicateCount)
