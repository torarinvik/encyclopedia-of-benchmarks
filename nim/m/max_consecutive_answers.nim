## Maximize one repeated binary answer while changing at most k entries.
const MaxBits = 1024

proc longestForTarget(input: ptr UncheckedArray[int64], count, allowed: int, target: int64): int =
  var left = 0
  var opposite = 0
  var best = 0
  for right in 0 ..< count:
    if input[right + 1] != target: inc opposite
    while opposite > allowed:
      if input[left + 1] != target: dec opposite
      inc left
    best = max(best, right - left + 1)
  best

proc max_consecutive_answers*(input: ptr UncheckedArray[int64], length: csize_t): int64
    {.cdecl, exportc: "max_consecutive_answers".} =
  if input == nil or length == 0 or length > csize_t(MaxBits + 1): return -1
  let count = int(length) - 1
  if input[0] < 0 or input[0] > int64(count): return -1
  for index in 0 ..< count:
    if input[index + 1] != 0'i64 and input[index + 1] != 1'i64: return -1
  let allowed = int(input[0])
  int64(max(longestForTarget(input, count, allowed, 1),
            longestForTarget(input, count, allowed, 0)))
