const MaxMessageBytes = 4096
const MaxParseableInputLength = 4099
const MaxOutputBytes = 64
const RoundConstants: array[24, uint64] = [
  0x0000000000000001'u64,0x0000000000008082'u64,0x800000000000808a'u64,0x8000000080008000'u64,
  0x000000000000808b'u64,0x0000000080000001'u64,0x8000000080008081'u64,0x8000000000008009'u64,
  0x000000000000008a'u64,0x0000000000000088'u64,0x0000000080008009'u64,0x000000008000000a'u64,
  0x000000008000808b'u64,0x800000000000008b'u64,0x8000000080008089'u64,0x8000000000008003'u64,
  0x8000000000008002'u64,0x8000000000000080'u64,0x000000000000800a'u64,0x800000008000000a'u64,
  0x8000000080008081'u64,0x8000000000008080'u64,0x0000000080000001'u64,0x8000000080008008'u64]
const RotationOffsets: array[25, int] = [
  0,1,62,28,27,36,44,6,55,20,3,10,43,25,39,41,45,15,21,8,18,2,61,56,14]

proc rotateLeft(value: uint64, amount: int): uint64 =
  if amount == 0: return value
  (value shl amount) or (value shr (64 - amount))

proc keccakF(state: var array[25, uint64]) =
  for roundConstant in RoundConstants:
    var column: array[5, uint64]
    var delta: array[5, uint64]
    var moved: array[25, uint64]
    for x in 0 ..< 5:
      column[x] = state[x] xor state[x + 5] xor state[x + 10] xor state[x + 15] xor state[x + 20]
    for x in 0 ..< 5:
      delta[x] = column[(x + 4) mod 5] xor rotateLeft(column[(x + 1) mod 5], 1)
    for y in 0 ..< 5:
      for x in 0 ..< 5: state[x + 5 * y] = state[x + 5 * y] xor delta[x]
    for y in 0 ..< 5:
      for x in 0 ..< 5:
        let source = x + 5 * y
        let target = y + 5 * ((2 * x + 3 * y) mod 5)
        moved[target] = rotateLeft(state[source], RotationOffsets[source])
    for y in 0 ..< 5:
      for x in 0 ..< 5:
        state[x + 5 * y] = moved[x + 5 * y] xor
          ((not moved[(x + 1) mod 5 + 5 * y]) and moved[(x + 2) mod 5 + 5 * y])
    state[0] = state[0] xor roundConstant

proc absorbByte(state: var array[25, uint64], offset: int, value: uint8) =
  state[offset div 8] = state[offset div 8] xor (uint64(value) shl ((offset mod 8) * 8))

proc sha3Digest(variant: int, input: ptr UncheckedArray[int64], messageLength: int): array[64, uint8] =
  let digestLengths = [28, 32, 48, 64]
  let rates = [144, 136, 104, 72]
  let rate = rates[variant]
  var state: array[25, uint64]
  var offset = 0
  while messageLength - offset >= rate:
    for index in 0 ..< rate: absorbByte(state, index, uint8(input[2 + offset + index]))
    keccakF(state)
    offset += rate

  var blockBytes: array[144, uint8]
  let remaining = messageLength - offset
  for index in 0 ..< remaining: blockBytes[index] = uint8(input[2 + offset + index])
  blockBytes[remaining] = blockBytes[remaining] xor 0x06'u8
  blockBytes[rate - 1] = blockBytes[rate - 1] xor 0x80'u8
  for index in 0 ..< rate: absorbByte(state, index, blockBytes[index])
  keccakF(state)

  var digest: array[64, uint8]
  for index in 0 ..< digestLengths[variant]:
    digest[index] = uint8((state[index div 8] shr ((index mod 8) * 8)) and 0xff'u64)
  digest

proc sha3*(input: ptr UncheckedArray[int64], inputLength: csize_t,
    output: ptr UncheckedArray[uint8], outputCapacity: csize_t): int64
    {.cdecl, exportc: "sha3".} =
  if input.isNil or inputLength < 2 or inputLength > MaxParseableInputLength.csize_t: return -1
  if input[0] < 0 or input[0] > 3 or input[1] < 0 or input[1] > MaxMessageBytes: return -1
  let variant = int(input[0])
  let messageLength = int(input[1])
  if int(inputLength) != 2 + messageLength: return -1
  for index in 0 ..< messageLength:
    if input[2 + index] < 0 or input[2 + index] > 255: return -1

  let digestLengths = [28, 32, 48, 64]
  let digestLength = digestLengths[variant]
  if digestLength > MaxOutputBytes: return -1
  if output.isNil or outputCapacity < digestLength.csize_t: return -2
  let digest = sha3Digest(variant, input, messageLength)
  for index in 0 ..< digestLength: output[index] = digest[index]
  digestLength.int64
