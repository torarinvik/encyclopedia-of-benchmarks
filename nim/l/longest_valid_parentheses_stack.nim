## Track unmatched opening positions to find the longest valid parentheses substring.
const MaxLength = 4096

proc longest_valid_parentheses_stack*(input: ptr UncheckedArray[int64], length: csize_t): int64
    {.cdecl, exportc: "longest_valid_parentheses_stack".} =
  if length > csize_t(MaxLength) or (length != 0 and input == nil): return -1
  for index in 0 ..< int(length):
    if input[index] != 40 and input[index] != 41: return -1

  var unmatched: array[MaxLength + 1, int]
  var top = 0
  unmatched[top] = -1
  var best = 0
  for index in 0 ..< int(length):
    if input[index] == 40:
      inc top
      unmatched[top] = index
    elif top == 0:
      unmatched[0] = index
    else:
      dec top
      let current = index - unmatched[top]
      if current > best: best = current
  int64(best)
