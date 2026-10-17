const MaxVertices = 64
const MaxEdges = MaxVertices * (MaxVertices - 1) div 2
const MaxValidInputLength = 2 + 3 * MaxEdges
const MaxInputLength = MaxValidInputLength + 1
const WeightMin = -1_000_000'i64
const WeightMax = 1_000_000'i64
const FnvOffset = 14695981039346656037'u64
const FnvPrime = 1099511628211'u64

type Edge = object
  left: int
  right: int
  weight: int32

proc siftDown(edges: var array[MaxEdges, Edge], rootArg, endExclusive: int) =
  var root = rootArg
  while root * 2 + 1 < endExclusive:
    var child = root * 2 + 1
    if child + 1 < endExclusive and edges[child].weight < edges[child + 1].weight:
      inc child
    if edges[root].weight >= edges[child].weight: return
    swap(edges[root], edges[child])
    root = child

proc sortEdges(edges: var array[MaxEdges, Edge], count: int) =
  var start = count div 2
  while start > 0:
    dec start
    siftDown(edges, start, count)
  var endExclusive = count
  while endExclusive > 1:
    dec endExclusive
    swap(edges[0], edges[endExclusive])
    siftDown(edges, 0, endExclusive)

proc findRoot(parent: var array[MaxVertices, int], vertexArg: int): int =
  var root = vertexArg
  while parent[root] != root:
    root = parent[root]
  var vertex = vertexArg
  while parent[vertex] != vertex:
    let next = parent[vertex]
    parent[vertex] = root
    vertex = next
  root

proc unionSets(parent: var array[MaxVertices, int], ranks: var array[MaxVertices, int], left, right: int): bool =
  let leftRoot = findRoot(parent, left)
  let rightRoot = findRoot(parent, right)
  if leftRoot == rightRoot: return false
  if ranks[leftRoot] < ranks[rightRoot]:
    parent[leftRoot] = rightRoot
  else:
    parent[rightRoot] = leftRoot
    if ranks[leftRoot] == ranks[rightRoot]: inc ranks[leftRoot]
  true

proc hashByte(hashValue: uint64, byte: uint8): uint64 =
  (hashValue xor uint64(byte)) *% FnvPrime

proc hashU16(hashValue: uint64, value: uint16): uint64 =
  var hash = hashValue
  for shift in countup(0, 8, 8):
    hash = hashByte(hash, uint8(value shr shift))
  hash

proc hashI32(hashValue: uint64, value: int32): uint64 =
  var hash = hashValue
  let bits = cast[uint32](value)
  for shift in countup(0, 24, 8):
    hash = hashByte(hash, uint8(bits shr shift))
  hash

proc hashI64(hashValue: uint64, value: int64): uint64 =
  var hash = hashValue
  let bits = cast[uint64](value)
  for shift in countup(0, 56, 8):
    hash = hashByte(hash, uint8(bits shr shift))
  hash

proc kruskal_mst*(input: ptr UncheckedArray[int64], length: csize_t): int64
    {.cdecl, exportc: "kruskal_mst".} =
  if input.isNil or length < csize_t(2) or length > csize_t(MaxInputLength): return -1
  let vertexCount64 = input[0]
  let edgeCount64 = input[1]
  if vertexCount64 < 1'i64 or vertexCount64 > int64(MaxVertices) or
      edgeCount64 < 0'i64 or edgeCount64 > int64(MaxEdges): return -1
  let vertexCount = int(vertexCount64)
  let edgeCount = int(edgeCount64)
  if int(length) != 2 + 3 * edgeCount or int(length) > MaxValidInputLength: return -1
  let maximumForGraph = vertexCount * (vertexCount - 1) div 2
  if edgeCount > maximumForGraph or
      (vertexCount == 1 and edgeCount != 0) or
      (vertexCount > 1 and edgeCount < vertexCount - 1): return -1

  var edges: array[MaxEdges, Edge]
  var seenPairs: array[MaxVertices * MaxVertices, bool]
  for index in 0 ..< edgeCount:
    let offset = 2 + 3 * index
    let rawLeft = input[offset]
    let rawRight = input[offset + 1]
    let rawWeight = input[offset + 2]
    if rawLeft < 0'i64 or rawLeft >= vertexCount64 or
        rawRight < 0'i64 or rawRight >= vertexCount64 or rawLeft == rawRight or
        rawWeight < WeightMin or rawWeight > WeightMax: return -1
    let left = int(rawLeft)
    let right = int(rawRight)
    let lower = min(left, right)
    let upper = max(left, right)
    let pairIndex = lower * MaxVertices + upper
    if seenPairs[pairIndex]: return -1
    seenPairs[pairIndex] = true
    edges[index] = Edge(left: lower, right: upper, weight: int32(rawWeight))

  sortEdges(edges, edgeCount)
  if edgeCount > 1:
    for index in 1 ..< edgeCount:
      if edges[index - 1].weight == edges[index].weight: return -1

  var parent: array[MaxVertices, int]
  var ranks: array[MaxVertices, int]
  for vertex in 0 ..< vertexCount:
    parent[vertex] = vertex
  var accepted: array[MaxVertices - 1, Edge]
  var acceptedCount = 0
  var totalWeight = 0'i64
  for index in 0 ..< edgeCount:
    if acceptedCount == vertexCount - 1: break
    if unionSets(parent, ranks, edges[index].left, edges[index].right):
      accepted[acceptedCount] = edges[index]
      inc acceptedCount
      totalWeight += int64(edges[index].weight)
  if acceptedCount != vertexCount - 1: return -1

  var hash = FnvOffset
  hash = hashU16(hash, uint16(vertexCount))
  hash = hashU16(hash, uint16(acceptedCount))
  for index in 0 ..< acceptedCount:
    hash = hashU16(hash, uint16(accepted[index].left))
    hash = hashU16(hash, uint16(accepted[index].right))
    hash = hashI32(hash, accepted[index].weight)
  hash = hashI64(hash, totalWeight)
  int64(hash and 0x7fff_ffff_ffff_ffff'u64)
