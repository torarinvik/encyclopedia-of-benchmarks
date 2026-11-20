const
  MaxIslands = 6
  MaxEdgeSlots = 12
  MaxParseableInputLength = 20

type
  Solver = object
    islandCount, edgeCount: int
    x, y: array[MaxIslands, int64]
    residual: array[MaxIslands, int64]
    remaining: array[MaxIslands, int]
    edgeU, edgeV: array[MaxEdgeSlots, int]
    multiplicity, solution: array[MaxEdgeSlots, int]

proc edgesCross(s: var Solver, first, second: int): bool =
  let a = s.edgeU[first]
  let b = s.edgeV[first]
  let c = s.edgeU[second]
  let d = s.edgeV[second]
  let firstHorizontal = s.y[a] == s.y[b]
  let secondHorizontal = s.y[c] == s.y[d]
  if firstHorizontal == secondHorizontal: return false
  let h0 = if firstHorizontal: a else: c
  let h1 = if firstHorizontal: b else: d
  let v0 = if firstHorizontal: c else: a
  let v1 = if firstHorizontal: d else: b
  let hx = s.x[v0]
  let hy = s.y[h0]
  let hmin = min(s.x[h0], s.x[h1])
  let hmax = max(s.x[h0], s.x[h1])
  let vmin = min(s.y[v0], s.y[v1])
  let vmax = max(s.y[v0], s.y[v1])
  hmin < hx and hx < hmax and vmin < hy and hy < vmax

proc possibleGraphConnected(s: var Solver, assignedThrough: int): bool =
  var reached: array[MaxIslands, bool]
  var stack: array[MaxIslands, int]
  var top = 1
  reached[0] = true
  stack[0] = 0
  while top != 0:
    dec top
    let island = stack[top]
    for edge in 0 ..< s.edgeCount:
      var usable = edge <= assignedThrough and s.multiplicity[edge] != 0
      if edge > assignedThrough:
        usable = true
        for fixed in 0 .. assignedThrough:
          if s.multiplicity[fixed] != 0 and s.edgesCross(fixed, edge):
            usable = false
            break
      if not usable: continue
      var neighbor = s.islandCount
      if s.edgeU[edge] == island: neighbor = s.edgeV[edge]
      elif s.edgeV[edge] == island: neighbor = s.edgeU[edge]
      if neighbor < s.islandCount and not reached[neighbor]:
        reached[neighbor] = true
        stack[top] = neighbor
        inc top
  for island in 0 ..< s.islandCount:
    if not reached[island]: return false
  true

proc residualsFeasible(s: Solver): bool =
  for island in 0 ..< s.islandCount:
    if s.residual[island] < 0 or s.residual[island] > int64(2 * s.remaining[island]):
      return false
  true

proc search(s: var Solver, depth: int): bool =
  if depth == s.edgeCount:
    for island in 0 ..< s.islandCount:
      if s.residual[island] != 0: return false
    if not s.possibleGraphConnected(s.edgeCount - 1): return false
    for edge in 0 ..< s.edgeCount: s.solution[edge] = s.multiplicity[edge]
    return true
  let u = s.edgeU[depth]
  let v = s.edgeV[depth]
  dec s.remaining[u]
  dec s.remaining[v]
  for amount in 0 .. 2:
    if int64(amount) > s.residual[u] or int64(amount) > s.residual[v]: continue
    var conflict = false
    if amount != 0:
      for prior in 0 ..< depth:
        if s.multiplicity[prior] != 0 and s.edgesCross(prior, depth):
          conflict = true
          break
    if conflict: continue
    s.multiplicity[depth] = amount
    s.residual[u] -= int64(amount)
    s.residual[v] -= int64(amount)
    if s.residualsFeasible() and s.possibleGraphConnected(depth) and s.search(depth + 1):
      s.residual[u] += int64(amount)
      s.residual[v] += int64(amount)
      inc s.remaining[u]
      inc s.remaining[v]
      return true
    s.residual[u] += int64(amount)
    s.residual[v] += int64(amount)
    s.multiplicity[depth] = 0
  inc s.remaining[u]
  inc s.remaining[v]
  false

proc hashiwokakero_small_solver*(input: ptr UncheckedArray[int64],
    length: csize_t): int64 {.cdecl, exportc: "hashiwokakero_small_solver".} =
  if input.isNil or length < 1 or length > csize_t(MaxParseableInputLength): return -1
  if input[0] < 2 or input[0] > MaxIslands: return -1
  let islandCount = int(input[0])
  if int(length) != 1 + 3 * islandCount: return -1
  var s: Solver
  s.islandCount = islandCount
  for island in 0 ..< islandCount:
    let x = input[1 + 3 * island]
    let y = input[2 + 3 * island]
    let demand = input[3 + 3 * island]
    if x < 0 or x > 7 or y < 0 or y > 7 or demand < 1 or demand > 8: return -1
    for prior in 0 ..< island:
      if s.x[prior] == x and s.y[prior] == y: return -1
    s.x[island] = x
    s.y[island] = y
    s.residual[island] = demand
  for first in 0 ..< islandCount:
    for second in first + 1 ..< islandCount:
      if s.x[first] != s.x[second] and s.y[first] != s.y[second]: continue
      var blocked = false
      for middle in 0 ..< islandCount:
        if middle == first or middle == second: continue
        if s.y[first] == s.y[second] and s.y[middle] == s.y[first] and
            min(s.x[first], s.x[second]) < s.x[middle] and s.x[middle] < max(s.x[first], s.x[second]):
          blocked = true
        if s.x[first] == s.x[second] and s.x[middle] == s.x[first] and
            min(s.y[first], s.y[second]) < s.y[middle] and s.y[middle] < max(s.y[first], s.y[second]):
          blocked = true
      if not blocked:
        if s.edgeCount == MaxEdgeSlots: return -1
        let edge = s.edgeCount
        inc s.edgeCount
        s.edgeU[edge] = first
        s.edgeV[edge] = second
        inc s.remaining[first]
        inc s.remaining[second]
  if not s.search(0): return -2
  var result = 1'i64 shl 32
  for edge in 0 ..< s.edgeCount:
    result = result or (int64(s.solution[edge]) shl (2 * edge))
  result
