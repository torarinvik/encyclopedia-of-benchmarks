## Count every pair of distinct indices whose values sum to the target.
const MaxInputLength = 257

proc pairs_with_given_sum*(input: ptr UncheckedArray[int64], length: csize_t): int64 {.cdecl, exportc: "pairs_with_given_sum".} =
  if input.isNil or length == 0 or length > csize_t(MaxInputLength):
    return -2
  for index in 0 ..< int(length):
    if input[index] < -2147483648'i64 or input[index] > 2147483647'i64:
      return -2

  let target = input[0]
  let valueCount = int(length) - 1
  var pairs = 0'i64
  for left in 0 ..< valueCount:
    for right in (left + 1) ..< valueCount:
      if input[left + 1] + input[right + 1] == target:
        inc pairs
  pairs
