## Compute an MD5 digest over a bounded byte array with RFC 1321 padding.
const Md5Shifts: array[64, uint32] = [
  7'u32,12,17,22,7,12,17,22,7,12,17,22,7,12,17,22,
  5,9,14,20,5,9,14,20,5,9,14,20,5,9,14,20,
  4,11,16,23,4,11,16,23,4,11,16,23,4,11,16,23,
  6,10,15,21,6,10,15,21,6,10,15,21,6,10,15,21]
const Md5K: array[64, uint32] = [
  0xd76aa478'u32,0xe8c7b756,0x242070db,0xc1bdceee,0xf57c0faf,0x4787c62a,0xa8304613,0xfd469501,
  0x698098d8,0x8b44f7af,0xffff5bb1,0x895cd7be,0x6b901122,0xfd987193,0xa679438e,0x49b40821,
  0xf61e2562,0xc040b340,0x265e5a51,0xe9b6c7aa,0xd62f105d,0x02441453,0xd8a1e681,0xe7d3fbc8,
  0x21e1cde6,0xc33707d6,0xf4d50d87,0x455a14ed,0xa9e3e905,0xfcefa3f8,0x676f02d9,0x8d2a4c8a,
  0xfffa3942,0x8771f681,0x6d9d6122,0xfde5380c,0xa4beea44,0x4bdecfa9,0xf6bb4b60,0xbebfbc70,
  0x289b7ec6,0xeaa127fa,0xd4ef3085,0x04881d05,0xd9d4d039,0xe6db99e5,0x1fa27cf8,0xc4ac5665,
  0xf4292244,0x432aff97,0xab9423a7,0xfc93a039,0x655b59c3,0x8f0ccc92,0xffeff47d,0x85845dd1,
  0x6fa87e4f,0xfe2ce6e0,0xa3014314,0x4e0811a1,0xf7537e82,0xbd3af235,0x2ad7d2bb,0xeb86d391]

proc md5Add(left, right: uint32): uint32 =
  uint32((uint64(left) + uint64(right)) and 0xffff_ffff'u64)

proc md5RotateLeft(value: uint32, amount: int): uint32 =
  (value shl amount) or (value shr (32 - amount))

proc md5Byte(input: ptr UncheckedArray[int64], length, paddedLength: int,
             bitLength: uint64, position: int): uint32 =
  if position < length: return uint32(input[position])
  if position == length: return 0x80'u32
  if position >= paddedLength - 8:
    return uint32((bitLength shr (8 * (position - (paddedLength - 8)))) and 0xff'u64)
  0'u32

proc md5Word(input: ptr UncheckedArray[int64], length, paddedLength: int,
             bitLength: uint64, blockOffset, wordIndex: int): uint32 =
  var word = 0'u32
  let start = blockOffset + wordIndex * 4
  for byte in 0 ..< 4:
    word = word or (md5Byte(input, length, paddedLength, bitLength, start + byte) shl (8 * byte))
  word

proc md5*(input: ptr UncheckedArray[int64], length: csize_t,
          output: ptr UncheckedArray[uint8], outputCapacity: csize_t): int64
          {.cdecl, exportc: "md5".} =
  if length > 4096 or (length > 0 and input == nil): return -1
  let count = int(length)
  for index in 0 ..< count:
    if input[index] < 0 or input[index] > 255: return -1
  if output == nil or outputCapacity < 16: return -2

  let paddedLength = ((count + 8) div 64 + 1) * 64
  let bitLength = uint64(count) * 8'u64
  var h0 = 0x67452301'u32
  var h1 = 0xefcdab89'u32
  var h2 = 0x98badcfe'u32
  var h3 = 0x10325476'u32
  for offset in countup(0, paddedLength - 64, 64):
    var words: array[16, uint32]
    for index in 0 ..< 16:
      words[index] = md5Word(input, count, paddedLength, bitLength, offset, index)
    var a = h0
    var b = h1
    var c = h2
    var d = h3
    for index in 0 ..< 64:
      var f, g: uint32
      if index < 16:
        f = (b and c) or ((not b) and d)
        g = uint32(index)
      elif index < 32:
        f = (d and b) or ((not d) and c)
        g = uint32((5 * index + 1) mod 16)
      elif index < 48:
        f = b xor c xor d
        g = uint32((3 * index + 5) mod 16)
      else:
        f = c xor (b or (not d))
        g = uint32((7 * index) mod 16)
      let total = md5Add(md5Add(md5Add(a, f), Md5K[index]), words[int(g)])
      let previousD = d
      d = c
      c = b
      b = md5Add(b, md5RotateLeft(total, int(Md5Shifts[index])))
      a = previousD
    h0 = md5Add(h0, a)
    h1 = md5Add(h1, b)
    h2 = md5Add(h2, c)
    h3 = md5Add(h3, d)
  let state = [h0, h1, h2, h3]
  for word in 0 ..< 4:
    for byte in 0 ..< 4:
      output[word * 4 + byte] = uint8((state[word] shr (8 * byte)) and 0xff'u32)
  16
