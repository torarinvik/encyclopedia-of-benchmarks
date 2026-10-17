const MaxVertices = 64
const MaxOutputBytes = 1016

proc writeI64Le(output: ptr UncheckedArray[uint8], offset: int, value: int64) =
  var bits = cast[uint64](value)
  for byte in 0 ..< 8:
    output[offset + byte] = uint8(bits and 255'u64)
    bits = bits shr 8

proc makeCode(input: ptr UncheckedArray[int64], n: int,
              code: var array[MaxVertices, int64]): int =
  var adjacency: array[MaxVertices * MaxVertices, bool]
  var degree: array[MaxVertices, int]
  for edge in 0 ..< n - 1:
    let rawU = input[2 + edge * 2]
    let rawV = input[3 + edge * 2]
    if rawU < 0 or rawV < 0 or rawU >= int64(n) or rawV >= int64(n) or rawU == rawV: return -1
    let u = int(rawU)
    let v = int(rawV)
    if adjacency[u * MaxVertices + v]: return -1
    adjacency[u * MaxVertices + v] = true
    adjacency[v * MaxVertices + u] = true
    inc degree[u]
    inc degree[v]
  var visited: array[MaxVertices, bool]
  var queue: array[MaxVertices, int]
  var head = 0
  var tail = 0
  visited[0] = true
  queue[tail] = 0
  inc tail
  while head < tail:
    let u = queue[head]
    inc head
    for v in 0 ..< n:
      if adjacency[u * MaxVertices + v] and not visited[v]:
        visited[v] = true
        queue[tail] = v
        inc tail
  if tail != n: return -1
  var active: array[MaxVertices, bool]
  for v in 0 ..< n: active[v] = true
  var codeLength = 0
  for _ in 0 ..< max(0, n - 2):
    var leaf = -1
    for v in countdown(n - 1, 0):
      if active[v] and degree[v] == 1:
        leaf = v
        break
    if leaf < 0: return -1
    var neighbor = -1
    for v in 0 ..< n:
      if active[v] and adjacency[leaf * MaxVertices + v]:
        neighbor = v
        break
    if neighbor < 0: return -1
    code[codeLength] = int64(neighbor)
    inc codeLength
    active[leaf] = false
    adjacency[leaf * MaxVertices + neighbor] = false
    adjacency[neighbor * MaxVertices + leaf] = false
    dec degree[neighbor]
  codeLength

proc addEdge(edges: var array[(MaxVertices - 1) * 2, int64], index, u, v: int) =
  edges[index * 2] = int64(min(u, v))
  edges[index * 2 + 1] = int64(max(u, v))

proc makeDecodedEdges(input: ptr UncheckedArray[int64], n: int,
                      edges: var array[(MaxVertices - 1) * 2, int64]): int =
  var remaining: array[MaxVertices, int]
  for i in 0 ..< n - 2:
    let raw = input[2 + i]
    if raw < 0 or raw >= int64(n): return -1
    inc remaining[int(raw)]
  var active: array[MaxVertices, bool]
  for v in 0 ..< n: active[v] = true
  var edgeCount = 0
  for i in 0 ..< n - 2:
    var leaf = -1
    for v in countdown(n - 1, 0):
      if active[v] and remaining[v] == 0:
        leaf = v
        break
    if leaf < 0: return -1
    let vertex = int(input[2 + i])
    addEdge(edges, edgeCount, leaf, vertex)
    inc edgeCount
    active[leaf] = false
    dec remaining[vertex]
  var first = -1
  for v in countdown(n - 1, 0):
    if active[v]:
      first = v
      break
  if first < 0: return -1
  active[first] = false
  var second = -1
  for v in countdown(n - 1, 0):
    if active[v]:
      second = v
      break
  if second < 0: return -1
  addEdge(edges, edgeCount, first, second)
  inc edgeCount
  for i in 1 ..< edgeCount:
    let u = edges[i * 2]
    let v = edges[i * 2 + 1]
    var j = i
    while j > 0 and (edges[(j - 1) * 2] > u or
        (edges[(j - 1) * 2] == u and edges[(j - 1) * 2 + 1] > v)):
      edges[j * 2] = edges[(j - 1) * 2]
      edges[j * 2 + 1] = edges[(j - 1) * 2 + 1]
      dec j
    edges[j * 2] = u
    edges[j * 2 + 1] = v
  edgeCount

proc prufer_code*(input: ptr UncheckedArray[int64], length: csize_t,
                  output: ptr UncheckedArray[uint8], capacity: csize_t): int64
    {.cdecl, exportc: "prufer_code".} =
  if input == nil or length < 2 or length > 129: return -1
  let mode = input[0]
  let rawN = input[1]
  if rawN < 1 or rawN > MaxVertices or (mode != 0 and mode != 1): return -1
  let n = int(rawN)
  if mode == 0:
    if length != csize_t(2 * n): return -1
    var code: array[MaxVertices, int64]
    let codeLength = makeCode(input, n, code)
    if codeLength < 0: return -1
    let needed = codeLength * 8
    if needed == 0: return 0
    if output == nil or capacity < csize_t(needed): return -2
    for i in 0 ..< codeLength: writeI64Le(output, i * 8, code[i])
    return int64(needed)
  if n < 2 or length != csize_t(n): return -1
  var edges: array[(MaxVertices - 1) * 2, int64]
  let edgeCount = makeDecodedEdges(input, n, edges)
  if edgeCount < 0: return -1
  let needed = 8 + edgeCount * 16
  if needed > MaxOutputBytes: return -1
  if output == nil or capacity < csize_t(needed): return -2
  writeI64Le(output, 0, int64(edgeCount))
  for i in 0 ..< edgeCount:
    writeI64Le(output, 8 + i * 16, edges[i * 2])
    writeI64Le(output, 16 + i * 16, edges[i * 2 + 1])
  int64(needed)
