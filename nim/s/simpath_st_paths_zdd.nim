const MaxN = 8
const MaxM = 9
const MaxStates = 1023
const MaxZdd = 511
const MaxInput = 23
const Radix = 2048'i64

type
  Edge = object
    u, v: int
  Memo = object
    level: int
    mate: array[MaxN, uint8]
    result: int
  ZNode = object
    level, low, high: int
  Context = object
    n, m, source, target: int
    memoCount, nodeCount: int
    edges: array[MaxM, Edge]
    last: array[MaxN, int]
    memo: array[MaxStates, Memo]
    nodes: array[MaxZdd, ZNode]

proc degreeOf(mate: array[MaxN, uint8], vertex: int): int =
  if int(mate[vertex]) == vertex + 1: return 0
  if mate[vertex] == 0: return 2
  1

# Status 0 prunes, 1 returns a suffix state, 2 returns the one-terminal.
proc transition(c: Context, level: int, mate: array[MaxN, uint8], selected: bool): tuple[status: int, state: array[MaxN, uint8]] =
  result.state = mate
  if selected:
    let u = c.edges[level].u
    let v = c.edges[level].v
    let du = degreeOf(result.state, u)
    let dv = degreeOf(result.state, v)
    if du == 2 or dv == 2: return (0, result.state)
    if (u == c.source or u == c.target) and du == 1: return (0, result.state)
    if (v == c.source or v == c.target) and dv == 1: return (0, result.state)
    let mu = int(result.state[u])
    let mv = int(result.state[v])
    if mu == v + 1 and mv == u + 1: return (0, result.state)
    if (mu == c.source + 1 and mv == c.target + 1) or (mu == c.target + 1 and mv == c.source + 1):
      for w in 0 ..< c.n:
        if w != c.source and w != c.target and w != u and w != v and degreeOf(result.state, w) == 1:
          return (0, result.state)
      return (2, result.state)
    result.state[u] = 0
    result.state[v] = 0
    result.state[mu - 1] = uint8(mv)
    result.state[mv - 1] = uint8(mu)
  for w in 0 ..< c.n:
    if c.last[w] != level: continue
    let degree = degreeOf(result.state, w)
    if w == c.source or w == c.target:
      if degree == 0: return (0, result.state)
    else:
      if degree == 1: return (0, result.state)
      result.state[w] = uint8(w + 1)
  (1, result.state)

proc memoFind(c: Context, level: int, mate: array[MaxN, uint8]): int =
  for i in 0 ..< c.memoCount:
    let entry = c.memo[i]
    if entry.level != level: continue
    var equal = true
    for v in 0 ..< c.n:
      if entry.mate[v] != mate[v]:
        equal = false
        break
    if equal: return entry.result
  -1

proc makeNode(c: var Context, level, low, high: int): int =
  if high == 0: return low
  for i in 0 ..< c.nodeCount:
    let node = c.nodes[i]
    if node.level == level and node.low == low and node.high == high: return i + 2
  if c.nodeCount >= MaxZdd: return -1
  c.nodes[c.nodeCount] = ZNode(level: level, low: low, high: high)
  inc c.nodeCount
  c.nodeCount + 1

proc solve(c: var Context, level: int, mate: array[MaxN, uint8]): int =
  if level == c.m: return 0
  let cached = memoFind(c, level, mate)
  if cached >= 0: return cached
  let lowTransition = transition(c, level, mate, false)
  let low = if lowTransition.status == 0: 0 else: solve(c, level + 1, lowTransition.state)
  let highTransition = transition(c, level, mate, true)
  var high = 0
  if highTransition.status == 2: high = 1
  elif highTransition.status == 1: high = solve(c, level + 1, highTransition.state)
  let node = makeNode(c, level, low, high)
  if node < 0 or c.memoCount >= MaxStates: return -1
  c.memo[c.memoCount] = Memo(level: level, mate: mate, result: node)
  inc c.memoCount
  node

proc reachableNodes(c: Context, root: int): int =
  var seen: array[MaxZdd + 2, bool]
  var stack: array[2 * MaxZdd + 3, int]
  var top = 1
  stack[0] = root
  while top > 0:
    dec top
    let id = stack[top]
    if id <= 1 or seen[id]: continue
    seen[id] = true
    inc result
    let node = c.nodes[id - 2]
    stack[top] = node.low
    inc top
    stack[top] = node.high
    inc top

proc simpath_st_paths_zdd*(input: ptr UncheckedArray[int64], length: csize_t): int64 {.cdecl, exportc: "simpath_st_paths_zdd".} =
  if input.isNil or length < 4 or length > MaxInput: return -1
  let n64 = input[0]
  let m64 = input[1]
  let s64 = input[2]
  let t64 = input[3]
  if n64 < 2 or n64 > MaxN or m64 < 0 or m64 > MaxM or s64 < 0 or s64 >= n64 or t64 < 0 or t64 >= n64 or s64 == t64:
    return -1
  let n = int(n64)
  let m = int(m64)
  if length != csize_t(4 + 2 * m): return -1
  var c = Context(n: n, m: m, source: int(s64), target: int(t64))
  for v in 0 ..< n: c.last[v] = -1
  for i in 0 ..< m:
    let u64 = input[4 + 2 * i]
    let v64 = input[5 + 2 * i]
    if u64 < 0 or u64 >= v64 or v64 >= n64: return -1
    let u = int(u64)
    let v = int(v64)
    for j in 0 ..< i:
      if c.edges[j].u == u and c.edges[j].v == v: return -1
    c.edges[i] = Edge(u: u, v: v)
    c.last[u] = i
    c.last[v] = i
  var initial: array[MaxN, uint8]
  for v in 0 ..< n: initial[v] = uint8(v + 1)
  let root = solve(c, 0, initial)
  if root < 0: return -1
  var ways: array[MaxZdd + 2, int]
  ways[1] = 1
  for id in 2 ..< c.nodeCount + 2:
    let node = c.nodes[id - 2]
    ways[id] = ways[node.low] + ways[node.high]
  let pathCount = ways[root]
  if pathCount >= 2048: return -1
  int64(reachableNodes(c, root)) * Radix + int64(pathCount)
