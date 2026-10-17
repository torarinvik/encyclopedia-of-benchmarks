const MaxOperations = 256
const MaxInputValues = 513
const MaxOutputBytes = 6152

proc writeI64Le(output: var array[MaxOutputBytes, uint8], offset: int, value: int64) =
  var bits = cast[uint64](value)
  for byte in 0 ..< 8:
    output[offset + byte] = uint8(bits and 255'u64)
    bits = bits shr 8

proc min_stack*(input: ptr UncheckedArray[int64], length: csize_t,
    output: ptr UncheckedArray[uint8], capacity: csize_t): int64
    {.cdecl, exportc: "min_stack".} =
  if input == nil or length < 1 or length > MaxInputValues: return -1
  let countValue = input[0]
  if countValue < 0 or countValue > MaxOperations: return -1
  let count = int(countValue)

  var opcodes: array[MaxOperations, int64]
  var operands: array[MaxOperations, int64]
  var position = 1
  var queryCount = 0
  for index in 0 ..< count:
    if position >= int(length): return -1
    let opcode = input[position]
    inc position
    var operand = 0'i64
    if opcode == 0:
      if position >= int(length): return -1
      operand = input[position]
      inc position
      if operand < int64(low(int32)) or operand > int64(high(int32)): return -1
    elif opcode == 2 or opcode == 3:
      inc queryCount
    elif opcode != 1:
      return -1
    opcodes[index] = opcode
    operands[index] = operand
  if position != int(length): return -1

  let needed = (1 + 3 * queryCount) * 8
  if output == nil or capacity < csize_t(needed): return -2

  var buffer: array[MaxOutputBytes, uint8]
  writeI64Le(buffer, 0, int64(queryCount))
  var stackValues: array[MaxOperations, int64]
  var stackMinima: array[MaxOperations, int64]
  var depth = 0
  var record = 1
  for index in 0 ..< count:
    let opcode = opcodes[index]
    if opcode == 0:
      let value = operands[index]
      stackValues[depth] = value
      stackMinima[depth] = if depth == 0 or value < stackMinima[depth - 1]:
        value
      else:
        stackMinima[depth - 1]
      inc depth
    elif opcode == 1:
      if depth > 0: dec depth
    else:
      var exceptionFlag = 0'i64
      var value = 0'i64
      if depth == 0:
        exceptionFlag = 1
      elif opcode == 2:
        value = stackValues[depth - 1]
      else:
        value = stackMinima[depth - 1]
      writeI64Le(buffer, record * 8, opcode)
      writeI64Le(buffer, (record + 1) * 8, exceptionFlag)
      writeI64Le(buffer, (record + 2) * 8, value)
      record += 3
  for index in 0 ..< needed: output[index] = buffer[index]
  int64(needed)
