const MaxLength = 18

proc vogel_approximation_transportation*(input: ptr UncheckedArray[int64],
                                         length: csize_t): int64
    {.cdecl, exportc: "vogel_approximation_transportation".} =
  if input.isNil or length < 5 or length > csize_t(MaxLength): return -1
  if input[0] < 1 or input[0] > 3 or input[1] < 1 or input[1] > 3: return -1
  let rows = int(input[0])
  let cols = int(input[1])
  let cellCount = rows * cols
  if length != csize_t(2 + cellCount + rows + cols): return -1

  var costs: array[9, int64]
  var supply: array[3, int64]
  var demand: array[3, int64]
  var offset = 2
  for i in 0 ..< cellCount:
    let value = input[offset + i]
    if value < 0 or value > 9: return -1
    costs[i] = value
  offset += cellCount
  var supplyTotal = 0'i64
  var demandTotal = 0'i64
  for i in 0 ..< rows:
    let value = input[offset + i]
    if value < 1 or value > 3: return -1
    supply[i] = value
    supplyTotal += value
  offset += rows
  for j in 0 ..< cols:
    let value = input[offset + j]
    if value < 1 or value > 3: return -1
    demand[j] = value
    demandTotal += value
  if supplyTotal != demandTotal: return -1

  var activeRows: array[3, bool]
  var activeCols: array[3, bool]
  for i in 0 ..< 3:
    activeRows[i] = true
    activeCols[i] = true
  var allocation: array[9, int64]
  var totalCost = 0'i64
  var remaining = supplyTotal
  while remaining > 0:
    var bestKind = -1
    var bestLine = 0
    var bestPenalty = -1'i64
    for kind in 0 ..< 2:
      let lineCount = if kind == 0: rows else: cols
      let partnerCount = if kind == 0: cols else: rows
      for line in 0 ..< lineCount:
        if not (if kind == 0: activeRows[line] else: activeCols[line]): continue
        var first = 10'i64
        var second = 10'i64
        var found = 0
        for partner in 0 ..< partnerCount:
          if not (if kind == 0: activeCols[partner] else: activeRows[partner]): continue
          let row = if kind == 0: line else: partner
          let col = if kind == 0: partner else: line
          let value = costs[row * cols + col]
          if value < first:
            second = first
            first = value
          elif value < second:
            second = value
          inc found
        if found == 0: continue
        let penalty = if found == 1: 10'i64 else: second - first
        if penalty > bestPenalty:
          bestPenalty = penalty
          bestKind = kind
          bestLine = line
    if bestKind < 0: return -1
    let partnerCount = if bestKind == 0: cols else: rows
    var bestPartner = partnerCount
    var cheapest = 10'i64
    for partner in 0 ..< partnerCount:
      if not (if bestKind == 0: activeCols[partner] else: activeRows[partner]): continue
      let row = if bestKind == 0: bestLine else: partner
      let col = if bestKind == 0: partner else: bestLine
      let value = costs[row * cols + col]
      if value < cheapest:
        cheapest = value
        bestPartner = partner
    if bestPartner == partnerCount: return -1
    let row = if bestKind == 0: bestLine else: bestPartner
    let col = if bestKind == 0: bestPartner else: bestLine
    let quantity = min(supply[row], demand[col])
    allocation[row * 3 + col] = quantity
    totalCost += quantity * costs[row * cols + col]
    supply[row] -= quantity
    demand[col] -= quantity
    remaining -= quantity
    if supply[row] == 0: activeRows[row] = false
    if demand[col] == 0: activeCols[col] = false

  var signature = 0'i64
  var place = 1'i64
  for cell in 0 ..< 9:
    signature += allocation[cell] * place
    place *= 4
  totalCost * place + signature
