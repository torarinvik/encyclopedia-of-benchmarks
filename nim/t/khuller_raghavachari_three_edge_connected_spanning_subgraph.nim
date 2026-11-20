const MaxN = 8
const MaxM = 28
const MaxInput = 59

proc put(outp: ptr UncheckedArray[uint8], at: int, value: int64) =
  let bits = cast[uint64](value)
  for byte in 0..<8: outp[at + byte] = uint8((bits shr (8 * byte)) and 255)

proc khuller_raghavachari_three_edge_connected_spanning_subgraph*(
    input: ptr UncheckedArray[int64], length: csize_t,
    output: ptr UncheckedArray[uint8], capacity: csize_t): int64 {.cdecl, exportc:"khuller_raghavachari_three_edge_connected_spanning_subgraph".} =
  if input.isNil or length < 2 or length > csize_t(MaxInput): return -1
  let n0 = input[0]
  let m0 = input[1]
  if n0 < 4 or n0 > 8 or m0 < 6 or m0 > 28: return -1
  let n = int(n0)
  let m = int(m0)
  if int(length) != 2 + 2 * m: return -1
  var u, v: array[MaxM, int]
  for edge in 0..<m:
    let a = input[2 + 2 * edge]
    let b = input[3 + 2 * edge]
    if a < 0 or a >= b or b >= n0: return -1
    u[edge] = int(a)
    v[edge] = int(b)
    for prior in 0..<edge:
      if u[prior] == u[edge] and v[prior] == v[edge]: return -1
  let full = (1 shl n) - 1
  for side in 1..<full:
    if (side and 1) == 0: continue
    var cut = 0
    for edge in 0..<m:
      if ((side shr u[edge]) and 1) != ((side shr v[edge]) and 1): inc cut
    if cut < 3: return -1

  var selected: array[MaxM, bool]
  var state, discovery, finish, parent, parentEdge: array[MaxN, int]
  var postorder, stackVertex, stackSlot: array[MaxN, int]
  var postCount = 0
  var clock = 1
  var top = 1
  state[0] = 1
  discovery[0] = 0
  parent[0] = n
  parentEdge[0] = m
  stackVertex[0] = 0
  while top > 0:
    let frame = top - 1
    let x = stackVertex[frame]
    if stackSlot[frame] < m:
      let edge = stackSlot[frame]
      inc stackSlot[frame]
      var y = n
      if u[edge] == x: y = v[edge]
      elif v[edge] == x: y = u[edge]
      if y == n or state[y] != 0: continue
      selected[edge] = true
      state[y] = 1
      parent[y] = x
      parentEdge[y] = edge
      discovery[y] = clock
      inc clock
      stackVertex[top] = y
      stackSlot[top] = 0
      inc top
      continue
    state[x] = 2
    finish[x] = clock
    if parentEdge[x] < m:
      postorder[postCount] = parentEdge[x]
      inc postCount
    dec top

  for position in 0..<postCount:
    let treeEdge = postorder[position]
    let child = if parentEdge[u[treeEdge]] == treeEdge: u[treeEdge] else: v[treeEdge]
    let upper = parent[child]
    var separated = false
    for removed in 0..<m:
      if separated or not selected[removed]: continue
      var seen: array[MaxN, bool]
      var queue: array[MaxN, int]
      var head = 0
      var tail = 1
      seen[upper] = true
      queue[0] = upper
      while head < tail:
        let current = queue[head]
        inc head
        for edge in 0..<m:
          if not selected[edge] or edge == removed: continue
          var next = n
          if u[edge] == current: next = v[edge]
          elif v[edge] == current: next = u[edge]
          if next < n and not seen[next]:
            seen[next] = true
            queue[tail] = next
            inc tail
      if not seen[child]: separated = true
    if not separated: continue
    var candidate = m
    var earliest = n
    for edge in 0..<m:
      if selected[edge]: continue
      let uInside = discovery[child] <= discovery[u[edge]] and discovery[u[edge]] < finish[child]
      let vInside = discovery[child] <= discovery[v[edge]] and discovery[v[edge]] < finish[child]
      if uInside == vInside: continue
      let ancestor = if uInside: v[edge] else: u[edge]
      if discovery[ancestor] < earliest:
        earliest = discovery[ancestor]
        candidate = edge
    if candidate == m: return -1
    selected[candidate] = true

  var leader: array[MaxN, int]
  for vertex in 0..<n: leader[vertex] = vertex
  for edge in 0..<m:
    if selected[edge]: continue
    var a = u[edge]
    var b = v[edge]
    while leader[a] != a:
      leader[a] = leader[leader[a]]
      a = leader[a]
    while leader[b] != b:
      leader[b] = leader[leader[b]]
      b = leader[b]
    if a != b:
      leader[b] = a
      selected[edge] = true
  var count = 0
  for edge in 0..<m:
    if selected[edge]: inc count
  let bytes = 8 * (1 + 2 * count)
  if output.isNil or int(capacity) < bytes: return -2
  put(output, 0, int64(count))
  var slot = 0
  for edge in 0..<m:
    if not selected[edge]: continue
    put(output, 8 * (1 + 2 * slot), int64(u[edge]))
    put(output, 8 * (2 + 2 * slot), int64(v[edge]))
    inc slot
  int64(bytes)
