# Clean-room bounded port of GAPBS OrderedCount; see package LICENSE.txt.
const MaxN = 16

proc gapbs_ordered_triangle_count*(input: ptr UncheckedArray[int64], length: csize_t): int64
    {.cdecl, exportc: "gapbs_ordered_triangle_count".} =
  if input.isNil or length < csize_t(2) or length > csize_t(1 + MaxN * MaxN): return -1
  if input[0] < 1 or input[0] > int64(MaxN): return -1
  let n = int(input[0])
  if int(length) != 1 + n * n: return -1
  var adjacency: array[MaxN, array[MaxN, int64]]
  var neighbors: array[MaxN, array[MaxN, int]]
  var degree: array[MaxN, int]
  for u in 0..<n:
    for v in 0..<n:
      let edge = input[1 + u * n + v]
      if edge != 0 and edge != 1: return -1
      if u == v and edge != 0: return -1
      adjacency[u][v] = edge
  for u in 0..<n:
    for v in (u + 1)..<n:
      if adjacency[u][v] != adjacency[v][u]: return -1
  for u in 0..<n:
    for v in 0..<n:
      if adjacency[u][v] != 0:
        neighbors[u][degree[u]] = v
        inc degree[u]
  var total = 0'i64
  for u in 0..<n:
    for vi in 0..<degree[u]:
      let v = neighbors[u][vi]
      if v > u: break
      var edgePos = 0
      for wi in 0..<degree[u]:
        let w = neighbors[u][wi]
        if w > v: break
        while edgePos < degree[v] and neighbors[v][edgePos] < w:
          inc edgePos
        if edgePos < degree[v] and neighbors[v][edgePos] == w:
          inc total
  total
