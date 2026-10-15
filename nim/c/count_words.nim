const MaxLength = 4096

proc isTrimCharacter(value: int64): bool = value <= 32
proc isRegexWhitespace(value: int64): bool = value in [9'i64, 10, 11, 12, 13, 32]

## Count tokens after Java String.trim() and split("\\s+").
proc count_words*(values: ptr UncheckedArray[int64], length: csize_t): int64
    {.cdecl, exportc: "count_words".} =
  if length > MaxLength or (length > 0 and values == nil): return -1
  for i in 0 ..< int(length):
    if values[i] < 0 or values[i] > 127: return -1
  if length == 0: return 0
  var start = 0
  var ending = int(length)
  while start < ending and isTrimCharacter(values[start]): inc start
  while ending > start and isTrimCharacter(values[ending - 1]): dec ending
  if start == ending: return 1
  var count = 0'i64
  var inWord = false
  for i in start ..< ending:
    if isRegexWhitespace(values[i]):
      inWord = false
    elif not inWord:
      inc count
      inWord = true
  count
