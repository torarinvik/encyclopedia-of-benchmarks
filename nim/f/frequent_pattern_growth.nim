type GrowthContext = object
  minimum: int64
  order: array[8, int]
  result: int64

proc grow(ctx: var GrowthContext, masks, weights: array[64, int64], length, rankLimit: int) =
  for rank in countdown(rankLimit - 1, 0):
    let bit = 1'i64 shl ctx.order[rank]
    var support = 0'i64
    for i in 0 ..< length:
      if (masks[i] and bit) != 0: support += weights[i]
    if support < ctx.minimum: continue
    inc ctx.result
    var ancestor = 0'i64
    for r in 0 ..< rank: ancestor = ancestor or (1'i64 shl ctx.order[r])
    var nextMasks: array[64, int64]
    var nextWeights: array[64, int64]
    var nextLen = 0
    for i in 0 ..< length:
      if (masks[i] and bit) != 0:
        nextMasks[nextLen] = masks[i] and ancestor
        nextWeights[nextLen] = weights[i]
        inc nextLen
    grow(ctx, nextMasks, nextWeights, nextLen, rank)

proc frequent_pattern_growth*(a: ptr int64, length: csize_t): int64 {.cdecl, exportc: "frequent_pattern_growth".} =
  if a == nil or length < 3 or length > 67: return -1
  let values = cast[ptr UncheckedArray[int64]](a)
  let rows = values[0]
  let items = values[1]
  let minimum = values[2]
  if rows < 1 or rows > 64 or items < 1 or items > 8 or minimum < 1 or minimum > rows or length != csize_t(3 + rows): return -1
  let limit = 1'i64 shl items
  for row in 0 ..< int(rows):
    let mask = values[3 + row]
    if mask < 0 or mask >= limit: return -1
  var support: array[8, int]
  var ctx = GrowthContext(minimum: minimum, result: 0)
  var masks: array[64, int64]
  var weights: array[64, int64]
  for row in 0 ..< int(rows):
    masks[row] = values[3 + row]; weights[row] = 1
    for item in 0 ..< int(items):
      if (values[3 + row] and (1'i64 shl item)) != 0: inc support[item]
  for item in 0 ..< int(items): ctx.order[item] = item
  for i in 1 ..< int(items):
    let value = ctx.order[i]
    var j = i
    while j > 0 and (support[ctx.order[j - 1]] < support[value] or (support[ctx.order[j - 1]] == support[value] and ctx.order[j - 1] > value)):
      ctx.order[j] = ctx.order[j - 1]
      dec j
    ctx.order[j] = value
  grow(ctx, masks, weights, int(rows), int(items))
  ctx.result
