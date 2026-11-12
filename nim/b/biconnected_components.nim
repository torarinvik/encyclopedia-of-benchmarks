## Classical DFS low-link and edge-stack biconnected decomposition.
import std/ffi

const MaxVertices = 6
const MaxEdges = 10
const MaxAdjacency = 20
const MaxBlocks = MaxVertices + MaxEdges
const MaxOutputValues = 113
const MaxOutputBytes = 904
const MaxInputLength = 22
type
  I64Input = ptr UncheckedArray[int64]
  U8Output = ptr UncheckedArray[uint8]
  GraphContext = object
    vertexCount, edgeCount: int
    edgeLeft, edgeRight: array[MaxEdges, int]
    degree: array[MaxVertices, int]
    adjacentVertex, adjacentEdge: array[MaxVertices * MaxAdjacency, int]
    discovery, low: array[MaxVertices, int]
    edgeStack: array[MaxEdges, int]
    stackSize, clock: int
    blockVertices: array[MaxBlocks * MaxVertices, int]
    blockSize: array[MaxBlocks, int]
    blockCount: int

proc appendBlock(context: var GraphContext, stopEdge: int) =
  var member: array[MaxVertices, bool]
  while context.stackSize > 0:
    dec context.stackSize
    let edge = context.edgeStack[context.stackSize]
    member[context.edgeLeft[edge]] = true
    member[context.edgeRight[edge]] = true
    if edge == stopEdge: break
  let block = context.blockCount
  inc context.blockCount
  for vertex in 0 ..< context.vertexCount:
    if member[vertex]:
      context.blockVertices[block * MaxVertices + context.blockSize[block]] = vertex
      inc context.blockSize[block]

proc visit(context: var GraphContext, vertex, parentEdge: int) =
  context.discovery[vertex] = context.clock
  context.low[vertex] = context.clock
  inc context.clock
  for slot in 0 ..< context.degree[vertex]:
    let index = vertex * MaxAdjacency + slot
    let neighbor = context.adjacentVertex[index]
    let edge = context.adjacentEdge[index]
    if edge == parentEdge: continue
    if context.discovery[neighbor] < 0:
      context.edgeStack[context.stackSize] = edge
      inc context.stackSize
      visit(context, neighbor, edge)
      context.low[vertex] = min(context.low[vertex], context.low[neighbor])
      if context.low[neighbor] >= context.discovery[vertex]: appendBlock(context, edge)
    elif context.discovery[neighbor] < context.discovery[vertex]:
      context.edgeStack[context.stackSize] = edge
      inc context.stackSize
      context.low[vertex] = min(context.low[vertex], context.discovery[neighbor])

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

proc biconnected_components*(input: I64Input, length: csize_t, output: U8Output,
    outputCapacity: csize_t): int64 {.cdecl, exportc: "biconnected_components".} =
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
  for vertex in 0 ..< vertexCount: context.discovery[vertex] = -1
  for edge in 0 ..< edgeCount:
    let left = input[2 + 2 * edge]
    let right = input[3 + 2 * edge]
    if left < 0 or left >= vertexValue or right < 0 or right >= vertexValue or left == right: return -1
    let u = int(left)
    let v = int(right)
    context.edgeLeft[edge] = u
    context.edgeRight[edge] = v
    let uSlot = context.degree[u]
    let vSlot = context.degree[v]
    inc context.degree[u]
    inc context.degree[v]
    context.adjacentVertex[u * MaxAdjacency + uSlot] = v
    context.adjacentEdge[u * MaxAdjacency + uSlot] = edge
    context.adjacentVertex[v * MaxAdjacency + vSlot] = u
    context.adjacentEdge[v * MaxAdjacency + vSlot] = edge
  for root in 0 ..< vertexCount:
    if context.discovery[root] >= 0: continue
    visit(context, root, MaxEdges)
    if context.degree[root] == 0:
      let block = context.blockCount
      inc context.blockCount
      context.blockVertices[block * MaxVertices] = root
      context.blockSize[block] = 1

  var order: array[MaxBlocks, int]
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
