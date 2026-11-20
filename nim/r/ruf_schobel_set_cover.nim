const
  MaxRows = 6
  MaxColumns = 8
  MaxInput = 17
  MaxStack = 32

proc storeI64Le(output: ptr UncheckedArray[uint8], value: int64) =
  var bits = cast[uint64](value)
  for byte in 0 ..< 8:
    output[byte] = uint8(bits and 255)
    bits = bits shr 8

proc intervalCover(left, right: array[MaxRows, int], count: int,
                   weights: array[MaxColumns, int64], columns: int,
                   outCost, outMask: var int64): bool =
  if count == 0:
    outCost = 0
    outMask = 0
    return true
  var minimumRight = right[0]
  var maximumLeft = left[0]
  for i in 1 ..< count:
    minimumRight = min(minimumRight, right[i])
    maximumLeft = max(maximumLeft, left[i])
  var costs: array[MaxColumns, int64]
  var masks: array[MaxColumns, int64]
  for point in 0 ..< columns: costs[point] = 1_000_000
  for point in 0 ..< columns:
    if point <= minimumRight:
      costs[point] = weights[point]
      masks[point] = 1'i64 shl point
    for previous in 0 ..< point:
      if costs[previous] == 1_000_000: continue
      var blocked = false
      for i in 0 ..< count:
        if previous < left[i] and right[i] < point:
          blocked = true
          break
      if blocked: continue
      let candidateCost = costs[previous] + weights[point]
      let candidateMask = masks[previous] or (1'i64 shl point)
      if candidateCost < costs[point] or
          (candidateCost == costs[point] and candidateMask < masks[point]):
        costs[point] = candidateCost
        masks[point] = candidateMask
  outCost = 1_000_000
  outMask = 0
  for point in maximumLeft ..< columns:
    if costs[point] < outCost or
        (costs[point] == outCost and costs[point] != 1_000_000 and masks[point] < outMask):
      outCost = costs[point]
      outMask = masks[point]
  outCost != 1_000_000

proc ruf_schobel_set_cover*(input: ptr UncheckedArray[int64], length: csize_t,
    output: ptr UncheckedArray[uint8], capacity: csize_t): int64
    {.cdecl, exportc: "ruf_schobel_set_cover".} =
  if input == nil or length < 4 or length > csize_t(MaxInput): return -1
  let rowsRaw = input[0]
  let columnsRaw = input[1]
  if rowsRaw < 1 or rowsRaw > MaxRows or columnsRaw < 1 or columnsRaw > MaxColumns: return -1
  let rows = int(rowsRaw)
  let columns = int(columnsRaw)
  if int(length) != 2 + rows + columns: return -1
  var weights: array[MaxColumns, int64]
  for column in 0 ..< columns:
    let weight = input[2 + column]
    if weight < 1 or weight > 20: return -1
    weights[column] = weight
  let allowed = (1'u64 shl columns) - 1
  var rowMasks: array[MaxRows, uint64]
  var blockLeft, blockRight: array[MaxRows, array[MaxColumns, int]]
  var blockCount: array[MaxRows, int]
  for row in 0 ..< rows:
    let raw = input[2 + columns + row]
    if raw < 0 or (uint64(raw) and not allowed) != 0: return -1
    rowMasks[row] = uint64(raw)
    var column = 0
    while column < columns:
      if (rowMasks[row] and (1'u64 shl column)) == 0:
        inc column
        continue
      let block = blockCount[row]
      blockLeft[row][block] = column
      while column + 1 < columns and (rowMasks[row] and (1'u64 shl (column + 1))) != 0:
        inc column
      blockRight[row][block] = column
      inc blockCount[row]
      inc column

  for row in 0 ..< rows:
    if rowMasks[row] == 0:
      if output == nil or capacity < 8: return -2
      storeI64Le(output, -1)
      return 8

  var bestCost = 1_000_000'i64
  var stack: array[MaxStack, array[MaxRows, int]]
  var stackSize = 1
  for row in 0 ..< rows: stack[0][row] = -1
  while stackSize > 0:
    dec stackSize
    let fixed = stack[stackSize]
    var left, right: array[MaxRows, int]
    var count = 0
    for row in 0 ..< rows:
      if blockCount[row] == 1 or fixed[row] >= 0:
        let block = if blockCount[row] == 1: 0 else: fixed[row]
        left[count] = blockLeft[row][block]
        right[count] = blockRight[row][block]
        inc count
    var lowerCost, lowerMask: int64
    if not intervalCover(left, right, count, weights, columns, lowerCost, lowerMask): continue
    var extraLeft, extraRight: array[MaxRows, int]
    var extraCount = 0
    for row in 0 ..< rows:
      if (rowMasks[row] and uint64(lowerMask)) != 0: continue
      var chosen = 0
      var chosenCost = 1_000_000'i64
      for block in 0 ..< blockCount[row]:
        var cheapest = 1_000_000'i64
        for column in blockLeft[row][block] .. blockRight[row][block]:
          cheapest = min(cheapest, weights[column])
        if cheapest < chosenCost:
          chosenCost = cheapest
          chosen = block
      extraLeft[extraCount] = blockLeft[row][chosen]
      extraRight[extraCount] = blockRight[row][chosen]
      inc extraCount
    var extraCost, extraMask: int64
    if not intervalCover(extraLeft, extraRight, extraCount, weights, columns, extraCost, extraMask): continue
    let candidateMask = lowerMask or extraMask
    var candidateCost = 0'i64
    for column in 0 ..< columns:
      if (candidateMask and (1'i64 shl column)) != 0: candidateCost += weights[column]
    bestCost = min(bestCost, candidateCost)
    if bestCost <= lowerCost: continue
    var branch = -1
    for row in 0 ..< rows:
      if blockCount[row] > 1 and fixed[row] < 0:
        branch = row
        break
    if branch < 0: continue
    for block in countdown(blockCount[branch] - 1, 0):
      for row in 0 ..< rows: stack[stackSize][row] = fixed[row]
      stack[stackSize][branch] = block
      inc stackSize

  let result = if bestCost == 1_000_000: -1'i64 else: bestCost
  if output == nil or capacity < 8: return -2
  storeI64Le(output, result)
  8
