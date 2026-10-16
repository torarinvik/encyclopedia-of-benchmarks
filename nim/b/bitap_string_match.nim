const MaxTextLength = 4096
const MaxPatternLength = 63

proc bitap_string_match*(values: ptr UncheckedArray[int64], length: csize_t): int64
    {.cdecl, exportc: "bitap_string_match".} =
  if values == nil or length < 2 or values[0] < 0 or values[0] > MaxTextLength or
      values[1] < 0 or values[1] > MaxPatternLength:
    return -2
  let textLength = int(values[0])
  let patternLength = int(values[1])
  if length != csize_t(2 + textLength + patternLength): return -2
  for index in 2 ..< int(length):
    if values[index] < 97 or values[index] > 122: return -2
  if patternLength == 0: return 0
  if patternLength > textLength: return -1

  var masks: array[26, uint64]
  for letter in 0 ..< 26: masks[letter] = high(uint64)
  for index in 0 ..< patternLength:
    let letter = int(values[2 + textLength + index] - 97)
    masks[letter] = masks[letter] and not (1'u64 shl index)
  var state = not 1'u64
  for index in 0 ..< textLength:
    let letter = int(values[2 + index] - 97)
    state = (state or masks[letter]) shl 1
    if (state and (1'u64 shl patternLength)) == 0:
      return int64(index - patternLength + 1)
  -1
