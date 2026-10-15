## Count stones whose ASCII byte appears in the unique-jewel set.
const MaxJewelsLength = 127
const MaxStonesLength = 4096
const MaxPackedLength = 4225

proc jewels_and_stones*(input: ptr UncheckedArray[int64], length: csize_t): int64
    {.cdecl, exportc: "jewels_and_stones".} =
  if input == nil or length < 2 or length > csize_t(MaxPackedLength): return -1
  if input[0] < 0 or input[0] > MaxJewelsLength or input[1] < 0 or input[1] > MaxStonesLength: return -1
  let jewelCount = int(input[0])
  let stoneCount = int(input[1])
  if int(length) != 2 + jewelCount + stoneCount: return -1
  var counts: array[128, int64]
  for index in 0 ..< jewelCount:
    let value = input[2 + index]
    if value < 1 or value > 127 or counts[int(value)] != 0: return -1
    counts[int(value)] = 1
  var total = 0'i64
  let stoneStart = 2 + jewelCount
  for index in 0 ..< stoneCount:
    let value = input[stoneStart + index]
    if value < 1 or value > 127: return -1
    total += counts[int(value)]
  total
