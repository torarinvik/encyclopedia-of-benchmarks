const MaxVertices = 64
const MaxEdges = 256
const MaxWeight = 1_000_000'i64
const Inf = 1_000_000_000'i64

proc bidirectional_dijkstra*(input: ptr UncheckedArray[int64], length: csize_t): int64
    {.cdecl, exportc: "bidirectional_dijkstra".} =
  if input.isNil or length < 4: return -1
  let nValue = input[0]
  let mValue = input[1]
  let sourceValue = input[2]
  let targetValue = input[3]
  if nValue < 1 or nValue > MaxVertices or mValue < 0 or mValue > MaxEdges: return -1
  if sourceValue < 0 or sourceValue >= nValue or targetValue < 0 or targetValue >= nValue: return -1
  let n = int(nValue)
  let m = int(mValue)
  if length != csize_t(4 + 3 * m): return -1
  for edge in 0 ..< m:
    let fromValue = input[4 + 3 * edge]
    let toValue = input[5 + 3 * edge]
    let weight = input[6 + 3 * edge]
    if fromValue < 0 or fromValue >= nValue or toValue < 0 or toValue >= nValue
        or weight < 0 or weight > MaxWeight: return -1
  let source = int(sourceValue)
  let target = int(targetValue)
  if source == target: return 0

  var forward: array[MaxVertices, int64]
  var backward: array[MaxVertices, int64]
  var settledForward: array[MaxVertices, bool]
  var settledBackward: array[MaxVertices, bool]
  for vertex in 0 ..< n:
    forward[vertex] = Inf
    backward[vertex] = Inf
  forward[source] = 0
  backward[target] = 0
  var best = Inf

  for step in 0 ..< 2 * n:
    var nextForward = n
    var nextBackward = n
    var minForward = Inf
    var minBackward = Inf
    for vertex in 0 ..< n:
      if not settledForward[vertex] and forward[vertex] < minForward:
        minForward = forward[vertex]
        nextForward = vertex
      if not settledBackward[vertex] and backward[vertex] < minBackward:
        minBackward = backward[vertex]
        nextBackward = vertex
    if nextForward == n or nextBackward == n: break
    if best != Inf and minForward + minBackward >= best: break

    if minForward <= minBackward:
      let current = nextForward
      settledForward[current] = true
      if backward[current] != Inf and forward[current] + backward[current] < best:
        best = forward[current] + backward[current]
      for edge in 0 ..< m:
        if int(input[4 + 3 * edge]) != current: continue
        let to = int(input[5 + 3 * edge])
        let candidate = forward[current] + input[6 + 3 * edge]
        if not settledForward[to] and candidate < forward[to]: forward[to] = candidate
        if backward[to] != Inf and candidate + backward[to] < best: best = candidate + backward[to]
    else:
      let current = nextBackward
      settledBackward[current] = true
      if forward[current] != Inf and forward[current] + backward[current] < best:
        best = forward[current] + backward[current]
      for edge in 0 ..< m:
        if int(input[5 + 3 * edge]) != current: continue
        let from = int(input[4 + 3 * edge])
        let candidate = backward[current] + input[6 + 3 * edge]
        if not settledBackward[from] and candidate < backward[from]: backward[from] = candidate
        if forward[from] != Inf and forward[from] + input[6 + 3 * edge] + backward[current] < best:
          best = forward[from] + input[6 + 3 * edge] + backward[current]
  if best == Inf: -1 else: best
