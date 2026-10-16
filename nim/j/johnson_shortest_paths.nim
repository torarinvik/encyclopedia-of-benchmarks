## Bounded Johnson all-pairs shortest paths for the pinned R contract.
const MaxVertices = 32
const MaxEdges = 256
const MaxInputLength = 770
const MaxQueue = MaxEdges + 1
const UnreachableSentinel = 1'i64 shl 62
const FnvOffset = 14695981039346656037'u64
const FnvPrime = 1099511628211'u64

proc fnvWord(hash: uint64, value: int64): uint64 =
  let bits = cast[uint64](value)
  var resultHash = hash
  for byte in 0 ..< 8:
    resultHash = (resultHash xor ((bits shr (8 * byte)) and 255'u64)) * FnvPrime
  resultHash

proc johnson_shortest_paths*(input: ptr UncheckedArray[int64], length: csize_t): int64
    {.cdecl, exportc: "johnson_shortest_paths".} =
  if input.isNil or length < 2 or length > csize_t(MaxInputLength): return -1
  let vertexValue = input[0]
  let edgeValue = input[1]
  if vertexValue < 1 or vertexValue > MaxVertices or edgeValue < 0 or edgeValue > MaxEdges: return -1
  let vertices = int(vertexValue)
  let edges = int(edgeValue)
  if int(length) != 2 + 3 * edges: return -1

  var edgeFrom: array[MaxEdges, int]
  var edgeTo: array[MaxEdges, int]
  var edgeWeight: array[MaxEdges, int64]
  for edge in 0 ..< edges:
    let fromValue = input[2 + 3 * edge]
    let toValue = input[3 + 3 * edge]
    let weight = input[4 + 3 * edge]
    if fromValue < 1 or fromValue > vertexValue or toValue < 1 or toValue > vertexValue or weight < -32 or weight > 32: return -1
    edgeFrom[edge] = int(fromValue - 1)
    edgeTo[edge] = int(toValue - 1)
    edgeWeight[edge] = weight

  var potential: array[MaxVertices, int64]
  for _ in 1 ..< vertices:
    var updated = false
    for edge in 0 ..< edges:
      let from = edgeFrom[edge]
      let to = edgeTo[edge]
      let candidate = potential[from] + edgeWeight[edge]
      if candidate < potential[to]:
        potential[to] = candidate
        updated = true
    if not updated: break
  for edge in 0 ..< edges:
    if potential[edgeFrom[edge]] + edgeWeight[edge] < potential[edgeTo[edge]]: return -1

  var resultHash = FnvOffset
  for source in 0 ..< vertices:
    var distance: array[MaxVertices, int64]
    var visited: array[MaxVertices, bool]
    for vertex in 0 ..< vertices: distance[vertex] = high(int64)
    distance[source] = 0
    var queueVertices: array[MaxQueue, int]
    var queueDistances: array[MaxQueue, int64]
    var queueLength = 1
    queueVertices[0] = source
    queueDistances[0] = 0
    while queueLength > 0:
      var minimum = 0
      for index in 1 ..< queueLength:
        if queueDistances[index] < queueDistances[minimum]: minimum = index
      let current = queueVertices[minimum]
      for index in minimum + 1 ..< queueLength:
        queueVertices[index - 1] = queueVertices[index]
        queueDistances[index - 1] = queueDistances[index]
      dec queueLength
      if visited[current]: continue
      visited[current] = true

      for edge in 0 ..< edges:
        if edgeFrom[edge] != current: continue
        let next = edgeTo[edge]
        let reweighted = edgeWeight[edge] + potential[current] - potential[next]
        let candidate = distance[current] + reweighted
        if not visited[next] and candidate < distance[next]:
          distance[next] = candidate
          queueVertices[queueLength] = next
          queueDistances[queueLength] = candidate
          inc queueLength

    for destination in 0 ..< vertices:
      let output = if distance[destination] == high(int64): UnreachableSentinel
                   else: distance[destination] - potential[source] + potential[destination]
      resultHash = fnvWord(resultHash, output)
  int64(resultHash and 0x7fff_ffff_ffff_ffff'u64)
