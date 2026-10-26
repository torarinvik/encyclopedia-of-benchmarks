## Clean-room negative-cycle detection and witness extraction.
const MaxN = 20
const MaxM = 64
const MaxInput = 2 + 3 * MaxM

proc storeI64LE(output: ptr UncheckedArray[uint8], offset: int, value: int64) =
  let bits = cast[uint64](value)
  for byte in 0..<8: output[offset + byte] = uint8((bits shr (8*byte)) and 255)

proc negative_cycle_detection*(input: ptr UncheckedArray[int64], length: csize_t,
    output: ptr UncheckedArray[uint8], capacity: csize_t): int64
    {.cdecl, exportc: "negative_cycle_detection".} =
  if input.isNil or length < csize_t(2) or length > csize_t(MaxInput): return -1
  let n64 = input[0]
  let m64 = input[1]
  if n64 < 0 or n64 > int64(MaxN) or m64 < 0 or m64 > int64(MaxM): return -1
  let n = int(n64)
  let m = int(m64)
  if int(length) != 2 + 3*m: return -1
  var edgeFrom: array[MaxM, int]
  var edgeTo: array[MaxM, int]
  var weight: array[MaxM, int64]
  for edge in 0..<m:
    let u64 = input[2 + 3*edge]
    let v64 = input[3 + 3*edge]
    let w = input[4 + 3*edge]
    if u64 < 0 or u64 >= n64 or v64 < 0 or v64 >= n64 or w < -1000 or w > 1000: return -1
    edgeFrom[edge] = int(u64)
    edgeTo[edge] = int(v64)
    weight[edge] = w
  var distance: array[MaxN, int64]
  var predecessor: array[MaxN, int]
  for vertex in 0..<n: predecessor[vertex] = -1
  var changedVertex = -1
  for pass in 0..<n:
    changedVertex = -1
    for edge in 0..<m:
      let u = edgeFrom[edge]
      let v = edgeTo[edge]
      let candidate = distance[u] + weight[edge]
      if candidate < distance[v]:
        distance[v] = candidate
        predecessor[v] = u
        changedVertex = v
    if changedVertex < 0: break
  var record: array[MaxN + 2, int64]
  var recordLength = 1
  if changedVertex >= 0:
    var vertex = changedVertex
    for step in 0..<n:
      if predecessor[vertex] < 0: return -1
      vertex = predecessor[vertex]
    let start = vertex
    var cycle: array[MaxN, int]
    var cycleLength = 0
    while true:
      if cycleLength >= n or predecessor[vertex] < 0: return -1
      cycle[cycleLength] = vertex
      inc cycleLength
      vertex = predecessor[vertex]
      if vertex == start: break
    for i in 0..<(cycleLength div 2): swap(cycle[i], cycle[cycleLength - 1 - i])
    var minimum = 0
    for i in 1..<cycleLength:
      if cycle[i] < cycle[minimum]: minimum = i
    record[0] = 1
    record[1] = int64(cycleLength)
    for i in 0..<cycleLength: record[2+i] = int64(cycle[(minimum+i) mod cycleLength])
    recordLength = cycleLength + 2
  else:
    record[0] = 0
  let outputLength = 8 * recordLength
  if output.isNil or capacity < csize_t(outputLength): return -2
  for i in 0..<recordLength: storeI64LE(output, 8*i, record[i])
  return int64(outputLength)
