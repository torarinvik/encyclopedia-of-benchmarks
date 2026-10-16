const MaxMessageBytes = 4096
const InitialStates: array[2, array[5, uint64]] = [
  [0xee9398aadb67f03d'u64, 0x8bb21831c60f1002'u64, 0xb48a92db98d5da62'u64,
   0x43189921b8f8e3e8'u64, 0x348fa5c9d525e140'u64],
  [0x01470194fc6528a6'u64, 0x738ec38ac0adffa7'u64, 0x2ec8e3296c76384c'u64,
   0xd6f6a54d7f52377d'u64, 0xa13c42a223be8d87'u64]
]

proc rotateRight(value: uint64, count: int): uint64 =
  (value shr count) or (value shl (64 - count))

proc permute(state: var array[5, uint64], rounds: int) =
  const Constants: array[12, uint64] = [0xf0'u64, 0xe1, 0xd2, 0xc3, 0xb4, 0xa5,
    0x96, 0x87, 0x78, 0x69, 0x5a, 0x4b]
  let first = if rounds == 12: 0 else: 4
  for round in first ..< 12:
    let x0 = state[0]; let x1 = state[1]; let x2 = state[2]
    let x3 = state[3]; let x4 = state[4]; let c = Constants[round]
    let t0 = x0 xor x1 xor x2 xor x3 xor c xor (x1 and (x0 xor x2 xor x4 xor c))
    let t1 = x0 xor x2 xor x3 xor x4 xor c xor ((x1 xor x2 xor c) and (x1 xor x3))
    let t2 = x1 xor x2 xor x4 xor c xor (x3 and x4)
    let t3 = x0 xor x1 xor x2 xor c xor ((not x0) and (x3 xor x4))
    let t4 = x1 xor x3 xor x4 xor ((x0 xor x4) and x1)
    state[0] = t0 xor rotateRight(t0, 19) xor rotateRight(t0, 28)
    state[1] = t1 xor rotateRight(t1, 39) xor rotateRight(t1, 61)
    state[2] = not (t2 xor rotateRight(t2, 1) xor rotateRight(t2, 6))
    state[3] = t3 xor rotateRight(t3, 10) xor rotateRight(t3, 17)
    state[4] = t4 xor rotateRight(t4, 7) xor rotateRight(t4, 41)

proc ascon_digest*(input: ptr UncheckedArray[int64], length: csize_t,
    output: ptr UncheckedArray[uint8], capacity: csize_t): int64 {.cdecl, exportc: "ascon_digest".} =
  if input.isNil or length < 2: return -1
  let variant = input[0]
  let messageLengthValue = input[1]
  if (variant != 0 and variant != 1) or messageLengthValue < 0 or
      messageLengthValue > int64(MaxMessageBytes) or length != csize_t(messageLengthValue + 2): return -1
  let messageLength = int(messageLengthValue)
  for index in 0 ..< messageLength:
    if input[index + 2] < 0 or input[index + 2] > 255: return -1

  var state = InitialStates[int(variant)]
  let rounds = if variant == 0: 12 else: 8
  let completeLength = messageLength - messageLength mod 8
  if completeLength > 0:
    for offset in countup(0, completeLength - 8, 8):
      var word = 0'u64
      for byte in 0 ..< 8: word = (word shl 8) or uint64(input[offset + byte + 2])
      state[0] = state[0] xor word
      permute(state, rounds)
  let tailLength = messageLength - completeLength
  var finalWord = 0x80'u64 shl (56 - tailLength * 8)
  for byte in 0 ..< tailLength:
    finalWord = finalWord or (uint64(input[completeLength + byte + 2]) shl (56 - byte * 8))
  state[0] = state[0] xor finalWord
  permute(state, 12)

  if output.isNil or capacity < 32: return -2
  for blockIndex in 0 ..< 4:
    for byte in 0 ..< 8:
      output[blockIndex * 8 + byte] = uint8(state[0] shr (56 - byte * 8))
    if blockIndex != 3: permute(state, rounds)
  32
