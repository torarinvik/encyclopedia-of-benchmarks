## Memoized endpoint recurrence, evaluated bottom-up from right to left.
const MaxLength = 4096

proc longest_valid_parentheses*(input: ptr UncheckedArray[int64], length: csize_t): int64
    {.cdecl, exportc: "longest_valid_parentheses".} =
  if length > csize_t(MaxLength) or (length != 0 and input == nil): return -1
  for index in 0 ..< int(length):
    if input[index] != 40 and input[index] != 41: return -1

  var endExclusive: array[MaxLength, int]
  var best = 0
  for remaining in countdown(int(length), 1):
    let index = remaining - 1
    if input[index] == 40:
      if index + 1 < int(length) and input[index + 1] == 41:
        endExclusive[index] = index + 2
        if index + 2 < int(length) and endExclusive[index + 2] > endExclusive[index]:
          endExclusive[index] = endExclusive[index + 2]
      elif index + 1 < int(length):
        let nestedEnd = endExclusive[index + 1]
        if nestedEnd > 0 and nestedEnd < int(length) and input[nestedEnd] == 41:
          endExclusive[index] = nestedEnd + 1
          if nestedEnd + 1 < int(length) and endExclusive[nestedEnd + 1] > endExclusive[index]:
            endExclusive[index] = endExclusive[nestedEnd + 1]
    if endExclusive[index] > index and endExclusive[index] - index > best:
      best = endExclusive[index] - index
  int64(best)
