const MaxN = 64
const MinValue = -1_000_000'i64
const MaxValue = 1_000_000'i64

proc interpolation_sequential_search*(input: ptr UncheckedArray[int64], length: csize_t): int64
    {.cdecl, exportc: "interpolation_sequential_search".} =
  if input == nil or length < 2 or length > csize_t(MaxN + 3): return -1
  let countValue = input[0]
  let target = input[1]
  if countValue < 0 or countValue > MaxN or length != csize_t(countValue + 2): return -1
  if target < MinValue or target > MaxValue: return -1
  let count = int(countValue)
  for i in 0 ..< count:
    let value = input[i + 2]
    if value < MinValue or value > MaxValue: return -1
    if i > 0 and input[i + 1] >= value: return -1
  if count == 0: return -1
  let first = input[2]
  let last = input[count + 1]
  if target < first or target > last: return -1
  if count == 1:
    if first == target: return 0
    return -1
  let position = int((target - first) * int64(count - 1) div (last - first))
  let estimated = input[position + 2]
  if estimated == target: return int64(position)
  if estimated < target:
    for i in position + 1 ..< count:
      let value = input[i + 2]
      if value >= target:
        if value == target: return int64(i)
        return -1
  else:
    var i = position
    while i > 0:
      dec i
      let value = input[i + 2]
      if value <= target:
        if value == target: return int64(i)
        return -1
  return -1
