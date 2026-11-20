const MaxText = 64
const MaxWords = 16
const MaxWordLength = 8
const MaxParseableLength = 211

proc maximum_matching_word_segmentation*(input: ptr UncheckedArray[int64], length: csize_t,
    output: ptr UncheckedArray[uint8], capacity: csize_t): int64
    {.cdecl, exportc: "maximum_matching_word_segmentation".} =
  if input.isNil or length < 2 or length > csize_t(MaxParseableLength):
    return -1
  let textLengthValue = input[0]
  let wordCountValue = input[1]
  if textLengthValue < 0 or textLengthValue > MaxText or wordCountValue < 0 or wordCountValue > MaxWords:
    return -1
  let textLength = int(textLengthValue)
  let wordCount = int(wordCountValue)
  if int(length) < 2 + textLength:
    return -1
  for position in 0 ..< textLength:
    if input[position + 2] < 97 or input[position + 2] > 122:
      return -1

  var wordOffsets: array[MaxWords, int]
  var wordLengths: array[MaxWords, int]
  var cursor = 2 + textLength
  for word in 0 ..< wordCount:
    if cursor >= int(length):
      return -1
    let wordLengthValue = input[cursor]
    inc cursor
    if wordLengthValue < 1 or wordLengthValue > MaxWordLength:
      return -1
    let wordLength = int(wordLengthValue)
    if wordLength > int(length) - cursor:
      return -1
    wordOffsets[word] = cursor
    wordLengths[word] = wordLength
    for offset in 0 ..< wordLength:
      if input[cursor + offset] < 97 or input[cursor + offset] > 122:
        return -1
    cursor += wordLength
  if cursor != int(length):
    return -1

  var tokenIds: array[MaxText, uint8]
  var tokenCount = 0
  var position = 0
  while position < textLength:
    var bestLength = 0
    var bestId = 0'u8
    for word in 0 ..< wordCount:
      let candidateLength = wordLengths[word]
      if candidateLength <= bestLength or candidateLength > textLength - position:
        continue
      var offset = 0
      while offset < candidateLength and input[wordOffsets[word] + offset] == input[2 + position + offset]:
        inc offset
      if offset == candidateLength:
        bestLength = candidateLength
        bestId = uint8(word + 1)
    tokenIds[tokenCount] = bestId
    inc tokenCount
    position += if bestLength == 0: 1 else: bestLength

  let outputLength = tokenCount + 1
  if output.isNil or capacity < csize_t(outputLength):
    return -2
  output[0] = uint8(tokenCount)
  for token in 0 ..< tokenCount:
    output[token + 1] = tokenIds[token]
  int64(outputLength)
