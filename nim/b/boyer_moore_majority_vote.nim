## Return a strict majority element, or -1 if none exists.
proc boyer_moore_majority_vote*(values: ptr UncheckedArray[int64], length: csize_t): int64
    {.cdecl, exportc: "boyer_moore_majority_vote".} =
  if length < 1 or length > 256 or values.isNil: return -1
  var candidate = 0'i64
  var balance = 0
  for index in 0 ..< int(length):
    if balance == 0: candidate = values[index]
    if values[index] == candidate: inc balance
    else: dec balance
  var occurrences = 0
  for index in 0 ..< int(length):
    if values[index] == candidate: inc occurrences
  if occurrences > int(length) div 2: candidate else: -1
