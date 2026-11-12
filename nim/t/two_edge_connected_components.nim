## Tarjan bridge detection followed by components after bridge removal.
import std/ffi

const MaxVertices = 6
const MaxEdges = 10
const MaxAdjacency = 20
const MaxOutputValues = 13
const MaxOutputBytes = 104
const MaxInputLength = 22
type
  I64Input = ptr UncheckedArray[int64]
  U8Output = ptr UncheckedArray[uint8]
  GraphContext = object
    vertexCount, edgeCount: int
    degree: array[MaxVertices, int]
    adjacentVertex, adjacentEdge: array[MaxVertices * MaxAdjacency, int]
    discovery, low: array[MaxVertices, int]
    isBridge: array[MaxEdges, bool]
    clock: int
    component: array[MaxVertices, int]
    blockVertices: array[MaxVertices * MaxVertices, int]
    blockSize: array[MaxVertices, int]
    blockCount: int

proc findBridges(context: var GraphContext, vertex, parentEdge: int) =
  context.discovery[vertex] = context.clock
  context.low[vertex] = context.clock
  inc context.clock
  for slot in 0 ..< context.degree[vertex]:
    let index = vertex * MaxAdjacency + slot
    let neighbor = context.adjacentVertex[index]
    let edge = context.adjacentEdge[index]
    if edge == parentEdge: continue
    if context.discovery[neighbor] < 0:
      findBridges(context, neighbor, edge)
      context.low[vertex] = min(context.low[vertex], context.low[neighbor])
      if context.low[neighbor] > context.discovery[vertex]: context.isBridge[edge] = true
    elif context.discovery[neighbor] < context.low[vertex]:
      context.low[vertex] = context.discovery[neighbor]

proc assignComponents(context: var GraphContext) =
  var queue: array[MaxVertices, int]
  for root in 0 ..< context.vertexCount:
    if context.component[root] >= 0: continue
    let block = context.blockCount
    inc context.blockCount
    var head = 0
    var tail = 0
    context.component[root] = block
    queue[tail] = root
    inc tail
    while head < tail:
      let vertex = queue[head]
      inc head
      for slot in 0 ..< context.degree[vertex]:
        let index = vertex * MaxAdjacency + slot
        let neighbor = context.adjacentVertex[index]
        let edge = context.adjacentEdge[index]
        if context.isBridge[edge] or context.component[neighbor] >= 0: continue
        context.component[neighbor] = block
        queue[tail] = neighbor
        inc tail
    for vertex in 0 ..< context.vertexCount:
      if context.component[vertex] == block:
        context.blockVertices[block * MaxVertices + context.blockSize[block]] = vertex
        inc context.blockSize[block]

proc blockLess(context: GraphContext, left, right: int): bool =
  let common = min(context.blockSize[left], context.blockSize[right])
  for i in 0 ..< common:
    let a = context.blockVertices[left * MaxVertices + i]
    let b = context.blockVertices[right * MaxVertices + i]
    if a != b: return a < b
  context.blockSize[left] < context.blockSize[right]

proc storeU64Le(output: var array[MaxOutputBytes, uint8], offset: int, value: uint64) =
  for byte in 0 ..< 8:
    output[offset + byte] = uint8((value shr (byte * 8)) and 0xff'u64)

proc two_edge_connected_components*(input: I64Input, length: csize_t, output: U8Output,
    outputCapacity: csize_t): int64 {.cdecl, exportc: "two_edge_connected_components".} =
  if input == nil or length < csize_t(2) or length > csize_t(MaxInputLength): return -1
  let vertexValue = input[0]
  let edgeValue = input[1]
  if vertexValue < 1 or vertexValue > MaxVertices or edgeValue < 0 or edgeValue > MaxEdges: return -1
  let vertexCount = int(vertexValue)
  let edgeCount = int(edgeValue)
  if length != csize_t(2 + 2 * edgeCount): return -1

  var context = GraphContext()
  context.vertexCount = vertexCount
  context.edgeCount = edgeCount
  for vertex in 0 ..< vertexCount:
    context.discovery[vertex] = -1
    context.component[vertex] = -1
  for edge in 0 ..< edgeCount:
    let left = input[2 + 2 * edge]
    let right = input[3 + 2 * edge]
    if left < 0 or left >= vertexValue or right < 0 or right >= vertexValue: return -1
    let u = int(left)
    let v = int(right)
    let uSlot = context.degree[u]
    inc context.degree[u]
    let vSlot = context.degree[v]
    inc context.degree[v]
    context.adjacentVertex[u * MaxAdjacency + uSlot] = v
    context.adjacentEdge[u * MaxAdjacency + uSlot] = edge
    context.adjacentVertex[v * MaxAdjacency + vSlot] = u
    context.adjacentEdge[v * MaxAdjacency + vSlot] = edge
  for root in 0 ..< vertexCount:
    if context.discovery[root] < 0: findBridges(context, root, MaxEdges)
  assignComponents(context)

  var order: array[MaxVertices, int]
  for i in 0 ..< context.blockCount:
    var position = i
    order[i] = i
    while position > 0 and blockLess(context, order[position], order[position - 1]):
      swap(order[position], order[position - 1])
      dec position
  var staged: array[MaxOutputBytes, uint8]
  var packedCount = 0
  storeU64Le(staged, packedCount * 8, uint64(context.blockCount))
  inc packedCount
  for i in 0 ..< context.blockCount:
    let block = order[i]
    storeU64Le(staged, packedCount * 8, uint64(context.blockSize[block]))
    inc packedCount
    for j in 0 ..< context.blockSize[block]:
      storeU64Le(staged, packedCount * 8, uint64(context.blockVertices[block * MaxVertices + j]))
      inc packedCount
  let bytes = 8 * packedCount
  if output == nil or outputCapacity < csize_t(bytes): return -2
  for byte in 0 ..< bytes: output[byte] = staged[byte]
  int64(bytes)
