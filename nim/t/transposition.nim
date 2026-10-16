const MaxKey = 32
const MaxText = 512
const MaxInput = 3 + MaxKey + MaxText
const MaxPadded = MaxText + MaxKey

proc asciiLetter(value: int64): bool =
  (value >= ord('A').int64 and value <= ord('Z').int64) or
    (value >= ord('a').int64 and value <= ord('z').int64)

proc hashOutput(text: array[MaxPadded, uint8], length: int): int64 =
  var hash = 14_695_981_039_346_656_037'u64
  template feed(value: uint8) =
    hash = (hash xor uint64(value)) *% 1_099_511_628_211'u64
  let size = uint64(length)
  for byteIndex in 0 ..< 8:
    feed(uint8((size shr (byteIndex * 8)) and 255'u64))
  for index in 0 ..< length:
    let codepoint = uint32(text[index])
    for byteIndex in 0 ..< 4:
      feed(uint8((codepoint shr (byteIndex * 8)) and 255'u32))
  int64(hash and 0x7FFF_FFFF_FFFF_FFFF'u64)

proc transposition*(input: ptr UncheckedArray[int64], length: csize_t): int64
    {.cdecl, exportc: "transposition".} =
  if input.isNil or length < 4 or length > csize_t(MaxInput): return -1
  let mode = input[0]
  let keyLengthValue = input[1]
  if (mode != 0 and mode != 1) or keyLengthValue < 1 or keyLengthValue > MaxKey: return -1
  let keyLength = int(keyLengthValue)
  let textLengthIndex = 2 + keyLength
  if length <= csize_t(textLengthIndex): return -1
  let textLengthValue = input[textLengthIndex]
  if textLengthValue < 1 or textLengthValue > MaxText: return -1
  let textLength = int(textLengthValue)
  if length != csize_t(textLengthIndex + 1 + textLength): return -1

  var key, sorted: array[MaxKey, uint8]
  for index in 0 ..< keyLength:
    let value = input[2 + index]
    if not asciiLetter(value): return -1
    var ch = uint8(value)
    if ch >= uint8(ord('A')) and ch <= uint8(ord('Z')): ch += uint8(ord('a') - ord('A'))
    key[index] = ch
    sorted[index] = ch
  for index in 1 ..< keyLength:
    let value = sorted[index]
    var cursor = index
    while cursor > 0 and sorted[cursor - 1] > value:
      sorted[cursor] = sorted[cursor - 1]
      dec cursor
    sorted[cursor] = value
  var ranks: array[MaxKey, int]
  for index in 0 ..< keyLength:
    var first = 0
    var duplicate = 0
    while first < keyLength and sorted[first] != key[index]: inc first
    for prior in 0 ..< index:
      if key[prior] == key[index]: inc duplicate
    ranks[index] = first + duplicate + 1

  var text, result: array[MaxPadded, uint8]
  for index in 0 ..< textLength:
    let value = input[textLengthIndex + 1 + index]
    if value < 32 or value > 126: return -1
    text[index] = uint8(value)
  if mode == 0 and text[textLength - 1] == uint8(ord(' ')): return -1
  let padding = keyLength - textLength mod keyLength
  let paddedLength = textLength + padding
  for index in textLength ..< paddedLength: text[index] = uint8(ord(' '))

  var resultLength = 0
  if mode == 0:
    var start = 0
    while start < paddedLength:
      var block: array[MaxKey, uint8]
      for offset in 0 ..< keyLength: block[ranks[offset] - 1] = text[start + offset]
      for offset in 0 ..< keyLength:
        result[resultLength] = block[offset]
        inc resultLength
      start += keyLength
  else:
    var start = 0
    while start < textLength:
      for offset in 0 ..< keyLength:
        result[resultLength] = text[start + ranks[offset] - 1]
        inc resultLength
      start += keyLength
    while resultLength > 0 and result[resultLength - 1] == uint8(ord(' ')): dec resultLength
  hashOutput(result, resultLength)
