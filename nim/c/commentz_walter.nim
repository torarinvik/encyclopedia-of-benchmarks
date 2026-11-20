const CwP = 6
const CwL = 8
const CwT = 64
const CwNodes = 33
const CwInput = 105

proc cwIsSuffix(v, u: int, depth: array[CwNodes, int],
                path: array[CwNodes, array[CwL, int64]]): bool =
  if depth[v] >= depth[u]: return false
  let offset = depth[u] - depth[v]
  for i in 0 ..< depth[v]:
    if path[v][i] != path[u][offset + i]: return false
  true

proc commentz_walter*(values: ptr UncheckedArray[int64], length: csize_t): int64
    {.cdecl, exportc: "commentz_walter".} =
  if values == nil or length < 2 or length > csize_t(CwInput): return -1
  let pv = values[0]
  let nv = values[1]
  if pv < 1 or pv > CwP or nv < 0 or nv > CwT: return -1
  let p = int(pv)
  let n = int(nv)
  if length < csize_t(2 + p): return -1
  var lens: array[CwP, int]
  var total = 0
  var shortest = CwL + 1
  for i in 0 ..< p:
    let raw = values[2 + i]
    if raw < 1 or raw > CwL: return -1
    lens[i] = int(raw)
    total += lens[i]
    shortest = min(shortest, lens[i])
  if total > 32 or length != csize_t(2 + p + total + n): return -1
  var patterns: array[CwP, array[CwL, int64]]
  var text: array[CwT, int64]
  var at = 2 + p
  for i in 0 ..< p:
    for j in 0 ..< lens[i]:
      let symbol = values[at]
      inc at
      if symbol < 1 or symbol > 4: return -1
      patterns[i][j] = symbol
    for prior in 0 ..< i:
      if lens[prior] != lens[i]: continue
      var same = true
      for j in 0 ..< lens[i]:
        if patterns[prior][j] != patterns[i][j]: same = false
      if same: return -1
  for i in 0 ..< n:
    let symbol = values[at]
    inc at
    if symbol < 1 or symbol > 4: return -1
    text[i] = symbol

  var child: array[CwNodes, array[5, int]]
  var parent, label, depth: array[CwNodes, int]
  var path: array[CwNodes, array[CwL, int64]]
  var terminal: array[CwNodes, bool]
  var nodes = 1
  for i in 0 ..< p:
    var v = 0
    for j in countdown(lens[i] - 1, 0):
      let symbol = int(patterns[i][j])
      var encoded = child[v][symbol]
      if encoded == 0:
        let u = nodes
        inc nodes
        child[v][symbol] = u + 1
        parent[u] = v
        label[u] = symbol
        depth[u] = depth[v] + 1
        for k in 0 ..< depth[v]: path[u][k] = path[v][k]
        path[u][depth[v]] = int64(symbol)
        encoded = u + 1
      v = encoded - 1
    terminal[v] = true

  var shift1, shift2: array[CwNodes, int]
  var bad: array[5, int]
  for v in 0 ..< nodes:
    shift1[v] = shortest
    shift2[v] = shortest
  shift1[0] = 1
  for a in 0 .. 4: bad[a] = shortest + 1
  for v in 1 ..< nodes:
    bad[label[v]] = min(bad[label[v]], depth[v])
    shift2[v] = shift2[parent[v]]
    for u in 1 ..< nodes:
      if cwIsSuffix(v, u, depth, path):
        let delta = depth[u] - depth[v]
        shift1[v] = min(shift1[v], delta)
        if terminal[u]: shift2[v] = min(shift2[v], delta)

  var matches = 0'i64
  var position = shortest - 1
  while position < n:
    var v = 0
    var i = position
    while i >= 0:
      let encoded = child[v][int(text[i])]
      if encoded == 0: break
      v = encoded - 1
      dec i
      if terminal[v]: inc matches
    let symbol = if i >= 0: int(text[i]) else: 0
    let charShift = if symbol == 0: shortest + 1 else: bad[symbol]
    let delta = min(shift2[v], max(shift1[v], charShift - depth[v] - 1))
    position += delta
  matches
