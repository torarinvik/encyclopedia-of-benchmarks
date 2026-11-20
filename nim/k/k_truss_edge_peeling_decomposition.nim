# Clean-room bounded edge-peeling truss decomposition.
const MaxN = 16
const MaxM = 120
const MaxParseableInput = 243

proc storeI64LE(output: ptr UncheckedArray[uint8], offset: int, value: int64) =
  let bits = cast[uint64](value)
  for byte in 0..<8:
    output[offset + byte] = uint8((bits shr (byte * 8)) and 255)

proc k_truss_edge_peeling_decomposition*(input: ptr UncheckedArray[int64], length: csize_t,
    output: ptr UncheckedArray[uint8], capacity: csize_t): int64
    {.cdecl, exportc: "k_truss_edge_peeling_decomposition".} =
  if input.isNil or length < csize_t(2) or length > csize_t(MaxParseableInput): return -1
  let n64 = input[0]
  let m64 = input[1]
  if n64 < 1 or n64 > int64(MaxN) or m64 < 0 or m64 > int64(MaxM) or
      2 + 2 * m64 != int64(length) or length > csize_t(242): return -1
  let n = int(n64)
  let m = int(m64)
  var adjacent: array[MaxN, array[MaxN, bool]]
  var edgeIndex: array[MaxN, array[MaxN, int]]
  for u in 0..<MaxN:
    for v in 0..<MaxN: edgeIndex[u][v] = -1
  var edgeU, edgeV, support: array[MaxM, int]
  var alive: array[MaxM, bool]
  var trussness: array[MaxM, int64]
  for edge in 0..<m:
    let u64 = input[2 + 2 * edge]
    let v64 = input[3 + 2 * edge]
    if u64 < 0 or v64 <= u64 or v64 >= n64: return -1
    let u = int(u64)
    let v = int(v64)
    if adjacent[u][v]: return -1
    adjacent[u][v] = true
    adjacent[v][u] = true
    edgeIndex[u][v] = edge
    edgeIndex[v][u] = edge
    edgeU[edge] = u
    edgeV[edge] = v
    alive[edge] = true
  for u in 0..<n:
    for v in u + 1..<n:
      for w in v + 1..<n:
        if adjacent[u][v] and adjacent[u][w] and adjacent[v][w]:
          inc support[edgeIndex[u][v]]
          inc support[edgeIndex[u][w]]
          inc support[edgeIndex[v][w]]
  let outputBytes = 8 * m
  if output.isNil or capacity < csize_t(outputBytes): return -2
  var remaining = m
  var level = 0
  while remaining > 0:
    var selected = -1
    for edge in 0..<m:
      if alive[edge] and (selected < 0 or support[edge] < support[selected]): selected = edge
    if support[selected] > level: level = support[selected]
    trussness[selected] = int64(level + 2)
    alive[selected] = false
    dec remaining
    let u = edgeU[selected]
    let v = edgeV[selected]
    for w in 0..<n:
      if w == u or w == v or not adjacent[u][w] or not adjacent[v][w]: continue
      let first = edgeIndex[u][w]
      let second = edgeIndex[v][w]
      if alive[first] and alive[second]:
        if support[first] > level: dec support[first]
        if support[second] > level: dec support[second]
  for edge in 0..<m: storeI64LE(output, 8 * edge, trussness[edge])
  int64(outputBytes)
