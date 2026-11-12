## Exact MIS by maximum-degree branching and a greedy clique-cover bound.
const MaxN = 22
const MaxInput = 465

proc popcount(bits: uint64): int =
  var remaining = bits
  while remaining != 0:
    remaining = remaining and (remaining - 1'u64)
    inc result

proc cliqueCoverBound(adjacency: array[MaxN, uint64], remainingInput: uint64): int =
  var remaining = remainingInput
  while remaining != 0:
    inc result
    var candidates = remaining
    while candidates != 0:
      var vertex = 0
      while (candidates and (1'u64 shl vertex)) == 0: inc vertex
      let bit = 1'u64 shl vertex
      remaining = remaining and not bit
      candidates = candidates and not bit and adjacency[vertex]

proc searchMis(adjacency: array[MaxN, uint64], n: int, remaining: uint64,
               chosen: int, best: var int) =
  if remaining == 0:
    best = max(best, chosen)
    return
  if chosen + popcount(remaining) <= best: return
  if chosen + cliqueCoverBound(adjacency, remaining) <= best: return
  var branch = -1
  var branchDegree = -1
  for vertex in 0 ..< n:
    let bit = 1'u64 shl vertex
    if (remaining and bit) != 0:
      let degree = popcount(adjacency[vertex] and remaining)
      if degree > branchDegree:
        branch = vertex
        branchDegree = degree
  let bit = 1'u64 shl branch
  searchMis(adjacency, n, remaining and not bit and not adjacency[branch], chosen + 1, best)
  searchMis(adjacency, n, remaining and not bit, chosen, best)

proc maximum_independent_set*(packed: ptr UncheckedArray[int64], length: csize_t): int64
    {.cdecl, exportc: "maximum_independent_set".} =
  if packed.isNil or length < 2 or length > csize_t(MaxInput): return -1
  let n64 = packed[0]
  let m64 = packed[1]
  if n64 < 0 or n64 > int64(MaxN): return -1
  let n = int(n64)
  let maxEdges = n * (n - 1) div 2
  if m64 < 0 or m64 > int64(maxEdges) or int(length) != 2 + 2 * int(m64): return -1
  var adjacency: array[MaxN, uint64]
  for edge in 0 ..< int(m64):
    let u64 = packed[2 + 2 * edge]
    let v64 = packed[3 + 2 * edge]
    if u64 < 0 or v64 < 0 or u64 >= n64 or v64 >= n64 or u64 == v64: return -1
    let u = int(u64)
    let v = int(v64)
    let vBit = 1'u64 shl v
    if (adjacency[u] and vBit) != 0: return -1
    adjacency[u] = adjacency[u] or vBit
    adjacency[v] = adjacency[v] or (1'u64 shl u)
  var best = 0
  let allVertices = (1'u64 shl n) - 1'u64
  searchMis(adjacency, n, allVertices, 0, best)
  int64(best)
