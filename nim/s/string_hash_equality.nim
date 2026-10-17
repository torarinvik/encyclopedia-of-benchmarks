const
  MaxBytes = 64'i64
  MaxParseableInputLength = 131
  RateBytes = 136
  RoundConstants: array[24, uint64] = [
    0x0000000000000001'u64,
  0x0000000000008082'u64,
  0x800000000000808a'u64,
  0x8000000080008000'u64,
  0x000000000000808b'u64,
  0x0000000080000001'u64,
  0x8000000080008081'u64,
  0x8000000000008009'u64,
  0x000000000000008a'u64,
  0x0000000000000088'u64,
  0x0000000080008009'u64,
  0x000000008000000a'u64,
  0x000000008000808b'u64,
  0x800000000000008b'u64,
  0x8000000000008089'u64,
  0x8000000000008003'u64,
  0x8000000000008002'u64,
  0x8000000000000080'u64,
  0x000000000000800a'u64,
  0x800000008000000a'u64,
  0x8000000080008081'u64,
  0x8000000000008080'u64,
  0x0000000080000001'u64,
  0x8000000080008008'u64
  ]
  RotationOffsets: array[25, int] = [0, 1, 62, 28, 27, 36, 44, 6, 55, 20, 3, 10, 43, 25, 39, 41, 45, 15, 21, 8, 18, 2, 61, 56, 14]

proc rotateLeft(value: uint64, amount: int): uint64 =
  if amount == 0: return value
  (value shl amount) or (value shr (64 - amount))

proc keccakF1600(state: var array[25, uint64]) =
  for round in 0 ..< 24:
    var column: array[5, uint64]
    var delta: array[5, uint64]
    var moved: array[25, uint64]
    for x in 0 ..< 5:
      column[x] = state[x] xor state[x + 5] xor state[x + 10] xor state[x + 15] xor state[x + 20]
    for x in 0 ..< 5:
      delta[x] = column[(x + 4) mod 5] xor rotateLeft(column[(x + 1) mod 5], 1)
    for y in 0 ..< 5:
      for x in 0 ..< 5:
        let source = x + 5 * y
        let target = y + 5 * ((2 * x + 3 * y) mod 5)
        moved[target] = rotateLeft(state[source] xor delta[x], RotationOffsets[source])
    for y in 0 ..< 5:
      for x in 0 ..< 5:
        state[x + 5 * y] = moved[x + 5 * y] xor ((not moved[(x + 1) mod 5 + 5 * y]) and moved[(x + 2) mod 5 + 5 * y])
    state[0] = state[0] xor RoundConstants[round]

proc keccak256Bytes(input: ptr UncheckedArray[int64], start, byteLength: int): array[4, uint64] =
  var paddedBlock: array[RateBytes, uint8]
  for i in 0 ..< byteLength: paddedBlock[i] = uint8(input[start + i])
  paddedBlock[byteLength] = paddedBlock[byteLength] xor 0x01'u8
  paddedBlock[RateBytes - 1] = paddedBlock[RateBytes - 1] xor 0x80'u8
  var state: array[25, uint64]
  for lane in 0 ..< RateBytes div 8:
    for byte in 0 ..< 8:
      state[lane] = state[lane] or (uint64(paddedBlock[lane * 8 + byte]) shl (8 * byte))
  keccakF1600(state)
  result[0] = state[0]
  result[1] = state[1]
  result[2] = state[2]
  result[3] = state[3]

proc string_hash_equality*(input: ptr UncheckedArray[int64], length: csize_t): int64
    {.cdecl, exportc: "string_hash_equality".} =
  if input.isNil or length < 2 or length > csize_t(MaxParseableInputLength): return -1
  if input[0] < 0 or input[0] > MaxBytes or input[1] < 0 or input[1] > MaxBytes: return -1
  let lengthA = int(input[0]); let lengthB = int(input[1])
  if int(length) != 2 + lengthA + lengthB: return -1
  for i in 0 ..< lengthA + lengthB:
    if input[2 + i] < 0 or input[2 + i] > 255: return -1
  let digestA = keccak256Bytes(input, 2, lengthA)
  let digestB = keccak256Bytes(input, 2 + lengthA, lengthB)
  for lane in 0 ..< 4:
    if digestA[lane] != digestB[lane]: return 0
  1
