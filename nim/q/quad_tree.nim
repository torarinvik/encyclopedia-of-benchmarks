const
  MaxPoints = 64
  MaxCapacity = 8
  MaxDepth = 12
  MaxNodes = 1 + 4 * MaxPoints * MaxDepth
  MaxParseableInputLength = 137
  MaxOutputWords = 194
  MaxOutputBytes = 1552

type
  Point = object
    x, y: float64
  QuadNode = object
    centerX, centerY, halfWidth: float64
    pointCount: int
    pointIndices: array[MaxCapacity, int]
    children: array[4, int]
    divided: bool

proc contains(node: QuadNode, point: Point): bool =
  point.x >= node.centerX - node.halfWidth and point.x <= node.centerX + node.halfWidth and
    point.y >= node.centerY - node.halfWidth and point.y <= node.centerY + node.halfWidth

proc intersects(node: QuadNode, queryX, queryY, queryHalfWidth: float64): bool =
  queryX - queryHalfWidth <= node.centerX + node.halfWidth and
    queryX + queryHalfWidth >= node.centerX - node.halfWidth and
    queryY - queryHalfWidth <= node.centerY + node.halfWidth and
    queryY + queryHalfWidth >= node.centerY - node.halfWidth

proc subdivide(nodes: var array[MaxNodes, QuadNode], nodeIndex: int, nodeCount: var int) =
  let node = nodes[nodeIndex]
  let childHalf = node.halfWidth / 2.0
  let childX = [node.centerX - childHalf, node.centerX + childHalf,
                node.centerX - childHalf, node.centerX + childHalf]
  let childY = [node.centerY + childHalf, node.centerY + childHalf,
                node.centerY - childHalf, node.centerY - childHalf]
  for child in 0 .. 3:
    let index = nodeCount
    inc nodeCount
    nodes[index] = QuadNode(centerX: childX[child], centerY: childY[child], halfWidth: childHalf)
    nodes[nodeIndex].children[child] = index
  nodes[nodeIndex].divided = true

proc insertPoint(nodes: var array[MaxNodes, QuadNode], nodeIndex, pointIndex: int,
    points: openArray[Point], capacity: int, nodeCount: var int): bool =
  let node = nodes[nodeIndex]
  let point = points[pointIndex]
  if not contains(node, point): return false
  if node.pointCount < capacity:
    nodes[nodeIndex].pointIndices[node.pointCount] = pointIndex
    inc nodes[nodeIndex].pointCount
    return true
  if not node.divided: subdivide(nodes, nodeIndex, nodeCount)
  for child in 0 .. 3:
    let childIndex = nodes[nodeIndex].children[child]
    if insertPoint(nodes, childIndex, pointIndex, points, capacity, nodeCount): return true
  false

proc queryNode(nodes: openArray[QuadNode], nodeIndex: int,
    points: openArray[Point], queryX, queryY, queryHalfWidth: float64,
    queryIndices: var array[MaxPoints, int], queryCount: var int) =
  let node = nodes[nodeIndex]
  if not intersects(node, queryX, queryY, queryHalfWidth): return
  let left = queryX - queryHalfWidth
  let right = queryX + queryHalfWidth
  let bottom = queryY - queryHalfWidth
  let top = queryY + queryHalfWidth
  for index in 0 ..< node.pointCount:
    let pointIndex = node.pointIndices[index]
    let point = points[pointIndex]
    if point.x >= left and point.x <= right and point.y >= bottom and point.y <= top:
      queryIndices[queryCount] = pointIndex
      inc queryCount
  if node.divided:
    for child in 0 .. 3: queryNode(nodes, node.children[child], points, queryX, queryY,
        queryHalfWidth, queryIndices, queryCount)

proc writeI64Le(output: ptr UncheckedArray[uint8], offset: int, value: int64) =
  let bits = cast[uint64](value)
  for byte in 0 ..< 8:
    output[offset + byte] = uint8((bits shr (byte * 8)) and 0xff'u64)

proc quadTree*(input: ptr UncheckedArray[int64], inputLength: csize_t,
    output: ptr UncheckedArray[uint8], capacity: csize_t): int64
    {.cdecl, exportc: "quad_tree".} =
  if input == nil or inputLength < 8 or inputLength > MaxParseableInputLength.csize_t: return -1
  if input[0] < -2048 or input[0] > 2048 or input[1] < -2048 or input[1] > 2048 or
      input[2] < 1 or input[2] > 1024 or input[3] < 1 or input[3] > MaxCapacity.int64 or
      input[4] < 0 or input[4] > MaxPoints.int64: return -1
  let pointCount = int(input[4])
  if inputLength != csize_t(8 + 2 * pointCount): return -1
  let queryOffset = 5 + 2 * pointCount
  if input[queryOffset] < -8192 or input[queryOffset] > 8192 or
      input[queryOffset + 1] < -8192 or input[queryOffset + 1] > 8192 or
      input[queryOffset + 2] < 0 or input[queryOffset + 2] > 8192: return -1

  var nodes: array[MaxNodes, QuadNode]
  var nodeCount = 1
  nodes[0].centerX = float64(input[0])
  nodes[0].centerY = float64(input[1])
  nodes[0].halfWidth = float64(input[2])
  var points: array[MaxPoints, Point]
  for point in 0 ..< pointCount:
    let x = input[5 + 2 * point]
    let y = input[6 + 2 * point]
    if x < -8192 or x > 8192 or y < -8192 or y > 8192: return -1
    for earlier in 0 ..< point:
      if input[5 + 2 * earlier] == x and input[6 + 2 * earlier] == y: return -1
    points[point] = Point(x: float64(x), y: float64(y))

  var queryIndices: array[MaxPoints, int]
  var queryCount = 0
  let capacityInt = int(input[3])
  var words: array[MaxOutputWords, int64]
  words[0] = int64(pointCount)
  for point in 0 ..< pointCount:
    words[1 + point] = if insertPoint(nodes, 0, point, points, capacityInt, nodeCount): 1 else: 0
  let queryX = float64(input[queryOffset])
  let queryY = float64(input[queryOffset + 1])
  let queryHalfWidth = float64(input[queryOffset + 2])
  queryNode(nodes, 0, points, queryX, queryY, queryHalfWidth, queryIndices, queryCount)
  let wordCount = 2 + pointCount + 2 * queryCount
  words[1 + pointCount] = int64(queryCount)
  for index in 0 ..< queryCount:
    let point = points[queryIndices[index]]
    words[2 + pointCount + 2 * index] = int64(point.x)
    words[3 + pointCount + 2 * index] = int64(point.y)
  let outputBytes = wordCount * 8
  if outputBytes > MaxOutputBytes: return -1
  if output == nil or capacity < csize_t(outputBytes): return -2
  for index in 0 ..< wordCount: writeI64Le(output, index * 8, words[index])
  int64(outputBytes)
