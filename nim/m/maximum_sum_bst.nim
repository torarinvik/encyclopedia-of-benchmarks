const
  MaxSlots = 31
  MaxValue = 1_000_000'i64
  EmptyMin = 1_000_001'i64

proc maximum_sum_bst*(input: ptr UncheckedArray[int64], length: csize_t): int64
    {.cdecl, exportc: "maximum_sum_bst".} =
  if input.isNil or length < 1 or length > 32: return -1
  if input[0] < 0 or input[0] > MaxSlots or length != csize_t(input[0]) + 1: return -1
  let count = int(input[0])
  for i in 0 ..< count:
    if input[i + 1] < -1 or input[i + 1] > MaxValue: return -1
    if input[i + 1] != -1 and i > 0 and input[(i - 1) div 2 + 1] == -1: return -1
  if count == 0: return 0
  var valid: array[MaxSlots, bool]
  var subtreeMin, subtreeMax, subtreeSum, best: array[MaxSlots, int64]
  for remaining in countdown(count - 1, 0):
    if input[remaining + 1] == -1:
      valid[remaining] = true
      subtreeMin[remaining] = EmptyMin
      subtreeMax[remaining] = -1
      continue
    let left = 2 * remaining + 1
    let right = left + 1
    let leftValid = left >= count or valid[left]
    let rightValid = right >= count or valid[right]
    let leftMax = if left < count: subtreeMax[left] else: -1'i64
    let rightMin = if right < count: subtreeMin[right] else: EmptyMin
    let leftMin = if left < count: subtreeMin[left] else: EmptyMin
    let rightMax = if right < count: subtreeMax[right] else: -1'i64
    let leftSum = if left < count: subtreeSum[left] else: 0'i64
    let rightSum = if right < count: subtreeSum[right] else: 0'i64
    let leftBest = if left < count: best[left] else: 0'i64
    let rightBest = if right < count: best[right] else: 0'i64
    let value = input[remaining + 1]
    if leftValid and rightValid and leftMax < value and value < rightMin:
      valid[remaining] = true
      subtreeMin[remaining] = min(leftMin, value)
      subtreeMax[remaining] = max(rightMax, value)
      subtreeSum[remaining] = leftSum + rightSum + value
      best[remaining] = max(subtreeSum[remaining], leftBest, rightBest)
    else:
      best[remaining] = max(leftBest, rightBest)
  best[0]
