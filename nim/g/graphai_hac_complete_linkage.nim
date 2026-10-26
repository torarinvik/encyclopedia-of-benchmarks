# Clean-room bounded GraphAIBench complete-linkage HAC; see package LICENSE.txt.
const MaxN = 8
const MaxM = 24
const MaxInput = 74
const MaxNodes = 15
const RootParent = 4_294_967_295'i64

proc storeI64LE(output: ptr UncheckedArray[uint8], offset: int, value: int64) =
  let bits = cast[uint64](value)
  for byte in 0..<8: output[offset + byte] = uint8((bits shr (8 * byte)) and 255)

proc graphai_hac_complete_linkage*(input: ptr UncheckedArray[int64], length: csize_t,
    output: ptr UncheckedArray[uint8], capacity: csize_t): int64
    {.cdecl, exportc: "graphai_hac_complete_linkage".} =
  if input.isNil or length < csize_t(2) or length > csize_t(MaxInput): return -1
  let n64 = input[0]
  let m64 = input[1]
  if n64 < 1 or n64 > int64(MaxN) or m64 < 0 or m64 > int64(MaxM) or
      int64(length) != 2 + 3 * m64: return -1
  let n = int(n64)
  let m = int(m64)
  var adjacent: array[MaxN, array[MaxN, int]]
  var usedWeight: array[33, bool]
  for edge in 0..<m:
    let u64 = input[2 + 3 * edge]
    let v64 = input[3 + 3 * edge]
    let w64 = input[4 + 3 * edge]
    if u64 < 0 or v64 <= u64 or v64 >= n64 or w64 < 1 or w64 > 32: return -1
    let u = int(u64); let v = int(v64); let w = int(w64)
    if adjacent[u][v] != 0 or usedWeight[w]: return -1
    adjacent[u][v] = w; adjacent[v][u] = w; usedWeight[w] = true
  var reached: array[MaxN, bool]
  var queue: array[MaxN, int]
  var head = 0
  var tail = 1
  reached[0] = true
  while head < tail:
    let u = queue[head]
    inc head
    for v in 0..<n:
      if adjacent[u][v] != 0 and not reached[v]:
        reached[v] = true
        queue[tail] = v
        inc tail
  for v in 0..<n:
    if not reached[v]: return -1
  let nodeCount = 2 * n - 1
  let outputBytes = 16 * nodeCount
  if output.isNil or capacity < csize_t(outputBytes): return -2

  var active: array[MaxN, bool]
  var currentId: array[MaxN, int]
  var parent: array[MaxNodes, int64]
  var mergeWeight: array[MaxNodes, int64]
  for node in 0..<MaxNodes: parent[node] = RootParent
  for u in 0..<n: active[u] = true; currentId[u] = u
  for merge in 0..<n-1:
    var bestU = -1
    var bestV = -1
    var bestWeight = 0
    for u in 0..<n:
      if active[u]:
        for v in u+1..<n:
          if active[v] and adjacent[u][v] > bestWeight:
            bestWeight = adjacent[u][v]; bestU = u; bestV = v
    if bestU < 0: return -1
    var degreeU = 0
    var degreeV = 0
    for z in 0..<n:
      if active[z] and adjacent[bestU][z] != 0: inc degreeU
      if active[z] and adjacent[bestV][z] != 0: inc degreeV
    let larger = if degreeU < degreeV: bestV else: bestU
    let smaller = if larger == bestU: bestV else: bestU
    let newId = n + merge
    parent[currentId[bestU]] = int64(newId)
    parent[currentId[bestV]] = int64(newId)
    mergeWeight[currentId[bestU]] = int64(bestWeight)
    mergeWeight[currentId[bestV]] = int64(bestWeight)
    var mergedWeight: array[MaxN, int]
    for z in 0..<n:
      if active[z] and z != bestU and z != bestV:
        let a = adjacent[bestU][z]
        let b = adjacent[bestV][z]
        if a != 0 or b != 0: mergedWeight[z] = if a != 0 and b != 0: min(a,b) else: (if a != 0: a else: b)
    for z in 0..<n:
      adjacent[bestU][z] = 0; adjacent[z][bestU] = 0
      adjacent[bestV][z] = 0; adjacent[z][bestV] = 0
    active[smaller] = false
    for z in 0..<n:
      if active[z] and z != larger and mergedWeight[z] != 0:
        adjacent[larger][z] = mergedWeight[z]; adjacent[z][larger] = mergedWeight[z]
    currentId[larger] = newId
  for node in 0..<nodeCount:
    storeI64LE(output, 16 * node, parent[node])
    storeI64LE(output, 16 * node + 8, mergeWeight[node])
  int64(outputBytes)
