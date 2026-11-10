## Compare lowercase ASCII strings by their letter frequencies.
proc valid_anagram*(input: ptr UncheckedArray[int64], length: csize_t): int64
    {.cdecl, exportc: "valid_anagram".} =
  if length < 2 or length > 2050: return -1
  let first = cast[uint64](input[0])
  let second = cast[uint64](input[1])
  if first > 1024 or second > 1024 or length != 2 + first + second: return -1
  if first != second:
    for i in 2 ..< int(length):
      if cast[uint64](input[i]) - 97 > 25: return -1
    return 0

  var counts: array[26, uint16]
  let count = int(first)
  for i in 2 ..< 2 + count:
    let left = cast[uint64](input[i]) - 97
    let right = cast[uint64](input[i + count]) - 97
    if left > 25 or right > 25: return -1
    if left != right:
      counts[int(left)] += 1
      counts[int(right)] -= 1
  for balance in counts:
    if balance != 0: return 0
  1
