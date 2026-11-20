const MaxText = 64
const MaxPattern = 16
const MaxAlphabet = 16
const MaxParseableInput = 84
const MaxOutputBytes = 520

proc storeWord(output: ptr UncheckedArray[uint8], word: int, value: int64) =
  let bits = cast[uint64](value)
  for byte in 0 ..< 8:
    output[word * 8 + byte] = uint8((bits shr (8 * byte)) and 255)

proc patternPair(pattern: openArray[int64], previous: openArray[int],
    current, prefixPosition: int): bool =
  let prior = previous[current]
  if prior < 0 or current - prior > prefixPosition:
    return previous[prefixPosition] < 0
  let distance = current - prior
  pattern[prefixPosition] == pattern[prefixPosition - distance]

proc textPair(text: openArray[int64], textPosition, patternPosition: int,
    previous: openArray[int], lastText: openArray[int]): bool =
  let prior = previous[patternPosition]
  let symbol = int(text[textPosition])
  if prior < 0:
    return lastText[symbol] < textPosition - patternPosition
  let distance = patternPosition - prior
  text[textPosition] == text[textPosition - distance]

proc parameterized_pattern_matching_kmp*(input: ptr UncheckedArray[int64],
    length: csize_t, output: ptr UncheckedArray[uint8], capacity: csize_t): int64
    {.cdecl, exportc: "parameterized_pattern_matching_kmp".} =
  if input.isNil or length < csize_t(3) or length > csize_t(MaxParseableInput): return -1
  let nValue, mValue, alphabetValue = input[0], input[1], input[2]
  if nValue < 0 or nValue > MaxText or mValue < 1 or mValue > MaxPattern or
      alphabetValue < 1 or alphabetValue > MaxAlphabet: return -1
  let n, m, alphabetSize = int(nValue), int(mValue), int(alphabetValue)
  if int(length) != 3 + n + m: return -1
  var text: array[MaxText, int64]
  var pattern: array[MaxPattern, int64]
  for index in 0 ..< n + m:
    let symbol = input[3 + index]
    if symbol < 0 or symbol >= alphabetSize: return -1
    if index < n: text[index] = symbol
    else: pattern[index - n] = symbol

  var previous: array[MaxPattern, int]
  var lastPattern: array[MaxAlphabet, int]
  for symbol in 0 ..< MaxAlphabet: lastPattern[symbol] = -1
  for index in 0 ..< m:
    let symbol = int(pattern[index])
    previous[index] = lastPattern[symbol]
    lastPattern[symbol] = index

  var failure: array[MaxPattern, int]
  for current in 1 ..< m:
    var matched = failure[current - 1]
    while matched > 0 and not patternPair(pattern, previous, current, matched):
      matched = failure[matched - 1]
    if patternPair(pattern, previous, current, matched): inc matched
    failure[current] = matched

  var lastText: array[MaxAlphabet, int]
  for symbol in 0 ..< MaxAlphabet: lastText[symbol] = -1
  var matches: array[MaxText, int64]
  var matchCount = 0
  var matched = 0
  if m <= n:
    for textPosition in 0 ..< n:
      while true:
        if textPair(text, textPosition, matched, previous, lastText):
          inc matched
          if matched == m:
            matches[matchCount] = int64(textPosition + 1 - m)
            inc matchCount
            matched = failure[m - 1]
          break
        if matched == 0: break
        matched = failure[matched - 1]
      lastText[int(text[textPosition])] = textPosition

  let outputBytes = 8 * (matchCount + 1)
  if output.isNil or int(capacity) < outputBytes: return -2
  var staged: array[MaxOutputBytes, uint8]
  storeWord(addr staged[0], 0, int64(matchCount))
  for index in 0 ..< matchCount: storeWord(addr staged[0], index + 1, matches[index])
  for index in 0 ..< outputBytes: output[index] = staged[index]
  int64(outputBytes)
