type I64Array = ptr UncheckedArray[int64]

const
  MaxLeft = 8
  MaxRight = 8
  MaxInput = 67
  MaxStates = 256
  Inf = 1'i64 shl 60

proc minimum_cost_bipartite_edge_cover_subset_dp*(input: I64Array, length: csize_t): int64
    {.cdecl, exportc: "minimum_cost_bipartite_edge_cover_subset_dp".} =
  if input.isNil or length < 2 or length > csize_t(MaxInput): return -1
  let leftValue = input[0]
  let rightValue = input[1]
  if leftValue < 1 or leftValue > MaxLeft or rightValue < 1 or rightValue > MaxRight: return -1
  let leftCount = int(leftValue)
  let rightCount = int(rightValue)
  if int(length) != 2 + leftCount * rightCount: return -1
  for edge in 0 ..< leftCount * rightCount:
    if input[2 + edge] < 0 or input[2 + edge] > 1000: return -1

  let states = 1 shl rightCount
  var current: array[MaxStates, int64]
  var following: array[MaxStates, int64]
  var subsetCost: array[MaxStates, int64]
  for mask in 0 ..< states: current[mask] = Inf
  current[0] = 0
  for left in 0 ..< leftCount:
    subsetCost[0] = 0
    for subset in 1 ..< states:
      let lowBit = subset and -subset
      var right = 0
      var scan = lowBit
      while scan > 1:
        scan = scan shr 1
        inc right
      subsetCost[subset] = subsetCost[subset xor lowBit] + input[2 + left * rightCount + right]
    for mask in 0 ..< states: following[mask] = Inf
    for covered in 0 ..< states:
      if current[covered] == Inf: continue
      for selected in 1 ..< states:
        let combined = covered or selected
        let candidate = current[covered] + subsetCost[selected]
        if candidate < following[combined]: following[combined] = candidate
    swap(current, following)
  current[states - 1]
