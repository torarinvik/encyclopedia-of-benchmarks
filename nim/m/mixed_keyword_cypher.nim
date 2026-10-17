const MaxKeywordLength = 64
const MaxPlaintextLength = 512
const MaxInputLength = 2 + MaxKeywordLength + MaxPlaintextLength

type
  I64Input = ptr UncheckedArray[int64]
  U8Output = ptr UncheckedArray[uint8]

proc mixed_keyword_cypher*(input: I64Input, length: csize_t, output: U8Output,
    capacity: csize_t): int64
    {.cdecl, exportc: "mixed_keyword_cypher".} =
  if input == nil or length < 2 or length > csize_t(MaxInputLength):
    return -1

  let rawKeywordLength = input[0]
  if rawKeywordLength < 1 or rawKeywordLength > int64(MaxKeywordLength):
    return -1
  let keywordLength = int(rawKeywordLength)
  let plaintextLengthIndex = 1 + keywordLength
  if plaintextLengthIndex >= int(length):
    return -1

  let rawPlaintextLength = input[plaintextLengthIndex]
  if rawPlaintextLength < 0 or rawPlaintextLength > int64(MaxPlaintextLength):
    return -1
  let plaintextLength = int(rawPlaintextLength)
  if int(length) != plaintextLengthIndex + 1 + plaintextLength:
    return -1

  var uniqueLetters: array[26, uint8]
  var seen: array[26, bool]
  var uniqueCount = 0
  for index in 0..<keywordLength:
    let raw = input[1 + index]
    if raw < 0 or raw > 127:
      return -1
    var letter = uint8(raw)
    if letter >= uint8(ord('a')) and letter <= uint8(ord('z')):
      letter -= uint8(ord('a') - ord('A'))
    if letter >= uint8(ord('A')) and letter <= uint8(ord('Z')):
      let alphabetIndex = int(letter - uint8(ord('A')))
      if not seen[alphabetIndex]:
        seen[alphabetIndex] = true
        uniqueLetters[uniqueCount] = letter
        inc uniqueCount
  if uniqueCount == 0:
    return -1

  for index in 0..<plaintextLength:
    let raw = input[plaintextLengthIndex + 1 + index]
    if raw < 0 or raw > 127:
      return -1

  var shifted: array[26, uint8]
  for index in 0..<uniqueCount:
    shifted[index] = uniqueLetters[index]
  var shiftedCount = uniqueCount
  for index in 0..<26:
    if not seen[index]:
      shifted[shiftedCount] = uint8(ord('A') + index)
      inc shiftedCount

  var mapping: array[26, uint8]
  var alphabetIndex = 0
  for column in 0..<uniqueCount:
    var rowStart = 0
    while rowStart < 26:
      let shiftedIndex = rowStart + column
      if shiftedIndex >= 26:
        break
      mapping[alphabetIndex] = shifted[shiftedIndex]
      inc alphabetIndex
      rowStart += uniqueCount

  var buffer: array[MaxPlaintextLength, uint8]
  for index in 0..<plaintextLength:
    var letter = uint8(input[plaintextLengthIndex + 1 + index])
    if letter >= uint8(ord('a')) and letter <= uint8(ord('z')):
      letter -= uint8(ord('a') - ord('A'))
    if letter >= uint8(ord('A')) and letter <= uint8(ord('Z')):
      buffer[index] = mapping[int(letter - uint8(ord('A')))]
    else:
      buffer[index] = letter

  if output == nil or capacity < csize_t(plaintextLength):
    return -2
  for index in 0..<plaintextLength:
    output[index] = buffer[index]
  int64(plaintextLength)
