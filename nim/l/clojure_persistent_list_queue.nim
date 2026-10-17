const MaxOperations = 256
const MaxQueueLength = 64
const MaxValidInputLength = 513
const MaxParseableInputLength = 514
const FnvOffset = 14695981039346656037'u64
const FnvPrime = 1099511628211'u64

proc hashByte(hash: var uint64, byte: uint8) =
  hash = (hash xor uint64(byte)) *% FnvPrime

proc hashU16(hash: var uint64, value: uint16) =
  for byte in 0 ..< 2: hashByte(hash, uint8((value shr (8 * byte)) and 255'u16))

proc hashI32(hash: var uint64, value: int32) =
  let bits = cast[uint32](value)
  for byte in 0 ..< 4: hashByte(hash, uint8((bits shr (8 * byte)) and 255'u32))

proc hashI64(hash: var uint64, value: int64) =
  let bits = cast[uint64](value)
  for byte in 0 ..< 8: hashByte(hash, uint8((bits shr (8 * byte)) and 255'u64))

proc clojure_persistent_list_queue*(input: ptr UncheckedArray[int64], length: csize_t): int64
    {.cdecl, exportc: "clojure_persistent_list_queue".} =
  if input.isNil or length < csize_t(1) or length > csize_t(MaxParseableInputLength): return -1
  if input[0] < 0 or input[0] > MaxOperations: return -1
  let operationCount = int(input[0])
  if int(length) != 1 + 2 * operationCount or length > csize_t(MaxValidInputLength): return -1

  var newestFirst: array[MaxQueueLength, int32]
  var queueSize = 0
  var results: array[MaxOperations, int64]
  var opcodes: array[MaxOperations, uint8]
  for operation in 0 ..< operationCount:
    let offset = 1 + 2 * operation
    let opcodeValue = input[offset]
    let argument = input[offset + 1]
    if opcodeValue < 0 or opcodeValue > 3: return -1
    let opcode = int(opcodeValue)
    opcodes[operation] = uint8(opcode)
    if opcode == 0:
      if argument < int64(low(int32)) or argument > int64(high(int32)) or queueSize >= MaxQueueLength: return -1
      for index in countdown(queueSize, 1): newestFirst[index] = newestFirst[index - 1]
      newestFirst[0] = int32(argument)
      inc queueSize
      results[operation] = int64(queueSize)
    elif opcode == 1:
      if argument != 0: return -1
      if queueSize > 0: dec queueSize
      results[operation] = int64(queueSize)
    elif opcode == 2:
      if argument != 0: return -1
      results[operation] = if queueSize == 0: low(int64) else: int64(newestFirst[queueSize - 1])
    else:
      if argument != 0: return -1
      results[operation] = if queueSize == 0: 1 else: 0

  var hash = FnvOffset
  hashU16(hash, uint16(operationCount))
  for operation in 0 ..< operationCount:
    hashByte(hash, opcodes[operation])
    hashI64(hash, results[operation])
  hashU16(hash, uint16(queueSize))
  if queueSize > 0:
    for index in countdown(queueSize - 1, 0): hashI32(hash, newestFirst[index])
  int64(hash and 0x7fff_ffff_ffff_ffff'u64)
