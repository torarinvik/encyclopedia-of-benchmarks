## Bounded Johnson all-pairs distances for the pinned Java matrix contract.
const MaxVertices = 16
const MaxInputLength = 1 + MaxVertices * MaxVertices
const MaxWeight = 32'i64
const UnreachableSentinel = 1'i64 shl 62
const FnvOffset = 14695981039346656037'u64
const FnvPrime = 1099511628211'u64

proc fnvWord(hash: uint64, value: int64): uint64 =
  let bits = cast[uint64](value)
  var resultHash = hash
  for byte in 0 ..< 8:
    resultHash = (resultHash xor ((bits shr (8 * byte)) and 255'u64)) * FnvPrime
  resultHash

proc johnsons_algorithm*(input: ptr UncheckedArray[int64], length: csize_t): int64
    {.cdecl, exportc: "johnsons_algorithm".} =
  if input.isNil or length < 1 or length > csize_t(MaxInputLength): return -1
  let vertexValue = input[0]
  if vertexValue < 1 or vertexValue > MaxVertices: return -1
  let vertices = int(vertexValue)
  if int(length) != 1 + vertices * vertices: return -1

  var weight: array[MaxVertices, array[MaxVertices, int64]]
  var edge: array[MaxVertices, array[MaxVertices, bool]]
  var reachable: array[MaxVertices, array[MaxVertices, bool]]
  for fromVertex in 0 ..< vertices:
    reachable[fromVertex][fromVertex] = true
    for toVertex in 0 ..< vertices:
      let value = input[1 + fromVertex * vertices + toVertex]
      if value < -MaxWeight or value > MaxWeight: return -1
      if fromVertex != toVertex and value != 0:
        edge[fromVertex][toVertex] = true
        weight[fromVertex][toVertex] = value
        reachable[fromVertex][toVertex] = true
  for intermediate in 0 ..< vertices:
    for fromVertex in 0 ..< vertices:
      for toVertex in 0 ..< vertices:
        reachable[fromVertex][toVertex] = reachable[fromVertex][toVertex] or
          (reachable[fromVertex][intermediate] and reachable[intermediate][toVertex])
  for fromVertex in 0 ..< vertices:
    for toVertex in 0 ..< vertices:
      if not reachable[fromVertex][toVertex]: return -1

  var potential: array[MaxVertices, int64]
  for _ in 1 ..< vertices:
    var updated = false
    for fromVertex in 0 ..< vertices:
      for toVertex in 0 ..< vertices:
        if not edge[fromVertex][toVertex]: continue
        let candidate = potential[fromVertex] + weight[fromVertex][toVertex]
        if candidate < potential[toVertex]:
          potential[toVertex] = candidate
          updated = true
    if not updated: break
  for fromVertex in 0 ..< vertices:
    for toVertex in 0 ..< vertices:
      if not edge[fromVertex][toVertex]: continue
      if potential[fromVertex] + weight[fromVertex][toVertex] < potential[toVertex] or
          weight[fromVertex][toVertex] + potential[fromVertex] - potential[toVertex] <= 0:
        return -1

  var reweighted: array[MaxVertices, array[MaxVertices, int64]]
  for fromVertex in 0 ..< vertices:
    for toVertex in 0 ..< vertices:
      if edge[fromVertex][toVertex]:
        reweighted[fromVertex][toVertex] = weight[fromVertex][toVertex] +
          potential[fromVertex] - potential[toVertex]

  var resultHash = FnvOffset
  for source in 0 ..< vertices:
    var distance: array[MaxVertices, int64]
    var visited: array[MaxVertices, bool]
    for vertex in 0 ..< vertices: distance[vertex] = high(int64)
    distance[source] = 0
    for _ in 0 ..< vertices:
      var current = vertices
      for vertex in 0 ..< vertices:
        if not visited[vertex] and (current == vertices or distance[vertex] <= distance[current]):
          current = vertex
      if current == vertices or distance[current] == high(int64): break
      visited[current] = true
      for next in 0 ..< vertices:
        if not edge[current][next] or visited[next]: continue
        let candidate = distance[current] + reweighted[current][next]
        if candidate < distance[next]: distance[next] = candidate
    for destination in 0 ..< vertices:
      let output = if distance[destination] == high(int64): UnreachableSentinel
                   else: distance[destination] - potential[source] + potential[destination]
      resultHash = fnvWord(resultHash, output)
  int64(resultHash and 0x7fff_ffff_ffff_ffff'u64)
