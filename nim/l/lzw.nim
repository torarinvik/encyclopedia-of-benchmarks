const MaxItems = 4096
const MaxCodes = 4352
const MaxOutput = 65536
const FnvOffset = 14695981039346656037'u64
const FnvPrime = 1099511628211'u64

proc hashI64(hashValue: var uint64, value: int64) =
  let bits = cast[uint64](value)
  for shift in countup(0, 56, 8):
    hashValue = (hashValue xor uint64(uint8(bits shr shift))) *% FnvPrime

proc hashRecord(mode: int64, values: openArray[int64]): int64 =
  var hashValue = FnvOffset
  hashI64(hashValue, mode)
  hashI64(hashValue, int64(values.len))
  for value in values: hashI64(hashValue, value)
  int64(hashValue and 0x7fff_ffff_ffff_ffff'u64)

proc hashEmptyRecord(mode: int64): int64 =
  var hashValue = FnvOffset
  hashI64(hashValue, mode)
  hashI64(hashValue, 0)
  int64(hashValue and 0x7fff_ffff_ffff_ffff'u64)

proc expandCode(code, dictionarySize: int, prefix: openArray[int32],
                suffix: openArray[uint8], phrase: var array[MaxCodes, uint8]): int =
  var length = 0
  var current = code
  while current >= 256:
    if current >= dictionarySize or length >= MaxCodes: return -1
    phrase[length] = suffix[current]
    inc length
    if prefix[current] < 0: return -1
    current = int(prefix[current])
  if current < 0 or current > 255 or length >= MaxCodes: return -1
  phrase[length] = uint8(current)
  inc length
  var left = 0
  var right = length - 1
  while left < right:
    swap(phrase[left], phrase[right])
    inc left
    dec right
  length

proc lzw*(input: ptr UncheckedArray[int64], length: csize_t): int64 {.cdecl, exportc: "lzw".} =
  if input.isNil or length < 2 or length > csize_t(MaxItems + 2): return -1
  let mode = input[0]
  let count64 = input[1]
  if (mode != 0 and mode != 1) or count64 < 0 or count64 > MaxItems or length != csize_t(count64 + 2): return -1
  let count = int(count64)

  var prefix: array[MaxCodes, int32]
  var nextSibling: array[MaxCodes, int32]
  var firstChild: array[MaxCodes, int32]
  var suffix: array[MaxCodes, uint8]
  var firstSymbol: array[MaxCodes, uint8]
  for i in 0 ..< MaxCodes:
    prefix[i] = -1
    nextSibling[i] = -1
    firstChild[i] = -1
  for code in 0 ..< 256:
    suffix[code] = uint8(code)
    firstSymbol[code] = uint8(code)

  if mode == 0:
    for i in 0 ..< count:
      if input[2 + i] < 0 or input[2 + i] > 127: return -1
    var codes: array[MaxItems, int64]
    var codeCount = 0
    if count > 0:
      var dictionarySize = 256
      var current = int(input[2])
      for i in 1 ..< count:
        let byte = uint8(input[2 + i])
        var match = firstChild[current]
        while match >= 0 and suffix[int(match)] != byte:
          match = nextSibling[int(match)]
        if match >= 0:
          current = int(match)
        else:
          codes[codeCount] = int64(current)
          inc codeCount
          if dictionarySize >= MaxCodes: return -1
          prefix[dictionarySize] = int32(current)
          suffix[dictionarySize] = byte
          firstSymbol[dictionarySize] = firstSymbol[current]
          nextSibling[dictionarySize] = firstChild[current]
          firstChild[current] = int32(dictionarySize)
          inc dictionarySize
          current = int(byte)
      codes[codeCount] = int64(current)
      inc codeCount
    if codeCount == 0: return hashEmptyRecord(0)
    return hashRecord(0, codes.toOpenArray(0, codeCount - 1))

  for i in 0 ..< count:
    if input[2 + i] < 0 or input[2 + i] >= MaxCodes: return -1
  if count == 0: return hashEmptyRecord(1)
  let firstCode = int(input[2])
  if firstCode > 127: return -1
  var decoded: array[MaxOutput, uint8]
  var phrase: array[MaxCodes, uint8]
  decoded[0] = uint8(firstCode)
  var decodedLength = 1
  var dictionarySize = 256
  var previous = firstCode
  for i in 1 ..< count:
    let code = int(input[2 + i])
    var phraseLength: int
    if code < dictionarySize:
      phraseLength = expandCode(code, dictionarySize, prefix, suffix, phrase)
      if phraseLength < 0: return -1
    elif code == dictionarySize:
      phraseLength = expandCode(previous, dictionarySize, prefix, suffix, phrase)
      if phraseLength < 0 or phraseLength >= MaxCodes: return -1
      phrase[phraseLength] = firstSymbol[previous]
      inc phraseLength
    else:
      return -1
    if decodedLength > MaxOutput - phraseLength: return -1
    for j in 0 ..< phraseLength:
      if phrase[j] > 127: return -1
      decoded[decodedLength + j] = phrase[j]
    decodedLength += phraseLength
    if dictionarySize >= MaxCodes: return -1
    let nextByte = if code == dictionarySize: firstSymbol[previous] else: firstSymbol[code]
    prefix[dictionarySize] = int32(previous)
    suffix[dictionarySize] = nextByte
    firstSymbol[dictionarySize] = firstSymbol[previous]
    inc dictionarySize
    previous = code
  var hashValue = FnvOffset
  hashI64(hashValue, 1)
  hashI64(hashValue, int64(decodedLength))
  for i in 0 ..< decodedLength: hashI64(hashValue, int64(decoded[i]))
  int64(hashValue and 0x7fff_ffff_ffff_ffff'u64)
