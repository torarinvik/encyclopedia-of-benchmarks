const
  MaxBitCount = 128
  MaxParseableInputLength = 130
  MaxOutputBytes = 8256
  MaxDictionaryEntries = 130
  MaxPhraseLength = 129

proc lempel_ziv_decompress*(input: ptr UncheckedArray[int64], inputLength: csize_t,
    output: ptr UncheckedArray[uint8], outputCapacity: csize_t): int64
    {.cdecl, exportc: "lempel_ziv_decompress".} =
  if input == nil or inputLength < 1 or inputLength > MaxParseableInputLength.csize_t:
    return -1
  let bitCountValue = input[0]
  if bitCountValue < 0 or bitCountValue > MaxBitCount.int64:
    return -1
  let bitCount = int(bitCountValue)
  if inputLength != (1 + bitCount).csize_t:
    return -1
  for index in 0 ..< bitCount:
    if input[index + 1] != 48 and input[index + 1] != 49:
      return -1

  var codes: array[MaxDictionaryEntries, int]
  var phraseLengths: array[MaxDictionaryEntries, int]
  var phrases: array[MaxDictionaryEntries * MaxPhraseLength, uint8]
  codes[0] = 0
  codes[1] = 1
  phraseLengths[0] = 1
  phraseLengths[1] = 1
  phrases[0] = 48
  phrases[MaxPhraseLength] = 49
  var entryCount = 2
  var codeWidth = 1
  var nextIndex = 2
  var result: array[MaxOutputBytes, uint8]
  var resultLength = 0
  var cursor = 0

  while cursor + codeWidth <= bitCount:
    let codeWidthUsed = codeWidth
    var code = 0
    for bitOffset in 0 ..< codeWidth:
      code = code * 2 + int(input[cursor + bitOffset + 1] - 48)
    var found = entryCount
    for index in 0 ..< entryCount:
      if codes[index] == code:
        found = index
        break
    if found == entryCount:
      break

    let lastLength = phraseLengths[found]
    var lastPhrase: array[MaxPhraseLength, uint8]
    for index in 0 ..< lastLength:
      let value = phrases[found * MaxPhraseLength + index]
      lastPhrase[index] = value
      result[resultLength] = value
      inc resultLength
    phrases[found * MaxPhraseLength + lastLength] = 48
    phraseLengths[found] = lastLength + 1

    if (nextIndex and (nextIndex - 1)) == 0:
      inc codeWidth
    codes[entryCount] = nextIndex
    phraseLengths[entryCount] = lastLength + 1
    for index in 0 ..< lastLength:
      phrases[entryCount * MaxPhraseLength + index] = lastPhrase[index]
    phrases[entryCount * MaxPhraseLength + lastLength] = 49
    inc entryCount
    inc nextIndex
    cursor += codeWidthUsed

  if output == nil or outputCapacity < resultLength.csize_t:
    return -2
  for index in 0 ..< resultLength:
    output[index] = result[index]
  int64(resultLength)
