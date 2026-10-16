proc continuation(byte: uint8): bool = byte >= 0x80'u8 and byte <= 0xBF'u8

proc decodeUtf8(bytes: ptr UncheckedArray[uint8], length, index: int,
    codepoint: var uint32, width: var int): bool =
  let first = bytes[index]
  if first <= 0x7F'u8:
    codepoint = uint32(first); width = 1; return true
  if first >= 0xC2'u8 and first <= 0xDF'u8:
    if index + 1 >= length or not continuation(bytes[index + 1]): return false
    codepoint = (uint32(first and 0x1F'u8) shl 6) or uint32(bytes[index + 1] and 0x3F'u8)
    width = 2; return true
  if first >= 0xE0'u8 and first <= 0xEF'u8:
    if index + 2 >= length: return false
    let second = bytes[index + 1]
    let third = bytes[index + 2]
    if not continuation(second) or not continuation(third) or
        (first == 0xE0'u8 and second < 0xA0'u8) or
        (first == 0xED'u8 and second >= 0xA0'u8): return false
    codepoint = (uint32(first and 0x0F'u8) shl 12) or
        (uint32(second and 0x3F'u8) shl 6) or uint32(third and 0x3F'u8)
    width = 3; return true
  if first >= 0xF0'u8 and first <= 0xF4'u8:
    if index + 3 >= length: return false
    let second = bytes[index + 1]
    let third = bytes[index + 2]
    let fourth = bytes[index + 3]
    if not continuation(second) or not continuation(third) or not continuation(fourth) or
        (first == 0xF0'u8 and second < 0x90'u8) or
        (first == 0xF4'u8 and second > 0x8F'u8): return false
    codepoint = (uint32(first and 0x07'u8) shl 18) or
        (uint32(second and 0x3F'u8) shl 12) or
        (uint32(third and 0x3F'u8) shl 6) or uint32(fourth and 0x3F'u8)
    width = 4; return true
  false

proc mapTurkish(codepoint: uint32): uint8 =
  case codepoint
  of 0x0131'u32: uint8('i')
  of 0x0130'u32: uint8('I')
  of 0x00FC'u32: uint8('u')
  of 0x00DC'u32: uint8('U')
  of 0x00F6'u32: uint8('o')
  of 0x00D6'u32: uint8('O')
  of 0x015F'u32: uint8('s')
  of 0x015E'u32: uint8('S')
  of 0x00E7'u32: uint8('c')
  of 0x00C7'u32: uint8('C')
  of 0x011F'u32: uint8('g')
  of 0x011E'u32: uint8('G')
  else: 0'u8

proc turkish_to_latin_conversion*(input: ptr UncheckedArray[int64], length: csize_t,
    output: ptr UncheckedArray[uint8], outputCapacity: csize_t): int64
    {.cdecl, exportc: "turkish_to_latin_conversion".} =
  const MaxTextBytes = 1024
  if input == nil or length < 1 or length > MaxTextBytes + 1: return -1
  if input[0] < 0 or input[0] > MaxTextBytes or length != csize_t(input[0] + 1): return -1
  let textLength = int(input[0])
  var bytes: array[MaxTextBytes, uint8]
  for index in 0 ..< textLength:
    if input[index + 1] < 0 or input[index + 1] > 255: return -1
    bytes[index] = uint8(input[index + 1])

  var resultLength = 0
  var index = 0
  while index < textLength:
    var codepoint: uint32
    var width: int
    if not decodeUtf8(cast[ptr UncheckedArray[uint8]](addr bytes[0]), textLength, index, codepoint, width): return -1
    let mapped = mapTurkish(codepoint)
    resultLength += (if mapped != 0: 1 else: width)
    index += width
  if csize_t(resultLength) > outputCapacity or (resultLength > 0 and output == nil): return -2

  var written = 0
  index = 0
  while index < textLength:
    var codepoint: uint32
    var width: int
    discard decodeUtf8(cast[ptr UncheckedArray[uint8]](addr bytes[0]), textLength, index, codepoint, width)
    let mapped = mapTurkish(codepoint)
    if mapped != 0:
      output[written] = mapped
      inc written
    else:
      for byte in 0 ..< width: output[written + byte] = bytes[index + byte]
      written += width
    index += width
  int64(resultLength)
