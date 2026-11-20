proc storeI64Le(output: ptr UncheckedArray[uint8], offset: int, value: int64) =
  let bits = cast[uint64](value)
  for byte in 0 ..< 8:
    output[offset + byte] = uint8((bits shr (byte * 8)) and 255)

proc deterministic_linear_threshold_spread*(input: ptr UncheckedArray[int64], length: csize_t,
    output: ptr UncheckedArray[uint8], capacity: csize_t): int64
    {.cdecl, exportc: "deterministic_linear_threshold_spread".} =
  if input.isNil or length < 3 or length > 92: return -1
  let nRaw = input[0]
  let mRaw = input[1]
  let sRaw = input[2]
  if nRaw < 1 or nRaw > 8 or mRaw < 0 or mRaw > 24 or sRaw < 0 or sRaw > nRaw: return -1
  let n = int(nRaw)
  let m = int(mRaw)
  let seedCount = int(sRaw)
  let edgeOffset = 3 + seedCount
  let thresholdOffset = edgeOffset + 3 * m
  if int(length) != thresholdOffset + n: return -1

  var seeded: array[8, bool]
  var seen: array[64, bool]
  var head: array[8, int64]
  var edgeTo, edgeWeight, edgeNext: array[24, int64]
  var incoming, threshold, activationRound, accumulated: array[8, int64]
  for v in 0 ..< n: head[v] = -1
  for i in 0 ..< seedCount:
    let seed = input[3 + i]
    if seed < 0 or seed >= nRaw or seeded[int(seed)]: return -1
    seeded[int(seed)] = true
  for i in 0 ..< m:
    let u = input[edgeOffset + 3 * i]
    let v = input[edgeOffset + 3 * i + 1]
    let w = input[edgeOffset + 3 * i + 2]
    if u < 0 or u >= nRaw or v < 0 or v >= nRaw or u == v or w < 0 or w > 16: return -1
    let slot = int(u) * 8 + int(v)
    if seen[slot]: return -1
    seen[slot] = true
    incoming[int(v)] += w
    if incoming[int(v)] > 16: return -1
    edgeTo[i] = v
    edgeWeight[i] = w
    edgeNext[i] = head[int(u)]
    head[int(u)] = int64(i)
  for v in 0 ..< n:
    threshold[v] = input[thresholdOffset + v]
    if threshold[v] < 1 or threshold[v] > 16: return -1
    activationRound[v] = if seeded[v]: 0 else: -1
  let outputBytes = 8 * (n + 2)
  if output.isNil or capacity < csize_t(outputBytes): return -2

  var frontier, following: array[8, int]
  var frontierCount = 0
  for v in 0 ..< n:
    if seeded[v]:
      frontier[frontierCount] = v
      inc frontierCount
  var waves = 0'i64
  while frontierCount > 0:
    var followingCount = 0
    for i in 0 ..< frontierCount:
      let source = frontier[i]
      var edge = head[source]
      while edge >= 0:
        let target = int(edgeTo[int(edge)])
        if activationRound[target] < 0:
          accumulated[target] += edgeWeight[int(edge)]
          if accumulated[target] >= threshold[target]:
            activationRound[target] = waves + 1
            following[followingCount] = target
            inc followingCount
        edge = edgeNext[int(edge)]
    frontierCount = followingCount
    for i in 0 ..< followingCount: frontier[i] = following[i]
    if followingCount > 0: inc waves
  storeI64Le(output, 0, nRaw)
  storeI64Le(output, 8, waves)
  for v in 0 ..< n: storeI64Le(output, 8 * (v + 2), activationRound[v])
  int64(outputBytes)
