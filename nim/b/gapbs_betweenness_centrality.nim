# Clean-room bounded Brandes profile; see package LICENSE.txt.
const MaxN = 8

proc gapbs_betweenness_centrality*(input: ptr UncheckedArray[int64], length: csize_t): int64
    {.cdecl, exportc: "gapbs_betweenness_centrality".} =
  if input == nil or length < 12 or length > 74: return -1
  if input[0] < 3 or input[0] > int64(MaxN) or input[1] < 1 or input[1] > input[0]: return -1
  let n = int(input[0])
  let k = int(input[1])
  if int(length) != 2 + k + n*n: return -1
  var sources: array[MaxN, int]
  for i in 0 ..< k:
    let raw = input[2+i]
    if raw < 0 or raw >= int64(n): return -1
    sources[i] = int(raw)
    for j in 0 ..< i:
      if sources[j] == sources[i]: return -1
  var adjacency: array[MaxN, array[MaxN, int]]
  for u in 0 ..< n:
    for v in 0 ..< n:
      let edge = input[2+k+u*n+v]
      if edge != 0 and edge != 1: return -1
      if u == v and edge != 0: return -1
      adjacency[u][v] = int(edge)
  for u in 0 ..< n:
    for v in (u+1) ..< n:
      if adjacency[u][v] != adjacency[v][u]: return -1

  var scores: array[MaxN, float32]
  for si in 0 ..< k:
    var depth: array[MaxN, int]
    var queue: array[MaxN, int]
    var paths: array[MaxN, float64]
    var delta: array[MaxN, float32]
    for v in 0 ..< n: depth[v] = -1
    let source = sources[si]
    depth[source] = 0
    paths[source] = 1.0
    var head = 0
    var tail = 1
    queue[0] = source
    while head < tail:
      let u = queue[head]
      inc head
      for v in 0 ..< n:
        if adjacency[u][v] != 0:
          if depth[v] == -1:
            depth[v] = depth[u] + 1
            queue[tail] = v
            inc tail
          if depth[v] == depth[u] + 1:
            paths[v] += paths[u]
    var maxDepth = 0
    for v in 0 ..< n:
      if depth[v] > maxDepth: maxDepth = depth[v]
    for d in countdown(maxDepth, 0):
      for u in 0 ..< n:
        if depth[u] == d:
          var deltaU = 0.0'f32
          for v in 0 ..< n:
            if adjacency[u][v] != 0 and depth[v] == d + 1:
              let onePlus = 1.0'f32 + delta[v]
              let contribution = (paths[u] / paths[v]) * float64(onePlus)
              deltaU = float32(float64(deltaU) + contribution)
          delta[u] = deltaU
          scores[u] = float32(float64(scores[u]) + float64(deltaU))
  var biggest = 0.0'f32
  for v in 0 ..< n:
    if scores[v] > biggest: biggest = scores[v]
  if biggest <= 0.0'f32: return -1
  var checksum = 0'i64
  for v in 0 ..< n:
    let normalized = scores[v] / biggest
    let qscore = int64(float64(normalized) * 1000.0 + 0.5)
    checksum += int64(v+1) * qscore
  checksum
