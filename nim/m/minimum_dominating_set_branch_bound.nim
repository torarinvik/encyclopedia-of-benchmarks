## Exact minimum dominating set by closed-neighborhood branch and bound.
const MaxN = 12
const MaxInput = 135

proc popcount(bitsValue: uint64): int =
  var bits = bitsValue
  while bits != 0:
    bits = bits and (bits - 1'u64)
    inc result

proc searchMds(closed: array[MaxN, uint64], n: int, full, covered: uint64,
               chosen: int, best: var int) =
  if chosen >= best: return
  if covered == full:
    best = chosen
    return
  let uncovered = full and not covered
  let uncoveredCount = popcount(uncovered)
  var maximumGain = 0
  for v in 0 ..< n: maximumGain = max(maximumGain, popcount(closed[v] and uncovered))
  let lowerBound = (uncoveredCount + maximumGain - 1) div maximumGain
  if chosen + lowerBound >= best: return

  var branch = -1
  var branchDegree = MaxN + 1
  for v in 0 ..< n:
    if (uncovered and (1'u64 shl v)) != 0:
      let degree = popcount(closed[v])
      if degree < branchDegree:
        branch = v
        branchDegree = degree
  var candidates: array[MaxN, int]
  var gains: array[MaxN, int]
  var count = 0
  for v in 0 ..< n:
    if (closed[branch] and (1'u64 shl v)) == 0: continue
    let gain = popcount(closed[v] and uncovered)
    var pos = count
    while pos > 0 and (gain > gains[pos - 1] or (gain == gains[pos - 1] and v < candidates[pos - 1])):
      gains[pos] = gains[pos - 1]
      candidates[pos] = candidates[pos - 1]
      dec pos
    gains[pos] = gain
    candidates[pos] = v
    inc count
  for i in 0 ..< count:
    let v = candidates[i]
    searchMds(closed, n, full, covered or closed[v], chosen + 1, best)

proc minimum_dominating_set_branch_bound*(packed: ptr UncheckedArray[int64], length: csize_t): int64
    {.cdecl, exportc: "minimum_dominating_set_branch_bound".} =
  if packed.isNil or length < 2 or length > csize_t(MaxInput): return -1
  let n64 = packed[0]
  let m64 = packed[1]
  if n64 < 1 or n64 > int64(MaxN): return -1
  let n = int(n64)
  let maxEdges = n * (n - 1) div 2
  if m64 < 0 or m64 > int64(maxEdges) or int(length) != 2 + 2 * int(m64): return -1
  var adjacency: array[MaxN, uint64]
  for edge in 0 ..< int(m64):
    let u64 = packed[2 + 2 * edge]
    let v64 = packed[3 + 2 * edge]
    if u64 < 0 or v64 < 0 or u64 >= n64 or v64 >= n64 or u64 == v64: return -1
    let u = int(u64); let v = int(v64)
    let bit = 1'u64 shl v
    if (adjacency[u] and bit) != 0: return -1
    adjacency[u] = adjacency[u] or bit
    adjacency[v] = adjacency[v] or (1'u64 shl u)
  var closed: array[MaxN, uint64]
  for v in 0 ..< n: closed[v] = adjacency[v] or (1'u64 shl v)
  let full = (1'u64 shl n) - 1'u64
  var covered = 0'u64
  var greedy = 0
  while covered != full:
    var vertex = 0
    var bestGain = -1
    for v in 0 ..< n:
      let gain = popcount(closed[v] and not covered)
      if gain > bestGain:
        vertex = v
        bestGain = gain
    covered = covered or closed[vertex]
    inc greedy
  var best = greedy
  searchMds(closed, n, full, 0, 0, best)
  int64(best)
