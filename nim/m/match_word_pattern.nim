const
  MaxPatternLength = 8
  MaxTextLength = 32
  MaxInputLength = 43

proc matchWordPatternSearch(input: ptr UncheckedArray[int64], patternLength,
                            textStart, textLength, patternIndex, textIndex: int,
                            mappedStart: var array[128, int],
                            mappedLength: var array[128, int]): bool =
  if patternIndex == patternLength: return textIndex == textLength
  if textIndex == textLength: return false

  let symbol = int(input[2 + patternIndex])
  let knownLength = mappedLength[symbol]
  if knownLength != 0:
    if knownLength > textLength - textIndex: return false
    for offset in 0 ..< knownLength:
      if input[textStart + mappedStart[symbol] + offset] != input[textStart + textIndex + offset]:
        return false
    return matchWordPatternSearch(input, patternLength, textStart, textLength,
                                  patternIndex + 1, textIndex + knownLength,
                                  mappedStart, mappedLength)

  for ending in textIndex + 1 .. textLength:
    let candidateLength = ending - textIndex
    var alreadyUsed = false
    for otherIndex in 0 ..< patternIndex:
      let other = int(input[2 + otherIndex])
      if other == symbol: continue
      if mappedLength[other] == candidateLength:
        var equal = true
        for offset in 0 ..< candidateLength:
          if input[textStart + mappedStart[other] + offset] != input[textStart + textIndex + offset]:
            equal = false
            break
        if equal:
          alreadyUsed = true
          break
    if alreadyUsed: continue

    mappedStart[symbol] = textIndex
    mappedLength[symbol] = candidateLength
    if matchWordPatternSearch(input, patternLength, textStart, textLength,
                              patternIndex + 1, ending, mappedStart, mappedLength):
      return true
    mappedLength[symbol] = 0
  false

proc match_word_pattern*(input: ptr UncheckedArray[int64], inputLength: csize_t): int64
    {.cdecl, exportc: "match_word_pattern".} =
  if input == nil or inputLength < 2 or inputLength > csize_t(MaxInputLength): return -1
  if input[0] < 0 or input[0] > MaxPatternLength or input[1] < 0 or input[1] > MaxTextLength:
    return -1
  let patternLength = int(input[0])
  let textLength = int(input[1])
  if int(inputLength) != 2 + patternLength + textLength: return -1
  for index in 0 ..< patternLength + textLength:
    if input[2 + index] < 0 or input[2 + index] > 127: return -1

  var mappedStart: array[128, int]
  var mappedLength: array[128, int]
  if matchWordPatternSearch(input, patternLength, 2 + patternLength, textLength,
                            0, 0, mappedStart, mappedLength):
    return 1
  0
