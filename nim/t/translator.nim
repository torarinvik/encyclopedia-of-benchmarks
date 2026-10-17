const MaxKeys = 4
const MaxKeyLength = 4
const MaxTextLength = 64
const MaxInputLength = 107
const MaxOutputLength = 256

proc translator*(input: ptr UncheckedArray[int64], length: csize_t,
    output: ptr UncheckedArray[uint8], capacity: csize_t): int64
    {.cdecl, exportc: "translator".} =
  if input.isNil or length < 2 or length > MaxInputLength: return -1
  if input[0] < 0 or input[0] > 4 or input[1] < 0 or input[1] > 64: return -1
  let keyCount = int(input[0])
  let textLength = int(input[1])
  var keys: array[MaxKeys, array[MaxKeyLength, uint8]]
  var replacements: array[MaxKeys, array[MaxKeyLength, uint8]]
  var keyLengths, replacementLengths: array[MaxKeys, int]
  var cursor = 2
  for keyIndex in 0 ..< keyCount:
    if cursor + 2 > int(length): return -1
    let keyLengthValue = input[cursor]
    let valueLengthValue = input[cursor + 1]
    cursor += 2
    if keyLengthValue < 1 or keyLengthValue > 4 or valueLengthValue < 0 or valueLengthValue > 4: return -1
    let keyLength = int(keyLengthValue)
    let valueLength = int(valueLengthValue)
    if cursor + keyLength + valueLength > int(length): return -1
    for index in 0 ..< keyLength:
      let byte = input[cursor + index]
      if byte < 32 or byte > 126: return -1
      keys[keyIndex][index] = uint8(byte)
    cursor += keyLength
    for index in 0 ..< valueLength:
      let byte = input[cursor + index]
      if byte < 32 or byte > 126: return -1
      replacements[keyIndex][index] = uint8(byte)
    cursor += valueLength
    keyLengths[keyIndex] = keyLength
    replacementLengths[keyIndex] = valueLength
    for previous in 0 ..< keyIndex:
      if keyLengths[previous] == keyLength:
        var equal = true
        for index in 0 ..< keyLength:
          if keys[previous][index] != keys[keyIndex][index]: equal = false
        if equal: return -1
  if cursor + textLength != int(length): return -1
  var text: array[MaxTextLength, uint8]
  for index in 0 ..< textLength:
    let byte = input[cursor + index]
    if byte < 32 or byte > 126: return -1
    text[index] = uint8(byte)

  var result: array[MaxOutputLength, uint8]
  var resultLength = 0
  var start = 0
  while start < textLength:
    var matched = false
    let maximumLength = min(MaxKeyLength, textLength - start)
    for candidateLength in 1 .. maximumLength:
      for keyIndex in 0 ..< keyCount:
        if keyLengths[keyIndex] != candidateLength: continue
        if text[start ..< start + candidateLength] == keys[keyIndex][0 ..< candidateLength]:
          for index in 0 ..< replacementLengths[keyIndex]:
            result[resultLength + index] = replacements[keyIndex][index]
          resultLength += replacementLengths[keyIndex]
          start += candidateLength
          matched = true
          break
      if matched: break
    if not matched: break
  if output.isNil or capacity < csize_t(resultLength): return -2
  for index in 0 ..< resultLength: output[index] = result[index]
  int64(resultLength)
