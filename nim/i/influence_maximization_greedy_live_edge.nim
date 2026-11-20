const MaxN = 8
const MaxM = 24
const MaxWorlds = 8

proc putI64Le(output: ptr UncheckedArray[uint8], word: int, value: int64) =
  let bits = cast[uint64](value)
  for byte in 0 ..< 8:
    output[word * 8 + byte] = uint8((bits shr (byte * 8)) and 255'u64)

proc reachableCount(n, m, world: int, seeds: uint16,
    edgeU, edgeV, masks: array[MaxM, int]): int =
  var queue: array[MaxN, int]
  var reached = seeds
  var head = 0
  var tail = 0
  for vertex in 0 ..< n:
    if (seeds and (1'u16 shl vertex)) != 0'u16:
      queue[tail] = vertex
      inc tail
  while head < tail:
    let source = queue[head]
    inc head
    for edge in 0 ..< m:
      let target = edgeV[edge]
      let bit = 1'u16 shl target
      if edgeU[edge] == source and (masks[edge] and (1 shl world)) != 0 and (reached and bit) == 0'u16:
        reached = reached or bit
        queue[tail] = target
        inc tail
  for vertex in 0 ..< n:
    if (reached and (1'u16 shl vertex)) != 0'u16: inc result

proc influence_maximization_greedy_live_edge*(input: ptr UncheckedArray[int64], length: csize_t,
    output: ptr UncheckedArray[uint8], capacity: csize_t): int64 {.cdecl, exportc: "influence_maximization_greedy_live_edge".} =
  if input == nil or length < 4 or length > 77: return -1
  let n0 = input[0]
  let m0 = input[1]
  let k0 = input[2]
  let worlds0 = input[3]
  if n0 < 1 or n0 > MaxN or m0 < 0 or m0 > MaxM or k0 < 0 or k0 > n0 or worlds0 < 1 or worlds0 > MaxWorlds:
    return -1
  let n = int(n0)
  let m = int(m0)
  let k = int(k0)
  let worlds = int(worlds0)
  if length != csize_t(4 + 3 * m): return -1
  var edgeU, edgeV, masks: array[MaxM, int]
  let allowed = (1 shl worlds) - 1
  for edge in 0 ..< m:
    let u = input[4 + 3 * edge]
    let v = input[5 + 3 * edge]
    let mask = input[6 + 3 * edge]
    if u < 0 or u >= n0 or v < 0 or v >= n0 or u == v or mask < 0 or mask > int64(allowed): return -1
    for earlier in 0 ..< edge:
      if edgeU[earlier] == int(u) and edgeV[earlier] == int(v): return -1
    edgeU[edge] = int(u)
    edgeV[edge] = int(v)
    masks[edge] = int(mask)
  var selected: uint16 = 0
  var chosen, scores: array[MaxN, int]
  for round in 0 ..< k:
    var current: array[MaxWorlds, int]
    for world in 0 ..< worlds:
      current[world] = reachableCount(n, m, world, selected, edgeU, edgeV, masks)
    var bestNode = -1
    var bestScore = -1
    for candidate in 0 ..< n:
      let bit = 1'u16 shl candidate
      if (selected and bit) != 0'u16: continue
      var score = 0
      for world in 0 ..< worlds:
        score += reachableCount(n, m, world, selected or bit, edgeU, edgeV, masks) - current[world]
      if score > bestScore:
        bestNode = candidate
        bestScore = score
    if bestNode < 0: return -1
    selected = selected or (1'u16 shl bestNode)
    chosen[round] = bestNode
    scores[round] = bestScore
  let bytes = (1 + 2 * k) * 8
  if output == nil or capacity < csize_t(bytes): return -2
  putI64Le(output, 0, int64(k))
  for round in 0 ..< k:
    putI64Le(output, 1 + 2 * round, int64(chosen[round]))
    putI64Le(output, 2 + 2 * round, int64(scores[round]))
  int64(bytes)
