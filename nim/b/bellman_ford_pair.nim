const MaxVertices = 64
const MaxInputEdges = 256
const MaxNormalizedEdges = 128
const MaxWeight = 1_000'i64
const RecordBytes = 24

proc writeRecord(output: ptr UncheckedArray[uint8], capacity: csize_t,
                 status, reachable, distance: int64): int64 =
  if output.isNil or capacity < RecordBytes: return -2
  let record = [status, reachable, distance]
  for field in 0 .. 2:
    let bits = cast[uint64](record[field])
    for byte in 0 .. 7:
      output[field * 8 + byte] = uint8((bits shr (byte * 8)) and 0xff'u64)
  int64(RecordBytes)

proc bellman_ford_pair*(input: ptr UncheckedArray[int64], length: csize_t,
                        output: ptr UncheckedArray[uint8], capacity: csize_t): int64
    {.cdecl, exportc: "bellman_ford_pair".} =
  if input.isNil or length < 4: return -1
  let verticesValue = input[0]
  let inputEdgesValue = input[1]
  let sourceValue = input[2]
  let targetValue = input[3]
  if verticesValue < 1 or verticesValue > MaxVertices or
      inputEdgesValue < 0 or inputEdgesValue > MaxInputEdges: return -1
  let vertices = int(verticesValue)
  let inputEdges = int(inputEdgesValue)
  if sourceValue < 0 or sourceValue >= verticesValue or targetValue < 0 or targetValue >= verticesValue or
      length != csize_t(4 + 3 * inputEdges): return -1

  var matrixWeights: array[MaxVertices * MaxVertices, int64]
  var matrixPresent: array[MaxVertices * MaxVertices, bool]
  var normalizedCount = 0
  for edge in 0 ..< inputEdges:
    let fromValue = input[4 + 3 * edge]
    let toValue = input[5 + 3 * edge]
    let weightValue = input[6 + 3 * edge]
    if fromValue < 0 or fromValue >= verticesValue or toValue < 0 or toValue >= verticesValue or
        weightValue < -MaxWeight or weightValue > MaxWeight: return -1
    let key = int(fromValue) * vertices + int(toValue)
    if not matrixPresent[key]:
      matrixPresent[key] = true
      inc normalizedCount
      if normalizedCount > MaxNormalizedEdges: return -1
    matrixWeights[key] = weightValue

  var from: array[MaxNormalizedEdges, int]
  var to: array[MaxNormalizedEdges, int]
  var weight: array[MaxNormalizedEdges, int64]
  var edgeCount = 0
  for origin in 0 ..< vertices:
    for destination in 0 ..< vertices:
      let key = origin * vertices + destination
      if not matrixPresent[key]: continue
      from[edgeCount] = origin
      to[edgeCount] = destination
      weight[edgeCount] = matrixWeights[key]
      inc edgeCount

  let source = int(sourceValue)
  let target = int(targetValue)
  var distance: array[MaxVertices, int64]
  var reachable: array[MaxVertices, bool]
  reachable[source] = true
  for _ in 0 ..< vertices:
    var changed = false
    for edge in 0 ..< edgeCount:
      if not reachable[from[edge]]: continue
      let candidate = distance[from[edge]] + weight[edge]
      if not reachable[to[edge]] or candidate < distance[to[edge]]:
        distance[to[edge]] = candidate
        reachable[to[edge]] = true
        changed = true
    if not changed: break
  for edge in 0 ..< edgeCount:
    if reachable[from[edge]] and distance[to[edge]] > distance[from[edge]] + weight[edge]:
      return writeRecord(output, capacity, -1, 0, 0)
  let targetReachable = reachable[target]
  writeRecord(output, capacity, 0, (if targetReachable: 1'i64 else: 0'i64),
              (if targetReachable: distance[target] else: 0'i64))
