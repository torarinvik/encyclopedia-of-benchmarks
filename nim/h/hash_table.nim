## Collision-free integer-set membership for the shared hash-table contract.
const TableCapacity = 17
const MaxInsertCount = 8
const MaxQueryCount = 8
const MaxKey = 1000'i64
const MaxParseableLength = 19

proc storeI64Le(output: ptr UncheckedArray[uint8], offset: int, value: int64) =
  let bits = cast[uint64](value)
  for byte in 0 ..< 8:
    output[offset + byte] = uint8((bits shr (byte * 8)) and 255)

proc hash_table*(values: ptr UncheckedArray[int64], length: csize_t,
    output: ptr UncheckedArray[uint8], outputCapacity: csize_t): int64
    {.cdecl, exportc: "hash_table".} =
  if values == nil or length < 2 or length > csize_t(MaxParseableLength): return -1
  let rawInsertCount = values[0]
  if rawInsertCount < 0 or rawInsertCount > MaxInsertCount: return -1
  let insertCount = int(rawInsertCount)
  let queryCountIndex = 1 + insertCount
  if csize_t(queryCountIndex) >= length: return -1
  let rawQueryCount = values[queryCountIndex]
  if rawQueryCount < 1 or rawQueryCount > MaxQueryCount: return -1
  let queryCount = int(rawQueryCount)
  let queryStart = queryCountIndex + 1
  let totalKeys = insertCount + queryCount
  if length != csize_t(queryStart + queryCount): return -1

  for index in 0 ..< totalKeys:
    let position = if index < insertCount: 1 + index else: queryStart + index - insertCount
    let key = values[position]
    if key < 1 or key > MaxKey: return -1
    for prior in 0 ..< index:
      let priorPosition = if prior < insertCount: 1 + prior else: queryStart + prior - insertCount
      let other = values[priorPosition]
      let sameGroup = (index < insertCount) == (prior < insertCount)
      if key == other:
        if sameGroup: return -1
      elif key mod TableCapacity == other mod TableCapacity or key mod 3000 == other mod 3000:
        return -1

  var table: array[TableCapacity, int64]
  for index in 0 ..< insertCount:
    let key = values[1 + index]
    table[int(key mod TableCapacity)] = key

  let outputBytes = 8 * queryCount
  if output == nil or outputCapacity < csize_t(outputBytes): return -2
  for index in 0 ..< queryCount:
    let query = values[queryStart + index]
    let found = if table[int(query mod TableCapacity)] == query: 1'i64 else: 0'i64
    storeI64Le(output, 8 * index, found)
  return int64(outputBytes)
