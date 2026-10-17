const MaxOperations = 64
const MaxInputLength = 129
const MaxOutputBytes = 1536

type
  I64Input = ptr UncheckedArray[int64]
  U8Output = ptr UncheckedArray[uint8]

proc putI64Le(output: U8Output, offset: int, value: int64) =
  let bits = cast[uint64](value)
  for byte in 0..<8:
    output[offset + byte] = uint8((bits shr (8 * byte)) and 0xFF'u64)

proc putRecord(output: U8Output, offset: int, opcode, tag, value: int64) =
  putI64Le(output, offset, opcode)
  putI64Le(output, offset + 8, tag)
  putI64Le(output, offset + 16, value)

proc linked_stack*(input: I64Input, length: csize_t, output: U8Output,
    capacity: csize_t): int64
    {.cdecl, exportc: "linked_stack".} =
  if input == nil or length < 1 or length > csize_t(MaxInputLength):
    return -1
  let rawCount = input[0]
  if rawCount < 0 or rawCount > int64(MaxOperations):
    return -1
  let operationCount = int(rawCount)
  var opcodes: array[MaxOperations, int64]
  var arguments: array[MaxOperations, int64]
  var cursor = 1
  for index in 0..<operationCount:
    if cursor >= int(length):
      return -1
    let opcode = input[cursor]
    inc cursor
    opcodes[index] = opcode
    if opcode == 1:
      if cursor >= int(length):
        return -1
      let value = input[cursor]
      inc cursor
      if value < int64(low(int32)) or value > int64(high(int32)):
        return -1
      arguments[index] = value
    elif opcode < 2 or opcode > 4:
      return -1
  if cursor != int(length):
    return -1

  var nodeValues: array[MaxOperations + 1, int64]
  var below: array[MaxOperations + 1, int]
  var nodeCount = 0
  var head = 0
  var buffer: array[MaxOutputBytes, uint8]
  var written = 0
  for index in 0..<operationCount:
    let opcode = opcodes[index]
    var tag = 2'i64
    var value = 0'i64
    if opcode == 1:
      inc nodeCount
      nodeValues[nodeCount] = arguments[index]
      below[nodeCount] = head
      head = nodeCount
    elif opcode == 2:
      if head != 0:
        tag = 0
        value = nodeValues[head]
    elif opcode == 3:
      if head != 0:
        tag = 0
        value = nodeValues[head]
        head = below[head]
    else:
      tag = 1
      value = if head == 0: 1'i64 else: 0'i64
    putRecord(addr buffer[0], written, opcode, tag, value)
    written += 24

  if output == nil or capacity < csize_t(written):
    return -2
  for index in 0..<written:
    output[index] = buffer[index]
  int64(written)
