const MaxN = 16
const MaxQ = 32
const MaxIntervals = MaxN + 2 * MaxQ
const TreeNodes = 4 * MaxQ + 8

type TimeOp = object
  kind, a, b: int
  delta: int64
type Change = object
  kind, a, root, oldSize: int
  oldSum: int64

proc rootOf(parent: array[MaxN, int], inputVertex: int): int =
  result = inputVertex
  while parent[result] != result: result = parent[result]

proc place(node, left, right, ql, qr, id: int,
    count: var array[TreeNodes, int], bucket: var array[TreeNodes, array[MaxIntervals, int]]) =
  if ql <= left and right <= qr:
    bucket[node][count[node]] = id
    inc count[node]
    return
  let mid = left + (right - left) div 2
  if ql < mid: place(node * 2, left, mid, ql, qr, id, count, bucket)
  if qr > mid: place(node * 2 + 1, mid, right, ql, qr, id, count, bucket)

proc unite(u, v: int, parent, size: var array[MaxN, int], total: var array[MaxN, int64],
    history: var array[MaxIntervals, Change], histLen: var int) =
  var ru = rootOf(parent, u)
  var rv = rootOf(parent, v)
  if ru == rv: return
  if size[ru] < size[rv] or (size[ru] == size[rv] and ru > rv): swap(ru, rv)
  history[histLen] = Change(kind: 0, a: rv, root: ru, oldSize: size[ru], oldSum: total[ru])
  inc histLen
  parent[rv] = ru
  size[ru] += size[rv]
  total[ru] += total[rv]

proc addValue(v: int, delta: int64, parent: array[MaxN, int], total: var array[MaxN, int64],
    history: var array[MaxIntervals, Change], histLen: var int) =
  let r = rootOf(parent, v)
  history[histLen] = Change(kind: 1, a: r, oldSum: total[r])
  inc histLen
  total[r] += delta

proc rollback(mark: int, parent: var array[MaxN, int], size: var array[MaxN, int],
    total: var array[MaxN, int64], history: array[MaxIntervals, Change], histLen: var int) =
  while histLen > mark:
    dec histLen
    let c = history[histLen]
    if c.kind == 0:
      parent[c.a] = c.a
      size[c.root] = c.oldSize
      total[c.root] = c.oldSum
    else:
      total[c.a] = c.oldSum

proc visit(node, left, right: int, ops: array[MaxIntervals, TimeOp],
    count: array[TreeNodes, int], bucket: array[TreeNodes, array[MaxIntervals, int]],
    eventOp, eventA: array[MaxQ, int64], parent, size: var array[MaxN, int],
    total: var array[MaxN, int64], history: var array[MaxIntervals, Change],
    histLen: var int, answer: var array[MaxQ, int64]) =
  let mark = histLen
  for i in 0 ..< count[node]:
    let op = ops[bucket[node][i]]
    if op.kind == 0: unite(op.a, op.b, parent, size, total, history, histLen)
    else: addValue(op.a, op.delta, parent, total, history, histLen)
  if right - left == 1:
    if eventOp[left] == 3: answer[left] = total[rootOf(parent, int(eventA[left]))]
  else:
    let mid = left + (right - left) div 2
    visit(node * 2, left, mid, ops, count, bucket, eventOp, eventA, parent, size, total, history, histLen, answer)
    visit(node * 2 + 1, mid, right, ops, count, bucket, eventOp, eventA, parent, size, total, history, histLen, answer)
  rollback(mark, parent, size, total, history, histLen)

proc storeLe(output: ptr UncheckedArray[uint8], offset: int, value: int64) =
  let bits = cast[uint64](value)
  for b in 0 ..< 8: output[offset + b] = uint8((bits shr (8 * b)) and 255)

proc dynamic_graph_vertex_add_component_sum*(input: ptr UncheckedArray[int64], length: csize_t,
    output: ptr UncheckedArray[uint8], capacity: csize_t): int64
    {.cdecl, exportc: "dynamic_graph_vertex_add_component_sum".} =
  if input.isNil or length < 2 or length > csize_t(2 + MaxN + 3 * MaxQ + 1): return -1
  if input[0] < 1 or input[0] > MaxN or input[1] < 0 or input[1] > MaxQ: return -1
  let n = int(input[0])
  let q = int(input[1])
  if int(length) != 2 + n + 3 * q: return -1
  var initial: array[MaxN, int64]
  for v in 0 ..< n:
    initial[v] = input[2 + v]
    if initial[v] < 0 or initial[v] > 100: return -1
  var eventOp, eventA, eventB: array[MaxQ, int64]
  var active: array[MaxN, array[MaxN, bool]]
  var start: array[MaxN, array[MaxN, int]]
  var ops: array[MaxIntervals, TimeOp]
  var intervalLeft, intervalRight: array[MaxIntervals, int]
  var opCount = 0
  var queryCount = 0
  for t in 0 ..< q:
    let off = 2 + n + 3 * t
    let op = input[off]
    let a = input[off + 1]
    let b = input[off + 2]
    eventOp[t] = op; eventA[t] = a; eventB[t] = b
    if op == 0 or op == 1:
      if a < 0 or a >= n or b < 0 or b >= n or a == b: return -1
      var u = int(a); var v = int(b)
      if u > v: swap(u, v)
      if op == 0:
        if active[u][v]: return -1
        active[u][v] = true; start[u][v] = t
      else:
        if not active[u][v]: return -1
        active[u][v] = false
        if start[u][v] < t:
          ops[opCount] = TimeOp(kind: 0, a: u, b: v)
          intervalLeft[opCount] = start[u][v]; intervalRight[opCount] = t; inc opCount
    elif op == 2:
      if a < 0 or a >= n or b < 0 or b > 100: return -1
      if b != 0 and t < q:
        ops[opCount] = TimeOp(kind: 1, a: int(a), delta: b)
        intervalLeft[opCount] = t; intervalRight[opCount] = q; inc opCount
    elif op == 3:
      if a < 0 or a >= n or b != 0: return -1
      inc queryCount
    else: return -1
  for u in 0 ..< n:
    for v in u + 1 ..< n:
      if active[u][v] and start[u][v] < q:
        ops[opCount] = TimeOp(kind: 0, a: u, b: v)
        intervalLeft[opCount] = start[u][v]; intervalRight[opCount] = q; inc opCount
  if q != 0:
    for v in 0 ..< n:
      if initial[v] != 0:
        ops[opCount] = TimeOp(kind: 1, a: v, delta: initial[v])
        intervalLeft[opCount] = 0; intervalRight[opCount] = q; inc opCount
  if output.isNil or int(capacity) < 8 * queryCount: return -2
  var count: array[TreeNodes, int]
  var bucket: array[TreeNodes, array[MaxIntervals, int]]
  if q != 0:
    for i in 0 ..< opCount:
      if intervalLeft[i] < intervalRight[i]: place(1, 0, q, intervalLeft[i], intervalRight[i], i, count, bucket)
  var parent, size: array[MaxN, int]
  var total: array[MaxN, int64]
  for v in 0 ..< n: parent[v] = v; size[v] = 1
  var history: array[MaxIntervals, Change]
  var histLen = 0
  var answer: array[MaxQ, int64]
  if q != 0: visit(1, 0, q, ops, count, bucket, eventOp, eventA, parent, size, total, history, histLen, answer)
  var written = 0
  for t in 0 ..< q:
    if eventOp[t] == 3: storeLe(output, written, answer[t]); written += 8
  int64(written)
