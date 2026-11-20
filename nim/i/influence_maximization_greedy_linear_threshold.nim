const
  LtMaxN = 8
  LtMaxM = 24
  LtMaxWorlds = 8
  LtWeightScale = 256
  LtMaxInput = 141

proc ltReachableCount(n: int, parents: array[LtMaxN, int], seeds: uint16): int64 =
  var reached = seeds
  var queue: array[LtMaxN, int]
  var head = 0
  var tail = 0
  for vertex in 0 ..< n:
    if (seeds and (uint16(1) shl vertex)) != 0:
      queue[tail] = vertex
      inc tail
  while head < tail:
    let source = queue[head]
    inc head
    for target in 0 ..< n:
      let bit = uint16(1) shl target
      if parents[target] == source and (reached and bit) == 0:
        reached = reached or bit
        queue[tail] = target
        inc tail
  var count = 0
  for vertex in 0 ..< n:
    if (reached and (1'u16 shl vertex)) != 0'u16: inc count
  int64(count)

proc ltPutI64(output: ptr UncheckedArray[uint8], word: int, value: int64) =
  let bits = cast[uint64](value)
  for byte in 0 ..< 8:
    output[word * 8 + byte] = uint8((bits shr (8 * byte)) and 255'u64)

proc influence_maximization_greedy_linear_threshold*(input: ptr UncheckedArray[int64],
    length: csize_t, output: ptr UncheckedArray[uint8], capacity: csize_t): int64
    {.cdecl, exportc: "influence_maximization_greedy_linear_threshold".} =
  if input == nil or length < 4 or length > csize_t(LtMaxInput): return -1
  let n0 = input[0]
  let m0 = input[1]
  let k0 = input[2]
  let worlds0 = input[3]
  if n0 < 1 or n0 > LtMaxN or m0 < 0 or m0 > LtMaxM or k0 < 0 or k0 > n0
      or worlds0 < 1 or worlds0 > LtMaxWorlds: return -1
  let n = int(n0)
  let m = int(m0)
  let k = int(k0)
  let worlds = int(worlds0)
  if int(length) != 4 + 3 * m + worlds * n: return -1

  var edgeU, edgeV, edgeWeight: array[LtMaxM, int]
  var incomingSum: array[LtMaxN, int]
  for edge in 0 ..< m:
    let u0 = input[4 + 3 * edge]
    let v0 = input[5 + 3 * edge]
    let weight0 = input[6 + 3 * edge]
    if u0 < 0 or u0 >= n0 or v0 < 0 or v0 >= n0 or u0 == v0
        or weight0 < 0 or weight0 > LtWeightScale: return -1
    let u = int(u0)
    let v = int(v0)
    for prior in 0 ..< edge:
      if edgeU[prior] == u and edgeV[prior] == v: return -1
    edgeU[edge] = u
    edgeV[edge] = v
    edgeWeight[edge] = int(weight0)
    incomingSum[v] += int(weight0)
    if incomingSum[v] > LtWeightScale: return -1

  var draws: array[LtMaxWorlds, array[LtMaxN, int]]
  let drawsStart = 4 + 3 * m
  for world in 0 ..< worlds:
    for vertex in 0 ..< n:
      let draw = input[drawsStart + world * n + vertex]
      if draw < 0 or draw >= LtWeightScale: return -1
      draws[world][vertex] = int(draw)

  var parents: array[LtMaxWorlds, array[LtMaxN, int]]
  for world in 0 ..< worlds:
    for target in 0 ..< n:
      parents[world][target] = -1
      let ticket = draws[world][target]
      var offset = 0
      for edge in 0 ..< m:
        if edgeV[edge] != target: continue
        let nextOffset = offset + edgeWeight[edge]
        if offset <= ticket and ticket < nextOffset:
          parents[world][target] = edgeU[edge]
          break
        offset = nextOffset

  var selected: uint16 = 0
  var chosen, scores: array[LtMaxN, int64]
  for round in 0 ..< k:
    var current: array[LtMaxWorlds, int64]
    for world in 0 ..< worlds:
      current[world] = ltReachableCount(n, parents[world], selected)
    var bestNode = -1
    var bestScore: int64 = -1
    for candidate in 0 ..< n:
      let bit = uint16(1) shl candidate
      if (selected and bit) != 0: continue
      var score: int64 = 0
      for world in 0 ..< worlds:
        score += ltReachableCount(n, parents[world], selected or bit) - current[world]
      if score > bestScore:
        bestNode = candidate
        bestScore = score
    if bestNode < 0: return -1
    selected = selected or (uint16(1) shl bestNode)
    chosen[round] = int64(bestNode)
    scores[round] = bestScore

  let bytes = 8 * (1 + 2 * k)
  if output == nil or capacity < csize_t(bytes): return -2
  ltPutI64(output, 0, int64(k))
  for round in 0 ..< k:
    ltPutI64(output, 1 + 2 * round, chosen[round])
    ltPutI64(output, 2 + 2 * round, scores[round])
  int64(bytes)
