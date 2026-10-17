const
  MaxBitCount = 128
  MaxParseableInputLength = 130
  MaxOutputBytes = 1032
  MaxDictionaryEntries = 130
  MaxKeyLength = 129
  MaxCodeWidth = 8

proc lempel_ziv*(input: ptr UncheckedArray[int64], inputLength: csize_t,
    output: ptr UncheckedArray[uint8], outputCapacity: csize_t): int64
    {.cdecl, exportc: "lempel_ziv".} =
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

  var keys: array[MaxDictionaryEntries * MaxKeyLength, uint8]
  var keyLengths: array[MaxDictionaryEntries, int]
  var codes: array[MaxDictionaryEntries * MaxCodeWidth, uint8]
  var codeLengths: array[MaxDictionaryEntries, int]
  keys[0] = 48
  keys[MaxKeyLength] = 49
  keyLengths[0] = 1
  keyLengths[1] = 1
  codes[0] = 48
  codes[MaxCodeWidth] = 49
  codeLengths[0] = 1
  codeLengths[1] = 1
  var entryCount = 2
  var nextIndex = 2
  var current: array[MaxKeyLength, uint8]
  var currentLength = 0
  var result: array[MaxOutputBytes, uint8]
  var resultLength = 0

  for inputIndex in 0 ..< bitCount:
    current[currentLength] = uint8(input[inputIndex + 1])
    inc currentLength
    var found = entryCount
    for entry in 0 ..< entryCount:
      if keyLengths[entry] == currentLength:
        var matched = true
        for component in 0 ..< currentLength:
          if keys[entry * MaxKeyLength + component] != current[component]:
            matched = false
            break
        if matched:
          found = entry
          break
    if found == entryCount:
      continue

    let lastCodeLength = codeLengths[found]
    var lastCode: array[MaxCodeWidth, uint8]
    for component in 0 ..< lastCodeLength:
      lastCode[component] = codes[found * MaxCodeWidth + component]
      result[resultLength] = lastCode[component]
      inc resultLength

    for entry in found ..< entryCount - 1:
      for component in 0 ..< MaxKeyLength:
        keys[entry * MaxKeyLength + component] = keys[(entry + 1) * MaxKeyLength + component]
      for component in 0 ..< MaxCodeWidth:
        codes[entry * MaxCodeWidth + component] = codes[(entry + 1) * MaxCodeWidth + component]
      keyLengths[entry] = keyLengths[entry + 1]
      codeLengths[entry] = codeLengths[entry + 1]
    dec entryCount

    for component in 0 ..< currentLength:
      keys[entryCount * MaxKeyLength + component] = current[component]
    keys[entryCount * MaxKeyLength + currentLength] = 48
    keyLengths[entryCount] = currentLength + 1
    for component in 0 ..< lastCodeLength:
      codes[entryCount * MaxCodeWidth + component] = lastCode[component]
    codeLengths[entryCount] = lastCodeLength
    inc entryCount

    if (nextIndex and (nextIndex - 1)) == 0:
      for entry in 0 ..< entryCount:
        let codeLength = codeLengths[entry]
        for component in countdown(codeLength, 1):
          codes[entry * MaxCodeWidth + component] = codes[entry * MaxCodeWidth + component - 1]
        codes[entry * MaxCodeWidth] = 48
        codeLengths[entry] = codeLength + 1
    for component in 0 ..< currentLength:
      keys[entryCount * MaxKeyLength + component] = current[component]
    keys[entryCount * MaxKeyLength + currentLength] = 49
    keyLengths[entryCount] = currentLength + 1
    var codeWidth = 1
    var temp = nextIndex
    while temp > 1:
      temp = temp div 2
      inc codeWidth
    codeLengths[entryCount] = codeWidth
    for component in 0 ..< codeWidth:
      codes[entryCount * MaxCodeWidth + component] =
        uint8(ord('0') + ((nextIndex shr (codeWidth - component - 1)) and 1))
    inc entryCount
    inc nextIndex
    currentLength = 0

  if currentLength > 0:
    var maxKeyLength = 0
    for entry in 0 ..< entryCount:
      if keyLengths[entry] > maxKeyLength:
        maxKeyLength = keyLengths[entry]
    var found = entryCount
    while found == entryCount:
      for entry in 0 ..< entryCount:
        if keyLengths[entry] == currentLength:
          var matched = true
          for component in 0 ..< currentLength:
            if keys[entry * MaxKeyLength + component] != current[component]:
              matched = false
              break
          if matched:
            found = entry
            break
      if found == entryCount:
        if currentLength >= maxKeyLength:
          break
        current[currentLength] = 48
        inc currentLength
    if found == entryCount:
      return -1
    for component in 0 ..< codeLengths[found]:
      result[resultLength] = codes[found * MaxCodeWidth + component]
      inc resultLength

  if output == nil or outputCapacity < resultLength.csize_t:
    return -2
  for index in 0 ..< resultLength:
    output[index] = result[index]
  int64(resultLength)
