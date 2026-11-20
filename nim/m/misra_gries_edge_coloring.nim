const MaxLength = 15
const SignatureBase = 262144'i64

proc freeColor(vertex: int, color: int64, vertices: int,
               edgeAt: array[36, int], colors: array[6, int64]): bool =
  for other in 0 ..< vertices:
    let edge = edgeAt[vertex * 6 + other]
    if edge >= 0 and colors[edge] == color: return false
  true

proc misra_gries_edge_coloring*(input: ptr UncheckedArray[int64], length: csize_t): int64
    {.cdecl, exportc: "misra_gries_edge_coloring".} =
  if input.isNil or length < 2 or length > csize_t(MaxLength): return -1
  if input[0] < 1 or input[0] > 6 or input[1] < 0 or input[1] > 6: return -1
  let vertices = int(input[0])
  let edgeCount = int(input[1])
  if length != csize_t(2 + 2 * edgeCount): return -1
  var left: array[6, int]
  var right: array[6, int]
  var degree: array[6, int]
  var edgeAt: array[36, int]
  for i in 0 ..< 36: edgeAt[i] = -1
  for edge in 0 ..< edgeCount:
    let a = input[2 + 2 * edge]
    let b = input[3 + 2 * edge]
    if a < 0 or b < 0 or a >= int64(vertices) or b >= int64(vertices) or a == b: return -1
    let u = int(min(a, b))
    let v = int(max(a, b))
    if edgeAt[u * 6 + v] >= 0: return -1
    left[edge] = u; right[edge] = v
    edgeAt[u * 6 + v] = edge; edgeAt[v * 6 + u] = edge
    inc degree[u]; inc degree[v]
  var delta = 0
  for vertex in 0 ..< vertices:
    if degree[vertex] > delta: delta = degree[vertex]
  let palette = if edgeCount == 0: 0 else: delta + 1
  var colors: array[6, int64]
  for edge in 0 ..< 6: colors[edge] = -1

  for edge in 0 ..< edgeCount:
    let center = left[edge]
    var fan: array[6, int]
    var fanCount = 1
    fan[0] = right[edge]
    while true:
      let tail = fan[fanCount - 1]
      var extended = false
      for neighbor in 0 ..< vertices:
        let candidate = edgeAt[center * 6 + neighbor]
        if candidate < 0 or colors[candidate] < 0: continue
        var present = false
        for i in 0 ..< fanCount:
          if fan[i] == neighbor: present = true
        if present or not freeColor(tail, colors[candidate], vertices, edgeAt, colors): continue
        fan[fanCount] = neighbor
        inc fanCount
        extended = true
        break
      if not extended: break
    var colorC = 0'i64
    while colorC < int64(palette) and not freeColor(center, colorC, vertices, edgeAt, colors): inc colorC
    var colorD = 0'i64
    while colorD < int64(palette) and not freeColor(fan[fanCount - 1], colorD, vertices, edgeAt, colors): inc colorD
    if colorC >= int64(palette) or colorD >= int64(palette): return -1

    var path: array[6, int]
    var pathCount = 0
    var current = center
    var wanted = colorD
    var visited: array[6, bool]
    visited[current] = true
    for step in 0 ..< vertices:
      var pathEdge = -1
      var next = 0
      for neighbor in 0 ..< vertices:
        let candidate = edgeAt[current * 6 + neighbor]
        if candidate >= 0 and colors[candidate] == wanted:
          pathEdge = candidate; next = neighbor; break
      if pathEdge < 0 or visited[next]: break
      path[pathCount] = pathEdge
      inc pathCount
      visited[next] = true
      current = next
      wanted = if wanted == colorD: colorC else: colorD
    for i in 0 ..< pathCount:
      colors[path[i]] = if colors[path[i]] == colorD: colorC else: colorD

    var prefixEnd = fanCount
    for i in 0 ..< fanCount:
      if freeColor(fan[i], colorD, vertices, edgeAt, colors): prefixEnd = i; break
    if prefixEnd == fanCount: return -1
    var shifted: array[6, int64]
    for i in 0 ..< prefixEnd: shifted[i] = colors[edgeAt[center * 6 + fan[i + 1]]]
    for i in 0 ..< prefixEnd: colors[edgeAt[center * 6 + fan[i]]] = shifted[i]
    colors[edgeAt[center * 6 + fan[prefixEnd]]] = colorD

  var signature = 0'i64
  for edge in 0 ..< edgeCount: signature = signature or (colors[edge] shl (3 * edge))
  int64(palette) * SignatureBase + signature
