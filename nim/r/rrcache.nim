const MaxOperations = 32
const MaxInputLength = 3 + 3 * MaxOperations
const MaxOutputBytes = 8 * MaxOperations
const JavaMultiplier = 0x5DEECE66D'u64
const JavaAddend = 0xB'u64
const JavaMask = (1'u64 shl 48) - 1'u64

type
  I64Input = ptr UncheckedArray[int64]
  U8Output = ptr UncheckedArray[uint8]

proc javaNextBits(state: var uint64, bits: int): uint32 =
  state = (state *% JavaMultiplier +% JavaAddend) and JavaMask
  uint32(state shr (48 - bits))

proc javaNextInt(state: var uint64, bound: uint32): uint32 =
  if (bound and (bound - 1)) == 0:
    return uint32((uint64(bound) * uint64(javaNextBits(state, 31))) shr 31)
  while true:
    let bits = javaNextBits(state, 31)
    let value = bits mod bound
    if uint64(bits) - uint64(value) + uint64(bound - 1) <= 0x7fff_ffff'u64:
      return value

proc putI64Le(output: U8Output, offset: int, value: int64) =
  var bits = cast[uint64](value)
  for byte in 0 ..< 8:
    output[offset + byte] = uint8(bits and 0xff'u64)
    bits = bits shr 8

proc rrcache*(input: I64Input, inputLength: csize_t, output: U8Output,
    outputCapacity: csize_t): int64
    {.cdecl, exportc: "rrcache".} =
  if input == nil or inputLength < 3 or inputLength > csize_t(MaxInputLength): return -1
  if input[0] < 1 or input[0] > 8 or input[2] < 0 or input[2] > MaxOperations: return -1
  let cacheCapacity = int(input[0])
  let operationCount = int(input[2])
  if int(inputLength) != 3 + 3 * operationCount: return -1

  var keys: array[8, int64]
  var values: array[8, int64]
  var results: array[MaxOperations, int64]
  var size = 0
  var randomState = (cast[uint64](input[1]) xor JavaMultiplier) and JavaMask

  for operation in 0 ..< operationCount:
    let offset = 3 + 3 * operation
    let opcode = input[offset]
    let key = input[offset + 1]
    let value = input[offset + 2]
    if opcode == 0:
      if key < 1 or key > 1024 or value < 100 or value > 1_000_000: return -1
      var index = 0
      while index < size and keys[index] != key: inc index
      if index < size:
        values[index] = value
      else:
        if size == cacheCapacity:
          let evicted = int(javaNextInt(randomState, uint32(size)))
          for movement in evicted ..< size - 1:
            keys[movement] = keys[movement + 1]
            values[movement] = values[movement + 1]
          dec size
        keys[size] = key
        values[size] = value
        inc size
      results[operation] = -2
    elif opcode == 1:
      if key < 1 or key > 1024 or value != 0: return -1
      var index = 0
      while index < size and keys[index] != key: inc index
      results[operation] = if index < size: values[index] else: -1
    elif opcode == 2:
      if key != 0 or value != 0: return -1
      results[operation] = int64(size)
    else:
      return -1

  let outputBytes = operationCount * 8
  if output == nil or outputCapacity < csize_t(outputBytes): return -2
  var staged: array[MaxOutputBytes, uint8]
  for operation in 0 ..< operationCount:
    putI64Le(cast[U8Output](addr staged[0]), operation * 8, results[operation])
  for byte in 0 ..< outputBytes: output[byte] = staged[byte]
  int64(outputBytes)
