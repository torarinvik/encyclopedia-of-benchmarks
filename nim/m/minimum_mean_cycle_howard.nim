const
  MaxVertices = 8
  MaxEdges = 16
  MaxInputLength = 51
  OutputBytes = 16

type Edge = object
  fromVertex: int
  toVertex: int
  weight: int64

proc storeI64Le(output: var array[OutputBytes, uint8], offset: int, value: int64) =
  let bits = cast[uint64](value)
  for byte in 0 ..< 8:
    output[offset + byte] = uint8((bits shr (byte * 8)) and 255'u64)

proc gcdPositive(aValue, bValue: int64): int64 =
  var a = aValue
  var b = bValue
  while b != 0:
    let remainder = a mod b
    a = b
    b = remainder
  a

proc compareRatio(aNumerator, aDenominator, bNumerator, bDenominator: int64): int =
  let left = aNumerator * bDenominator
  let right = bNumerator * aDenominator
  if left < right: -1 elif left > right: 1 else: 0

proc allReachable(n: int, adjacent: array[MaxVertices * MaxVertices, bool], reverse: bool): bool =
  var seen: array[MaxVertices, bool]
  var queue: array[MaxVertices, int]
  var head = 0
  var tail = 1
  seen[0] = true
  queue[0] = 0
  while head < tail:
    let u = queue[head]
    inc head
    for v in 0 ..< n:
      let slot = if reverse: v * MaxVertices + u else: u * MaxVertices + v
      if adjacent[slot] and not seen[v]:
        seen[v] = true
        queue[tail] = v
        inc tail
  for v in 0 ..< n:
    if not seen[v]: return false
  true

proc compareAppraisal(aEdge, bEdge: int, edges: array[MaxEdges, Edge],
    valueNum, valueDen, biasNum: array[MaxVertices, int64]): int =
  let a = edges[aEdge]
  let b = edges[bEdge]
  result = compareRatio(valueNum[a.toVertex], valueDen[a.toVertex],
    valueNum[b.toVertex], valueDen[b.toVertex])
  if result != 0: return
  let aBias = a.weight * valueDen[a.toVertex] - valueNum[a.toVertex] + biasNum[a.toVertex]
  let bBias = b.weight * valueDen[b.toVertex] - valueNum[b.toVertex] + biasNum[b.toVertex]
  compareRatio(aBias, valueDen[a.toVertex], bBias, valueDen[b.toVertex])

proc evaluatePolicy(n: int, edges: array[MaxEdges, Edge],
    policy: array[MaxVertices, int], valueNum, valueDen, biasNum: var array[MaxVertices, int64]) =
  var assigned: array[MaxVertices, bool]
  for start in 0 ..< n:
    if assigned[start]: continue
    var localPosition: array[MaxVertices, int]
    for vertex in 0 ..< MaxVertices: localPosition[vertex] = -1
    var path: array[MaxVertices, int]
    var pathLength = 0
    var vertex = start
    while not assigned[vertex] and localPosition[vertex] < 0:
      localPosition[vertex] = pathLength
      path[pathLength] = vertex
      inc pathLength
      vertex = edges[policy[vertex]].toVertex

    var prefixLength = pathLength
    if not assigned[vertex]:
      let cycleStart = localPosition[vertex]
      let cycleLength = pathLength - cycleStart
      var cycleWeight = 0'i64
      var headPosition = cycleStart
      for index in cycleStart ..< pathLength:
        let member = path[index]
        cycleWeight += edges[policy[member]].weight
        if path[index] < path[headPosition]: headPosition = index
      let absoluteWeight = if cycleWeight < 0: -cycleWeight else: cycleWeight
      let divisor = gcdPositive(absoluteWeight, int64(cycleLength))
      let meanNum = cycleWeight div divisor
      let meanDen = int64(cycleLength) div divisor
      let head = path[headPosition]
      for index in cycleStart ..< pathLength:
        let member = path[index]
        valueNum[member] = meanNum
        valueDen[member] = meanDen
        assigned[member] = true

      biasNum[head] = 0
      var currentPosition = headPosition
      while true:
        let previousPosition = if currentPosition == cycleStart: pathLength - 1 else: currentPosition - 1
        let previous = path[previousPosition]
        if previous == head: break
        biasNum[previous] = edges[policy[previous]].weight * meanDen - meanNum + biasNum[path[currentPosition]]
        currentPosition = previousPosition
      prefixLength = cycleStart

    var prefixPosition = prefixLength
    while prefixPosition > 0:
      dec prefixPosition
      let u = path[prefixPosition]
      let successor = edges[policy[u]].toVertex
      valueNum[u] = valueNum[successor]
      valueDen[u] = valueDen[successor]
      biasNum[u] = edges[policy[u]].weight * valueDen[successor] - valueNum[successor] + biasNum[successor]
      assigned[u] = true

proc minimum_mean_cycle_howard*(input: ptr UncheckedArray[int64], inputLength: csize_t,
    output: ptr UncheckedArray[uint8], outputCapacity: csize_t): int64
    {.cdecl, exportc: "minimum_mean_cycle_howard".} =
  if input.isNil or inputLength < 2 or inputLength > csize_t(MaxInputLength): return -1
  let nArg = input[0]
  let mArg = input[1]
  if nArg < 1 or nArg > MaxVertices or mArg < 1 or mArg > MaxEdges: return -1
  let n = int(nArg)
  let m = int(mArg)
  if m > n * n or int(inputLength) != 2 + 3 * m: return -1

  var edges: array[MaxEdges, Edge]
  var adjacent: array[MaxVertices * MaxVertices, bool]
  var outgoing: array[MaxVertices * MaxEdges, int]
  var degree: array[MaxVertices, int]
  var policy: array[MaxVertices, int]
  for edgeIndex in 0 ..< m:
    let fromArg = input[2 + 3 * edgeIndex]
    let toArg = input[3 + 3 * edgeIndex]
    let weight = input[4 + 3 * edgeIndex]
    if fromArg < 0 or fromArg >= nArg or toArg < 0 or toArg >= nArg or weight < -1000 or weight > 1000:
      return -1
    let fromVertex = int(fromArg)
    let toVertex = int(toArg)
    let adjacentSlot = fromVertex * MaxVertices + toVertex
    if adjacent[adjacentSlot]: return -1
    adjacent[adjacentSlot] = true
    edges[edgeIndex] = Edge(fromVertex: fromVertex, toVertex: toVertex, weight: weight)
    outgoing[fromVertex * MaxEdges + degree[fromVertex]] = edgeIndex
    inc degree[fromVertex]
    if degree[fromVertex] == 1: policy[fromVertex] = edgeIndex
  if not allReachable(n, adjacent, false) or not allReachable(n, adjacent, true): return -1
  if output.isNil or outputCapacity < csize_t(OutputBytes): return -2

  var policyLimit = 1
  for vertex in 0 ..< n: policyLimit *= degree[vertex]
  var valueNum: array[MaxVertices, int64]
  var valueDen: array[MaxVertices, int64]
  var biasNum: array[MaxVertices, int64]
  for vertex in 0 ..< MaxVertices: valueDen[vertex] = 1
  var converged = false
  for _ in 0 ..< policyLimit:
    evaluatePolicy(n, edges, policy, valueNum, valueDen, biasNum)
    var improved = policy
    var changed = false
    for vertex in 0 ..< n:
      var best = policy[vertex]
      for index in 0 ..< degree[vertex]:
        let candidate = outgoing[vertex * MaxEdges + index]
        if compareAppraisal(candidate, best, edges, valueNum, valueDen, biasNum) < 0:
          best = candidate
      improved[vertex] = best
      if best != policy[vertex]: changed = true
    if not changed:
      converged = true
      break
    policy = improved
  if not converged: return -1

  var bestVertex = 0
  for vertex in 1 ..< n:
    if compareRatio(valueNum[vertex], valueDen[vertex], valueNum[bestVertex], valueDen[bestVertex]) < 0:
      bestVertex = vertex
  var answerNum = valueNum[bestVertex]
  var answerDen = valueDen[bestVertex]
  let absoluteAnswer = if answerNum < 0: -answerNum else: answerNum
  let divisor = gcdPositive(absoluteAnswer, answerDen)
  answerNum = answerNum div divisor
  answerDen = answerDen div divisor

  var staged: array[OutputBytes, uint8]
  storeI64Le(staged, 0, answerNum)
  storeI64Le(staged, 8, answerDen)
  for byte in 0 ..< OutputBytes: output[byte] = staged[byte]
  OutputBytes.int64
