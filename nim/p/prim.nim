## Dense Prim scan over a bounded packed undirected edge list.
proc prim*(values: ptr UncheckedArray[int64], length: csize_t): int64 {.cdecl, exportc: "prim".} =
  if values == nil or length < 2 or length > 12290:
    return -2
  if values[0] < 0 or values[0] > 64 or values[1] < 0 or values[1] > 4096:
    return -2
  let vertices = int(values[0])
  let edges = int(values[1])
  if int(length) != 2 + 3 * edges or (vertices == 0 and edges != 0):
    return -2
  if vertices == 0:
    return 0

  var present: array[4096, bool]
  var weights: array[4096, int64]
  for edge in 0 ..< edges:
    let uValue = values[2 + 3 * edge]
    let vValue = values[3 + 3 * edge]
    let cost = values[4 + 3 * edge]
    if uValue < 0 or vValue < 0 or uValue >= int64(vertices) or vValue >= int64(vertices) or cost < 0 or cost > 2147483647'i64:
      return -2
    let u = int(uValue)
    let v = int(vValue)
    if u != v:
      let uv = u * 64 + v
      let vu = v * 64 + u
      if not present[uv] or cost < weights[uv]:
        present[uv] = true
        present[vu] = true
        weights[uv] = cost
        weights[vu] = cost

  var inTree: array[64, bool]
  var hasBest: array[64, bool]
  var best: array[64, int64]
  hasBest[0] = true
  var total = 0'i64
  for step in 0 ..< vertices:
    var selected = vertices
    for vertex in 0 ..< vertices:
      if not inTree[vertex] and hasBest[vertex] and (selected == vertices or best[vertex] < best[selected]):
        selected = vertex
    if selected == vertices:
      return -1
    inTree[selected] = true
    total += best[selected]
    for vertex in 0 ..< vertices:
      let slot = selected * 64 + vertex
      if not inTree[vertex] and present[slot] and (not hasBest[vertex] or weights[slot] < best[vertex]):
        hasBest[vertex] = true
        best[vertex] = weights[slot]
  total
