const MaxMessageLength = 64
const MaxInputLength = 98
const LimbMask = 0x3ffffff'u64

template load32Le(bytes: untyped, offset: int): uint64 =
  uint64(bytes[offset]) or (uint64(bytes[offset + 1]) shl 8) or
  (uint64(bytes[offset + 2]) shl 16) or (uint64(bytes[offset + 3]) shl 24)

template store32Le(output: untyped, offset: int, value: uint32) =
  for byte in 0 ..< 4: output[offset + byte] = uint8(value shr (8 * byte))

proc poly1305Tag(key: var array[32, uint8], message: var array[MaxMessageLength, uint8],
    messageLength: int): array[16, uint8] =
  let r0 = load32Le(key, 0) and 0x3ffffff'u64
  let r1 = (load32Le(key, 3) shr 2) and 0x3ffff03'u64
  let r2 = (load32Le(key, 6) shr 4) and 0x3ffc0ff'u64
  let r3 = (load32Le(key, 9) shr 6) and 0x3f03fff'u64
  let r4 = (load32Le(key, 12) shr 8) and 0x00fffff'u64
  let s1 = r1 * 5; let s2 = r2 * 5; let s3 = r3 * 5; let s4 = r4 * 5
  var h0 = 0'u64; var h1 = 0'u64; var h2 = 0'u64; var h3 = 0'u64; var h4 = 0'u64
  var offset = 0
  while offset < messageLength:
    var block: array[16, uint8]
    let blockLength = min(16, messageLength - offset)
    for i in 0 ..< blockLength: block[i] = message[offset + i]
    var highBit = 1'u64 shl 24
    if blockLength < 16: block[blockLength] = 1; highBit = 0
    h0 += load32Le(block, 0) and LimbMask
    h1 += (load32Le(block, 3) shr 2) and LimbMask
    h2 += (load32Le(block, 6) shr 4) and LimbMask
    h3 += (load32Le(block, 9) shr 6) and LimbMask
    h4 += (load32Le(block, 12) shr 8) or highBit
    let d0 = h0 * r0 + h1 * s4 + h2 * s3 + h3 * s2 + h4 * s1
    let d1 = h0 * r1 + h1 * r0 + h2 * s4 + h3 * s3 + h4 * s2
    let d2 = h0 * r2 + h1 * r1 + h2 * r0 + h3 * s4 + h4 * s3
    let d3 = h0 * r3 + h1 * r2 + h2 * r1 + h3 * r0 + h4 * s4
    let d4 = h0 * r4 + h1 * r3 + h2 * r2 + h3 * r1 + h4 * r0
    var carry = d0 shr 26; h0 = d0 and LimbMask
    let q1 = d1 + carry; carry = q1 shr 26; h1 = q1 and LimbMask
    let q2 = d2 + carry; carry = q2 shr 26; h2 = q2 and LimbMask
    let q3 = d3 + carry; carry = q3 shr 26; h3 = q3 and LimbMask
    let q4 = d4 + carry; carry = q4 shr 26; h4 = q4 and LimbMask
    h0 += carry * 5
    carry = h0 shr 26; h0 = h0 and LimbMask; h1 += carry
    offset += blockLength
  for pass in 0 ..< 3:
    var carry = h0 shr 26; h0 = h0 and LimbMask; h1 += carry
    carry = h1 shr 26; h1 = h1 and LimbMask; h2 += carry
    carry = h2 shr 26; h2 = h2 and LimbMask; h3 += carry
    carry = h3 shr 26; h3 = h3 and LimbMask; h4 += carry
    carry = h4 shr 26; h4 = h4 and LimbMask; h0 += carry * 5
    carry = h0 shr 26; h0 = h0 and LimbMask; h1 += carry
  if h4 == LimbMask and h3 == LimbMask and h2 == LimbMask and h1 == LimbMask and h0 >= LimbMask - 4:
    h0 -= LimbMask - 4; h1 = 0; h2 = 0; h3 = 0; h4 = 0
  let f0 = ((h0 or (h1 shl 26)) and 0xffffffff'u64) + load32Le(key, 16)
  let f1 = ((h1 shr 6 or (h2 shl 20)) and 0xffffffff'u64) + load32Le(key, 20) + (f0 shr 32)
  let f2 = ((h2 shr 12 or (h3 shl 14)) and 0xffffffff'u64) + load32Le(key, 24) + (f1 shr 32)
  let f3 = ((h3 shr 18 or (h4 shl 8)) and 0xffffffff'u64) + load32Le(key, 28) + (f2 shr 32)
  var tag: array[16, uint8]
  store32Le(tag, 0, uint32(f0)); store32Le(tag, 4, uint32(f1))
  store32Le(tag, 8, uint32(f2)); store32Le(tag, 12, uint32(f3))
  tag

proc poly1305*(input: ptr UncheckedArray[int64], length: csize_t,
    output: ptr UncheckedArray[uint8], outputCapacity: csize_t): int64 {.cdecl, exportc: "poly1305".} =
  if input.isNil or length < 33 or length > csize_t(MaxInputLength): return -1
  let rawLength = input[0]
  if rawLength < 0 or rawLength > MaxMessageLength or int(length) != 33 + int(rawLength): return -1
  for i in 1 ..< int(length):
    if input[i] < 0 or input[i] > 255: return -1
  if output.isNil or outputCapacity < 16: return -2
  var key: array[32, uint8]
  var message: array[MaxMessageLength, uint8]
  for i in 0 ..< 32: key[i] = uint8(input[i + 1])
  for i in 0 ..< int(rawLength): message[i] = uint8(input[33 + i])
  var tag = poly1305Tag(key, message, int(rawLength))
  for i in 0 ..< 16: output[i] = tag[i]
  16
