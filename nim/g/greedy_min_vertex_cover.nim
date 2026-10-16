const MaxVertices = 16

proc bitCount(value: uint64): int =
  var remaining = value
  while remaining != 0:
    remaining = remaining and (remaining - 1)
    inc result

proc greedy_min_vertex_cover*(values: ptr UncheckedArray[int64], length: csize_t): int64
    {.cdecl, exportc: "greedy_min_vertex_cover".} =
  if values == nil or length < 2 or length > MaxVertices + 1: return -1
  let countValue = values[0]
  if countValue < 1 or countValue > MaxVertices.int64 or length.int != countValue.int + 1: return -1
  let count = countValue.int
  let limit = (1'u64 shl count) - 1
  var neighbors: array[MaxVertices, uint64]
  for vertex in 0..<count:
    let maskValue = values[vertex + 1]
    if maskValue < 0 or cast[uint64](maskValue) > limit: return -1
    let mask = cast[uint64](maskValue)
    if (mask and (1'u64 shl vertex)) != 0: return -1
    neighbors[vertex] = mask
  for vertex in 0..<count:
    for other in vertex + 1..<count:
      if ((neighbors[vertex] shr other) and 1) != ((neighbors[other] shr vertex) and 1): return -1
  var chosen = 0'u64
  while true:
    var bestVertex = -1
    var bestDegree = 0
    for vertex in 0..<count:
      let degree = bitCount(neighbors[vertex])
      if degree > bestDegree:
        bestVertex = vertex
        bestDegree = degree
    if bestVertex < 0: return cast[int64](chosen)
    let bit = 1'u64 shl bestVertex
    chosen = chosen or bit
    for vertex in 0..<count: neighbors[vertex] = neighbors[vertex] and not bit
    neighbors[bestVertex] = 0
