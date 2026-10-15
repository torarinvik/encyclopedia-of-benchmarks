## Bottom-up word segmentation over packed lowercase ASCII letter codes.
proc word_break*(values: ptr UncheckedArray[int64], length: csize_t): int64
    {.cdecl, exportc: "word_break".} =
  if length < 2 or length > 1122: return -1
  let textLengthValue = values[0]
  let wordCountValue = values[1]
  if textLengthValue < 0 or textLengthValue > 64 or wordCountValue < 0 or wordCountValue > 32:
    return -1
  let textLength = int(textLengthValue)
  let wordCount = int(wordCountValue)
  let dictionaryStart = 2 + textLength
  if int(length) != dictionaryStart + wordCount * 33: return -1
  for index in 0 ..< textLength:
    if values[2 + index] < 1 or values[2 + index] > 26: return -1
  for word in 0 ..< wordCount:
    let slot = dictionaryStart + word * 33
    let wordLengthValue = values[slot]
    if wordLengthValue < 1 or wordLengthValue > 32: return -1
    let wordLength = int(wordLengthValue)
    for index in 0 ..< 32:
      let code = values[slot + 1 + index]
      if index < wordLength:
        if code < 1 or code > 26: return -1
      elif code != 0:
        return -1

  var reachable: array[65, bool]
  reachable[0] = true
  for start in 0 ..< textLength:
    if not reachable[start]: continue
    for word in 0 ..< wordCount:
      let slot = dictionaryStart + word * 33
      let wordLength = int(values[slot])
      if wordLength > textLength - start: continue
      var index = 0
      while index < wordLength and values[2 + start + index] == values[slot + 1 + index]:
        index += 1
      if index == wordLength: reachable[start + wordLength] = true
  return int64(reachable[textLength])
