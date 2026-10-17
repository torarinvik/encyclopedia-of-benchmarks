const MaxCount = 64
const MaxInputLength = MaxCount + 5
const I32Min = -2_147_483_648'i64
const I32Max = 2_147_483_647'i64

proc linearSearchThread*(input: ptr UncheckedArray[int64], length: csize_t): int64
    {.cdecl, exportc: "linear_search_thread".} =
  if input == nil or length < 4 or length > csize_t(MaxInputLength): return -1
  let countArg = input[0]
  let left = input[1]
  let right = input[2]
  let target = input[3]
  if countArg < 1 or countArg > MaxCount or length != csize_t(countArg) + 4: return -1
  if left < 0 or left > right or right > countArg or target < I32Min or target > I32Max:
    return -1
  let count = int(countArg)
  for index in 0 ..< count:
    let value = input[index + 4]
    if value < I32Min or value > I32Max: return -1
  for index in int(left) ..< int(right):
    if input[index + 4] == target: return 1
  0
