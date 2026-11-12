const MaxVertices = 16
const MaxEdges = 64
const MaxInput = 133
const MaxPaths = 162
const MaxOutput = 1296

proc enumerate(n, target: int, predecessor: var array[MaxVertices, array[MaxVertices, bool]],
    useful: var array[MaxVertices, bool], path: var array[MaxVertices, uint8], depth: int,
    staged: var array[MaxOutput, uint8], used, count: var int, overflow: var bool, u: int) =
  if overflow: return
  path[depth] = uint8(u)
  if u == target:
    if count >= MaxPaths or used + depth + 2 > MaxOutput:
      overflow = true
      return
    for i in 0 .. depth:
      staged[used] = path[i]
      inc used
    staged[used] = 0xff'u8
    inc used
    inc count
    return
  for v in 0 ..< n:
    if useful[v] and predecessor[v][u]:
      enumerate(n, target, predecessor, useful, path, depth + 1, staged, used, count, overflow, v)

proc all_shortest_paths_unweighted*(input: ptr UncheckedArray[int64], length: csize_t,
    output: ptr UncheckedArray[uint8], outputCapacity: csize_t): int64
    {.cdecl, exportc: "all_shortest_paths_unweighted".} =
  if input == nil or length < 4 or length > csize_t(MaxInput): return -1
  let nValue = input[0]
  let mValue = input[1]
  if nValue < 1 or nValue > MaxVertices or mValue < 0 or mValue > MaxEdges: return -1
  let n = int(nValue)
  let m = int(mValue)
  let sourceValue = input[2]
  let targetValue = input[3]
  if sourceValue < 0 or sourceValue >= nValue or targetValue < 0 or targetValue >= nValue or int(length) != 4 + 2 * m: return -1
  let source = int(sourceValue)
  let target = int(targetValue)

  var adjacent: array[MaxVertices, array[MaxVertices, bool]]
  for e in 0 ..< m:
    let rawU = input[4 + 2 * e]
    let rawV = input[5 + 2 * e]
    if rawU < 0 or rawU >= nValue or rawV < 0 or rawV >= nValue or rawU == rawV: return -1
    let u = int(rawU)
    let v = int(rawV)
    if adjacent[u][v]: return -1
    adjacent[u][v] = true
    adjacent[v][u] = true

  var distance: array[MaxVertices, int]
  var queue: array[MaxVertices, int]
  var predecessor: array[MaxVertices, array[MaxVertices, bool]]
  for v in 0 ..< n: distance[v] = -1
  var head = 0
  var tail = 0
  distance[source] = 0
  queue[tail] = source
  inc tail
  while head < tail:
    let u = queue[head]
    inc head
    for v in 0 ..< n:
      if not adjacent[u][v]: continue
      if distance[v] < 0:
        distance[v] = distance[u] + 1
        queue[tail] = v
        inc tail
      if distance[v] == distance[u] + 1: predecessor[v][u] = true

  var useful: array[MaxVertices, bool]
  if distance[target] >= 0:
    var stack: array[MaxVertices, int]
    var size = 0
    useful[target] = true
    stack[size] = target
    inc size
    while size > 0:
      dec size
      let v = stack[size]
      for u in 0 ..< n:
        if predecessor[v][u] and not useful[u]:
          useful[u] = true
          stack[size] = u
          inc size

  var staged: array[MaxOutput, uint8]
  var path: array[MaxVertices, uint8]
  var used = 0
  var count = 0
  var overflow = false
  if distance[target] >= 0:
    enumerate(n, target, predecessor, useful, path, 0, staged, used, count, overflow, source)
  if overflow: return -2
  if output == nil or outputCapacity < csize_t(used): return -2
  for i in 0 ..< used: output[i] = staged[i]
  int64(count)
