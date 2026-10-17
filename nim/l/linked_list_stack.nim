const MaxOperations = 64
const MaxInputLength = 1 + 2 * MaxOperations
const MaxDepth = 64
const MaxOutputBytes = 4 + 8 * MaxOperations

type
  I64Input = ptr UncheckedArray[int64]
  U8Output = ptr UncheckedArray[uint8]
  StackNode = object
    value: int32
    next: int32

proc putI32Le(output: U8Output, offset: int, value: int32) =
  let bits = cast[uint32](value)
  for byte in 0 ..< 4:
    output[offset + byte] = uint8((bits shr (8 * byte)) and 0xFF'u32)

proc linked_list_stack*(input: I64Input, length: csize_t, output: U8Output,
    capacity: csize_t): int64
    {.cdecl, exportc: "linked_list_stack".} =
  if input == nil or length < 1 or length > csize_t(MaxInputLength): return -1
  if input[0] < 0 or input[0] > int64(MaxOperations): return -1

  let operationCount = int(input[0])
  let inputLength = int(length)
  var nodes: array[MaxDepth, StackNode]
  var records: array[2 * MaxOperations, int32]
  var nodeCount = 0
  var queryCount = 0
  var cursor = 1
  var top = -1'i32
  var stackSize = 0'i32
  for _ in 0 ..< operationCount:
    if cursor >= inputLength: return -1
    let opcode = input[cursor]
    cursor += 1
    if opcode == 0:
      if cursor >= inputLength: return -1
      let value = input[cursor]
      cursor += 1
      if value < int64(low(int32)) or value > int64(high(int32)) or
          stackSize >= int32(MaxDepth) or nodeCount >= MaxDepth:
        return -1
      nodes[nodeCount].value = int32(value)
      nodes[nodeCount].next = top
      top = int32(nodeCount)
      nodeCount += 1
      stackSize += 1
    elif opcode == 1:
      if stackSize == 0 or top < 0: return -1
      records[2 * queryCount] = 1
      records[2 * queryCount + 1] = nodes[int(top)].value
      queryCount += 1
      top = nodes[int(top)].next
      stackSize -= 1
    elif opcode == 2:
      records[2 * queryCount] = 2
      records[2 * queryCount + 1] = stackSize
      queryCount += 1
    elif opcode == 3:
      records[2 * queryCount] = 3
      records[2 * queryCount + 1] = if stackSize == 0: 1'i32 else: 0'i32
      queryCount += 1
    else:
      return -1
  if cursor != inputLength: return -1

  let outputBytes = 4 + 8 * queryCount
  if output == nil or capacity < csize_t(outputBytes): return -2
  var buffer: array[MaxOutputBytes, uint8]
  let out = cast[U8Output](addr buffer[0])
  putI32Le(out, 0, int32(queryCount))
  for index in 0 ..< 2 * queryCount:
    putI32Le(out, 4 + 4 * index, records[index])
  for byte in 0 ..< outputBytes: output[byte] = buffer[byte]
  int64(outputBytes)
