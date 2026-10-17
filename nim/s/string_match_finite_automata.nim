const MaxTextLength = 256
const MaxPatternLength = 32
const AlphabetSize = 128
const TransitionTableSize = (MaxPatternLength + 1) * AlphabetSize
const MaxParseableInputLength = 2 + MaxTextLength + MaxPatternLength + 1

proc nextState(pattern: ptr UncheckedArray[int64], patternLength, state: int, symbol: int64): int =
  if state < patternLength and symbol == pattern[state]:
    return state + 1
  var candidate = state
  while candidate > 0:
    if pattern[candidate - 1] == symbol:
      var prefixMatches = true
      for index in 0 ..< candidate - 1:
        if pattern[index] != pattern[state - candidate + index + 1]:
          prefixMatches = false
          break
      if prefixMatches:
        return candidate
    dec candidate
  0

proc storeI32Le(output: ptr UncheckedArray[uint8], offset: int, value: int32) =
  let bits = cast[uint32](value)
  for byte in 0 ..< 4:
    output[offset + byte] = uint8((bits shr (byte * 8)) and 255)

proc string_match_finite_automata*(values: ptr UncheckedArray[int64], length: csize_t,
    output: ptr UncheckedArray[uint8], outputCapacity: csize_t): int64
    {.cdecl, exportc: "string_match_finite_automata".} =
  if values == nil or length < 2 or length > csize_t(MaxParseableInputLength): return -1
  let rawTextLength = values[0]
  let rawPatternLength = values[1]
  if rawTextLength < 0 or rawTextLength > int64(MaxTextLength) or
      rawPatternLength < 1 or rawPatternLength > int64(MaxPatternLength) or
      length != csize_t(2 + rawTextLength + rawPatternLength): return -1
  let textLength = int(rawTextLength)
  let patternLength = int(rawPatternLength)
  for index in 0 ..< textLength + patternLength:
    let symbol = values[2 + index]
    if symbol < 0 or symbol >= int64(AlphabetSize): return -1

  let text = cast[ptr UncheckedArray[int64]](addr values[2])
  let pattern = cast[ptr UncheckedArray[int64]](addr values[2 + textLength])
  var transitions: array[TransitionTableSize, int32]
  for state in 0 .. patternLength:
    for symbol in 0 ..< AlphabetSize:
      transitions[state * AlphabetSize + symbol] =
        int32(nextState(pattern, patternLength, state, int64(symbol)))

  var matches: array[MaxTextLength, int32]
  var matchCount = 0
  var state = 0
  for index in 0 ..< textLength:
    state = int(transitions[state * AlphabetSize + int(text[index])])
    if state == patternLength:
      matches[matchCount] = int32(index + 1 - patternLength)
      inc matchCount

  let byteCount = matchCount * 4
  if output == nil or outputCapacity < csize_t(byteCount): return -2
  for index in 0 ..< matchCount:
    storeI32Le(output, 4 * index, matches[index])
  int64(byteCount)
