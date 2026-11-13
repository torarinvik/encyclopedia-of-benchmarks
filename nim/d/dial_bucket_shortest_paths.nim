import std/[cstddef]

const
  MaxN = 16
  MaxM = 64
  MaxRecords = MaxM + 1
  MaxDistance = 120
  BucketCount = 9
  MaxInput = 196
  MaxOutputBytes = 128

proc putI64Le(output: var array[MaxOutputBytes, uint8], offset: int, value: int64) =
  let bits = cast[uint64](value)
  for byte in 0 ..< 8:
    output[offset + byte] = uint8((bits shr (8 * byte)) and 255'u64)

proc dialBucketShortestPaths*(input: ptr UncheckedArray[int64], length: csize_t,
    output: ptr UncheckedArray[uint8], capacity: csize_t): int64
    {.cdecl, exportc: "dial_bucket_shortest_paths".} =
  if input.isNil or length < 3 or length > MaxInput: return -1
  let n64 = input[0]
  let m64 = input[1]
  let source64 = input[2]
  if n64 < 1 or n64 > MaxN or m64 < 0 or m64 > MaxM or
      source64 < 0 or source64 >= n64: return -1
  let n = int(n64)
  let m = int(m64)
  let source = int(source64)
  if int(length) != 3 + 3 * m: return -1

  var edgeTo: array[MaxM, int]
  var edgeNext: array[MaxM, int]
  var edgeWeight: array[MaxM, int64]
  var edgeHead: array[MaxN, int]
  for vertex in 0 ..< n: edgeHead[vertex] = MaxM
  for edge in 0 ..< m:
    let u = input[3 + 3 * edge]
    let v = input[4 + 3 * edge]
    let w = input[5 + 3 * edge]
    if u < 0 or u >= n64 or v < 0 or v >= n64 or w < 0 or w > 8: return -1
    let from = int(u)
    edgeTo[edge] = int(v)
    edgeWeight[edge] = w
    edgeNext[edge] = edgeHead[from]
    edgeHead[from] = edge

  let needed = 8 * n
  if output.isNil or capacity < csize_t(needed): return -2
  var distance: array[MaxN, int64]
  var settled: array[MaxN, bool]
  for vertex in 0 ..< n: distance[vertex] = MaxDistance + 1
  distance[source] = 0
  var bucketHead, bucketTail: array[BucketCount, int]
  for bucket in 0 ..< BucketCount:
    bucketHead[bucket] = MaxRecords
    bucketTail[bucket] = MaxRecords
  var recordVertex, recordNext: array[MaxRecords, int]
  var recordDistance: array[MaxRecords, int64]
  var used = 1
  recordVertex[0] = source
  recordDistance[0] = 0
  recordNext[0] = MaxRecords
  bucketHead[0] = 0
  bucketTail[0] = 0
  for current in 0 .. MaxDistance:
    let bucket = current mod BucketCount
    while bucketHead[bucket] != MaxRecords:
      let record = bucketHead[bucket]
      bucketHead[bucket] = recordNext[record]
      if bucketHead[bucket] == MaxRecords: bucketTail[bucket] = MaxRecords
      let u = recordVertex[record]
      if recordDistance[record] != int64(current) or settled[u] or
          distance[u] != int64(current): continue
      settled[u] = true
      var edge = edgeHead[u]
      while edge != MaxM:
        let v = edgeTo[edge]
        let candidate = int64(current) + edgeWeight[edge]
        if not settled[v] and candidate < distance[v]:
          if used >= MaxRecords: return -1
          distance[v] = candidate
          let destination = int(candidate mod int64(BucketCount))
          recordVertex[used] = v
          recordDistance[used] = candidate
          recordNext[used] = MaxRecords
          if bucketTail[destination] == MaxRecords: bucketHead[destination] = used
          else: recordNext[bucketTail[destination]] = used
          bucketTail[destination] = used
          inc used
        edge = edgeNext[edge]
  var staged: array[MaxOutputBytes, uint8]
  for vertex in 0 ..< n:
    putI64Le(staged, 8 * vertex,
      if distance[vertex] > MaxDistance: -1 else: distance[vertex])
  for byte in 0 ..< needed: output[byte] = staged[byte]
  int64(needed)

