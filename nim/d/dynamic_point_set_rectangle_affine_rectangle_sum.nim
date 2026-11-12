const
  MaxN = 32
  MaxQ = 32
  MaxPoints = MaxN + MaxQ
  MaxTree = 4 * MaxPoints + 8
  MaxInput = 2 + 3 * MaxN + 7 * MaxQ + 1
  Modulus = 998244353'i64
  MaxCoord = 1_000_000_000'i64

type
  Op = object
    kind, a, b, c, d, e, f: int64
  Node = object
    minX, maxX, minY, maxY: int64
    sum, lazyA, lazyB: int64
    active: int

proc lessPoint(a, b, axis: int, xs, ys: array[MaxPoints, int64]): bool =
  let av = if axis == 0: xs[a] else: ys[a]
  let bv = if axis == 0: xs[b] else: ys[b]
  if av != bv: return av < bv
  let ao = if axis == 0: ys[a] else: xs[a]
  let bo = if axis == 0: ys[b] else: xs[b]
  if ao != bo: return ao < bo
  a < b

proc sortPoints(order: var array[MaxPoints, int], low, high, axis: int,
                xs, ys: array[MaxPoints, int64]) =
  for i in low + 1 ..< high:
    let point = order[i]
    var j = i
    while j > low and lessPoint(point, order[j - 1], axis, xs, ys):
      order[j] = order[j - 1]
      dec j
    order[j] = point

proc build(tree: var array[MaxTree, Node], order: var array[MaxPoints, int],
           xs, ys, weights: array[MaxPoints, int64], rank: var array[MaxPoints, int],
           low, high, index, depth, initialN: int) =
  tree[index].lazyA = 1
  if high - low == 1:
    let p = order[low]
    tree[index].minX = xs[p]; tree[index].maxX = xs[p]
    tree[index].minY = ys[p]; tree[index].maxY = ys[p]
    tree[index].active = (if p < initialN: 1 else: 0)
    tree[index].sum = (if p < initialN: weights[p] else: 0)
    rank[p] = low
    return
  sortPoints(order, low, high, depth and 1, xs, ys)
  let mid = low + (high - low) div 2
  build(tree, order, xs, ys, weights, rank, low, mid, index * 2, depth + 1, initialN)
  build(tree, order, xs, ys, weights, rank, mid, high, index * 2 + 1, depth + 1, initialN)
  let l = tree[index * 2]; let r = tree[index * 2 + 1]
  tree[index].minX = min(l.minX, r.minX); tree[index].maxX = max(l.maxX, r.maxX)
  tree[index].minY = min(l.minY, r.minY); tree[index].maxY = max(l.maxY, r.maxY)
  tree[index].active = l.active + r.active
  tree[index].sum = (l.sum + r.sum) mod Modulus

proc apply(tree: var array[MaxTree, Node], i: int, a, b: int64) =
  if tree[i].active == 0: return
  tree[i].sum = (a * tree[i].sum + b * int64(tree[i].active)) mod Modulus
  tree[i].lazyA = (a * tree[i].lazyA) mod Modulus
  tree[i].lazyB = (a * tree[i].lazyB + b) mod Modulus

proc push(tree: var array[MaxTree, Node], i, low, high: int) =
  if high - low == 1 or (tree[i].lazyA == 1 and tree[i].lazyB == 0): return
  apply(tree, i * 2, tree[i].lazyA, tree[i].lazyB)
  apply(tree, i * 2 + 1, tree[i].lazyA, tree[i].lazyB)
  tree[i].lazyA = 1; tree[i].lazyB = 0

proc disjoint(node: Node, l, d, r, u: int64): bool =
  node.maxX < l or node.minX >= r or node.maxY < d or node.minY >= u
proc covered(node: Node, l, d, r, u: int64): bool =
  l <= node.minX and node.maxX < r and d <= node.minY and node.maxY < u
proc pull(tree: var array[MaxTree, Node], i: int) =
  tree[i].sum = (tree[i * 2].sum + tree[i * 2 + 1].sum) mod Modulus
  tree[i].active = tree[i * 2].active + tree[i * 2 + 1].active

proc rectSum(tree: var array[MaxTree, Node], i, low, high: int,
             l, d, r, u: int64): int64 =
  let node = tree[i]
  if node.active == 0 or disjoint(node, l, d, r, u): return 0
  if covered(node, l, d, r, u): return node.sum
  push(tree, i, low, high)
  let mid = low + (high - low) div 2
  (rectSum(tree, i * 2, low, mid, l, d, r, u) +
   rectSum(tree, i * 2 + 1, mid, high, l, d, r, u)) mod Modulus

proc rectAffine(tree: var array[MaxTree, Node], i, low, high: int,
                l, d, r, u, a, b: int64) =
  let node = tree[i]
  if node.active == 0 or disjoint(node, l, d, r, u): return
  if covered(node, l, d, r, u): apply(tree, i, a, b); return
  push(tree, i, low, high)
  let mid = low + (high - low) div 2
  rectAffine(tree, i * 2, low, mid, l, d, r, u, a, b)
  rectAffine(tree, i * 2 + 1, mid, high, l, d, r, u, a, b)
  pull(tree, i)

proc setPoint(tree: var array[MaxTree, Node], i, low, high, target: int, weight: int64) =
  if high - low == 1:
    tree[i].sum = weight; tree[i].active = 1
    tree[i].lazyA = 1; tree[i].lazyB = 0
    return
  push(tree, i, low, high)
  let mid = low + (high - low) div 2
  if target < mid: setPoint(tree, i * 2, low, mid, target, weight)
  else: setPoint(tree, i * 2 + 1, mid, high, target, weight)
  pull(tree, i)

proc writeLe(output: ptr UncheckedArray[uint8], offset: int, value: int64) =
  let bits = cast[uint64](value)
  for b in 0 ..< 8: output[offset + b] = uint8((bits shr (8 * b)) and 255)

proc dynamic_point_set_rectangle_affine_rectangle_sum*(input: ptr UncheckedArray[int64],
    length: csize_t, output: ptr UncheckedArray[uint8], capacity: csize_t): int64
    {.cdecl, exportc: "dynamic_point_set_rectangle_affine_rectangle_sum".} =
  if input.isNil or length < 2 or length > csize_t(MaxInput): return -1
  if input[0] < 1 or input[0] > int64(MaxN) or input[1] < 1 or input[1] > int64(MaxQ): return -1
  let n = int(input[0]); let q = int(input[1])
  if 2 + 3 * n > int(length): return -1
  var xs, ys, weights: array[MaxPoints, int64]
  var ops: array[MaxQ, Op]
  var points = n; var active = n; var queryCount = 0
  for i in 0 ..< n:
    xs[i] = input[2 + 3 * i]; ys[i] = input[3 + 3 * i]; weights[i] = input[4 + 3 * i]
    if xs[i] < 0 or xs[i] > MaxCoord or ys[i] < 0 or ys[i] > MaxCoord or weights[i] < 0 or weights[i] >= Modulus: return -1
  var cursor = 2 + 3 * n
  for oi in 0 ..< q:
    if cursor >= int(length): return -1
    let kind = input[cursor]; inc cursor
    if kind == 0:
      if cursor + 3 > int(length) or points >= MaxPoints: return -1
      let x = input[cursor]; let y = input[cursor + 1]; let w = input[cursor + 2]; cursor += 3
      if x < 0 or x > MaxCoord or y < 0 or y > MaxCoord or w < 0 or w >= Modulus: return -1
      xs[points] = x; ys[points] = y; ops[oi] = Op(kind: kind, a: int64(points), b: w)
      inc points; inc active
    elif kind == 1:
      if cursor + 2 > int(length): return -1
      let id = input[cursor]; let w = input[cursor + 1]; cursor += 2
      if id < 0 or id >= int64(active) or w < 0 or w >= Modulus: return -1
      ops[oi] = Op(kind: kind, a: id, b: w)
    elif kind == 2 or kind == 3:
      let fields = if kind == 2: 4 else: 6
      if cursor + fields > int(length): return -1
      let l = input[cursor]; let d = input[cursor + 1]; let r = input[cursor + 2]; let u = input[cursor + 3]
      if l < 0 or l >= r or r > MaxCoord or d < 0 or d >= u or u > MaxCoord: return -1
      if kind == 2:
        cursor += 4; ops[oi] = Op(kind: kind, a: l, b: d, c: r, d: u); inc queryCount
      else:
        let a = input[cursor + 4]; let b = input[cursor + 5]; cursor += 6
        if a < 0 or a >= Modulus or b < 0 or b >= Modulus: return -1
        ops[oi] = Op(kind: kind, a: l, b: d, c: r, d: u, e: a, f: b)
    else: return -1
  if cursor != int(length): return -1
  let bytes = 8 * queryCount
  if bytes > 0 and (output.isNil or int(capacity) < bytes): return -2
  var tree: array[MaxTree, Node]
  var order, rank: array[MaxPoints, int]
  for i in 0 ..< points: order[i] = i
  build(tree, order, xs, ys, weights, rank, 0, points, 1, 0, n)
  var answers: array[MaxQ, int64]
  var answerCount = 0
  for oi in 0 ..< q:
    let op = ops[oi]
    if op.kind == 0 or op.kind == 1: setPoint(tree, 1, 0, points, rank[int(op.a)], op.b)
    elif op.kind == 2:
      answers[answerCount] = rectSum(tree, 1, 0, points, op.a, op.b, op.c, op.d)
      inc answerCount
    else: rectAffine(tree, 1, 0, points, op.a, op.b, op.c, op.d, op.e, op.f)
  for i in 0 ..< answerCount: writeLe(output, 8 * i, answers[i])
  int64(bytes)
