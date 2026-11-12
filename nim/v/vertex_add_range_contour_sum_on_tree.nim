import std/strutils

const
  MaxN = 64
  MaxQ = 128
  MaxLevel = 8
  MaxInputValues = 3 * MaxN + 4 * MaxQ + 1
  MaxAbsValue = 1_000_000'i64

type
  Context = object
    n: int
    degree: array[MaxN, int]
    adjacent: array[MaxN, array[MaxN, int]]
    removed: array[MaxN, bool]
    parent: array[MaxN, int]
    subtreeSize: array[MaxN, int]
    ancestor: array[MaxN, array[MaxLevel, int]]
    distance: array[MaxN, array[MaxLevel, int]]
    branchFor: array[MaxN, array[MaxLevel, int]]
    pathLength: array[MaxN, int]
    branchCount: int
    total: array[MaxN, array[MaxN + 1, int64]]
    branch: array[MaxN, array[MaxN + 1, int64]]

proc collectComponent(ctx: var Context, start: int,
                      order: var array[MaxN, int]): int =
  var stack: array[MaxN, int]
  var top = 1
  result = 0
  ctx.parent[start] = -1
  stack[0] = start
  while top > 0:
    dec top
    let u = stack[top]
    order[result] = u
    inc result
    for i in 0 ..< ctx.degree[u]:
      let v = ctx.adjacent[u][i]
      if ctx.removed[v] or v == ctx.parent[u]: continue
      ctx.parent[v] = u
      stack[top] = v
      inc top
  for index in countdown(result - 1, 0):
    let u = order[index]
    ctx.subtreeSize[u] = 1
    for i in 0 ..< ctx.degree[u]:
      let v = ctx.adjacent[u][i]
      if not ctx.removed[v] and ctx.parent[v] == u:
        ctx.subtreeSize[u] += ctx.subtreeSize[v]

proc decompose(ctx: var Context, start, level: int) =
  var order: array[MaxN, int]
  let count = collectComponent(ctx, start, order)
  var center = start
  for index in 0 ..< count:
    let u = order[index]
    var largest = count - ctx.subtreeSize[u]
    for i in 0 ..< ctx.degree[u]:
      let v = ctx.adjacent[u][i]
      if not ctx.removed[v] and ctx.parent[v] == u:
        largest = max(largest, ctx.subtreeSize[v])
    if 2 * largest <= count:
      center = u
      break

  ctx.removed[center] = true
  ctx.ancestor[center][level] = center
  ctx.distance[center][level] = 0
  ctx.branchFor[center][level] = -1
  ctx.pathLength[center] = level + 1
  for edge in 0 ..< ctx.degree[center]:
    let root = ctx.adjacent[center][edge]
    if ctx.removed[root]: continue
    let branchId = ctx.branchCount
    inc ctx.branchCount
    var nodes, parents, distances: array[MaxN, int]
    var top = 1
    nodes[0] = root
    parents[0] = center
    distances[0] = 1
    while top > 0:
      dec top
      let u = nodes[top]
      let p = parents[top]
      let d = distances[top]
      ctx.ancestor[u][level] = center
      ctx.distance[u][level] = d
      ctx.branchFor[u][level] = branchId
      ctx.pathLength[u] = level + 1
      for i in 0 ..< ctx.degree[u]:
        let v = ctx.adjacent[u][i]
        if ctx.removed[v] or v == p: continue
        nodes[top] = v
        parents[top] = u
        distances[top] = d + 1
        inc top
    decompose(ctx, root, level + 1)

proc fenwickAdd(row: var array[MaxN + 1, int64], position: int, delta: int64) =
  var index = position + 1
  while index <= MaxN:
    row[index] += delta
    index += index and -index

proc fenwickPrefix(row: array[MaxN + 1, int64], count: int): int64 =
  var index = count
  while index > 0:
    result += row[index]
    index -= index and -index

proc rowRange(row: array[MaxN + 1, int64], left, right: int): int64 =
  let l = max(0, min(MaxN, left))
  let r = max(0, min(MaxN, right))
  if r > l: result = fenwickPrefix(row, r) - fenwickPrefix(row, l)

proc storeI64Le(output: ptr UncheckedArray[uint8], offset: int, value: int64) =
  let bits = cast[uint64](value)
  for byte in 0 ..< 8:
    output[offset + byte] = uint8((bits shr (8 * byte)) and 255)

proc vertex_add_range_contour_sum_on_tree*(input: ptr UncheckedArray[int64],
    length: csize_t, output: ptr UncheckedArray[uint8], capacity: csize_t): int64
    {.cdecl, exportc: "vertex_add_range_contour_sum_on_tree".} =
  if input.isNil or length < 2 or length > csize_t(MaxInputValues): return -1
  let nv = input[0]
  let qv = input[1]
  if nv < 1 or nv > MaxN or qv < 0 or qv > MaxQ: return -1
  let n = int(nv)
  let q = int(qv)
  if length < csize_t(3 * n): return -1

  var ctx: Context
  ctx.n = n
  for v in 0 ..< n:
    for d in 0 ..< MaxLevel:
      ctx.ancestor[v][d] = -1
      ctx.branchFor[v][d] = -1
  var values: array[MaxN, int64]
  for v in 0 ..< n:
    values[v] = input[2 + v]
    if values[v] < -MaxAbsValue or values[v] > MaxAbsValue: return -1

  let edgeStart = 2 + n
  for i in 0 ..< n - 1:
    let uv = input[edgeStart + 2 * i]
    let vv = input[edgeStart + 2 * i + 1]
    if uv < 0 or uv >= nv or vv < 0 or vv >= nv or uv == vv: return -1
    let u = int(uv)
    let v = int(vv)
    for j in 0 ..< ctx.degree[u]:
      if ctx.adjacent[u][j] == v: return -1
    ctx.adjacent[u][ctx.degree[u]] = v
    inc ctx.degree[u]
    ctx.adjacent[v][ctx.degree[v]] = u
    inc ctx.degree[v]

  var seen: array[MaxN, bool]
  var stack: array[MaxN, int]
  var top = 1
  var visited = 0
  stack[0] = 0
  seen[0] = true
  while top > 0:
    dec top
    let u = stack[top]
    inc visited
    for i in 0 ..< ctx.degree[u]:
      let v = ctx.adjacent[u][i]
      if not seen[v]:
        seen[v] = true
        stack[top] = v
        inc top
  if visited != n: return -1

  var kinds: array[MaxQ, int]
  var vertices: array[MaxQ, int]
  var first, second: array[MaxQ, int64]
  var queryCount = 0
  var cursor = 3 * n
  for i in 0 ..< q:
    if cursor >= int(length): return -1
    let op = input[cursor]
    inc cursor
    if op == 0:
      if cursor + 2 > int(length): return -1
      let p = input[cursor]
      let delta = input[cursor + 1]
      cursor += 2
      if p < 0 or p >= nv or delta < -MaxAbsValue or delta > MaxAbsValue: return -1
      kinds[i] = 0
      vertices[i] = int(p)
      first[i] = delta
    elif op == 1:
      if cursor + 3 > int(length): return -1
      let p = input[cursor]
      let left = input[cursor + 1]
      let right = input[cursor + 2]
      cursor += 3
      if p < 0 or p >= nv or left < 0 or left >= right or right > nv: return -1
      kinds[i] = 1
      vertices[i] = int(p)
      first[i] = left
      second[i] = right
      inc queryCount
    else:
      return -1
  if cursor != int(length): return -1

  decompose(ctx, 0, 0)
  for v in 0 ..< n:
    for d in 0 ..< ctx.pathLength[v]:
      let c = ctx.ancestor[v][d]
      let branchId = ctx.branchFor[v][d]
      fenwickAdd(ctx.total[c], ctx.distance[v][d], values[v])
      if branchId >= 0: fenwickAdd(ctx.branch[branchId], ctx.distance[v][d], values[v])

  var answers: array[MaxQ, int64]
  var answerCount = 0
  for i in 0 ..< q:
    let p = vertices[i]
    if kinds[i] == 0:
      for d in 0 ..< ctx.pathLength[p]:
        let c = ctx.ancestor[p][d]
        let branchId = ctx.branchFor[p][d]
        fenwickAdd(ctx.total[c], ctx.distance[p][d], first[i])
        if branchId >= 0: fenwickAdd(ctx.branch[branchId], ctx.distance[p][d], first[i])
    else:
      var total = 0'i64
      let left = int(first[i])
      let right = int(second[i])
      for d in 0 ..< ctx.pathLength[p]:
        let c = ctx.ancestor[p][d]
        let branchId = ctx.branchFor[p][d]
        let l = left - ctx.distance[p][d]
        let r = right - ctx.distance[p][d]
        total += rowRange(ctx.total[c], l, r)
        if branchId >= 0: total -= rowRange(ctx.branch[branchId], l, r)
      answers[answerCount] = total
      inc answerCount

  let outputBytes = 8 * answerCount
  if outputBytes > 0 and (output.isNil or capacity < csize_t(outputBytes)): return -2
  for i in 0 ..< answerCount: storeI64Le(output, 8 * i, answers[i])
  int64(outputBytes)
