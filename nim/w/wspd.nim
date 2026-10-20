import std/math

const MaxPoints = 8
const MaxNodes = 15
const MaxPairs = 28
const MaxOutputBytes = 456

type
  WspdNode = object
    left, right, count: int
    mask: uint64
    centerX, centerY, radius: float64
  WspdContext = object
    x, y: array[MaxPoints, int64]
    nodes: array[MaxNodes, WspdNode]
    leftMasks, rightMasks: array[MaxPairs, uint64]
    nextNode, pairCount, pointCount, separation: int
    overflow: bool

proc pointLess(ctx: WspdContext, a, b, axis: int): bool =
  let a0 = if axis == 0: ctx.x[a] else: ctx.y[a]
  let b0 = if axis == 0: ctx.x[b] else: ctx.y[b]
  let a1 = if axis == 0: ctx.y[a] else: ctx.x[a]
  let b1 = if axis == 0: ctx.y[b] else: ctx.x[b]
  a0 < b0 or (a0 == b0 and (a1 < b1 or (a1 == b1 and a < b)))

proc buildNode(ctx: var WspdContext, mask: uint64): int =
  let id = ctx.nextNode
  inc ctx.nextNode
  ctx.nodes[id].left = -1
  ctx.nodes[id].right = -1
  ctx.nodes[id].mask = mask
  var members: array[MaxPoints, int]
  var used = 0
  var minX, maxX, minY, maxY: int64
  for i in 0 ..< ctx.pointCount:
    if (mask and (1'u64 shl i)) != 0:
      if used == 0:
        minX = ctx.x[i]; maxX = ctx.x[i]; minY = ctx.y[i]; maxY = ctx.y[i]
      else:
        if ctx.x[i] < minX: minX = ctx.x[i]
        if ctx.x[i] > maxX: maxX = ctx.x[i]
        if ctx.y[i] < minY: minY = ctx.y[i]
        if ctx.y[i] > maxY: maxY = ctx.y[i]
      members[used] = i
      inc used
  ctx.nodes[id].count = used
  ctx.nodes[id].centerX = (float64(minX) + float64(maxX)) / 2.0
  ctx.nodes[id].centerY = (float64(minY) + float64(maxY)) / 2.0
  let halfX = (float64(maxX) - float64(minX)) / 2.0
  let halfY = (float64(maxY) - float64(minY)) / 2.0
  ctx.nodes[id].radius = sqrt(halfX * halfX + halfY * halfY)
  if used == 1: return id
  let axis = if maxX - minX >= maxY - minY: 0 else: 1
  for i in 1 ..< used:
    let value = members[i]
    var j = i
    while j > 0 and pointLess(ctx, value, members[j - 1], axis):
      members[j] = members[j - 1]
      dec j
    members[j] = value
  var leftMask = 0'u64
  var rightMask = 0'u64
  let middle = used div 2
  for i in 0 ..< used:
    if i < middle: leftMask = leftMask or (1'u64 shl members[i])
    else: rightMask = rightMask or (1'u64 shl members[i])
  let left = buildNode(ctx, leftMask)
  let right = buildNode(ctx, rightMask)
  ctx.nodes[id].left = left
  ctx.nodes[id].right = right
  id

proc wellSeparated(ctx: WspdContext, a, b: int): bool =
  let first = ctx.nodes[a]
  let second = ctx.nodes[b]
  let radius = max(first.radius, second.radius)
  let dx = first.centerX - second.centerX
  let dy = first.centerY - second.centerY
  sqrt(dx * dx + dy * dy) - 2.0 * radius > float64(ctx.separation) * radius

proc crossNodes(ctx: var WspdContext, a, b: int) =
  if ctx.overflow: return
  if wellSeparated(ctx, a, b):
    if ctx.pairCount >= MaxPairs:
      ctx.overflow = true
      return
    ctx.leftMasks[ctx.pairCount] = ctx.nodes[a].mask
    ctx.rightMasks[ctx.pairCount] = ctx.nodes[b].mask
    inc ctx.pairCount
    return
  if ctx.nodes[a].radius > ctx.nodes[b].radius:
    crossNodes(ctx, ctx.nodes[a].left, b)
    crossNodes(ctx, ctx.nodes[a].right, b)
  else:
    crossNodes(ctx, a, ctx.nodes[b].left)
    crossNodes(ctx, a, ctx.nodes[b].right)

proc visitNode(ctx: var WspdContext, id: int) =
  let left = ctx.nodes[id].left
  let right = ctx.nodes[id].right
  if left < 0: return
  visitNode(ctx, left)
  visitNode(ctx, right)
  crossNodes(ctx, left, right)

proc putI64(output: var array[MaxOutputBytes, uint8], offset: int, value: int64) =
  var bits = cast[uint64](value)
  for byte in 0 ..< 8:
    output[offset + byte] = uint8(bits and 255)
    bits = bits shr 8

proc wspd*(values: ptr UncheckedArray[int64], length: csize_t,
           output: ptr UncheckedArray[uint8], capacity: csize_t): int64
    {.cdecl, exportc: "wspd".} =
  if values.isNil or length < csize_t(4) or length > csize_t(18): return -1
  if values[0] < 1 or values[0] > int64(MaxPoints) or values[1] < 1 or values[1] > 8: return -1
  let count = int(values[0])
  if length != csize_t(2 + 2 * count): return -1
  var ctx: WspdContext
  ctx.pointCount = count
  ctx.separation = int(values[1])
  for i in 0 ..< count:
    let x = values[2 + 2 * i]
    let y = values[3 + 2 * i]
    if x < -1000 or x > 1000 or y < -1000 or y > 1000: return -1
    for j in 0 ..< i:
      if ctx.x[j] == x and ctx.y[j] == y: return -1
    ctx.x[i] = x
    ctx.y[i] = y
  let root = buildNode(ctx, (1'u64 shl count) - 1)
  visitNode(ctx, root)
  if ctx.overflow: return -2
  let required = 8 + 16 * ctx.pairCount
  var staged: array[MaxOutputBytes, uint8]
  putI64(staged, 0, int64(ctx.pairCount))
  for i in 0 ..< ctx.pairCount:
    putI64(staged, 8 + 16 * i, int64(ctx.leftMasks[i]))
    putI64(staged, 16 + 16 * i, int64(ctx.rightMasks[i]))
  if output.isNil or capacity < csize_t(required): return -2
  for i in 0 ..< required: output[i] = staged[i]
  int64(required)
