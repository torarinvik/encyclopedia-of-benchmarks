const MaxInitialItems = 32
const MaxOperations = 64
const MaxInputLength = 162
const MaxStackSize = MaxInitialItems + MaxOperations
const MaxOutputBytes = 16 * MaxOperations

type
  I64Input = ptr UncheckedArray[int64]
  U8Output = ptr UncheckedArray[uint8]

proc putI64Le(output: U8Output, offset: int, value: int64) =
  let bits = cast[uint64](value)
  for byte in 0..<8:
    output[offset + byte] = uint8((bits shr (8 * byte)) and 0xFF'u64)

proc list_based_stack*(input: I64Input, length: csize_t, output: U8Output,
    capacity: csize_t): int64
    {.cdecl, exportc: "list_based_stack".} =
  if input == nil or length < 2 or length > csize_t(MaxInputLength):
    return -1
  let initialCountRaw = input[0]
  if initialCountRaw < 0 or initialCountRaw > int64(MaxInitialItems):
    return -1
  let initialCount = int(initialCountRaw)
  let operationCountIndex = 1 + initialCount
  if operationCountIndex >= int(length):
    return -1

  var initialItems: array[MaxInitialItems, int64]
  for index in 0..<initialCount:
    let value = input[1 + index]
    if value < int64(low(int32)) or value > int64(high(int32)):
      return -1
    initialItems[index] = value

  let operationCountRaw = input[operationCountIndex]
  if operationCountRaw < 0 or operationCountRaw > int64(MaxOperations):
    return -1
  let operationCount = int(operationCountRaw)
  var opcodes: array[MaxOperations, int64]
  var arguments: array[MaxOperations, int64]
  var cursor = operationCountIndex + 1
  var validatedSize = initialCount
  for index in 0..<operationCount:
    if cursor >= int(length):
      return -1
    let opcode = input[cursor]
    inc cursor
    opcodes[index] = opcode
    if opcode == 1 or opcode == 5:
      if cursor >= int(length):
        return -1
      let value = input[cursor]
      inc cursor
      if value < int64(low(int32)) or value > int64(high(int32)):
        return -1
      arguments[index] = value
      if opcode == 1:
        inc validatedSize
    elif opcode == 2 or opcode == 3:
      if validatedSize == 0:
        return -1
      if opcode == 2:
        dec validatedSize
    elif opcode == 4:
      discard
    elif opcode == 6:
      validatedSize = 0
    else:
      return -1
  if cursor != int(length):
    return -1

  var stack: array[MaxStackSize, int64]
  var stackSize = initialCount
  for index in 0..<initialCount:
    stack[index] = initialItems[index]
  var buffer: array[MaxOutputBytes, uint8]
  var written = 0
  for index in 0..<operationCount:
    let opcode = opcodes[index]
    var result = 0'i64
    if opcode == 1:
      stack[stackSize] = arguments[index]
      inc stackSize
    elif opcode == 2:
      dec stackSize
      result = stack[stackSize]
    elif opcode == 3:
      result = stack[stackSize - 1]
    elif opcode == 4:
      result = int64(stackSize)
    elif opcode == 5:
      for item in 0..<stackSize:
        if stack[item] == arguments[index]:
          result = 1
          break
    else:
      stackSize = 0
    let out = cast[U8Output](addr buffer[0])
    putI64Le(out, written, opcode)
    putI64Le(out, written + 8, result)
    written += 16

  if output == nil or capacity < csize_t(written):
    return -2
  for index in 0..<written:
    output[index] = buffer[index]
  int64(written)
