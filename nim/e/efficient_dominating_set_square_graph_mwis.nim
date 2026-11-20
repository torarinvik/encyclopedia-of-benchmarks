## Efficient domination via weighted independent set on the square graph.
const MaxVertices = 12

proc bitCount(bits0: uint16): int =
  var bits = bits0
  while bits != 0'u16:
    bits = bits and (bits - 1'u16)
    inc result

proc weightedMis(square: array[MaxVertices, uint16], weights: array[MaxVertices, int],
                 remaining0: uint16, current: int, best: var int) =
  var upper = current
  for v in 0 ..< MaxVertices:
    if (remaining0 and (1'u16 shl v)) != 0'u16: upper += weights[v]
  if upper <= best: return
  if remaining0 == 0'u16:
    best = current
    return
  var branch = -1
  var branchDegree = -1
  for v in 0 ..< MaxVertices:
    if (remaining0 and (1'u16 shl v)) == 0'u16: continue
    let degree = bitCount(square[v] and remaining0)
    if degree > branchDegree:
      branch = v
      branchDegree = degree
  let bit = 1'u16 shl branch
  weightedMis(square, weights, remaining0 and not bit and not square[branch],
              current + weights[branch], best)
  weightedMis(square, weights, remaining0 and not bit, current, best)

proc efficient_dominating_set_square_graph_mwis*(input: ptr UncheckedArray[int64], length: csize_t): int64
    {.cdecl, exportc: "efficient_dominating_set_square_graph_mwis".} =
  if input.isNil or length < 2 or length > 135: return -1
  let n64 = input[0]
  let m64 = input[1]
  if n64 < 1 or n64 > MaxVertices or m64 < 0 or m64 > n64 * (n64 - 1) div 2:
    return -1
  if int64(length) != 2 + 2 * m64: return -1
  let n = int(n64)
  var adjacency: array[MaxVertices, uint16]
  for e in 0 ..< int(m64):
    let u64 = input[2 + 2 * e]
    let v64 = input[3 + 2 * e]
    if u64 < 0 or u64 >= v64 or v64 >= n64: return -1
    let u = int(u64)
    let v = int(v64)
    let vbit = 1'u16 shl v
    if (adjacency[u] and vbit) != 0'u16: return -1
    adjacency[u] = adjacency[u] or vbit
    adjacency[v] = adjacency[v] or (1'u16 shl u)

  var square: array[MaxVertices, uint16]
  var weights: array[MaxVertices, int]
  for v in 0 ..< n:
    square[v] = adjacency[v]
    for u in 0 ..< n:
      if (adjacency[v] and (1'u16 shl u)) != 0'u16: square[v] = square[v] or adjacency[u]
    square[v] = square[v] and not (1'u16 shl v)
    weights[v] = bitCount(adjacency[v]) + 1
  var best = 0
  let all = (1'u16 shl n) - 1'u16
  weightedMis(square, weights, all, 0, best)
  if best == n: 1 else: 0
