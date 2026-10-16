const MaxValues = 25
const MaxInputLength = 28

proc insertionSort(values: var array[MaxValues, int64], start, finish: int) =
  for index in start + 1 ..< finish:
    let value = values[index]
    var position = index
    while position > start and values[position - 1] > value:
      values[position] = values[position - 1]
      dec position
    values[position] = value

proc insertionSortSmall(values: var array[5, int64], finish: int) =
  for index in 1 ..< finish:
    let value = values[index]
    var position = index
    while position > 0 and values[position - 1] > value:
      values[position] = values[position - 1]
      dec position
    values[position] = value

proc selectKth(values: var array[MaxValues, int64], length, rank: int): int64 =
  var medians: array[5, int64]
  var medianCount = 0
  var start = 0
  while start < length:
    let finish = min(start + 5, length)
    insertionSort(values, start, finish)
    medians[medianCount] = values[(start + finish) div 2]
    inc medianCount
    start += 5
  insertionSortSmall(medians, medianCount)
  let pivot = medians[(medianCount - 1) div 2]

  var lower, higher: array[MaxValues, int64]
  var lowerCount = 0
  var higherCount = 0
  for index in 0 ..< length:
    if values[index] < pivot:
      lower[lowerCount] = values[index]
      inc lowerCount
    elif values[index] > pivot:
      higher[higherCount] = values[index]
      inc higherCount
  if rank < lowerCount:
    return selectKth(lower, lowerCount, rank)
  if rank > lowerCount:
    return selectKth(higher, higherCount, rank - lowerCount - 1)
  pivot

proc median_search*(input: ptr UncheckedArray[int64], length: csize_t): int64
    {.cdecl, exportc: "median_search".} =
  if input.isNil or length < 3 or length > csize_t(MaxInputLength): return -1
  let countValue = input[0]
  let rankValue = input[1]
  if countValue < 1 or countValue > int64(MaxValues) or rankValue < 0 or rankValue >= countValue:
    return -1
  let count = int(countValue)
  if length != csize_t(count + 2): return -1

  var values: array[MaxValues, int64]
  for index in 0 ..< count:
    let value = input[index + 2]
    if value < 0 or value > 2_147_483_647: return -1
    for previous in 0 ..< index:
      if values[previous] == value: return -1
    values[index] = value
  selectKth(values, count, int(rankValue))
