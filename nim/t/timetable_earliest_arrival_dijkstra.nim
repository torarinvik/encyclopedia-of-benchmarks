const MaxN = 8
const MaxArcs = 12
const MaxTrips = 4
const MaxOutputBytes = 88
const Inf = high(int64) div 4

proc storeI64Le(output: ptr UncheckedArray[uint8], offset: int, value: int64) =
  let bits = cast[uint64](value)
  for byte in 0 ..< 8: output[offset + byte] = uint8((bits shr (8 * byte)) and 255)

proc timetable_earliest_arrival_dijkstra*(input: ptr UncheckedArray[int64], length: csize_t,
    output: ptr UncheckedArray[uint8], capacity: csize_t): int64
    {.cdecl, exportc: "timetable_earliest_arrival_dijkstra".} =
  if input.isNil or length < csize_t(5) or length > csize_t(138): return -1
  let nRaw = input[0]
  let arcsRaw = input[1]
  let sourceRaw = input[2]
  let targetRaw = input[3]
  let startTime = input[4]
  if nRaw < 2 or nRaw > MaxN or arcsRaw < 0 or arcsRaw > MaxArcs or
      sourceRaw < 0 or sourceRaw >= nRaw or targetRaw < 0 or targetRaw >= nRaw or
      startTime < 0 or startTime > 1000: return -1
  let n = int(nRaw)
  let arcCount = int(arcsRaw)
  let source = int(sourceRaw)
  let target = int(targetRaw)
  var arcU: array[MaxArcs, int]
  var arcV: array[MaxArcs, int]
  var tripCount: array[MaxArcs, int]
  var departure: array[MaxArcs, array[MaxTrips, int64]]
  var arrival: array[MaxArcs, array[MaxTrips, int64]]
  var cursor = 5
  for edge in 0 ..< arcCount:
    if cursor + 3 > int(length): return -1
    let uRaw = input[cursor]
    let vRaw = input[cursor + 1]
    let countRaw = input[cursor + 2]
    cursor += 3
    if uRaw < 0 or uRaw >= nRaw or vRaw < 0 or vRaw >= nRaw or uRaw == vRaw or countRaw < 1 or countRaw > MaxTrips or cursor + 2 * int(countRaw) > int(length): return -1
    let u = int(uRaw)
    let v = int(vRaw)
    let count = int(countRaw)
    for prior in 0 ..< edge:
      if arcU[prior] == u and arcV[prior] == v: return -1
    arcU[edge] = u
    arcV[edge] = v
    tripCount[edge] = count
    for trip in 0 ..< count:
      let dep = input[cursor]
      let arr = input[cursor + 1]
      cursor += 2
      if dep < 0 or dep > 1000 or arr <= dep or arr > 2000 or
          (trip > 0 and (dep <= departure[edge][trip - 1] or arr < arrival[edge][trip - 1])): return -1
      departure[edge][trip] = dep
      arrival[edge][trip] = arr
  if cursor != int(length): return -1

  var distance: array[MaxN, int64]
  var parent: array[MaxN, int]
  var settled: array[MaxN, bool]
  for vertex in 0 ..< n:
    distance[vertex] = Inf
    parent[vertex] = -1
  distance[source] = startTime
  for _ in 0 ..< n:
    var chosen = -1
    for vertex in 0 ..< n:
      if not settled[vertex] and distance[vertex] < Inf and
          (chosen < 0 or distance[vertex] < distance[chosen] or
           (distance[vertex] == distance[chosen] and vertex < chosen)):
        chosen = vertex
    if chosen < 0: break
    settled[chosen] = true
    for edge in 0 ..< arcCount:
      let v = arcV[edge]
      if arcU[edge] != chosen or settled[v]: continue
      var trip = 0
      while trip < tripCount[edge] and departure[edge][trip] < distance[chosen]: inc trip
      if trip == tripCount[edge]: continue
      let candidate = arrival[edge][trip]
      if candidate < distance[v] or (candidate == distance[v] and (parent[v] < 0 or chosen < parent[v])):
        distance[v] = candidate
        parent[v] = chosen

  var reversePath: array[MaxN, int]
  var pathLength = 0
  if distance[target] < Inf:
    var current = target
    reversePath[pathLength] = current
    inc pathLength
    while current != source and pathLength < n:
      if parent[current] < 0:
        pathLength = 0
        break
      current = parent[current]
      reversePath[pathLength] = current
      inc pathLength
    if pathLength == 0 or reversePath[pathLength - 1] != source: pathLength = 0
  let reachable = pathLength > 0
  let outputBytes = if reachable: 8 * (3 + pathLength) else: 24
  if output.isNil or capacity < csize_t(outputBytes): return -2
  var staged: array[MaxOutputBytes, uint8]
  storeI64Le(addr staged[0], 0, if reachable: 1 else: 0)
  storeI64Le(addr staged[0], 8, if reachable: distance[target] else: -1)
  storeI64Le(addr staged[0], 16, int64(pathLength))
  if reachable:
    for i in 0 ..< pathLength: storeI64Le(addr staged[0], 24 + 8 * i, int64(reversePath[pathLength - 1 - i]))
  for byte in 0 ..< outputBytes: output[byte] = staged[byte]
  int64(outputBytes)
