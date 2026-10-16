proc find_min_iterator*(input: ptr UncheckedArray[int64], length: csize_t): int64
    {.cdecl, exportc: "find_min_iterator".} =
  if input.isNil or length < 1 or length > 129: return -1
  if input[0] < 0 or input[0] > 128 or length != csize_t(input[0]) + 1: return -1
  let count = int(input[0])
  if count == 0: return -1
  var minimum = 2_147_483_647'i64
  for i in 0 ..< count:
    let value = input[i + 1]
    if value < 0 or value > 2_147_483_647: return -1
    if value < minimum: minimum = value
  minimum
