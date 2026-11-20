const
  K = 16
  MaxN = 8
  MaxM = 28
  MaxQ = 32
  MaxInput = 167
  MaxNodes = 31
  LogK = 4
  Inf = high(int64) div 4

type
  IntervalNode = object
    low, high, middle, gap, left, right: int
  QueryState = object
    distance: array[MaxN, array[MaxN, int64]]
    nearest: array[K, array[MaxN, int]]
    bunch: array[MaxN, array[MaxN, bool]]
    trees: array[MaxN, array[MaxNodes, IntervalNode]]
    counts: array[MaxN, int]

proc midpoint(low, upper: int): int =
  result = -1
  var best = high(int)
  for candidate in countup(low + 2, upper - 2, 2):
    let delta = abs(2 * candidate - low - upper)
    if delta < best:
      best = delta
      result = candidate

proc buildTree(state: var QueryState, source, low, high: int): int =
  let index = state.counts[source]
  if index >= MaxNodes: return -1
  inc state.counts[source]
  state.trees[source][index] = IntervalNode(low: low, high: high,
    middle: -1, gap: -1, left: -1, right: -1)
  if high - low <= LogK: return index

  let middle = midpoint(low, high)
  if middle < 0: return -1
  var selected = low
  var bestDelta = state.distance[source][state.nearest[low + 2][source]] -
                  state.distance[source][state.nearest[low][source]]
  for level in countup(low + 2, middle - 2, 2):
    let delta = state.distance[source][state.nearest[level + 2][source]] -
                state.distance[source][state.nearest[level][source]]
    if delta > bestDelta:
      bestDelta = delta
      selected = level
  state.trees[source][index].middle = middle
  state.trees[source][index].gap = selected
  let left = buildTree(state, source, low, selected)
  let right = buildTree(state, source, middle, high)
  if left < 0 or right < 0: return -1
  state.trees[source][index].left = left
  state.trees[source][index].right = right
  index

proc distK(state: var QueryState, source0, target0, start: int,
           probes: var int64): int64 =
  var source = source0
  var target = target0
  var level = start
  while level < K:
    let pivot = state.nearest[level][source]
    inc probes
    if state.bunch[target][pivot]:
      return state.distance[source][pivot] + state.distance[target][pivot]
    if level + 1 >= K: return -1
    swap(source, target)
    inc level
  -1

proc putI64Le(output: ptr UncheckedArray[uint8], offset: int, value: int64) =
  let bits = cast[uint64](value)
  for byte in 0 ..< 8:
    output[offset + byte] = uint8((bits shr (8 * byte)) and 255)

proc wulffNilsenLogarithmicDistanceQuery*(input: ptr UncheckedArray[int64],
    length: csize_t, output: ptr UncheckedArray[uint8], capacity: csize_t): int64
    {.cdecl, exportc: "wulff_nilsen_logarithmic_distance_query".} =
  if input.isNil or length < 18 or length > csize_t(MaxInput): return -1
  let n0 = input[0]
  let m0 = input[1]
  if n0 < 1 or n0 > MaxN or m0 < 0 or m0 > MaxM: return -1
  let n = int(n0)
  let m = int(m0)
  let validBits = (1'u64 shl n) - 1
  var layers: array[K, uint64]
  for level in 1 ..< K:
    let raw = input[1 + level]
    if raw <= 0 or (cast[uint64](raw) and not validBits) != 0: return -1
    layers[level] = cast[uint64](raw)
    if level > 1 and (layers[level] and not layers[level - 1]) != 0: return -1

  let queryAt = 17 + 3 * m
  if queryAt >= int(length): return -1
  let q0 = input[queryAt]
  if q0 < 0 or q0 > MaxQ or int(length) != queryAt + 1 + 2 * int(q0): return -1
  let q = int(q0)

  var state: QueryState
  for i in 0 ..< n:
    for j in 0 ..< n:
      state.distance[i][j] = if i == j: 0 else: Inf
  var previousU = -1
  var previousV = -1
  for edge in 0 ..< m:
    let offset = 17 + 3 * edge
    let u0 = input[offset]
    let v0 = input[offset + 1]
    let weight = input[offset + 2]
    if u0 < 0 or v0 <= u0 or v0 >= n0 or weight < 1 or weight > 1000: return -1
    let u = int(u0)
    let v = int(v0)
    if u < previousU or (u == previousU and v <= previousV): return -1
    previousU = u
    previousV = v
    state.distance[u][v] = weight
    state.distance[v][u] = weight
  for via in 0 ..< n:
    for fromVertex in 0 ..< n:
      for to in 0 ..< n:
        let candidate = state.distance[fromVertex][via] + state.distance[via][to]
        if candidate < state.distance[fromVertex][to]: state.distance[fromVertex][to] = candidate
  for i in 0 ..< n:
    for j in 0 ..< n:
      if state.distance[i][j] == Inf: return -1

  for vertex in 0 ..< n: state.nearest[0][vertex] = vertex
  for level in 1 ..< K:
    for vertex in 0 ..< n:
      var best = -1
      for candidate in 0 ..< n:
        if ((layers[level] shr candidate) and 1'u64) == 0: continue
        if best < 0:
          best = candidate
        elif state.distance[vertex][candidate] < state.distance[vertex][best] or
            (state.distance[vertex][candidate] == state.distance[vertex][best] and candidate < best):
          best = candidate
      if best < 0: return -1
      state.nearest[level][vertex] = best

  for center in 0 ..< n:
    for level in 0 ..< K:
      let current = if level == 0: validBits else: layers[level]
      let following = if level + 1 == K: 0'u64 else: layers[level + 1]
      var nextDistance = Inf
      for candidate in 0 ..< n:
        if ((following shr candidate) and 1'u64) != 0:
          nextDistance = min(nextDistance, state.distance[center][candidate])
      for candidate in 0 ..< n:
        let inCurrent = ((current shr candidate) and 1'u64) != 0
        let inNext = ((following shr candidate) and 1'u64) != 0
        if inCurrent and not inNext and state.distance[center][candidate] < nextDistance:
          state.bunch[center][candidate] = true

  for source in 0 ..< n:
    if buildTree(state, source, 0, K - 1) < 0: return -1

  var staged: array[1 + 2 * MaxQ, int64]
  staged[0] = int64(q)
  for query in 0 ..< q:
    let offset = queryAt + 1 + 2 * query
    let source0 = input[offset]
    let target0 = input[offset + 1]
    if source0 < 0 or source0 >= n0 or target0 < 0 or target0 >= n0: return -1
    let source = int(source0)
    let target = int(target0)
    if source == target:
      staged[1 + 2 * query] = 0
      staged[2 + 2 * query] = 0
      continue
    var nodeIndex = 0
    var probes = 0'i64
    while state.trees[source][nodeIndex].high - state.trees[source][nodeIndex].low > LogK:
      let node = state.trees[source][nodeIndex]
      let first = state.bunch[target][state.nearest[node.gap][source]]
      let second = state.bunch[source][state.nearest[node.gap + 1][target]]
      probes += 2
      nodeIndex = if not first and not second: node.right else: node.left
    let estimate = distK(state, source, target, state.trees[source][nodeIndex].low, probes)
    if estimate < 0: return -1
    staged[1 + 2 * query] = estimate
    staged[2 + 2 * query] = probes

  let words = 1 + 2 * q
  let bytes = 8 * words
  if output.isNil or capacity < csize_t(bytes): return -2
  for index in 0 ..< words: putI64Le(output, 8 * index, staged[index])
  int64(bytes)
