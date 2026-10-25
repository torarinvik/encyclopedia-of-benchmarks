const MaxPatternLength = 63
const MaxTextLength = 4096
const MaxErrors = 2

proc agrep_approx_substring_count*(values: ptr UncheckedArray[int64], length: csize_t): int64
    {.cdecl, exportc: "agrep_approx_substring_count".} =
  if values == nil or length < 3 or values[0] < 1 or values[0] > MaxPatternLength or
      values[1] < 0 or values[1] > MaxTextLength or values[2] < 0 or values[2] > MaxErrors:
    return -2
  let patternLength = int(values[0])
  let textLength = int(values[1])
  if length != csize_t(3 + patternLength + textLength): return -2
  for index in 3 ..< int(length):
    if values[index] < 32 or values[index] > 126: return -2

  var previous: array[64, int64]
  var current: array[64, int64]
  for index in 0 .. patternLength: previous[index] = int64(index)
  var matches = 0'i64
  let textOffset = 3 + patternLength
  for textIndex in 0 ..< textLength:
    current[0] = 0
    for patternIndex in 1 .. patternLength:
      let substitution = previous[patternIndex - 1] +
        (if values[3 + patternIndex - 1] == values[textOffset + textIndex]: 0'i64 else: 1'i64)
      current[patternIndex] = min(previous[patternIndex] + 1,
        min(current[patternIndex - 1] + 1, substitution))
    if current[patternLength] <= values[2]: inc matches
    for index in 0 .. patternLength: previous[index] = current[index]
  matches
