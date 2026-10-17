const MaxVertices = 64
const MaxEdges = 4096
const MaxInputLength = 2 + 3 * MaxEdges

type
  I64Input = ptr UncheckedArray[int64]
  U8Output = ptr UncheckedArray[uint8]

proc edgeLess(input: I64Input, left, right: int): bool =
  let leftWeight = input[2 + 3 * left + 2]
  let rightWeight = input[2 + 3 * right + 2]
  leftWeight < rightWeight or (leftWeight == rightWeight and left < right)

proc siftDown(input: I64Input, order: var array[MaxEdges, int], rootStart, ending: int) =
  var root = rootStart
  while root * 2 + 1 < ending:
    var child = root * 2 + 1
    if child + 1 < ending and edgeLess(input, order[child], order[child + 1]):
      inc child
    if not edgeLess(input, order[root], order[child]):
      break
    swap(order[root], order[child])
    root = child

proc heapSort(input: I64Input, order: var array[MaxEdges, int], count: int) =
  var start = count div 2
  while start > 0:
    dec start
    siftDown(input, order, start, count)
  var ending = count
  while ending > 1:
    dec ending
    swap(order[0], order[ending])
    siftDown(input, order, 0, ending)

proc findRoot(parent: var array[MaxVertices, int], nodeStart: int): int =
  var node = nodeStart
  while parent[node] != node:
    parent[node] = parent[parent[node]]
    node = parent[node]
  node

proc putI64Le(output: U8Output, offset: int, value: int64) =
  let bits = cast[uint64](value)
  for byte in 0..<8:
    output[offset + byte] = uint8((bits shr (8 * byte)) and 0xFF'u64)

proc minimum_spanning_tree_kruskal*(input: I64Input, length: csize_t,
    output: U8Output, capacity: csize_t): int64
    {.cdecl, exportc: "minimum_spanning_tree_kruskal".} =
  if input == nil or length < 2 or length > csize_t(MaxInputLength):
    return -1
  let rawVertices = input[0]
  let rawEdges = input[1]
  if rawVertices < 0 or rawVertices > int64(MaxVertices) or rawEdges < 0 or rawEdges > int64(MaxEdges):
    return -1
  let vertexCount = int(rawVertices)
  let edgeCount = int(rawEdges)
  if length != csize_t(2 + 3 * edgeCount):
    return -1

  var order: array[MaxEdges, int]
  for index in 0..<edgeCount:
    let offset = 2 + 3 * index
    let u = input[offset]
    let v = input[offset + 1]
    if u < 0 or u >= rawVertices or v < 0 or v >= rawVertices:
      return -1
    order[index] = index
  heapSort(input, order, edgeCount)

  var parent: array[MaxVertices, int]
  for vertex in 0..<vertexCount:
    parent[vertex] = vertex
  var accepted: array[MaxVertices, int]
  var acceptedCount = 0
  for index in 0..<edgeCount:
    let edgeIndex = order[index]
    let offset = 2 + 3 * edgeIndex
    let leftRoot = findRoot(parent, int(input[offset]))
    let rightRoot = findRoot(parent, int(input[offset + 1]))
    if leftRoot != rightRoot:
      accepted[acceptedCount] = edgeIndex
      inc acceptedCount
      parent[leftRoot] = rightRoot

  let byteCount = acceptedCount * 24
  if output == nil or capacity < csize_t(byteCount):
    return -2
  for index in 0..<acceptedCount:
    let inputOffset = 2 + 3 * accepted[index]
    let outputOffset = index * 24
    putI64Le(output, outputOffset, input[inputOffset])
    putI64Le(output, outputOffset + 8, input[inputOffset + 1])
    putI64Le(output, outputOffset + 16, input[inputOffset + 2])
  int64(byteCount)
