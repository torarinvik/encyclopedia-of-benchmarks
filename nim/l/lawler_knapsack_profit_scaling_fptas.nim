const MaxN = 8
const MaxInput = 19
const MaxQ = 32

proc lawler_knapsack_profit_scaling_fptas*(input: ptr UncheckedArray[int64],
    length: csize_t): int64 {.cdecl, exportc: "lawler_knapsack_profit_scaling_fptas".} =
  if input.isNil or length < 2 or length > csize_t(MaxInput): return -1
  let capacity = input[0]
  let n64 = input[1]
  if capacity < 1 or capacity > 30 or n64 < 4 or n64 > MaxN or
      length != csize_t(2 + 2 * int(n64)): return -1
  let n = int(n64)
  var weight: array[MaxN, int64]
  var profit: array[MaxN, int64]
  for i in 0..<n:
    weight[i] = input[2 + 2 * i]
    profit[i] = input[3 + 2 * i]
    if weight[i] < 1 or weight[i] > capacity or profit[i] < 32 or profit[i] > 200:
      return -1

  var order: array[MaxN, int]
  for i in 0..<n: order[i] = i
  for i in 1..<n:
    let key = order[i]
    var j = i
    while j > 0:
      let previous = order[j - 1]
      let left = profit[key] * weight[previous]
      let right = profit[previous] * weight[key]
      if left < right or (left == right and key > previous): break
      order[j] = previous
      dec j
    order[j] = key

  var prefixWeight = 0'i64
  var prefixProfit = 0'i64
  var prefixMask = 0'i64
  var p0 = 0'i64
  var exact = true
  for position in 0..<n:
    let item = order[position]
    if prefixWeight + weight[item] > capacity:
      exact = false
      p0 = prefixProfit
      for i in 0..<n:
        if profit[i] > p0: p0 = profit[i]
      break
    prefixWeight += weight[item]
    prefixProfit += profit[item]
    prefixMask = prefixMask or (1'i64 shl item)
    if prefixWeight == capacity: break
  if exact:
    return (prefixProfit shl 8) or prefixMask

  var small: array[MaxN, int]
  var smallCount = 0
  var groups: array[MaxQ + 1, array[MaxN, int]]
  var groupCount: array[MaxQ + 1, int]
  for item in 0..<n:
    if 4 * profit[item] <= p0:
      # The global ratio order is used below, so membership is recorded here.
      small[smallCount] = item
      inc smallCount
    else:
      var scaled = 0
      for exponent in 0..1:
        let scale = 1 shl exponent
        if int64(scale) * p0 < 4 * profit[item] and
            4 * profit[item] <= 2 * int64(scale) * p0:
          scaled = scale * int(16 * profit[item] div (int64(scale) * p0))
          break
      if scaled <= 0 or scaled > MaxQ: return -1
      groups[scaled][groupCount[scaled]] = item
      inc groupCount[scaled]

  # Keep small items in exact ratio order with input index as the tie break.
  var orderedSmall: array[MaxN, int]
  var orderedSmallCount = 0
  for position in 0..<n:
    let item = order[position]
    for j in 0..<smallCount:
      if small[j] == item:
        orderedSmall[orderedSmallCount] = item
        inc orderedSmallCount
        break

  var stateWeight: array[MaxQ + 1, int64]
  var stateMask: array[MaxQ + 1, int64]
  var stateProfit: array[MaxQ + 1, int64]
  for q in 0..MaxQ: stateWeight[q] = capacity + 1
  stateWeight[0] = 0

  for q in countdown(MaxQ, 1):
    if groupCount[q] == 0: continue
    for i in 1..<groupCount[q]:
      let key = groups[q][i]
      var j = i
      while j > 0 and (weight[groups[q][j - 1]] > weight[key] or
          (weight[groups[q][j - 1]] == weight[key] and groups[q][j - 1] > key)):
        groups[q][j] = groups[q][j - 1]
        dec j
      groups[q][j] = key
    let kept = min(groupCount[q], MaxQ div q)
    var nextWeight: array[MaxQ + 1, int64]
    var nextMask: array[MaxQ + 1, int64]
    var nextProfit: array[MaxQ + 1, int64]
    for dst in 0..MaxQ: nextWeight[dst] = capacity + 1
    for oldQ in 0..MaxQ:
      if stateWeight[oldQ] > capacity: continue
      block offerUnchanged:
        let dst = oldQ
        let nw = stateWeight[oldQ]
        let nm = stateMask[oldQ]
        let np = stateProfit[oldQ]
        if nw < nextWeight[dst] or (nw == nextWeight[dst] and
            (np > nextProfit[dst] or (np == nextProfit[dst] and nm < nextMask[dst]))):
          nextWeight[dst] = nw
          nextMask[dst] = nm
          nextProfit[dst] = np
      var addedWeight = 0'i64
      var addedProfit = 0'i64
      var addedMask = 0'i64
      for take in 0..<kept:
        let item = groups[q][take]
        addedWeight += weight[item]
        if stateWeight[oldQ] + addedWeight > capacity: break
        addedProfit += profit[item]
        addedMask = addedMask or (1'i64 shl item)
        let dst = oldQ + q * (take + 1)
        if dst > MaxQ: continue
        let nw = stateWeight[oldQ] + addedWeight
        let nm = stateMask[oldQ] or addedMask
        let np = stateProfit[oldQ] + addedProfit
        if nw < nextWeight[dst] or (nw == nextWeight[dst] and
            (np > nextProfit[dst] or (np == nextProfit[dst] and nm < nextMask[dst]))):
          nextWeight[dst] = nw
          nextMask[dst] = nm
          nextProfit[dst] = np
    var bestHigherWeight = capacity + 1
    for scaled in countdown(MaxQ, 0):
      if nextWeight[scaled] <= capacity and nextWeight[scaled] < bestHigherWeight:
        bestHigherWeight = nextWeight[scaled]
      else:
        nextWeight[scaled] = capacity + 1
        nextMask[scaled] = 0
        nextProfit[scaled] = 0
    stateWeight = nextWeight
    stateMask = nextMask
    stateProfit = nextProfit

  var bestScore = -1'i64
  var bestProfit = -1'i64
  var bestWeight = capacity + 1
  var bestMask = 0'i64
  for q in 0..MaxQ:
    if stateWeight[q] > capacity: continue
    var used = stateWeight[q]
    var actualProfit = stateProfit[q]
    var mask = stateMask[q]
    for j in 0..<orderedSmallCount:
      let item = orderedSmall[j]
      if used + weight[item] > capacity: break
      used += weight[item]
      actualProfit += profit[item]
      mask = mask or (1'i64 shl item)
    let smallProfit = actualProfit - stateProfit[q]
    let score = p0 * int64(q) + 16 * smallProfit
    if score > bestScore or (score == bestScore and
        (actualProfit > bestProfit or (actualProfit == bestProfit and
          (used < bestWeight or (used == bestWeight and mask < bestMask))))):
      bestScore = score
      bestProfit = actualProfit
      bestWeight = used
      bestMask = mask
  (bestProfit shl 8) or bestMask
