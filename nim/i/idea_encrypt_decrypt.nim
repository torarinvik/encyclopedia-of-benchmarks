proc multiply(left, right: uint16): uint16 =
  let a = if left == 0: 65536'u64 else: uint64(left)
  let b = if right == 0: 65536'u64 else: uint64(right)
  let residue = (a * b) mod 65537'u64
  if residue == 65536'u64: 0'u16 else: uint16(residue)

proc inverse(value: uint16): uint16 =
  var oldR = 65537'i64
  var r = if value == 0: 65536'i64 else: int64(value)
  var oldS = 0'i64
  var s = 1'i64
  while r != 0:
    let quotient = oldR div r
    let nextR = oldR - quotient * r
    let nextS = oldS - quotient * s
    oldR = r; r = nextR; oldS = s; s = nextS
  var residue = oldS mod 65537
  if residue < 0: residue += 65537
  if residue == 65536: 0'u16 else: uint16(residue)

proc expandKey(key: array[8, uint16]): array[52, uint16] =
  var state = key
  var expanded: array[52, uint16]
  var offset = 0
  while offset < 52:
    let amount = min(8, 52 - offset)
    for i in 0..<amount: expanded[offset + i] = state[i]
    var rotated: array[8, uint16]
    for i in 0..<8:
      rotated[i] = uint16((uint32(state[(i + 1) and 7]) shl 9) or (uint32(state[(i + 2) and 7]) shr 7))
    state = rotated
    offset += amount
  expanded

proc encrypt(key: array[52, uint16], plainWords: array[4, uint16]): array[4, uint16] =
  var x1 = plainWords[0]; var x2 = plainWords[1]; var x3 = plainWords[2]; var x4 = plainWords[3]
  for round in 0..<8:
    let k = round * 6
    let a = multiply(x1, key[k])
    let b = uint16((uint32(x2) + uint32(key[k + 1])) and 65535)
    let c = uint16((uint32(x3) + uint32(key[k + 2])) and 65535)
    let d = multiply(x4, key[k + 3])
    let p = multiply(a xor c, key[k + 4])
    let q = multiply(uint16((uint32(b xor d) + uint32(p)) and 65535), key[k + 5])
    let r = uint16((uint32(p) + uint32(q)) and 65535)
    x1 = a xor q; x2 = c xor q; x3 = b xor r; x4 = d xor r
  [multiply(x1, key[48]), uint16((uint32(x3) + uint32(key[49])) and 65535),
   uint16((uint32(x2) + uint32(key[50])) and 65535), multiply(x4, key[51])]

proc decrypt(key: array[52, uint16], cipher: array[4, uint16]): array[4, uint16] =
  var x1 = multiply(cipher[0], inverse(key[48]))
  var x2 = uint16((int32(cipher[2]) + 65536 - int32(key[50])) mod 65536)
  var x3 = uint16((int32(cipher[1]) + 65536 - int32(key[49])) mod 65536)
  var x4 = multiply(cipher[3], inverse(key[51]))
  for step in countdown(7, 0):
    let k = step * 6
    let p = multiply(x1 xor x2, key[k + 4])
    let q = multiply(uint16((uint32(x3 xor x4) + uint32(p)) and 65535), key[k + 5])
    let r = uint16((uint32(p) + uint32(q)) and 65535)
    let a = x1 xor q; let c = x2 xor q; let b = x3 xor r; let d = x4 xor r
    x1 = multiply(a, inverse(key[k]))
    x2 = uint16((int32(b) + 65536 - int32(key[k + 1])) mod 65536)
    x3 = uint16((int32(c) + 65536 - int32(key[k + 2])) mod 65536)
    x4 = multiply(d, inverse(key[k + 3]))
  [x1, x2, x3, x4]

proc idea_encrypt_decrypt*(input: ptr UncheckedArray[int64], length: csize_t,
    output: ptr UncheckedArray[uint8], capacity: csize_t): int64
    {.cdecl, exportc: "idea_encrypt_decrypt".} =
  if input.isNil or length != 12: return -1
  var keyWords: array[8, uint16]
  var plainWords: array[4, uint16]
  for i in 0..<12:
    if input[i] < 0 or input[i] > 65535: return -1
    if i < 8: keyWords[i] = uint16(input[i])
    else: plainWords[i - 8] = uint16(input[i])
  if output.isNil or capacity < 16: return -2
  let subkeys = expandKey(keyWords)
  let encrypted = encrypt(subkeys, plainWords)
  let recovered = decrypt(subkeys, encrypted)
  for i in 0..<4:
    output[i * 2] = uint8(encrypted[i] mod 256)
    output[i * 2 + 1] = uint8(encrypted[i] div 256)
    output[8 + i * 2] = uint8(recovered[i] mod 256)
    output[9 + i * 2] = uint8(recovered[i] div 256)
  16
