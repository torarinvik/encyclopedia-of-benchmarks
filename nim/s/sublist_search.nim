const MaxListLength = 64
const MaxInputLength = 130
const MaxValue = 2_147_483_647'i64

proc sublist_search*(values: ptr UncheckedArray[int64], length: csize_t): int64
    {.cdecl, exportc: "sublist_search".} =
  if values == nil or length < 2 or length > csize_t(MaxInputLength): return -1
  let mainCountValue = values[0]
  let patternCountValue = values[1]
  if mainCountValue < 0 or mainCountValue > int64(MaxListLength) or
      patternCountValue < 0 or patternCountValue > int64(MaxListLength): return -1
  let mainCount = int(mainCountValue)
  let patternCount = int(patternCountValue)
  if length != csize_t(2 + mainCount + patternCount): return -1
  for i in 0 ..< mainCount + patternCount:
    let value = values[2 + i]
    if value < 0 or value > MaxValue: return -1

  if mainCount == 0 or patternCount == 0 or patternCount > mainCount: return 0
  let patternOffset = 2 + mainCount
  for start in 0 .. mainCount - patternCount:
    var matched = 0
    while matched < patternCount and values[2 + start + matched] == values[patternOffset + matched]:
      inc matched
    if matched == patternCount: return 1
  0
