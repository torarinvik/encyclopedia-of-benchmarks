## Clean-room bounded GBBS Shiloach-Vishkin spanning-forest profile.
const MaxN = 12
const MaxM = 24
const MaxInput = 2 + 2 * MaxM

proc findRoot(parent: var array[MaxN, int], vertexIn: int): int =
  var vertex = vertexIn
  while parent[vertex] != vertex:
    parent[vertex] = parent[parent[vertex]]
    vertex = parent[vertex]
  return vertex

proc gbbs_shiloach_vishkin_spanning_forest*(input: ptr UncheckedArray[int64], length: csize_t,
    output: ptr UncheckedArray[uint8], capacity: csize_t): int64
    {.cdecl, exportc: "gbbs_shiloach_vishkin_spanning_forest".} =
  if input.isNil or length < csize_t(2) or length > csize_t(MaxInput): return -1
  let n64 = input[0]
  let m64 = input[1]
  if n64 < 1 or n64 > MaxN or m64 < 0 or m64 > MaxM or
      int64(length) != 2 + 2 * m64: return -1
  let n = int(n64)
  let m = int(m64)
  var seen: array[MaxN, array[MaxN, bool]]
  var edgeU, edgeV: array[MaxM, int]
  for edge in 0..<m:
    let u64 = input[2 + 2 * edge]
    let v64 = input[3 + 2 * edge]
    if u64 < 0 or u64 >= n64 or v64 <= u64 or v64 >= n64: return -1
    let u = int(u64)
    let v = int(v64)
    if seen[u][v]: return -1
    seen[u][v] = true
    edgeU[edge] = u
    edgeV[edge] = v
  if output.isNil or capacity < csize_t(m): return -2

  var parent, previous, nextParent, bestLower: array[MaxN, int]
  var selected: array[MaxM, uint8]
  for vertex in 0..<n: parent[vertex] = vertex
  for round in 0..<n:
    for vertex in 0..<n:
      previous[vertex] = findRoot(parent, vertex)
      nextParent[vertex] = previous[vertex]
      bestLower[vertex] = n
    for edge in 0..<m:
      let rootU = previous[edgeU[edge]]
      let rootV = previous[edgeV[edge]]
      if rootU == rootV: continue
      let lower = min(rootU, rootV)
      let higher = max(rootU, rootV)
      if previous[higher] == higher and lower < bestLower[higher]: bestLower[higher] = lower
    var changed = false
    for higher in 0..<n:
      let lower = bestLower[higher]
      if lower == n: continue
      nextParent[higher] = lower
      changed = true
      for edge in 0..<m:
        let rootU = previous[edgeU[edge]]
        let rootV = previous[edgeV[edge]]
        if (rootU == higher and rootV == lower) or (rootU == lower and rootV == higher):
          selected[edge] = 1
          break
    for vertex in 0..<n: parent[vertex] = findRoot(nextParent, vertex)
    if not changed: break
  for edge in 0..<m: output[edge] = selected[edge]
  return int64(m)
