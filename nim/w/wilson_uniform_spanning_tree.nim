const MaxN = 8
const MaxEdges = 28
const WalkLimit = 64
const MaxInput = 4 + 2 * MaxEdges + WalkLimit * (MaxN - 1)

proc writeI64Le(output: ptr UncheckedArray[uint8], offset: int, value: int64) =
  let bits = cast[uint64](value)
  for byte in 0 ..< 8:
    output[offset + byte] = uint8((bits shr (8 * byte)) and 255'u64)

proc wilson_uniform_spanning_tree*(input: ptr UncheckedArray[int64], length: csize_t,
    output: ptr UncheckedArray[uint8], capacity: csize_t): int64 {.cdecl, exportc.} =
  if input.isNil or length < 4 or length > csize_t(MaxInput + 1): return -1
  let nRaw = input[0]
  let mRaw = input[1]
  let rootRaw = input[2]
  if nRaw < 1 or nRaw > MaxN or mRaw < 0 or mRaw > MaxEdges: return -1
  let n = int(nRaw)
  let m = int(mRaw)
  if rootRaw < 0 or rootRaw >= nRaw: return -1
  let root = int(rootRaw)
  let qAt = 3 + 2 * m
  if int(length) <= qAt: return -1
  let qRaw = input[qAt]
  if qRaw < 0 or qRaw > int64(WalkLimit) * int64(n - 1): return -1
  let q = int(qRaw)
  if int(length) != qAt + 1 + q: return -1

  var neighbors: array[MaxN, array[MaxN - 1, int]]
  var degree: array[MaxN, int]
  var prevU = -1'i64
  var prevV = -1'i64
  for edge in 0 ..< m:
    let uRaw = input[3 + 2 * edge]
    let vRaw = input[4 + 2 * edge]
    if uRaw < 0 or uRaw >= vRaw or vRaw >= nRaw: return -1
    if edge > 0 and (uRaw < prevU or (uRaw == prevU and vRaw <= prevV)): return -1
    prevU = uRaw
    prevV = vRaw
    let u = int(uRaw)
    let v = int(vRaw)
    neighbors[u][degree[u]] = v
    inc degree[u]
    neighbors[v][degree[v]] = u
    inc degree[v]
  for draw in 0 ..< q:
    let value = input[qAt + 1 + draw]
    if value < 0 or value > int64(MaxN - 2): return -1

  var seen: array[MaxN, bool]
  var queue: array[MaxN, int]
  var head = 0
  var tail = 0
  seen[root] = true
  queue[tail] = root
  inc tail
  while head < tail:
    let at = queue[head]
    inc head
    for k in 0 ..< degree[at]:
      let to = neighbors[at][k]
      if not seen[to]:
        seen[to] = true
        queue[tail] = to
        inc tail
  for vertex in 0 ..< n:
    if not seen[vertex]: return -1

  var inTree: array[MaxN, bool]
  var successor: array[MaxN, int]
  for i in 0 ..< MaxN: successor[i] = -1
  inTree[root] = true
  var cursor = 0
  for start in 0 ..< n:
    if inTree[start]: continue
    var current = start
    var steps = 0
    while not inTree[current]:
      if steps >= WalkLimit or cursor >= q: return -1
      let choice = int(input[qAt + 1 + cursor])
      if choice >= degree[current]: return -1
      successor[current] = neighbors[current][choice]
      current = successor[current]
      inc cursor
      inc steps
    current = start
    while not inTree[current]:
      inTree[current] = true
      current = successor[current]
  if cursor != q: return -1

  let required = 16 * (n - 1)
  if (required > 0 and output.isNil) or int(capacity) < required: return -2
  var offset = 0
  for child in 0 ..< n:
    if child == root: continue
    writeI64Le(output, offset, int64(child))
    offset += 8
    writeI64Le(output, offset, int64(successor[child]))
    offset += 8
  int64(required)
