const MaxN = 8
const MaxInitialEdges = 16
const MaxOperations = 20
const MaxOutputBytes = 168
type Adj = array[MaxN, array[MaxN, bool]]
type Reach = array[MaxN, bool]

proc rebuildReachable(n, source: int, adjacency: Adj, reachable: var Reach) =
  var queue: array[MaxN, int]
  var head = 0
  var tail = 0
  for i in 0 ..< MaxN: reachable[i] = false
  reachable[source] = true
  queue[tail] = source
  inc tail
  while head < tail:
    let u = queue[head]
    inc head
    for v in 0 ..< n:
      if adjacency[u][v] and not reachable[v]:
        reachable[v] = true
        queue[tail] = v
        inc tail

proc storeI64Le(output: ptr UncheckedArray[uint8], offset: int, value: int64) =
  let bits = cast[uint64](value)
  for byte in 0 ..< 8: output[offset + byte] = uint8((bits shr (8 * byte)) and 255)

proc single_source_dynamic_reachability_rebuild*(input: ptr UncheckedArray[int64], length: csize_t,
    output: ptr UncheckedArray[uint8], capacity: csize_t): int64
    {.cdecl, exportc: "single_source_dynamic_reachability_rebuild".} =
  if input.isNil or length < csize_t(4) or length > csize_t(97): return -1
  let nRaw = input[0]
  let sourceRaw = input[1]
  let edgeCountRaw = input[2]
  if nRaw < 2 or nRaw > MaxN or sourceRaw < 0 or sourceRaw >= nRaw or edgeCountRaw < 0 or edgeCountRaw > MaxInitialEdges: return -1
  let n = int(nRaw)
  let source = int(sourceRaw)
  let edgeCount = int(edgeCountRaw)
  let operationCountOffset = 3 + 2 * edgeCount
  if length <= csize_t(operationCountOffset): return -1
  let operationCountRaw = input[operationCountOffset]
  if operationCountRaw < 0 or operationCountRaw > MaxOperations or
      length != csize_t(operationCountOffset + 1 + 3 * int(operationCountRaw)): return -1
  let operationCount = int(operationCountRaw)

  var adjacency: Adj
  var cursor = 3
  for i in 0 ..< edgeCount:
    let uRaw = input[cursor]
    let vRaw = input[cursor + 1]
    cursor += 2
    if uRaw < 0 or uRaw >= nRaw or vRaw < 0 or vRaw >= nRaw: return -1
    let u = int(uRaw)
    let v = int(vRaw)
    if adjacency[u][v]: return -1
    adjacency[u][v] = true
  cursor = operationCountOffset + 1
  var opType: array[MaxOperations, int]
  var opU: array[MaxOperations, int]
  var opV: array[MaxOperations, int]
  var queryCount = 0
  for i in 0 ..< operationCount:
    let kind = input[cursor]
    let u = input[cursor + 1]
    let v = input[cursor + 2]
    cursor += 3
    if kind == 0 or kind == 1:
      if u < 0 or u >= nRaw or v < 0 or v >= nRaw: return -1
    elif kind == 2:
      if u < 0 or u >= nRaw or v != 0: return -1
      inc queryCount
    else:
      return -1
    opType[i] = int(kind)
    opU[i] = int(u)
    opV[i] = int(v)

  let outputBytes = 8 * (1 + queryCount)
  if output.isNil or capacity < csize_t(outputBytes): return -2
  var reachable: Reach
  var answers: array[MaxOperations, int64]
  var answerCount = 0
  rebuildReachable(n, source, adjacency, reachable)
  for i in 0 ..< operationCount:
    if opType[i] == 0:
      adjacency[opU[i]][opV[i]] = true
      rebuildReachable(n, source, adjacency, reachable)
    elif opType[i] == 1:
      adjacency[opU[i]][opV[i]] = false
      rebuildReachable(n, source, adjacency, reachable)
    else:
      answers[answerCount] = if reachable[opU[i]]: 1 else: 0
      inc answerCount
  var staged: array[MaxOutputBytes, uint8]
  storeI64Le(addr staged[0], 0, int64(answerCount))
  for i in 0 ..< answerCount: storeI64Le(addr staged[0], 8 * (i + 1), answers[i])
  for byte in 0 ..< outputBytes: output[byte] = staged[byte]
  int64(outputBytes)
