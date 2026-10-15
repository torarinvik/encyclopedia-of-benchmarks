## Return the length of a strict longest alternating subsequence.
const MaxLength = 512

proc longest_alternating_subsequence*(values: ptr UncheckedArray[int64], length: csize_t): int64
    {.cdecl, exportc: "longest_alternating_subsequence".} =
  if length > csize_t(MaxLength) or (length != 0 and values == nil): return -1
  var rising: array[MaxLength, int64]
  var falling: array[MaxLength, int64]
  var best = 1'i64
  for index in 0 ..< int(length):
    let value = values[csize_t(index)]
    if value < int64(low(int32)) or value > int64(high(int32)): return -1
    rising[index] = 1
    falling[index] = 1
    for previous in 0 ..< index:
      if values[csize_t(previous)] < value and rising[index] < falling[previous] + 1:
        rising[index] = falling[previous] + 1
      if values[csize_t(previous)] > value and falling[index] < rising[previous] + 1:
        falling[index] = rising[previous] + 1
    if rising[index] > best: best = rising[index]
    if falling[index] > best: best = falling[index]
  best
