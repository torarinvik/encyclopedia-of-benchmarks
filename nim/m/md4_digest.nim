const Md4R1: array[4, int] = [3, 7, 11, 19]
const Md4R2: array[4, int] = [3, 5, 9, 13]
const Md4R3: array[4, int] = [3, 9, 11, 15]
const Md4Order3: array[16, int] = [0, 8, 4, 12, 2, 10, 6, 14, 1, 9, 5, 13, 3, 11, 7, 15]

proc md4Add(left, right: uint32): uint32 =
  uint32((uint64(left) + uint64(right)) and 0xffff_ffff'u64)
proc md4Rotl(value: uint32, amount: int): uint32 =
  (value shl amount) or (value shr (32 - amount))
proc md4F(x, y, z: uint32): uint32 = (x and y) or ((not x) and z)
proc md4G(x, y, z: uint32): uint32 = (x and y) or (x and z) or (y and z)
proc md4H(x, y, z: uint32): uint32 = x xor y xor z

proc md4Word(input: ptr UncheckedArray[int64], n, padded: int,
             bitLength: uint64, offset, wordIndex: int): uint32 =
  var result = 0'u32
  let first = offset + 4 * wordIndex
  for j in 0 ..< 4:
    let position = first + j
    var byte = 0'u32
    if position < n: byte = uint32(input[position + 1])
    elif position == n: byte = 0x80'u32
    elif position >= padded - 8:
      byte = uint32((bitLength shr (8 * (position - (padded - 8)))) and 255'u64)
    result = result or (byte shl (8 * j))
  result

proc md4_digest*(input: ptr UncheckedArray[int64], inputLength: csize_t,
                 output: ptr UncheckedArray[uint8], outputCapacity: csize_t): int64
                 {.cdecl, exportc: "md4_digest".} =
  if input == nil or inputLength < 1 or inputLength > 4098: return -1
  let signedCount = input[0]
  if signedCount < 0 or signedCount > 4096 or inputLength != csize_t(signedCount + 1): return -1
  let n = int(signedCount)
  for i in 0 ..< n:
    if input[i + 1] < 0 or input[i + 1] > 255: return -1
  if output == nil or outputCapacity < 16: return -2

  let padded = ((n + 8) div 64 + 1) * 64
  let bitLength = uint64(n) * 8'u64
  var h0 = 0x67452301'u32
  var h1 = 0xefcdab89'u32
  var h2 = 0x98badcfe'u32
  var h3 = 0x10325476'u32
  for offset in countup(0, padded - 64, 64):
    var words: array[16, uint32]
    for i in 0 ..< 16: words[i] = md4Word(input, n, padded, bitLength, offset, i)
    var a = h0
    var b = h1
    var c = h2
    var d = h3
    for step in 0 ..< 48:
      let round = step div 16
      let j = step mod 16
      var mix, word: uint32
      var shift: int
      var constant = 0'u32
      if round == 0:
        mix = md4F(b, c, d); word = uint32(j); shift = Md4R1[j mod 4]
      elif round == 1:
        mix = md4G(b, c, d); word = uint32((j mod 4) * 4 + j div 4)
        shift = Md4R2[j mod 4]; constant = 0x5a827999'u32
      else:
        mix = md4H(b, c, d); word = uint32(Md4Order3[j])
        shift = Md4R3[j mod 4]; constant = 0x6ed9eba1'u32
      let nextB = md4Add(b, md4Rotl(md4Add(md4Add(md4Add(a, mix), words[int(word)]), constant), shift))
      let priorD = d
      d = c; c = b; b = nextB; a = priorD
    h0 = md4Add(h0, a); h1 = md4Add(h1, b); h2 = md4Add(h2, c); h3 = md4Add(h3, d)
  let state = [h0, h1, h2, h3]
  for word in 0 ..< 4:
    for byte in 0 ..< 4:
      output[word * 4 + byte] = uint8((state[word] shr (8 * byte)) and 255'u32)
  16
