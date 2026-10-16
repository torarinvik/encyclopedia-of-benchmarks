const
  MaxWidth = 64
  MaxTextBytes = 512
  MaxWords = 64
  MaxInputLength = 2 + MaxTextBytes + 1
  MaxOutputBytes = MaxWords * MaxWidth + MaxWords

proc text_justification*(input: ptr UncheckedArray[int64], length: csize_t,
    output: ptr UncheckedArray[uint8], outputCapacity: csize_t): int64
    {.cdecl, exportc: "text_justification".} =
  if input == nil or length < 2 or length > csize_t(MaxInputLength): return -1
  let widthValue = input[0]
  let textLengthValue = input[1]
  if widthValue < 1 or widthValue > MaxWidth or textLengthValue < 0 or
      textLengthValue > MaxTextBytes or length != csize_t(2 + textLengthValue):
    return -1
  let width = int(widthValue)
  let textLength = int(textLengthValue)
  var text: array[MaxTextBytes, uint8]
  for index in 0 ..< textLength:
    let value = input[index + 2]
    if value != 32 and (value < 33 or value > 126): return -1
    text[index] = uint8(value)

  var starts: array[MaxWords, int]
  var lengths: array[MaxWords, int]
  var wordCount = 0
  var index = 0
  while index < textLength:
    while index < textLength and text[index] == uint8(' '): inc index
    if index == textLength: break
    let start = index
    while index < textLength and text[index] != uint8(' '): inc index
    let wordLength = index - start
    if wordCount == MaxWords or wordLength > width: return -1
    starts[wordCount] = start
    lengths[wordCount] = wordLength
    inc wordCount

  var result: array[MaxOutputBytes, uint8]
  var resultLength = 0
  var lineStart = 0
  var lineEnd = 0
  var letters = 0
  var firstLine = true
  for word in 0 ..< wordCount:
    if letters + lengths[word] + (lineEnd - lineStart) <= width:
      letters += lengths[word]
      inc lineEnd
      continue
    if not firstLine:
      result[resultLength] = uint8('\n')
      inc resultLength
    firstLine = false
    let count = lineEnd - lineStart
    if count == 1:
      for i in 0 ..< lengths[lineStart]:
        result[resultLength] = text[starts[lineStart] + i]
        inc resultLength
      for i in lengths[lineStart] ..< width:
        result[resultLength] = uint8(' ')
        inc resultLength
    else:
      let gaps = count - 1
      let spaces = width - letters
      let base = spaces div gaps
      let extra = spaces mod gaps
      for item in 0 ..< count:
        let current = lineStart + item
        for i in 0 ..< lengths[current]:
          result[resultLength] = text[starts[current] + i]
          inc resultLength
        if item + 1 < count:
          let gapSpaces = base + (if item < extra: 1 else: 0)
          for i in 0 ..< gapSpaces:
            result[resultLength] = uint8(' ')
            inc resultLength
    lineStart = word
    lineEnd = word + 1
    letters = lengths[word]

  if not firstLine:
    result[resultLength] = uint8('\n')
    inc resultLength
  for item in lineStart ..< lineEnd:
    if item != lineStart:
      result[resultLength] = uint8(' ')
      inc resultLength
    for i in 0 ..< lengths[item]:
      result[resultLength] = text[starts[item] + i]
      inc resultLength
  let trailingSpaces = width - letters - (lineEnd - lineStart) + 1
  for i in 0 ..< trailingSpaces:
    result[resultLength] = uint8(' ')
    inc resultLength

  if outputCapacity < csize_t(resultLength) or (resultLength != 0 and output == nil): return -2
  for i in 0 ..< resultLength: output[i] = result[i]
  int64(resultLength)
