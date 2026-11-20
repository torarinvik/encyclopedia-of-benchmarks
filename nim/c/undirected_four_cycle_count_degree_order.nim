# Clean-room degree-oriented simple C4 counter; see package RIGHTS.md.
const MaxN = 16
const MaxM = 64

proc undirected_four_cycle_count_degree_order*(input: ptr UncheckedArray[int64], length: csize_t): int64
    {.cdecl, exportc: "undirected_four_cycle_count_degree_order".} =
  if input.isNil or length < csize_t(2) or length > csize_t(131): return -1
  let n64 = input[0]
  let m64 = input[1]
  if n64 < 1 or n64 > int64(MaxN) or m64 < 0 or m64 > int64(MaxM): return -1
  let n = int(n64)
  let m = int(m64)
  if int(length) != 2 + 2 * m: return -1

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
    neighbors[u][degree[u]] = v
    inc degree[u]
    neighbors[v][degree[v]] = u
    inc degree[v]

  var order: array[MaxN, int]
  var rank: array[MaxN, int]
  for i in 0..<n: order[i] = i
  for i in 1..<n:
    let key = order[i]
    var j = i
    while j > 0:
      let prior = order[j - 1]
      if degree[prior] < degree[key] or (degree[prior] == degree[key] and prior < key): break
      order[j] = prior
      dec j
    order[j] = key
  for i in 0..<n: rank[order[i]] = i

  var count: array[MaxN, int64]
  var total = 0'i64
  for position in 0..<n:
    let pivot = order[position]
    for bi in 0..<degree[pivot]:
      let middle = neighbors[pivot][bi]
      if rank[middle] >= position: continue
      for ci in 0..<degree[middle]:
        let opposite = neighbors[middle][ci]
        if rank[opposite] < position:
          total += count[opposite]
          inc count[opposite]
    for vertex in 0..<n: count[vertex] = 0
  total
