const InputBytes = 48

proc gfMul(a0, b0: uint8): uint8 =
  var a = a0
  var b = b0
  var result: uint8 = 0
  while b != 0:
    if (b and 1) != 0: result = result xor a
    a = uint8((uint16(a) shl 1) xor (if (a and 0x80) != 0: 0x1b'u16 else: 0'u16))
    b = b shr 1
  result

proc gfPow(a0: uint8, n0: uint32): uint8 =
  var a = a0
  var n = n0
  var result: uint8 = 1
  while n != 0:
    if (n and 1) != 0: result = gfMul(result, a)
    a = gfMul(a, a)
    n = n shr 1
  result

proc decryptBlock(key: array[32, uint8], input: array[16, uint8]): array[16, uint8] =
  var sbox, inverse: array[256, uint8]
  for x in 0 ..< 256:
    let q = if x == 0: 0'u8 else: gfPow(uint8(x), 254)
    sbox[x] = q xor uint8(((uint16(q) shl 1) or (uint16(q) shr 7)) and 255) xor
      uint8(((uint16(q) shl 2) or (uint16(q) shr 6)) and 255) xor
      uint8(((uint16(q) shl 3) or (uint16(q) shr 5)) and 255) xor
      uint8(((uint16(q) shl 4) or (uint16(q) shr 4)) and 255) xor 0x63'u8
  for x in 0 ..< 256: inverse[sbox[x]] = uint8(x)
  let roundConstants = [1'u8, 2, 4, 8, 16, 32, 64]
  var roundKeys: array[240, uint8]
  for i in 0 ..< 32: roundKeys[i] = key[i]
  var written = 32
  while written < 240:
    let word = written div 4
    var temp = [roundKeys[written-4], roundKeys[written-3], roundKeys[written-2], roundKeys[written-1]]
    if word mod 8 == 0:
      let first = temp[0]
      temp[0] = sbox[temp[1]] xor roundConstants[word div 8 - 1]
      temp[1] = sbox[temp[2]]
      temp[2] = sbox[temp[3]]
      temp[3] = sbox[first]
    elif word mod 8 == 4:
      for j in 0 ..< 4: temp[j] = sbox[temp[j]]
    for j in 0 ..< 4:
      roundKeys[written] = roundKeys[written-32] xor temp[j]
      inc written
  var state = input
  for i in 0 ..< 16: state[i] = state[i] xor roundKeys[224+i]
  for round in countdown(13, 1):
    let previous = state
    for col in 0 ..< 4:
      for row in 0 ..< 4: state[row+4*col] = inverse[previous[row+4*((col+4-row) mod 4)]]
    for i in 0 ..< 16: state[i] = state[i] xor roundKeys[round*16+i]
    for col in 0 ..< 4:
      let offset = 4*col
      let a = state[offset]
      let b = state[offset+1]
      let c = state[offset+2]
      let d = state[offset+3]
      state[offset] = gfMul(a,14) xor gfMul(b,11) xor gfMul(c,13) xor gfMul(d,9)
      state[offset+1] = gfMul(a,9) xor gfMul(b,14) xor gfMul(c,11) xor gfMul(d,13)
      state[offset+2] = gfMul(a,13) xor gfMul(b,9) xor gfMul(c,14) xor gfMul(d,11)
      state[offset+3] = gfMul(a,11) xor gfMul(b,13) xor gfMul(c,9) xor gfMul(d,14)
  let previous = state
  for col in 0 ..< 4:
    for row in 0 ..< 4: state[row+4*col] = inverse[previous[row+4*((col+4-row) mod 4)]]
  for i in 0 ..< 16: state[i] = state[i] xor roundKeys[i]
  state

proc cbench_security_rijndael_decrypt*(values: ptr UncheckedArray[int64], length: csize_t,
    output: ptr UncheckedArray[uint8], capacity: csize_t): int64
    {.cdecl, exportc: "cbench_security_rijndael_decrypt".} =
  if values.isNil or length != InputBytes.csize_t: return -1
  for i in 0 ..< InputBytes:
    if values[i] < 0 or values[i] > 255: return -1
  if output.isNil or capacity < 16: return -2
  var key: array[32, uint8]
  var block: array[16, uint8]
  for i in 0 ..< 32: key[i] = uint8(values[i])
  for i in 0 ..< 16: block[i] = uint8(values[32+i])
  let plain = decryptBlock(key, block)
  for i in 0 ..< 16: output[i] = plain[i]
  16
