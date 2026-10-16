const
  MaxKeywordLength = 26
  MaxMessageLength = 512
  MaxInputLength = 3 + MaxKeywordLength + MaxMessageLength + 1

proc keyword_shifted_alphabet*(input: ptr UncheckedArray[int64], length: csize_t,
    output: ptr UncheckedArray[uint8], outputCapacity: csize_t): int64
    {.cdecl, exportc: "keyword_shifted_alphabet".} =
  if input == nil or length < 3 or length > csize_t(MaxInputLength): return -1
  let operation = input[0]
  let keywordLengthValue = input[1]
  let messageLengthValue = input[2]
  if (operation != 0 and operation != 1) or keywordLengthValue < 1 or keywordLengthValue > 26 or
      messageLengthValue < 1 or messageLengthValue > MaxMessageLength: return -1
  let keywordLength = int(keywordLengthValue)
  let messageLength = int(messageLengthValue)
  if length != csize_t(3 + keywordLength + messageLength): return -1

  var keyword: array[MaxKeywordLength, uint8]
  var seen: array[26, bool] = default(array[26, bool])
  for i in 0 ..< keywordLength:
    let value = input[3 + i]
    if not ((value >= 65 and value <= 90) or (value >= 97 and value <= 122)): return -1
    var lower = uint8(value)
    if value >= 65 and value <= 90: lower = uint8(value + 32)
    let index = int(lower - uint8('a'))
    if seen[index]: return -1
    seen[index] = true
    keyword[i] = lower
  var message: array[MaxMessageLength, uint8]
  for i in 0 ..< messageLength:
    let value = input[3 + keywordLength + i]
    if value < 0 or value > 127: return -1
    message[i] = uint8(value)

  var cipherAlphabet: array[26, uint8]
  var encode: array[26, uint8]
  var decode: array[26, uint8]
  var cipherLength = 0
  for i in 0 ..< keywordLength:
    cipherAlphabet[cipherLength] = keyword[i]
    inc cipherLength
  for i in 0 ..< 26:
    let letter = uint8(ord('a') + i)
    if not seen[i]:
      cipherAlphabet[cipherLength] = letter
      inc cipherLength
  for i in 0 ..< 26:
    encode[i] = cipherAlphabet[i]
    decode[int(cipherAlphabet[i] - uint8('a'))] = uint8(ord('a') + i)

  if outputCapacity < csize_t(messageLength) or output == nil: return -2
  for i in 0 ..< messageLength:
    let value = message[i]
    let uppercase = value >= uint8('A') and value <= uint8('Z')
    var index = 0
    if uppercase:
      index = int(value - uint8('A'))
    elif value >= uint8('a') and value <= uint8('z'):
      index = int(value - uint8('a'))
    else:
      output[i] = value
      continue
    let translated = if operation == 0: encode[index] else: decode[index]
    output[i] = if uppercase: translated - uint8('a' - 'A') else: translated
  int64(messageLength)
