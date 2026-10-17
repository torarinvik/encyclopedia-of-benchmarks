const MaxVertices = 16
const MaxNeighbors = 64
const MaxDepth = 8
const MaxValidInputLength = 4 + 2 * MaxVertices + MaxNeighbors
const MaxParseableInputLength = MaxValidInputLength + 1
const MaxPathLength = MaxDepth + 1
const MaxOutputValues = 3 + MaxPathLength

proc storeI64Le(output: ptr UncheckedArray[uint8], offset: int, value: int64) =
  let bits = cast[uint64](value)
  for byte in 0 ..< 8:
    output[offset + byte] = uint8((bits shr (8 * byte)) and 255)

proc iddfs*(values: ptr UncheckedArray[int64], length: csize_t,
    output: ptr UncheckedArray[uint8], capacity: csize_t): int64 {.cdecl, exportc.} =
  if values == nil or length < 4 or length > csize_t(MaxParseableInputLength): return -1
  let rawStart = values[0]
  let rawTarget = values[1]
  let rawDepth = values[2]
  let rawEntries = values[3]
  if rawStart < 1 or rawStart > MaxVertices or rawTarget < 1 or rawTarget > MaxVertices or
      rawDepth < 0 or rawDepth > MaxDepth or rawEntries < 0 or rawEntries > MaxVertices: return -1
  let start = int(rawStart)
  let target = int(rawTarget)
  let depthLimit = int(rawDepth)
  let entryCount = int(rawEntries)

  var adjacency: array[MaxVertices * MaxNeighbors, int32]
  var degreeCount: array[MaxVertices, int]
  var named: array[MaxVertices, bool]
  var maxVertex = 0
  var totalNeighbors = 0
  var cursor = 4
  for _ in 0 ..< entryCount:
    if cursor + 2 > int(length): return -1
    let rawVertex = values[cursor]
    inc cursor
    let rawDegree = values[cursor]
    inc cursor
    if rawVertex < 1 or rawVertex > MaxVertices or rawDegree < 0 or rawDegree > MaxNeighbors: return -1
    let vertex = int(rawVertex)
    let degree = int(rawDegree)
    if named[vertex - 1] or degree > int(length) - cursor or totalNeighbors + degree > MaxNeighbors: return -1
    named[vertex - 1] = true
    maxVertex = max(maxVertex, vertex)
    totalNeighbors += degree
    for _ in 0 ..< degree:
      let rawNeighbor = values[cursor]
      inc cursor
      if rawNeighbor < -MaxVertices or rawNeighbor > MaxVertices: return -1
      if rawNeighbor > int64(maxVertex): maxVertex = int(rawNeighbor)
      if rawNeighbor >= 1:
        let slot = (vertex - 1) * MaxNeighbors + degreeCount[vertex - 1]
        adjacency[slot] = int32(rawNeighbor)
        inc degreeCount[vertex - 1]
  if cursor != int(length): return -1
  if maxVertex != 0 and (start > maxVertex or target > maxVertex): return -1

  var path: array[MaxPathLength, int]
  var nextNeighbor: array[MaxPathLength, int]
  var pathLength = 0
  var foundDepth = 0
  var found = false
  if maxVertex != 0:
    for limit in 0 .. depthLimit:
      pathLength = 1
      path[0] = start
      nextNeighbor[0] = 0
      if start == target:
        found = true
        foundDepth = 0
        break
      while pathLength > 0 and not found:
        let frame = pathLength - 1
        let current = path[frame]
        if frame >= limit or nextNeighbor[frame] >= degreeCount[current - 1]:
          dec pathLength
          continue
        let slot = (current - 1) * MaxNeighbors + nextNeighbor[frame]
        let neighbor = int(adjacency[slot])
        inc nextNeighbor[frame]
        var prior = 0
        while prior < pathLength and path[prior] != neighbor: inc prior
        if prior != pathLength: continue
        path[pathLength] = neighbor
        inc pathLength
        if neighbor == target:
          found = true
          foundDepth = pathLength - 1
        else:
          nextNeighbor[pathLength - 1] = 0
      if found: break

  var result: array[MaxOutputValues, int64]
  var resultCount = 3
  result[0] = if found: 1 else: 0
  result[1] = if found: int64(foundDepth) else: -1
  result[2] = if found: int64(pathLength) else: 0
  if found:
    resultCount += pathLength
    for index in 0 ..< pathLength: result[3 + index] = int64(path[index])
  let required = resultCount * 8
  if output == nil or capacity < csize_t(required): return -2
  for index in 0 ..< resultCount: storeI64Le(output, 8 * index, result[index])
  int64(required)
