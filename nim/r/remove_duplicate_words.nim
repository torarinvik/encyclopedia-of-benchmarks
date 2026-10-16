const MaxInputLength = 4096
const MaxWords = 2049

proc isAsciiWhitespace(byte: int64): bool =
  byte == 32 or (byte >= 9 and byte <= 13)

proc remove_duplicate_words*(values: ptr UncheckedArray[int64], length: csize_t,
                             output: ptr UncheckedArray[uint8], outputCapacity: csize_t): int64
    {.cdecl, exportc: "remove_duplicate_words".} =
  if values.isNil or length < 1 or values[0] < 0 or values[0] > MaxInputLength: return -1
  let textLength = int(values[0])
  if length != csize_t(textLength + 1): return -1
  for index in 0 ..< textLength:
    if values[index + 1] < 0 or values[index + 1] > 127: return -1

  var starts: array[MaxWords, int]
  var wordLengths: array[MaxWords, int]
  var wordCount = 0
  var tokenStart = 0
  var outputLength = 0
  var boundary = 0
  while boundary <= textLength:
    if boundary < textLength and not isAsciiWhitespace(values[boundary + 1]):
      inc boundary
      continue
    let wordLength = boundary - tokenStart
    var duplicate = false
    for previous in 0 ..< wordCount:
      if wordLengths[previous] != wordLength: continue
      var offset = 0
      while offset < wordLength and values[1 + starts[previous] + offset] == values[1 + tokenStart + offset]:
        inc offset
      if offset == wordLength:
        duplicate = true
        break
    if not duplicate:
      if wordCount == MaxWords: return -1
      starts[wordCount] = tokenStart
      wordLengths[wordCount] = wordLength
      if wordCount > 0: inc outputLength
      outputLength += wordLength
      inc wordCount
    if boundary < textLength: tokenStart = boundary + 1
    inc boundary
  if csize_t(outputLength) > outputCapacity or (outputLength > 0 and output.isNil): return -2

  var written = 0
  for word in 0 ..< wordCount:
    if word > 0:
      output[written] = uint8(32)
      inc written
    for offset in 0 ..< wordLengths[word]:
      output[written] = uint8(values[1 + starts[word] + offset])
      inc written
  int64(written)
