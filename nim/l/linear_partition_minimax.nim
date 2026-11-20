const MaxParseableInputLength = 35
const MaxN = 32

proc lpmFeasible(input: ptr UncheckedArray[int64], n, groups: int, limit: int64): bool =
  var usedGroups = 1
  var currentSum = 0'i64
  for i in 0..<n:
    let value = input[i + 2]
    if currentSum + value > limit:
      inc usedGroups
      currentSum = value
      if usedGroups > groups: return false
    else:
      currentSum += value
  true

proc linearPartitionMinimax*(input: ptr UncheckedArray[int64], length: csize_t): int64
    {.cdecl, exportc: "linear_partition_minimax".} =
  if input.isNil or length < 3 or length > MaxParseableInputLength: return -1
  if input[0] < 1 or input[0] > MaxN or input[1] < 1 or input[1] > input[0]: return -1
  let n = int(input[0])
  let groups = int(input[1])
  if int(length) != n + 2: return -1

  var low = 0'i64
  var upper = 0'i64
  for i in 0..<n:
    let value = input[i + 2]
    if value < 0 or value > 1000: return -1
    if value > low: low = value
    upper += value
  while low < upper:
    let middle = low + (upper - low) div 2
    if lpmFeasible(input, n, groups, middle): upper = middle
    else: low = middle + 1
  low
