## Check nondecreasing letter gaps after ASCII normalization and filtering.
const MaxLength = 4096

proc check_exceeding*(values: ptr UncheckedArray[int64], length: csize_t): int64
    {.cdecl, exportc: "check_exceeding".} =
  if length > csize_t(MaxLength) or (length != 0 and values == nil): return -2
  for index in 0 ..< int(length):
    let value = values[index]
    if value < 32 or value > 126: return -2

  var previousLetter = -1'i64
  var previousGap = -1'i64
  for index in 0 ..< int(length):
    var letter = values[index]
    if letter >= 97 and letter <= 122: letter -= 32
    if letter < 65 or letter > 90: continue
    if previousLetter >= 0 and letter != previousLetter:
      let gap = abs(letter - previousLetter)
      if previousGap >= 0 and gap < previousGap: return 0
      previousGap = gap
    previousLetter = letter
  1
