const MaxN = 12
const MaxM = 60
const MaxP = 119
const MaxB = 12
const MaxBlocks = 44
const MaxInput = 2088
const Inf = 1152921504606846976'i64

type
  Arc = object
    tail, head: int
    weight: int64
  Piece = object
    left, right, boundaryCount: int
    arcMask: uint64
    vertexMask: uint16
    boundary: array[MaxB, int]
  Block = object
    child, rowCount, columnCount: int
    rows, columns: array[MaxB, int]
    weights: array[MaxB, array[MaxB, int64]]
    bestValue: array[MaxB, int64]
    bestRow: array[MaxB, int]
  Context = object
    n, m, source, pieceCount: int
    pieces: array[MaxP, Piece]
    arcs: array[MaxM, Arc]
    ddg: array[MaxP, array[MaxN, array[MaxN, int64]]]
    potential: array[MaxP, array[MaxN, int64]]

proc popCount16(value: uint16): int =
  var v = value
  while v != 0:
    result += int(v and 1)
    v = v shr 1

proc countSetBits(value: uint64): int =
  var v = value
  while v != 0:
    result += int(v and 1)
    v = v shr 1

proc vertexMask(ctx: var Context, mask: uint64): uint16 =
  for e in 0 ..< ctx.m:
    if (mask and (1'u64 shl e)) != 0:
      result = result or (1'u16 shl ctx.arcs[e].tail) or (1'u16 shl ctx.arcs[e].head)

proc connected(ctx: var Context, mask: uint64, vertices: uint16): bool =
  if vertices == 0: return false
  var start = 0
  while (vertices and (1'u16 shl start)) == 0: inc start
  var reached = 1'u16 shl start
  var changed = true
  while changed:
    changed = false
    for e in 0 ..< ctx.m:
      if (mask and (1'u64 shl e)) == 0: continue
      let u = ctx.arcs[e].tail
      let v = ctx.arcs[e].head
      if (reached and (1'u16 shl u)) != 0 and (reached and (1'u16 shl v)) == 0:
        reached = reached or (1'u16 shl v); changed = true
      if (reached and (1'u16 shl v)) != 0 and (reached and (1'u16 shl u)) == 0:
        reached = reached or (1'u16 shl u); changed = true
  reached == vertices

proc parse(ctx: var Context, input: ptr UncheckedArray[int64], length: csize_t): bool =
  if input.isNil or length < csize_t(4) or length > csize_t(MaxInput): return false
  let n0 = input[0]; let m0 = input[1]; let source0 = input[2]; let p0 = input[3]
  if n0 < 2 or n0 > int64(MaxN) or m0 < 1 or m0 > int64(MaxM) or source0 < 0 or source0 >= n0 or p0 < 1 or p0 > int64(MaxP) or p0 mod 2 == 0: return false
  ctx.n = int(n0); ctx.m = int(m0); ctx.source = int(source0); ctx.pieceCount = int(p0)
  var seenArc: array[MaxN, array[MaxN, bool]]
  var seenPair: array[MaxN, array[MaxN, bool]]
  var pairCount = 0
  var offset = 4
  for e in 0 ..< ctx.m:
    if offset + 3 > int(length): return false
    let u0 = input[offset]; let v0 = input[offset + 1]; let weight = input[offset + 2]; offset += 3
    if u0 < 0 or u0 >= n0 or v0 < 0 or v0 >= n0 or u0 == v0 or weight < -100 or weight > 100: return false
    let u = int(u0); let v = int(v0)
    if seenArc[u][v]: return false
    seenArc[u][v] = true
    if not seenPair[u][v]: seenPair[u][v] = true; seenPair[v][u] = true; inc pairCount
    ctx.arcs[e] = Arc(tail: u, head: v, weight: weight)
  let edgeLimit = if ctx.n == 2: 1 else: 3 * ctx.n - 6
  if pairCount > edgeLimit or ctx.m > 2 * edgeLimit: return false
  var visited: array[MaxN, bool]
  var queue: array[MaxN, int]
  var head = 0; var tail = 1; queue[0] = 0; visited[0] = true
  while head < tail:
    let u = queue[head]; inc head
    for e in 0 ..< ctx.m:
      var v = -1
      if ctx.arcs[e].tail == u: v = ctx.arcs[e].head
      elif ctx.arcs[e].head == u: v = ctx.arcs[e].tail
      if v >= 0 and not visited[v]: visited[v] = true; queue[tail] = v; inc tail
  for v in 0 ..< ctx.n:
    if not visited[v]: return false

  var parents: array[MaxP, int]
  var leafUnion = 0'u64; var leafCount = 0
  let full = (1'u64 shl ctx.m) - 1
  for index in 0 ..< ctx.pieceCount:
    if offset + 4 > int(length): return false
    let left = input[offset]; let right = input[offset + 1]; let maskValue = input[offset + 2]; let bc0 = input[offset + 3]; offset += 4
    if bc0 < 1 or bc0 > int64(ctx.n) or bc0 > int64(MaxB) or offset + int(bc0) > int(length): return false
    var piece = Piece(left: int(left), right: int(right), boundaryCount: int(bc0))
    var listed = 0'u16
    for j in 0 ..< piece.boundaryCount:
      let value = input[offset]; inc offset
      if value < 0 or value >= n0: return false
      let v = int(value); let bit = 1'u16 shl v
      if (listed and bit) != 0: return false
      listed = listed or bit; piece.boundary[j] = v
    if left == -1 and right == -1:
      if maskValue <= 0: return false
      piece.arcMask = uint64(maskValue)
      if (piece.arcMask and not full) != 0 or countSetBits(piece.arcMask) > 3 or (leafUnion and piece.arcMask) != 0: return false
      leafUnion = leafUnion or piece.arcMask; inc leafCount
      piece.vertexMask = ctx.vertexMask(piece.arcMask)
      if not ctx.connected(piece.arcMask, piece.vertexMask): return false
    else:
      if left < 0 or right < 0 or left >= int64(index) or right >= int64(index) or left == right or maskValue != -1: return false
      let li = int(left); let ri = int(right)
      if parents[li] != 0 or parents[ri] != 0: return false
      parents[li] = 1; parents[ri] = 1
      let lp = ctx.pieces[li]; let rp = ctx.pieces[ri]
      if (lp.arcMask and rp.arcMask) != 0: return false
      piece.arcMask = lp.arcMask or rp.arcMask; piece.vertexMask = lp.vertexMask or rp.vertexMask
      let psize = popCount16(piece.vertexMask); let limit = (2 * psize + 2) div 3
      if popCount16(lp.vertexMask) > limit or popCount16(rp.vertexMask) > limit or (lp.vertexMask and rp.vertexMask) == 0: return false
    var expected = 0'u16
    for v in 0 ..< ctx.n:
      let bit = 1'u16 shl v
      if (piece.vertexMask and bit) == 0: continue
      if v == ctx.source: expected = expected or bit; continue
      for e in 0 ..< ctx.m:
        if (piece.arcMask and (1'u64 shl e)) == 0 and (ctx.arcs[e].tail == v or ctx.arcs[e].head == v): expected = expected or bit; break
    if listed != expected or not ctx.connected(piece.arcMask, piece.vertexMask): return false
    if index == ctx.pieceCount - 1 and (piece.arcMask != full or piece.vertexMask != (1'u16 shl ctx.n) - 1): return false
    ctx.pieces[index] = piece
  if offset != int(length) or ctx.pieceCount != 2 * leafCount - 1 or leafUnion != full or parents[ctx.pieceCount - 1] != 0: return false
  for i in 0 ..< ctx.pieceCount - 1:
    if parents[i] != 1: return false
  let root = ctx.pieces[ctx.pieceCount - 1]
  root.boundaryCount == 1 and root.boundary[0] == ctx.source

proc bellman(ctx: var Context, nodes: ptr UncheckedArray[int], nodeCount: int,
             arcs: ptr UncheckedArray[Arc], arcCount: int,
             labels: ptr UncheckedArray[int64]): bool =
  for v in 0 ..< ctx.n: labels[v] = Inf
  for i in 0 ..< nodeCount: labels[nodes[i]] = 0
  for _ in 0 ..< max(0, nodeCount - 1):
    var changed = false
    for e in 0 ..< arcCount:
      let a = arcs[e]; let candidate = labels[a.tail] + a.weight
      if candidate < labels[a.head]: labels[a.head] = candidate; changed = true
    if not changed: break
  for e in 0 ..< arcCount:
    let a = arcs[e]
    if labels[a.tail] + a.weight < labels[a.head]: return false
  true

proc seeded(ctx: var Context, arcs: ptr UncheckedArray[Arc], arcCount: int,
            seeds: ptr UncheckedArray[int64], labels: ptr UncheckedArray[int64]): bool =
  for v in 0 ..< ctx.n: labels[v] = seeds[v]
  for _ in 0 ..< ctx.n - 1:
    var changed = false
    for e in 0 ..< arcCount:
      let a = arcs[e]
      if labels[a.tail] != Inf and labels[a.tail] + a.weight < labels[a.head]: labels[a.head] = labels[a.tail] + a.weight; changed = true
    if not changed: break
  for e in 0 ..< arcCount:
    let a = arcs[e]
    if labels[a.tail] != Inf and labels[a.tail] + a.weight < labels[a.head]: return false
  true

proc monge(ctx: var Context, index, lo, hi: int): bool =
  if hi - lo <= 1: return true
  let piece = ctx.pieces[index]; let middle = (lo + hi) div 2
  for direction in 0 .. 1:
    let rlo = if direction == 0: lo else: middle
    let rhi = if direction == 0: middle else: hi
    let clo = if direction == 0: middle else: lo
    let chi = if direction == 0: hi else: middle
    for i in rlo ..< rhi:
      for i2 in i + 1 ..< rhi:
        for j in clo ..< chi:
          for j2 in j + 1 ..< chi:
            let u = piece.boundary[i]; let u2 = piece.boundary[i2]
            let v = piece.boundary[j]; let v2 = piece.boundary[j2]
            let a = ctx.ddg[index][u][v]; let b = ctx.ddg[index][u2][v2]
            let c = ctx.ddg[index][u][v2]; let d = ctx.ddg[index][u2][v]
            let lhs = if a == Inf or b == Inf: Inf else: a + b
            let rhs = if c == Inf or d == Inf: Inf else: c + d
            if lhs > rhs: return false
  monge(ctx, index, lo, middle) and monge(ctx, index, middle, hi)

proc addBlock(ctx: var Context, child: int, rows: ptr UncheckedArray[int], rowCount: int,
              cols: ptr UncheckedArray[int], colCount: int, potential: ptr UncheckedArray[int64],
              blocks: ptr UncheckedArray[Block], blockCount: var int) =
  if rowCount == 0 or colCount == 0 or blockCount >= MaxBlocks: return
  var block = Block(child: child, rowCount: rowCount, columnCount: colCount)
  for i in 0 ..< rowCount: block.rows[i] = rows[i]
  for j in 0 ..< colCount: block.columns[j] = cols[j]
  for i in 0 ..< rowCount:
    for j in 0 ..< colCount:
      let u = rows[i]; let v = cols[j]; let d = ctx.ddg[child][u][v]
      block.weights[i][j] = if d == Inf: Inf else: d + potential[u] - potential[v]
  blocks[blockCount] = block; inc blockCount

proc buildBlocksRec(ctx: var Context, child, lo, hi: int, potential: ptr UncheckedArray[int64],
                    blocks: ptr UncheckedArray[Block], blockCount: var int) =
  if hi - lo <= 1: return
  let piece = ctx.pieces[child]; let middle = (lo + hi) div 2
  ctx.addBlock(child, cast[ptr UncheckedArray[int]](unsafeAddr piece.boundary[lo]), middle-lo,
    cast[ptr UncheckedArray[int]](unsafeAddr piece.boundary[middle]), hi-middle, potential, blocks, blockCount)
  ctx.addBlock(child, cast[ptr UncheckedArray[int]](unsafeAddr piece.boundary[middle]), hi-middle,
    cast[ptr UncheckedArray[int]](unsafeAddr piece.boundary[lo]), middle-lo, potential, blocks, blockCount)
  ctx.buildBlocksRec(child, lo, middle, potential, blocks, blockCount)
  ctx.buildBlocksRec(child, middle, hi, potential, blocks, blockCount)

proc activate(vertex: int, value: int64, blocks: ptr UncheckedArray[Block], count: int,
              settled: ptr UncheckedArray[bool]) =
  for bi in 0 ..< count:
    var block = addr blocks[bi]
    for i in 0 ..< block.rowCount:
      if block.rows[i] != vertex: continue
      for j in 0 ..< block.columnCount:
        let target = block.columns[j]; let weight = block.weights[i][j]
        if settled[target] or weight == Inf: continue
        let candidate = value + weight
        if candidate < block.bestValue[j] or (candidate == block.bestValue[j] and vertex < block.bestRow[j]):
          block.bestValue[j] = candidate; block.bestRow[j] = vertex

proc settle(vertex: int, settled: ptr UncheckedArray[bool], blocks: ptr UncheckedArray[Block], count: int) =
  settled[vertex] = true
  for bi in 0 ..< count:
    for j in 0 ..< blocks[bi].columnCount:
      if blocks[bi].columns[j] == vertex: blocks[bi].bestValue[j] = Inf; blocks[bi].bestRow[j] = high(int)

proc dijkstra(ctx: var Context, nodes: ptr UncheckedArray[int], nodeCount: int,
              blocks: ptr UncheckedArray[Block], count: int, seeds: ptr UncheckedArray[int64],
              labels: ptr UncheckedArray[int64]) =
  var settled: array[MaxN, bool]
  for v in 0 ..< ctx.n: labels[v] = Inf
  for bi in 0 ..< count:
    for j in 0 ..< blocks[bi].columnCount: blocks[bi].bestValue[j] = Inf; blocks[bi].bestRow[j] = high(int)
  for i in 0 ..< nodeCount:
    let v = nodes[i]
    if seeds[v] < labels[v]: labels[v] = seeds[v]
  for i in 0 ..< nodeCount:
    let v = nodes[i]
    if labels[v] != Inf: activate(v, labels[v], blocks, count,
      cast[ptr UncheckedArray[bool]](addr settled[0]))
  while true:
    var best = -1; var bestRow = high(int); var bestValue = Inf
    for i in 0 ..< nodeCount:
      let v = nodes[i]; let value = labels[v]
      if not settled[v] and value != Inf and (value < bestValue or (value == bestValue and v < best)):
        best = v; bestValue = value; bestRow = -1
    for bi in 0 ..< count:
      for j in 0 ..< blocks[bi].columnCount:
        let v = blocks[bi].columns[j]; let value = blocks[bi].bestValue[j]; let row = blocks[bi].bestRow[j]
        if settled[v] or value == Inf: continue
        if value < bestValue or (value == bestValue and (best < 0 or v < best)) or (value == bestValue and v == best and row < bestRow):
          best = v; bestValue = value; bestRow = row
    if best < 0: break
    if bestValue < labels[best]: labels[best] = bestValue
    settle(best, cast[ptr UncheckedArray[bool]](addr settled[0]), blocks, count)
    activate(best, labels[best], blocks, count,
      cast[ptr UncheckedArray[bool]](addr settled[0]))

proc collectArcs(ctx: var Context, mask: uint64, arcs: ptr UncheckedArray[Arc]): int =
  for e in 0 ..< ctx.m:
    if (mask and (1'u64 shl e)) != 0: arcs[result] = ctx.arcs[e]; inc result

proc buildPiece(ctx: var Context, index: int, blocks: ptr UncheckedArray[Block]): bool =
  let piece = ctx.pieces[index]
  for u in 0 ..< ctx.n:
    for v in 0 ..< ctx.n: ctx.ddg[index][u][v] = Inf
  if piece.left == -1:
    var arcs: array[3, Arc]; let arcCount = ctx.collectArcs(piece.arcMask, cast[ptr UncheckedArray[Arc]](addr arcs[0]))
    var nodes: array[MaxN, int]; var nodeCount = 0
    for v in 0 ..< ctx.n:
      if (piece.vertexMask and (1'u16 shl v)) != 0: nodes[nodeCount] = v; inc nodeCount
    var potential: array[MaxN, int64]
    if not bellman(ctx, cast[ptr UncheckedArray[int]](addr nodes[0]), nodeCount,
        cast[ptr UncheckedArray[Arc]](addr arcs[0]), arcCount,
        cast[ptr UncheckedArray[int64]](addr potential[0])): return false
    for i in 0 ..< piece.boundaryCount:
      var seeds: array[MaxN, int64]; var labels: array[MaxN, int64]
      for v in 0 ..< ctx.n: seeds[v] = Inf
      seeds[piece.boundary[i]] = 0
      if not seeded(ctx, cast[ptr UncheckedArray[Arc]](addr arcs[0]), arcCount,
          cast[ptr UncheckedArray[int64]](addr seeds[0]), cast[ptr UncheckedArray[int64]](addr labels[0])): return false
      for j in 0 ..< piece.boundaryCount: ctx.ddg[index][piece.boundary[i]][piece.boundary[j]] = labels[piece.boundary[j]]
    return true
  let left = piece.left; let right = piece.right
  var present: array[MaxN, bool]
  for i in 0 ..< ctx.pieces[left].boundaryCount: present[ctx.pieces[left].boundary[i]] = true
  for i in 0 ..< ctx.pieces[right].boundaryCount: present[ctx.pieces[right].boundary[i]] = true
  var nodes: array[MaxN, int]; var nodeCount = 0
  for v in 0 ..< ctx.n:
    if present[v]: nodes[nodeCount] = v; inc nodeCount
  var unionArcs: array[2 * MaxB * MaxB, Arc]; var unionCount = 0
  for child in [left, right]:
    let cp = ctx.pieces[child]
    for i in 0 ..< cp.boundaryCount:
      for j in 0 ..< cp.boundaryCount:
        let u = cp.boundary[i]; let v = cp.boundary[j]; let d = ctx.ddg[child][u][v]
        if u != v and d != Inf: unionArcs[unionCount] = Arc(tail: u, head: v, weight: d); inc unionCount
  var potential: array[MaxN, int64]
  if not bellman(ctx, cast[ptr UncheckedArray[int]](addr nodes[0]), nodeCount,
      cast[ptr UncheckedArray[Arc]](addr unionArcs[0]), unionCount,
      cast[ptr UncheckedArray[int64]](addr potential[0])): return false
  ctx.potential[index] = potential
  for e in 0 ..< unionCount:
    let a = unionArcs[e]
    if a.weight + potential[a.tail] - potential[a.head] < 0: return false
  var blockCount = 0
  for child in [left, right]:
    if not monge(ctx, child, 0, ctx.pieces[child].boundaryCount): return false
    ctx.buildBlocksRec(child, 0, ctx.pieces[child].boundaryCount,
      cast[ptr UncheckedArray[int64]](addr potential[0]), blocks, blockCount)
  if blockCount > MaxBlocks: return false
  for i in 0 ..< piece.boundaryCount:
    var seeds: array[MaxN, int64]; var labels: array[MaxN, int64]
    for v in 0 ..< ctx.n: seeds[v] = Inf
    seeds[piece.boundary[i]] = 0
    dijkstra(ctx, cast[ptr UncheckedArray[int]](addr nodes[0]), nodeCount, blocks, blockCount,
      cast[ptr UncheckedArray[int64]](addr seeds[0]), cast[ptr UncheckedArray[int64]](addr labels[0]))
    for j in 0 ..< piece.boundaryCount:
      let source = piece.boundary[i]; let target = piece.boundary[j]; let d = labels[target]
      ctx.ddg[index][source][target] = if d == Inf: Inf else: d - potential[source] + potential[target]
  true

proc expand(ctx: var Context, index: int, known: ptr UncheckedArray[int64], result: ptr UncheckedArray[int64], blocks: ptr UncheckedArray[Block]) =
  let piece = ctx.pieces[index]
  if piece.left == -1:
    var arcs: array[3, Arc]; let arcCount = ctx.collectArcs(piece.arcMask, cast[ptr UncheckedArray[Arc]](addr arcs[0]))
    var labels: array[MaxN, int64]
    if not seeded(ctx, cast[ptr UncheckedArray[Arc]](addr arcs[0]), arcCount, known,
        cast[ptr UncheckedArray[int64]](addr labels[0])): return
    for v in 0 ..< ctx.n:
      if (piece.vertexMask and (1'u16 shl v)) != 0 and labels[v] < result[v]: result[v] = labels[v]
    return
  let left = piece.left; let right = piece.right
  var present: array[MaxN, bool]
  for i in 0 ..< ctx.pieces[left].boundaryCount: present[ctx.pieces[left].boundary[i]] = true
  for i in 0 ..< ctx.pieces[right].boundaryCount: present[ctx.pieces[right].boundary[i]] = true
  var nodes: array[MaxN, int]; var nodeCount = 0
  for v in 0 ..< ctx.n:
    if present[v]: nodes[nodeCount] = v; inc nodeCount
  var blockCount = 0
  ctx.buildBlocksRec(left, 0, ctx.pieces[left].boundaryCount,
    cast[ptr UncheckedArray[int64]](addr ctx.potential[index][0]), blocks, blockCount)
  ctx.buildBlocksRec(right, 0, ctx.pieces[right].boundaryCount,
    cast[ptr UncheckedArray[int64]](addr ctx.potential[index][0]), blocks, blockCount)
  var seeds: array[MaxN, int64]; var reduced: array[MaxN, int64]
  for v in 0 ..< ctx.n: seeds[v] = Inf
  for i in 0 ..< piece.boundaryCount:
    let v = piece.boundary[i]
    if known[v] != Inf: seeds[v] = known[v] - ctx.potential[index][v]
  dijkstra(ctx, cast[ptr UncheckedArray[int]](addr nodes[0]), nodeCount, blocks, blockCount,
    cast[ptr UncheckedArray[int64]](addr seeds[0]), cast[ptr UncheckedArray[int64]](addr reduced[0]))
  var raw: array[MaxN, int64]
  for v in 0 ..< ctx.n:
    raw[v] = if reduced[v] == Inf: Inf else: reduced[v] + ctx.potential[index][v]
  for child in [left, right]:
    var childKnown: array[MaxN, int64]
    for v in 0 ..< ctx.n: childKnown[v] = Inf
    for i in 0 ..< ctx.pieces[child].boundaryCount:
      let v = ctx.pieces[child].boundary[i]; childKnown[v] = raw[v]
    ctx.expand(child, cast[ptr UncheckedArray[int64]](addr childKnown[0]), result, blocks)

proc putI64(output: ptr UncheckedArray[uint8], offset: int, value: int64) =
  let bits = cast[uint64](value)
  for b in 0 ..< 8: output[offset + b] = uint8((bits shr (8 * b)) and 255)

proc fakcharoenphol_rao_planar_sssp*(input: ptr UncheckedArray[int64], length: csize_t,
    output: ptr UncheckedArray[uint8], capacity: csize_t): int64 {.cdecl, exportc: "fakcharoenphol_rao_planar_sssp".} =
  var ctx: Context
  if not parse(ctx, input, length): return -1
  var allNodes: array[MaxN, int]
  for v in 0 ..< ctx.n: allNodes[v] = v
  var potential: array[MaxN, int64]
  if not bellman(ctx, cast[ptr UncheckedArray[int]](addr allNodes[0]), ctx.n,
      cast[ptr UncheckedArray[Arc]](addr ctx.arcs[0]), ctx.m,
      cast[ptr UncheckedArray[int64]](addr potential[0])): return -1
  var blocks: array[MaxBlocks, Block]
  for p in 0 ..< ctx.pieceCount:
    if not buildPiece(ctx, p, cast[ptr UncheckedArray[Block]](addr blocks[0])): return -1
  var result: array[MaxN, int64]; var known: array[MaxN, int64]
  for v in 0 ..< ctx.n: result[v] = Inf; known[v] = Inf
  known[ctx.source] = 0
  ctx.expand(ctx.pieceCount - 1, cast[ptr UncheckedArray[int64]](addr known[0]),
    cast[ptr UncheckedArray[int64]](addr result[0]),
    cast[ptr UncheckedArray[Block]](addr blocks[0]))
  let required = csize_t(ctx.n * 8)
  if output.isNil or capacity < required: return -2
  for v in 0 ..< ctx.n: putI64(output, v * 8, if result[v] == Inf: high(int64) else: result[v])
  int64(required)
