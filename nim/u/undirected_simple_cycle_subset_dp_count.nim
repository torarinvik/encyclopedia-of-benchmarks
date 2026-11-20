# Clean-room all-length simple-cycle subset DP; see package RIGHTS.md.
const MaxN = 14
const MaxM = 91
const MaxStates = 1 shl MaxN

proc undirected_simple_cycle_subset_dp_count*(input: ptr UncheckedArray[int64], length: csize_t): int64
    {.cdecl, exportc: "undirected_simple_cycle_subset_dp_count".} =
  if input.isNil or length < csize_t(2) or length > csize_t(185): return -1
  let n64 = input[0]
  let m64 = input[1]
  if n64 < 1 or n64 > int64(MaxN) or m64 < 0 or
      m64 > n64 * (n64 - 1) div 2 or m64 > int64(MaxM): return -1
  let n = int(n64)
  let m = int(m64)
  if int(length) != 2 + 2 * m: return -1

  var adjacency: array[MaxN, array[MaxN, bool]]
  var neighbors: array[MaxN, array[MaxN, int]]
  var degree: array[MaxN, int]
  var previousU = -1'i64
  var previousV = -1'i64
  for edge in 0..<m:
    let u64 = input[2 + 2 * edge]
    let v64 = input[3 + 2 * edge]
    if u64 < 0 or u64 >= n64 or v64 < 0 or v64 >= n64 or u64 >= v64: return -1
    if edge != 0 and (u64 < previousU or (u64 == previousU and v64 <= previousV)): return -1
    previousU = u64
    previousV = v64
    let u = int(u64)
    let v = int(v64)
    adjacency[u][v] = true
    adjacency[v][u] = true
    neighbors[u][degree[u]] = v
    inc degree[u]
    neighbors[v][degree[v]] = u
    inc degree[v]

  var dp: array[MaxStates * MaxN, int64]
  let stateCount = 1 shl n
  for start in 0..<n: dp[(1 shl start) * MaxN + start] = 1
  var orientedCycles = 0'i64
  for mask in 1..<stateCount:
    var start = 0
    while (mask and (1 shl start)) == 0: inc start
    var cardinality = 0
    for vertex in 0..<n:
      if (mask and (1 shl vertex)) != 0: inc cardinality
    for endpoint in 0..<n:
      if (mask and (1 shl endpoint)) == 0: continue
      let ways = dp[mask * MaxN + endpoint]
      if ways == 0: continue
      if cardinality >= 3 and adjacency[endpoint][start]: orientedCycles += ways
      for i in 0..<degree[endpoint]:
        let next = neighbors[endpoint][i]
        if next > start and (mask and (1 shl next)) == 0:
          dp[(mask or (1 shl next)) * MaxN + next] += ways
  orientedCycles div 2
