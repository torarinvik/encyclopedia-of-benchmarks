const
  MaxItems = 5
  MaxAtoms = 3
  MaxInput = 43
  MaxOutputWords = 9

proc storeI64Le(output: ptr UncheckedArray[uint8], offset: int, value: int64) =
  let bits = cast[uint64](value)
  for byte in 0 ..< 8: output[offset + byte] = uint8((bits shr (8 * byte)) and 255)

proc densityBefore(left, right: int, rewards, fits, means: array[MaxItems, int64]): bool =
  let leftScore = rewards[left] * fits[left] * means[right]
  let rightScore = rewards[right] * fits[right] * means[left]
  leftScore > rightScore or (leftScore == rightScore and left < right)

proc stochastic_knapsack_greedy*(input: ptr UncheckedArray[int64], length: csize_t,
    output: ptr UncheckedArray[uint8], capacity: csize_t): int64
    {.cdecl, exportc: "stochastic_knapsack_greedy".} =
  if input.isNil or length < csize_t(2) or length > csize_t(MaxInput): return -1
  let nRaw, boundRaw = input[0], input[1]
  if nRaw < 1 or nRaw > MaxItems or boundRaw < 1 or boundRaw > 8: return -1
  let n, bound = int(nRaw), int(boundRaw)
  var rewards: array[MaxItems, int64]
  var atomCounts: array[MaxItems, int]
  var denominators, fits, means: array[MaxItems, int64]
  var sizes: array[MaxItems, array[MaxAtoms, int64]]
  var weights: array[MaxItems, array[MaxAtoms, int64]]
  var position = 2
  for item in 0 ..< n:
    if position + 2 > int(length): return -1
    let reward, atomCountRaw = input[position], input[position + 1]
    position += 2
    if reward < 0 or reward > 20 or atomCountRaw < 1 or atomCountRaw > MaxAtoms: return -1
    rewards[item] = reward
    atomCounts[item] = int(atomCountRaw)
    for atom in 0 ..< atomCounts[item]:
      if position + 2 > int(length): return -1
      let size, weight = input[position], input[position + 1]
      position += 2
      if size < 0 or size > bound + 1 or weight < 1 or weight > 3: return -1
      sizes[item][atom] = size
      weights[item][atom] = weight
      denominators[item] += weight
      if size <= bound: fits[item] += weight
      means[item] += min(size, int64(bound)) * weight
    if denominators[item] > 9 or means[item] == 0: return -1
  if position != int(length): return -1

  var order: array[MaxItems, int]
  for i in 0 ..< n:
    var j = i
    while j > 0 and densityBefore(i, order[j - 1], rewards, fits, means):
      order[j] = order[j - 1]
      dec j
    order[j] = i
  var bestSingle = 0
  for i in 1 ..< n:
    let leftScore = rewards[i] * fits[i] * denominators[bestSingle]
    let rightScore = rewards[bestSingle] * fits[bestSingle] * denominators[i]
    if leftScore > rightScore: bestSingle = i

  var jointDenominator = 1'i64
  var scenarioCount = 1
  for i in 0 ..< n:
    jointDenominator *= denominators[i]
    scenarioCount *= atomCounts[i]
  var singletonScore, orderScore = 0'i64
  for scenario in 0 ..< scenarioCount:
    var digits = scenario
    var scenarioWeight = 1'i64
    var selectedSize: array[MaxItems, int64]
    for item in 0 ..< n:
      let atom = digits mod atomCounts[item]
      digits = digits div atomCounts[item]
      selectedSize[item] = sizes[item][atom]
      scenarioWeight *= weights[item][atom]
    if selectedSize[bestSingle] <= bound: singletonScore += scenarioWeight * rewards[bestSingle]
    var used = 0'i64
    var earned = 0'i64
    for rank in 0 ..< n:
      let item = order[rank]
      if used + selectedSize[item] > bound: break
      used += selectedSize[item]
      earned += rewards[item]
    orderScore += scenarioWeight * earned

  let useOrder = orderScore > singletonScore
  let outputCount = if useOrder: n else: 1
  var staged: array[MaxOutputWords, int64]
  staged[0] = if useOrder: 1 else: 0
  staged[1] = int64(outputCount)
  for i in 0 ..< outputCount: staged[2 + i] = int64(if useOrder: order[i] else: bestSingle)
  staged[2 + outputCount] = if useOrder: orderScore else: singletonScore
  staged[3 + outputCount] = jointDenominator
  let words = outputCount + 4
  let bytes = words * 8
  if output.isNil or capacity < csize_t(bytes): return -2
  for word in 0 ..< words: storeI64Le(output, word * 8, staged[word])
  int64(bytes)
