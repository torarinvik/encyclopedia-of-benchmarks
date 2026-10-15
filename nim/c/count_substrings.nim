const MaxLength = 4096

proc findNext(values: ptr UncheckedArray[int64], textLength, patternLength, patternStart, start: int): int64 =
  if start > textLength or patternLength > textLength - start: return -1
  let last = textLength - patternLength
  for position in start .. last:
    var offset = 0
    while offset < patternLength and values[2 + position + offset] == values[patternStart + offset]: inc offset
    if offset == patternLength: return int64(position)
  -1

proc count_substrings*(values: ptr UncheckedArray[int64], length: csize_t): int64
    {.cdecl, exportc: "count_substrings".} =
  if values == nil or length < 2 or values[0] < 0 or values[0] > MaxLength or values[1] < 0 or values[1] > MaxLength: return -1
  let textLength = int(values[0])
  let patternLength = int(values[1])
  if length != csize_t(2 + textLength + patternLength): return -1
  for i in 2 ..< int(length):
    if values[i] < 0 or values[i] > 127: return -1
  if patternLength == 0: return int64(textLength) + 1
  let patternStart = 2 + textLength
  var count = 0'i64
  var position = findNext(values, textLength, patternLength, patternStart, 0)
  while position >= 0:
    inc count
    position = findNext(values, textLength, patternLength, patternStart, int(position) + 1)
  count
