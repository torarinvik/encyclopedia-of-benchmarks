const MaxInputLength = 202
const MaxListLength = 100

proc writeI32Le(output: ptr UncheckedArray[uint8], index: int, value: int32) =
  let bits = cast[uint32](value)
  let offset = index * 4
  for byte in 0 ..< 4:
    output[offset + byte] = uint8((bits shr (8 * byte)) and 0xFF'u32)

proc linkedlist_implentation_usingarray*(input: ptr UncheckedArray[int64], length: csize_t,
    output: ptr UncheckedArray[uint8], outputCapacity: csize_t): int64
    {.cdecl, exportc: "linkedlist_implentation_usingarray".} =
  if input == nil or length < 1 or length > csize_t(MaxInputLength): return -1
  let n = int(length)
  let operationCount = input[0]
  if operationCount < 0 or operationCount > 100 or n != 1 + 2 * int(operationCount): return -1
  var items: array[MaxListLength, int32]
  var itemCount = 0
  var cursor = 1
  for _ in 0 ..< int(operationCount):
    let opcode = input[cursor]
    let rawValue = input[cursor + 1]
    cursor += 2
    if rawValue < int64(low(int32)) or rawValue > int64(high(int32)) or itemCount >= MaxListLength: return -1
    let value = int32(rawValue)
    if opcode == 0:
      for index in countdown(itemCount, 1): items[index] = items[index - 1]
      items[0] = value
      inc itemCount
    elif opcode == 1:
      if itemCount == 0: return -1
      items[itemCount] = value
      inc itemCount
    else:
      return -1

  let outputBytes = (itemCount + 1) * 4
  if output == nil or outputCapacity < csize_t(outputBytes): return -2
  writeI32Le(output, 0, int32(itemCount))
  for index in 0 ..< itemCount: writeI32Le(output, index + 1, items[index])
  int64(outputBytes)
