const MaxItems = 512
const InvalidResult = -9_000_000_000_000_000_000'i64

proc siftDown(values: var array[MaxItems, int64], rootStart, endValue: int) =
  var root = rootStart
  while root < endValue div 2:
    var child = root * 2 + 1
    if child + 1 < endValue and values[child] < values[child + 1]: inc child
    if values[root] >= values[child]: break
    swap(values[root], values[child])
    root = child

proc heapSort(values: var array[MaxItems, int64], count: int) =
  for start in countdown(count div 2 - 1, 0): siftDown(values, start, count)
  for ending in countdown(count - 1, 1):
    swap(values[0], values[ending])
    siftDown(values, 0, ending)

proc absDifference(left, right: int64): int64 =
  let difference = left - right
  if difference < 0: -difference else: difference

proc three_sum_closest*(input: ptr UncheckedArray[int64], length: csize_t): int64
    {.cdecl, exportc: "three_sum_closest".} =
  if length < 2 or length > csize_t(MaxItems + 2): return InvalidResult
  let target = input[0]
  let countValue = input[1]
  if target < -2_147_483_648'i64 or target > 2_147_483_647'i64 or countValue < 3 or countValue > MaxItems:
    return InvalidResult
  let count = int(countValue)
  if int(length) != count + 2: return InvalidResult
  var values: array[MaxItems, int64]
  for index in 0 ..< count:
    let value = input[index + 2]
    if value < -2_147_483_648'i64 or value > 2_147_483_647'i64: return InvalidResult
    values[index] = value
  heapSort(values, count)
  var best = values[0] + values[1] + values[2]
  var bestDifference = absDifference(target, best)
  for first in 0 ..< count - 2:
    var left = first + 1
    var right = count - 1
    while left < right:
      let sum = values[first] + values[left] + values[right]
      let difference = absDifference(target, sum)
      if difference < bestDifference or (difference == bestDifference and sum < best):
        best = sum
        bestDifference = difference
      if sum < target: inc left
      elif sum > target: dec right
      else: return sum
  best
