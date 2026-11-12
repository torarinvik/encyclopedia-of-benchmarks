const
  N = 8
  M = 32
  Base = 8
  InputMax = 2 + 2 * N + 4 * M
  Inf = 1'i64 shl 60

type
  KttNode = object
    valid: bool
    winner: int
    best: int64
    lazy: int64
    deadline: int64
  KttOp = object
    kind, left, right, delta: int64

proc pull(tree: var array[2 * Base, KttNode], node: int, slope: array[N, int64]) =
  let left = 2 * node
  let right = left + 1
  if not tree[left].valid and not tree[right].valid:
    tree[node].valid = false
    tree[node].deadline = Inf
    return
  if not tree[left].valid or not tree[right].valid:
    let child = if tree[right].valid: right else: left
    tree[node].valid = true
    tree[node].winner = tree[child].winner
    tree[node].best = tree[child].best
    tree[node].deadline = tree[child].deadline
    return
  let li = tree[left].winner
  let ri = tree[right].winner
  let chooseLeft = tree[left].best > tree[right].best or
    (tree[left].best == tree[right].best and slope[li] > slope[ri])
  let win = if chooseLeft: left else: right
  let lose = if chooseLeft: right else: left
  let wi = tree[win].winner
  let lo = tree[lose].winner
  var crossing = Inf
  if slope[wi] < slope[lo]:
    let gap = tree[win].best - tree[lose].best
    let slopeGap = slope[lo] - slope[wi]
    crossing = if gap <= 0: 0 else: (gap + slopeGap - 1) div slopeGap
  tree[node].valid = true
  tree[node].winner = wi
  tree[node].best = tree[win].best
  tree[node].deadline = min(crossing, min(tree[left].deadline, tree[right].deadline))

proc apply(tree: var array[2 * Base, KttNode], node: int,
           slope: array[N, int64], delta: int64) =
  if not tree[node].valid: return
  tree[node].best += slope[tree[node].winner] * delta
  tree[node].lazy += delta
  tree[node].deadline -= delta

proc push(tree: var array[2 * Base, KttNode], node: int, slope: array[N, int64]) =
  let delta = tree[node].lazy
  if delta == 0 or node >= Base: return
  apply(tree, 2 * node, slope, delta)
  apply(tree, 2 * node + 1, slope, delta)
  tree[node].lazy = 0

proc repair(tree: var array[2 * Base, KttNode], node: int, slope: array[N, int64]) =
  if node >= Base or not tree[node].valid: return
  push(tree, node, slope)
  if tree[2 * node].valid and tree[2 * node].deadline <= 0:
    repair(tree, 2 * node, slope)
  if tree[2 * node + 1].valid and tree[2 * node + 1].deadline <= 0:
    repair(tree, 2 * node + 1, slope)
  pull(tree, node, slope)

proc translate(tree: var array[2 * Base, KttNode], node, lo, hi, ql, qr: int,
               delta: int64, slope: array[N, int64]) =
  if ql <= lo and hi <= qr:
    apply(tree, node, slope, delta)
    repair(tree, node, slope)
    return
  push(tree, node, slope)
  let mid = (lo + hi) div 2
  if ql < mid: translate(tree, 2 * node, lo, mid, ql, qr, delta, slope)
  if mid < qr: translate(tree, 2 * node + 1, mid, hi, ql, qr, delta, slope)
  pull(tree, node, slope)

proc query(tree: var array[2 * Base, KttNode], node, lo, hi, ql, qr: int,
           slope: array[N, int64]): int64 =
  if ql <= lo and hi <= qr: return tree[node].best
  push(tree, node, slope)
  let mid = (lo + hi) div 2
  var answer = low(int64)
  if ql < mid: answer = query(tree, 2 * node, lo, mid, ql, qr, slope)
  if mid < qr: answer = max(answer, query(tree, 2 * node + 1, mid, hi, ql, qr, slope))
  pull(tree, node, slope)
  answer

proc storeLe(output: ptr UncheckedArray[uint8], offset: int, value: int64) =
  let bits = cast[uint64](value)
  for byte in 0 ..< 8: output[offset + byte] = uint8((bits shr (8 * byte)) and 255'u64)

proc kinetic_tournament_tree*(input: ptr UncheckedArray[int64], length: csize_t,
    output: ptr UncheckedArray[uint8], capacity: csize_t): int64 {.cdecl,
    exportc: "kinetic_tournament_tree".} =
  if input.isNil or length < 2 or length > csize_t(InputMax): return -1
  let nr = input[0]
  let mr = input[1]
  if nr < 1 or nr > N.int64 or mr < 1 or mr > M.int64: return -1
  let n = int(nr)
  let m = int(mr)
  var cursor = 2
  var slope, intercept: array[N, int64]
  for i in 0 ..< n:
    if cursor + 2 > int(length): return -1
    slope[i] = input[cursor]
    intercept[i] = input[cursor + 1]
    cursor += 2
    if slope[i] < -8 or slope[i] > 8 or intercept[i] < -64 or intercept[i] > 64 or
        (i > 0 and slope[i] <= slope[i - 1]): return -1
  var operations: array[M, KttOp]
  var queryCount = 0
  for i in 0 ..< m:
    if cursor >= int(length): return -1
    let kind = input[cursor]
    inc cursor
    if kind == 0:
      if cursor + 3 > int(length): return -1
      let left = input[cursor]
      let right = input[cursor + 1]
      let delta = input[cursor + 2]
      cursor += 3
      if left < 0 or left > right or right >= nr or delta < 1 or delta > 8: return -1
      operations[i] = KttOp(kind: kind, left: left, right: right, delta: delta)
    elif kind == 1:
      if cursor + 2 > int(length): return -1
      let left = input[cursor]
      let right = input[cursor + 1]
      cursor += 2
      if left < 0 or left > right or right >= nr: return -1
      operations[i] = KttOp(kind: kind, left: left, right: right, delta: 0)
      inc queryCount
    else:
      return -1
  if cursor != int(length) or queryCount == 0: return -1
  let required = 8 * queryCount
  if output.isNil or capacity < csize_t(required): return -2

  var tree: array[2 * Base, KttNode]
  for i in 0 ..< 2 * Base: tree[i].deadline = Inf
  for i in 0 ..< n:
    let node = Base + i
    tree[node].valid = true
    tree[node].winner = i
    tree[node].best = intercept[i]
  for node in countdown(Base - 1, 1): pull(tree, node, slope)
  var answers: array[M, int64]
  var answerCount = 0
  for i in 0 ..< m:
    let op = operations[i]
    if op.kind == 0:
      translate(tree, 1, 0, Base, int(op.left), int(op.right) + 1, op.delta, slope)
    else:
      answers[answerCount] = query(tree, 1, 0, Base, int(op.left), int(op.right) + 1, slope)
      inc answerCount
  for i in 0 ..< answerCount: storeLe(output, 8 * i, answers[i])
  int64(required)
