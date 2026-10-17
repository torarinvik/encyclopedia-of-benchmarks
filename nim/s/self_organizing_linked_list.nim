const MaxInputLength = 130
const MaxOperations = 64
const MaxListLength = 64
const MaxOutputFields = 194

proc appendI64(records: var array[MaxOutputFields, int64], count: var int, value: int64) =
  records[count] = value
  inc count

proc writeI64Le(output: ptr UncheckedArray[uint8], offset: int, value: int64) =
  let bits = cast[uint64](value)
  for byte in 0 ..< 8:
    output[offset + byte] = uint8((bits shr (8 * byte)) and 0xFF'u64)

proc execute(input: ptr UncheckedArray[int64], length: int,
    records: var array[MaxOutputFields, int64]): int =
  if length < 1 or length > MaxInputLength: return -1
  let operationCount = input[0]
  if operationCount < 0 or operationCount > MaxOperations or
      length != 1 + 2 * int(operationCount): return -1

  var items: array[MaxListLength, int64]
  var itemCount = 0
  var recordCount = 0
  var cursor = 1
  for _ in 0 ..< int(operationCount):
    let opcode = input[cursor]
    let value = input[cursor + 1]
    cursor += 2
    if value < int64(low(int32)) or value > int64(high(int32)): return -1
    if opcode == 0:
      if itemCount == MaxListLength: return -1
      items[itemCount] = value
      inc itemCount
      appendI64(records, recordCount, 0)
      appendI64(records, recordCount, 0)
    elif opcode == 1:
      var foundAt = 0
      while foundAt < itemCount and items[foundAt] != value:
        inc foundAt
      let found = if foundAt < itemCount: 1'i64 else: 0'i64
      appendI64(records, recordCount, 1)
      appendI64(records, recordCount, 1)
      appendI64(records, recordCount, found)
      if found != 0 and foundAt != 0:
        var index = foundAt
        while index > 0:
          items[index] = items[index - 1]
          dec index
        items[0] = value
    else:
      return -1

  appendI64(records, recordCount, 2)
  appendI64(records, recordCount, int64(itemCount))
  for index in 0 ..< itemCount:
    appendI64(records, recordCount, items[index])
  recordCount

proc selfOrganizingLinkedList*(input: ptr UncheckedArray[int64], length: csize_t,
    output: ptr UncheckedArray[uint8], outputCapacity: csize_t): int64
    {.cdecl, exportc: "self_organizing_linked_list".} =
  if input == nil or length < 1 or length > csize_t(MaxInputLength): return -1
  var records: array[MaxOutputFields, int64]
  let recordCount = execute(input, int(length), records)
  if recordCount < 0: return -1
  let outputBytes = recordCount * 8
  if output == nil or outputCapacity < csize_t(outputBytes): return -2
  for index in 0 ..< recordCount:
    writeI64Le(output, index * 8, records[index])
  int64(outputBytes)
