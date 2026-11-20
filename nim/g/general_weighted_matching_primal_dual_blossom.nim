## Weighted matching by dual adjustment and odd-cycle contraction.
const MaxN = 64
const Slots = 2 * MaxN + 1
const Infinity = high(int64)

type Matcher = object
  n, nodes: int
  epoch: int32
  weight: array[Slots, array[Slots, int64]]
  dual: array[Slots, int64]
  edgeA, edgeB: array[Slots, array[Slots, int16]]
  mate, slackFrom, top, parent, state: array[Slots, int16]
  seen: array[Slots, int32]
  members: array[Slots, array[Slots, int16]]
  memberCount: array[Slots, int16]
  childOf: array[Slots, array[MaxN + 1, int16]]
  queue: array[MaxN, int]
  queued: array[MaxN + 1, bool]
  head, tail, count: int

proc delta(m: Matcher, a, b: int): int64 =
  int64(m.dual[int(m.edgeA[a][b])] + m.dual[int(m.edgeB[a][b])] - 2 * m.weight[a][b])

proc enqueueLeaf(m: var Matcher, v: int) =
  if v <= 0 or v > m.n or m.queued[v]: return
  m.queue[m.tail] = v
  m.tail = (m.tail + 1) mod m.n
  inc m.count
  m.queued[v] = true

proc enqueueMembers(m: var Matcher, x: int) =
  if x <= m.n:
    m.enqueueLeaf(x)
  else:
    for i in 0 ..< int(m.memberCount[x]): m.enqueueMembers(int(m.members[x][i]))

proc setTop(m: var Matcher, x, b: int) =
  m.top[x] = int16(b)
  if x > m.n:
    for i in 0 ..< int(m.memberCount[x]): m.setTop(int(m.members[x][i]), b)

proc updateSlack(m: var Matcher, u, x: int) =
  let old = int(m.slackFrom[x])
  if old == 0 or m.delta(u, x) < m.delta(old, x): m.slackFrom[x] = int16(u)

proc refreshSlack(m: var Matcher, x: int) =
  m.slackFrom[x] = 0
  for u in 1 .. m.n:
    let component = int(m.top[u])
    if m.weight[u][x] > 0 and component != x and m.state[component] == 0:
      m.updateSlack(u, x)

proc cyclePosition(m: var Matcher, b, child: int): int =
  let size = int(m.memberCount[b])
  var pos = 0
  while pos < size and int(m.members[b][pos]) != child: inc pos
  if pos == size: return 0
  if (pos and 1) == 1:
    var left = 1
    var right = size - 1
    while left < right:
      swap(m.members[b][left], m.members[b][right])
      inc left
      dec right
    pos = size - pos
  pos

proc rotateCycle(m: var Matcher, b, start: int) =
  let size = int(m.memberCount[b])
  var copy: array[Slots, int16]
  for i in 0 ..< size: copy[i] = m.members[b][(i + start) mod size]
  for i in 0 ..< size: m.members[b][i] = copy[i]

proc setPair(m: var Matcher, u, v: int) =
  m.mate[u] = m.edgeB[u][v]
  if u <= m.n: return
  let leaf = int(m.edgeA[u][v])
  let entry = int(m.childOf[u][leaf])
  let pos = m.cyclePosition(u, entry)
  for i in 0 ..< pos: m.setPair(int(m.members[u][i]), int(m.members[u][i xor 1]))
  m.setPair(entry, v)
  m.rotateCycle(u, pos)

proc augment(m: var Matcher, uStart, vStart: int) =
  var u = uStart
  var v = vStart
  while true:
    let next = int(m.top[int(m.mate[u])])
    m.setPair(u, v)
    if next == 0: return
    let prior = int(m.top[int(m.parent[next])])
    m.setPair(next, prior)
    u = prior
    v = next

proc commonBase(m: var Matcher, uStart, vStart: int): int =
  inc m.epoch
  var u = uStart
  var v = vStart
  while u != 0 or v != 0:
    if u != 0:
      if m.seen[u] == m.epoch: return u
      m.seen[u] = m.epoch
      u = int(m.top[int(m.mate[u])])
      if u != 0: u = int(m.top[int(m.parent[u])])
    swap(u, v)
  0

proc addChild(m: var Matcher, b, x: int) =
  let at = int(m.memberCount[b])
  m.members[b][at] = int16(x)
  inc m.memberCount[b]

proc contract(m: var Matcher, u, base, v: int) =
  var b = m.n + 1
  while b <= m.nodes and m.top[b] != 0: inc b
  if b > m.nodes: inc m.nodes
  m.dual[b] = 0
  m.state[b] = 0
  m.mate[b] = m.mate[base]
  m.memberCount[b] = 0
  m.addChild(b, base)
  var x = u
  while x != base:
    m.addChild(b, x)
    let y = int(m.top[int(m.mate[x])])
    m.addChild(b, y)
    m.enqueueMembers(y)
    x = int(m.top[int(m.parent[y])])
  var left = 1
  var right = int(m.memberCount[b]) - 1
  while left < right:
    swap(m.members[b][left], m.members[b][right])
    inc left
    dec right
  x = v
  while x != base:
    m.addChild(b, x)
    let y = int(m.top[int(m.mate[x])])
    m.addChild(b, y)
    m.enqueueMembers(y)
    x = int(m.top[int(m.parent[y])])
  m.setTop(b, b)

  for y in 1 .. m.nodes:
    m.weight[b][y] = 0
    m.weight[y][b] = 0
    m.edgeA[b][y] = 0; m.edgeB[b][y] = 0
    m.edgeA[y][b] = 0; m.edgeB[y][b] = 0
  for leaf in 0 .. MaxN: m.childOf[b][leaf] = 0
  for i in 0 ..< int(m.memberCount[b]):
    let child = int(m.members[b][i])
    for y in 1 .. m.nodes:
      if m.weight[child][y] == 0: continue
      if m.weight[b][y] == 0 or m.delta(child, y) < m.delta(b, y):
        m.weight[b][y] = m.weight[child][y]
        m.edgeA[b][y] = m.edgeA[child][y]; m.edgeB[b][y] = m.edgeB[child][y]
        m.weight[y][b] = m.weight[y][child]
        m.edgeA[y][b] = m.edgeA[y][child]; m.edgeB[y][b] = m.edgeB[y][child]
    for leaf in 1 .. m.n:
      let contains = if child <= m.n: child == leaf else: m.childOf[child][leaf] != 0
      if contains: m.childOf[b][leaf] = int16(child)
  m.refreshSlack(b)

proc expand(m: var Matcher, b: int) =
  for i in 0 ..< int(m.memberCount[b]):
    let child = int(m.members[b][i])
    m.setTop(child, child)
  let outside = int(m.parent[b])
  let entryLeaf = int(m.edgeA[b][outside])
  let entry = int(m.childOf[b][entryLeaf])
  let pos = m.cyclePosition(b, entry)
  var i = 0
  while i < pos:
    let inner = int(m.members[b][i])
    let outer = int(m.members[b][i + 1])
    m.parent[inner] = m.edgeA[outer][inner]
    m.state[inner] = 1
    m.state[outer] = 0
    m.slackFrom[inner] = 0
    m.refreshSlack(outer)
    m.enqueueMembers(outer)
    i += 2
  m.state[entry] = 1
  m.parent[entry] = int16(outside)
  for i in pos + 1 ..< int(m.memberCount[b]):
    let child = int(m.members[b][i])
    m.state[child] = -1
    m.refreshSlack(child)
  m.top[b] = 0

proc processEdge(m: var Matcher, left, right: int): bool =
  let u = int(m.top[left])
  let v = int(m.top[right])
  if m.state[v] == -1:
    m.parent[v] = int16(left)
    m.state[v] = 1
    let next = int(m.top[int(m.mate[v])])
    m.slackFrom[v] = 0
    m.slackFrom[next] = 0
    m.state[next] = 0
    m.enqueueMembers(next)
  elif m.state[v] == 0:
    let base = m.commonBase(u, v)
    if base == 0:
      m.augment(u, v)
      m.augment(v, u)
      return true
    m.contract(u, base, v)
  false

proc stage(m: var Matcher): bool =
  for x in 0 .. m.nodes:
    m.state[x] = -1
    m.slackFrom[x] = 0
  m.head = 0; m.tail = 0; m.count = 0
  for i in 0 .. MaxN: m.queued[i] = false
  for x in 1 .. m.nodes:
    if int(m.top[x]) == x and m.mate[x] == 0:
      m.parent[x] = 0
      m.state[x] = 0
      m.enqueueMembers(x)
  if m.count == 0: return false

  while true:
    while m.count != 0:
      let u = m.queue[m.head]
      m.head = (m.head + 1) mod m.n
      dec m.count
      m.queued[u] = false
      if m.state[int(m.top[u])] == 1: continue
      for v in 1 .. m.n:
        if m.weight[u][v] == 0 or m.top[u] == m.top[v]: continue
        if m.delta(u, v) == 0:
          if m.processEdge(int(m.edgeA[u][v]), int(m.edgeB[u][v])): return true
        else:
          m.updateSlack(u, int(m.top[v]))

    var step = Infinity
    for u in 1 .. m.n:
      if m.state[int(m.top[u])] == 0: step = min(step, m.dual[u])
    for b in m.n + 1 .. m.nodes:
      if int(m.top[b]) == b and m.state[b] == 1: step = min(step, m.dual[b] div 2)
    for x in 1 .. m.nodes:
      if int(m.top[x]) != x or m.slackFrom[x] == 0: continue
      let slack = m.delta(int(m.slackFrom[x]), x)
      if m.state[x] == -1: step = min(step, slack)
      elif m.state[x] == 0: step = min(step, slack div 2)
    if step == Infinity: return false

    for u in 1 .. m.n:
      case m.state[int(m.top[u])]
      of 0:
        if m.dual[u] == step: return false
        m.dual[u] -= step
      of 1: m.dual[u] += step
      else: discard
    for b in m.n + 1 .. m.nodes:
      if int(m.top[b]) != b: continue
      if m.state[b] == 0: m.dual[b] += 2 * step
      elif m.state[b] == 1: m.dual[b] -= 2 * step
    for x in 1 .. m.nodes:
      if int(m.top[x]) == x and m.slackFrom[x] != 0 and int(m.top[int(m.slackFrom[x])]) != x and
          m.delta(int(m.slackFrom[x]), x) == 0:
        let source = int(m.slackFrom[x])
        if m.processEdge(int(m.edgeA[source][x]), int(m.edgeB[source][x])): return true
    for b in m.n + 1 .. m.nodes:
      if int(m.top[b]) == b and m.state[b] == 1 and m.dual[b] == 0: m.expand(b)

proc general_weighted_matching_primal_dual_blossom*(input: ptr UncheckedArray[int64], length: csize_t): int64
    {.cdecl, exportc: "general_weighted_matching_primal_dual_blossom".} =
  if input.isNil or length < 2 or length > 6051: return -2
  let nValue = input[0]
  let mValue = input[1]
  if nValue < 1 or nValue > MaxN or mValue < 0 or mValue > nValue * (nValue - 1) div 2: return -2
  let n = int(nValue)
  let edges = int(mValue)
  if int(length) != 2 + 3 * edges: return -2
  var search: Matcher
  search.n = n
  search.nodes = n
  var largest = 0'i64
  for i in 0 ..< edges:
    let uValue = input[2 + 3 * i]
    let vValue = input[3 + 3 * i]
    let weight = input[4 + 3 * i]
    if uValue < 0 or uValue >= nValue or vValue < 0 or vValue >= nValue or uValue == vValue or weight < 1 or weight > 1_000_000: return -2
    let u = int(uValue) + 1
    let v = int(vValue) + 1
    if search.weight[u][v] != 0: return -2
    search.weight[u][v] = weight
    search.weight[v][u] = weight
    search.edgeA[u][v] = int16(u); search.edgeB[u][v] = int16(v)
    search.edgeA[v][u] = int16(v); search.edgeB[v][u] = int16(u)
    largest = max(largest, weight)
  for u in 1 .. n:
    search.top[u] = int16(u)
    search.dual[u] = largest
    search.childOf[u][u] = int16(u)
  while search.stage(): discard
  var answer = 0'i64
  for u in 1 .. n:
    let v = int(search.mate[u])
    if v > u: answer += search.weight[u][v]
  answer
