const MaxN = 16
const MaxEdges = 120
const MaxInput = 242
const MaxOutput = 2064

proc put(output: ptr UncheckedArray[uint8], offset: int, value: int64) =
  let bits = cast[uint64](value)
  for byte in 0..<8: output[offset + byte] = uint8((bits shr (8 * byte)) and 255)

proc treewidth_min_degree_elimination*(input: ptr UncheckedArray[int64], length: csize_t,
    output: ptr UncheckedArray[uint8], capacity: csize_t): int64 {.cdecl, exportc: "treewidth_min_degree_elimination".} =
  if input.isNil or length < 2 or length > csize_t(MaxInput): return -1
  let n64 = input[0]
  let m64 = input[1]
  if n64 < 1 or n64 > MaxN or m64 < 0 or m64 > MaxEdges: return -1
  let n = int(n64)
  let m = int(m64)
  if m > n * (n - 1) div 2 or int(length) != 2 + 2 * m: return -1
  var adjacent: array[MaxN, array[MaxN, bool]]
  for edge in 0..<m:
    let a64 = input[2 + 2 * edge]
    let b64 = input[3 + 2 * edge]
    if a64 < 0 or b64 < 0 or a64 >= n64 or b64 >= n64 or a64 >= b64: return -1
    let a = int(a64)
    let b = int(b64)
    if adjacent[a][b]: return -1
    adjacent[a][b] = true
    adjacent[b][a] = true

  var active: array[MaxN, bool]
  var order: array[MaxN, int64]
  var fillU, fillV: array[MaxEdges, int64]
  for vertex in 0..<n: active[vertex] = true
  var width = 0
  var fillCount = 0
  for step in 0..<n:
    var chosen = -1
    var chosenDegree = MaxN + 1
    for vertex in 0..<n:
      if active[vertex]:
        var degree = 0
        for other in 0..<n:
          if active[other] and adjacent[vertex][other]: inc degree
        if degree < chosenDegree:
          chosen = vertex
          chosenDegree = degree
    order[step] = int64(chosen)
    width = max(width, chosenDegree)
    var neighbors: array[MaxN, int]
    var neighborCount = 0
    for other in 0..<n:
      if active[other] and adjacent[chosen][other]:
        neighbors[neighborCount] = other
        inc neighborCount
    for i in 0..<neighborCount:
      for j in i + 1..<neighborCount:
        let a = neighbors[i]
        let b = neighbors[j]
        if not adjacent[a][b]:
          adjacent[a][b] = true
          adjacent[b][a] = true
          fillU[fillCount] = int64(a)
          fillV[fillCount] = int64(b)
          inc fillCount
    active[chosen] = false

  let bytes = 8 * (n + 2 + 2 * fillCount)
  if output.isNil or capacity < csize_t(bytes) or bytes > MaxOutput: return -2
  var staged: array[MaxOutput, uint8]
  put(addr staged[0], 0, int64(width))
  for i in 0..<n: put(addr staged[0], 8 * (i + 1), order[i])
  put(addr staged[0], 8 * (n + 1), int64(fillCount))
  for i in 0..<fillCount:
    put(addr staged[0], 8 * (n + 2 + 2 * i), fillU[i])
    put(addr staged[0], 8 * (n + 3 + 2 * i), fillV[i])
  for i in 0..<bytes: output[i] = staged[i]
  int64(bytes)
