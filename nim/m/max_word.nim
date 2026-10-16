const
  MaxTextLength = 512
  MaxInputLength = MaxTextLength + 2

proc lowerAscii(value: uint8): uint8 =
  if value >= uint8('A') and value <= uint8('Z'):
    return value + uint8('a' - 'A')
  value

proc max_word*(input: ptr UncheckedArray[int64], length: csize_t,
    output: ptr UncheckedArray[uint8], outputCapacity: csize_t): int64
    {.cdecl, exportc: "max_word".} =
  if input == nil or length < 1 or length > csize_t(MaxInputLength): return -1
  let textLengthValue = input[0]
  if textLengthValue < 1 or textLengthValue > MaxTextLength: return -1
  let textLength = int(textLengthValue)
  if length != csize_t(1 + textLength): return -1

  var text: array[MaxTextLength, uint8]
  for i in 0 ..< textLength:
    let value = input[i + 1]
    let isLetter = (value >= 65 and value <= 90) or (value >= 97 and value <= 122)
    if value == 32:
      if i == 0 or i + 1 == textLength or text[i - 1] == uint8(' '): return -1
    elif not isLetter or value == 73:
      return -1
    text[i] = uint8(value)

  var starts: array[MaxTextLength, int]
  var lengths: array[MaxTextLength, int]
  var counts: array[MaxTextLength, int]
  var uniqueCount = 0
  var start = 0
  while start < textLength:
    var finish = start
    while finish < textLength and text[finish] != uint8(' '): inc finish
    let wordLength = finish - start
    if wordLength > 6: return -1
    var found = uniqueCount
    for key in 0 ..< uniqueCount:
      if lengths[key] != wordLength: continue
      var offset = 0
      while offset < wordLength and
          lowerAscii(text[starts[key] + offset]) == lowerAscii(text[start + offset]):
        inc offset
      if offset == wordLength:
        found = key
        break
    if found == uniqueCount:
      starts[uniqueCount] = start
      lengths[uniqueCount] = wordLength
      counts[uniqueCount] = 1
      inc uniqueCount
    else:
      inc counts[found]
    start = finish + 1

  var winner = 0
  for key in 1 ..< uniqueCount:
    if counts[key] > counts[winner]: winner = key
  let resultLength = lengths[winner]
  if outputCapacity < csize_t(resultLength) or output == nil: return -2
  let singleWord = uniqueCount == 1 and counts[0] == 1
  for i in 0 ..< resultLength:
    let value = text[starts[winner] + i]
    output[i] = if singleWord: value else: lowerAscii(value)
  int64(resultLength)
