const KeyBytes = 32
const BlockBytes = 16
const InputBytes = 48

proc gfMul(leftValue, rightValue: uint8): uint8 =
  var left = leftValue
  var right = rightValue
  var result: uint8 = 0
  while right != 0:
    if (right and 1) != 0: result = result xor left
    left = uint8((uint16(left) shl 1) xor (if (left and 0x80) != 0: 0x1b'u16 else: 0'u16))
    right = right shr 1
  result

proc gfPow(valueValue: uint8, exponentValue: uint32): uint8 =
  var value = valueValue
  var exponent = exponentValue
  var result: uint8 = 1
  while exponent != 0:
    if (exponent and 1) != 0: result = gfMul(result, value)
    value = gfMul(value, value)
    exponent = exponent shr 1
  result

proc rotl8(value: uint8, amount: int): uint8 =
  uint8((uint16(value) shl amount) or (uint16(value) shr (8 - amount)))

proc makeSbox(): array[256, uint8] =
  var sbox: array[256, uint8]
  for value in 0 ..< 256:
    let inverse = if value == 0: 0'u8 else: gfPow(uint8(value), 254)
    sbox[value] = inverse xor rotl8(inverse, 1) xor rotl8(inverse, 2) xor
      rotl8(inverse, 3) xor rotl8(inverse, 4) xor 0x63'u8
  sbox

proc encryptBlock(key: array[KeyBytes, uint8], block: array[BlockBytes, uint8]): array[BlockBytes, uint8] =
  let sbox = makeSbox()
  let roundConstants = [1'u8, 2, 4, 8, 16, 32, 64]
  var roundKeys: array[240, uint8]
  for index in 0 ..< KeyBytes: roundKeys[index] = key[index]
  var written = KeyBytes
  while written < roundKeys.len:
    let word = written div 4
    var temporary: array[4, uint8]
    for index in 0 ..< 4: temporary[index] = roundKeys[written - 4 + index]
    if word mod 8 == 0:
      let first = temporary[0]
      temporary[0] = sbox[temporary[1]] xor roundConstants[word div 8 - 1]
      temporary[1] = sbox[temporary[2]]
      temporary[2] = sbox[temporary[3]]
      temporary[3] = sbox[first]
    elif word mod 8 == 4:
      for index in 0 ..< 4: temporary[index] = sbox[temporary[index]]
    for index in 0 ..< 4:
      roundKeys[written] = roundKeys[written - KeyBytes] xor temporary[index]
      inc written

  var state = block
  for index in 0 ..< BlockBytes: state[index] = state[index] xor roundKeys[index]
  for round in 1 ..< 14:
    for index in 0 ..< BlockBytes: state[index] = sbox[state[index]]
    let previous = state
    for column in 0 ..< 4:
      for row in 0 ..< 4:
        state[row + 4 * column] = previous[row + 4 * ((column + row) mod 4)]
    for column in 0 ..< 4:
      let offset = 4 * column
      let a = state[offset]
      let b = state[offset + 1]
      let c = state[offset + 2]
      let d = state[offset + 3]
      let total = a xor b xor c xor d
      state[offset] = a xor total xor gfMul(a xor b, 2)
      state[offset + 1] = b xor total xor gfMul(b xor c, 2)
      state[offset + 2] = c xor total xor gfMul(c xor d, 2)
      state[offset + 3] = d xor total xor gfMul(d xor a, 2)
    let keyOffset = round * BlockBytes
    for index in 0 ..< BlockBytes: state[index] = state[index] xor roundKeys[keyOffset + index]
  for index in 0 ..< BlockBytes: state[index] = sbox[state[index]]
  let previous = state
  for column in 0 ..< 4:
    for row in 0 ..< 4:
      state[row + 4 * column] = previous[row + 4 * ((column + row) mod 4)]
  for index in 0 ..< BlockBytes: state[index] = state[index] xor roundKeys[224 + index]
  state

proc mibench_security_rijndael*(input: ptr UncheckedArray[int64], inputLength: csize_t,
    output: ptr UncheckedArray[uint8], outputCapacity: csize_t): int64
    {.cdecl, exportc: "mibench_security_rijndael".} =
  if input.isNil or inputLength != InputBytes.csize_t: return -1
  for index in 0 ..< InputBytes:
    if input[index] < 0 or input[index] > 255: return -1
  if output.isNil or outputCapacity < BlockBytes.csize_t: return -2
  var key: array[KeyBytes, uint8]
  var block: array[BlockBytes, uint8]
  for index in 0 ..< KeyBytes: key[index] = uint8(input[index])
  for index in 0 ..< BlockBytes: block[index] = uint8(input[KeyBytes + index])
  let ciphertext = encryptBlock(key, block)
  for index in 0 ..< BlockBytes: output[index] = ciphertext[index]
  BlockBytes.int64
