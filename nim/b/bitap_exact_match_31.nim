const MaxTextLength = 4096
const MaxPatternLength = 31

proc bitap_exact_match_31*(values: ptr UncheckedArray[int64], length: csize_t): int64 {.cdecl, exportc: "bitap_exact_match_31".} =
  if values.isNil or length < 2 or values[0] < 0 or values[0] > MaxTextLength or values[1] < 0 or values[1] > MaxPatternLength: return -2
  let textLength = int(values[0])
  let patternLength = int(values[1])
  if length != csize_t(2 + textLength + patternLength): return -2
  for i in 2 ..< int(length):
    if values[i] < 97 or values[i] > 122: return -2
  if patternLength == 0: return 0
  if patternLength > textLength: return -1
  var masks: array[26, uint32]
  for c in 0 ..< 26: masks[c] = high(uint32)
  for i in 0 ..< patternLength:
    let letter = int(values[2 + textLength + i] - 97)
    masks[letter] = masks[letter] and not (1'u32 shl i)
  var state = not 1'u32
  for i in 0 ..< textLength:
    let letter = int(values[2 + i] - 97)
    state = (state or masks[letter]) shl 1
    if (state and (1'u32 shl patternLength)) == 0: return int64(i - patternLength + 1)
  -1
