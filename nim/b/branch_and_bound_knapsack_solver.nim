## Breadth-first branch-and-bound for bounded 0/1 knapsack.
const MaxItems = 8
const MaxNodes = 511

type SearchNode = object
  level: int32
  weight: int32
  value: int32
  mask: int32

proc upperBound(weights, itemValues: array[MaxItems, int32],
    count, capacity, level, weight, value: int32): float64 =
  var available = capacity - weight
  var bound = float64(value)
  var next = level + 1
  while available > 0 and next < count:
    if weights[next] <= available:
      bound += float64(itemValues[next])
      available -= weights[next]
    else:
      bound += float64(itemValues[next]) / float64(weights[next]) * float64(available)
      available = 0
    inc next
  bound

proc branch_and_bound_knapsack_solver*(input: ptr UncheckedArray[int64], length: csize_t,
    output: ptr UncheckedArray[uint8], outputCapacity: csize_t): int64
    {.cdecl, exportc: "branch_and_bound_knapsack_solver".} =
  if input == nil or length < 2 or length > 18: return -1
  if input[0] < 0 or input[0] > MaxItems or input[1] < 0 or input[1] > 8000: return -1
  let count = int(input[0])
  let capacity = int32(input[1])
  if int(length) != 2 + 2 * count: return -1

  var weights: array[MaxItems, int32]
  var itemValues: array[MaxItems, int32]
  var itemIds: array[MaxItems, int32]
  for index in 0 ..< count:
    let weight = input[2 + 2 * index]
    let value = input[3 + 2 * index]
    if weight < 1 or weight > 1000 or value < 1 or value > 1000: return -1
    var position = index
    while position > 0 and value * int64(weights[position - 1]) >
        int64(itemValues[position - 1]) * weight:
      weights[position] = weights[position - 1]
      itemValues[position] = itemValues[position - 1]
      itemIds[position] = itemIds[position - 1]
      dec position
    weights[position] = int32(weight)
    itemValues[position] = int32(value)
    itemIds[position] = int32(index)

  var queue: array[MaxNodes, SearchNode]
  var head = 0
  var tail = 1
  queue[0] = SearchNode(level: -1, weight: 0, value: 0, mask: 0)
  var bestValue = 0'i32
  var bestMask = 0'i32
  while head < tail:
    let parent = queue[head]
    inc head
    if parent.level == int32(count - 1): continue
    let next = int(parent.level + 1)
    let left = SearchNode(level: int32(next), weight: parent.weight + weights[next],
      value: parent.value + itemValues[next], mask: parent.mask or (1'i32 shl next))
    let right = SearchNode(level: int32(next), weight: parent.weight,
      value: parent.value, mask: parent.mask)
    if left.weight <= capacity and left.value > bestValue:
      bestValue = left.value
      bestMask = left.mask
    if upperBound(weights, itemValues, int32(count), capacity, left.level, left.weight, left.value) >
        float64(bestValue) and left.weight < capacity:
      queue[tail] = left
      inc tail
    if upperBound(weights, itemValues, int32(count), capacity, right.level, right.weight, right.value) >
        float64(bestValue):
      queue[tail] = right
      inc tail

  var selected: array[MaxItems, uint8]
  var selectedCount = 0
  for level in countdown(count - 1, 0):
    if (bestMask and (1'i32 shl level)) != 0:
      selected[selectedCount] = uint8(itemIds[level])
      inc selectedCount
  if csize_t(selectedCount) > outputCapacity or (selectedCount != 0 and output == nil): return -2
  for index in 0 ..< selectedCount: output[index] = selected[index]
  int64(selectedCount)
