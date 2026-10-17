const MaxCount = 30
const MaxTarget = 64'i64
const MaxValue = 64'i64
const MaxInputLength = 33

proc subset_count*(values: ptr UncheckedArray[int64], length: csize_t): int64
    {.cdecl, exportc: "subset_count".} =
  if values.isNil or length < 2 or length > csize_t(MaxInputLength): return -1

  let countValue = values[0]
  let targetValue = values[1]
  if countValue < 1 or countValue > int64(MaxCount) or targetValue < 0 or targetValue > MaxTarget: return -1
  let count = int(countValue)
  if int(length) != count + 2: return -1

  for index in 0 ..< count:
    let value = values[index + 2]
    if value < 0 or value > MaxValue: return -1

  var previous: array[65, int64]
  previous[0] = 1
  if values[2] <= targetValue:
    previous[int(values[2])] = 1

  let target = int(targetValue)
  for index in 1 ..< count:
    var current: array[65, int64]
    current[0] = 1
    for amount in 1 .. target:
      let value = values[index + 2]
      let notTaken = previous[amount]
      let taken = if value <= int64(amount): previous[amount - int(value)] else: 0'i64
      current[amount] = notTaken + taken
    previous = current
  previous[target]
