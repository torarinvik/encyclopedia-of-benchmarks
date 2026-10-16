const MaxOperations = 64
const MaxInputLength = 129
const MaxOutputBytes = 1536

proc writeI64Le(output: var array[MaxOutputBytes, uint8], offset: int, value: int64) =
  var bits = cast[uint64](value)
  for byte in 0 ..< 8:
    output[offset + byte] = uint8(bits and 255'u64)
    bits = bits shr 8

proc writeRecord(output: var array[MaxOutputBytes, uint8], offset: int,
                 opcode, tag, value: int64) =
  writeI64Le(output, offset, opcode)
  writeI64Le(output, offset + 8, tag)
  writeI64Le(output, offset + 16, value)

proc stack_with_singly_linked_list*(input: ptr UncheckedArray[int64], length: csize_t,
    output: ptr UncheckedArray[uint8], capacity: csize_t): int64
    {.cdecl, exportc: "stack_with_singly_linked_list".} =
  if input == nil or length < 1 or length > MaxInputLength: return -1
  let countValue = input[0]
  if countValue < 0 or countValue > MaxOperations: return -1
  let count = int(countValue)
  var opcodes: array[MaxOperations, int64]
  var arguments: array[MaxOperations, int64]
  var cursor = 1
  for i in 0 ..< count:
    if cursor >= int(length): return -1
    let opcode = input[cursor]
    inc cursor
    opcodes[i] = opcode
    if opcode == 1:
      if cursor >= int(length): return -1
      let value = input[cursor]
      inc cursor
      if value < int64(low(int32)) or value > int64(high(int32)): return -1
      arguments[i] = value
    elif opcode < 2 or opcode > 5:
      return -1
  if cursor != int(length): return -1

  var nodeValues: array[MaxOperations + 1, int64]
  var nextIds: array[MaxOperations + 1, int]
  var buffer: array[MaxOutputBytes, uint8]
  var nodeCount = 0
  var head = 0
  var written = 0
  for i in 0 ..< count:
    let opcode = opcodes[i]
    var tag = 2'i64
    var value = 0'i64
    if opcode == 1:
      inc nodeCount
      nodeValues[nodeCount] = arguments[i]
      nextIds[nodeCount] = head
      head = nodeCount
    elif opcode == 2 or opcode == 3:
      if head == 0:
        writeRecord(buffer, written, opcode, 4, 2)
        written += 24
        break
      tag = 0
      value = nodeValues[head]
      if opcode == 2: head = nextIds[head]
    elif opcode == 4:
      head = 0
    else:
      tag = 0
      var node = head
      while node != 0:
        inc value
        node = nextIds[node]
    writeRecord(buffer, written, opcode, tag, value)
    written += 24
  if output == nil or capacity < csize_t(written): return -2
  for i in 0 ..< written: output[i] = buffer[i]
  int64(written)
