# Clean-room bounded GAPBS delta-stepping profile; see package LICENSE.txt.
const MaxN = 16
const MaxM = 64
const MaxBuckets = 481
const MaxEvents = 8192
const InfDistance = 1_073_741_823'i64

proc appendEvent(bucket, vertex: int,
    heads: var array[MaxBuckets, int32], tails: var array[MaxBuckets, int32],
    eventVertex: var array[MaxEvents, int32], eventNext: var array[MaxEvents, int32],
    used: var int): bool =
  if bucket < 0 or bucket >= MaxBuckets or used >= MaxEvents: return false
  let event = int32(used)
  inc used
  eventVertex[int(event)] = int32(vertex)
  eventNext[int(event)] = -1
  if heads[bucket] < 0: heads[bucket] = event
  else: eventNext[int(tails[bucket])] = event
  tails[bucket] = event
  true

proc storeI64LE(output: ptr UncheckedArray[uint8], offset: int, value: int64) =
  let bits = cast[uint64](value)
  for byte in 0..<8:
    output[offset + byte] = uint8((bits shr (byte * 8)) and 255)

proc gapbs_delta_step_sssp*(input: ptr UncheckedArray[int64], length: csize_t,
    output: ptr UncheckedArray[uint8], capacity: csize_t): int64
    {.cdecl, exportc: "gapbs_delta_step_sssp".} =
  if input.isNil or length < csize_t(4) or length > csize_t(196): return -1
  let n64 = input[0]
  let m64 = input[1]
  let source64 = input[2]
  let delta64 = input[3]
  if n64 < 1 or n64 > int64(MaxN) or m64 < 0 or m64 > int64(MaxM) or
      source64 < 0 or source64 >= n64 or delta64 < 1 or delta64 > 16 or
      int64(length) != 4 + 3 * m64: return -1
  let n = int(n64)
  let m = int(m64)
  let source = int(source64)
  let delta = delta64
  var edgeFrom: array[MaxM, int]
  var edgeTo: array[MaxM, int]
  var edgeWeight: array[MaxM, int64]
  for edge in 0..<m:
    let from = input[4 + 3 * edge]
    let to = input[5 + 3 * edge]
    let weight = input[6 + 3 * edge]
    if from < 0 or from >= n64 or to < 0 or to >= n64 or weight < 0 or weight > 32: return -1
    edgeFrom[edge] = int(from)
    edgeTo[edge] = int(to)
    edgeWeight[edge] = weight
  let outputBytes = 8 * n
  if output.isNil or capacity < csize_t(outputBytes): return -2

  var distance: array[MaxN, int64]
  for vertex in 0..<n: distance[vertex] = InfDistance
  distance[source] = 0
  var heads: array[MaxBuckets, int32]
  var tails: array[MaxBuckets, int32]
  for bucket in 0..<MaxBuckets:
    heads[bucket] = -1
    tails[bucket] = -1
  var eventVertex: array[MaxEvents, int32]
  var eventNext: array[MaxEvents, int32]
  var used = 0
  if not appendEvent(0, source, heads, tails, eventVertex, eventNext, used): return -1

  for bucket in 0..<MaxBuckets:
    while heads[bucket] >= 0:
      let event = int(heads[bucket])
      heads[bucket] = eventNext[event]
      if heads[bucket] < 0: tails[bucket] = -1
      let u = int(eventVertex[event])
      if distance[u] < delta * int64(bucket): continue
      for edge in 0..<m:
        if edgeFrom[edge] != u: continue
        let v = edgeTo[edge]
        let candidate = distance[u] + edgeWeight[edge]
        if candidate < distance[v]:
          distance[v] = candidate
          let destination = int(candidate div delta)
          if not appendEvent(destination, v, heads, tails, eventVertex, eventNext, used): return -1
  for vertex in 0..<n: storeI64LE(output, 8 * vertex, distance[vertex])
  int64(outputBytes)
