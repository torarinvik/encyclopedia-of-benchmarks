const MaxInitialPoints = 64
const MaxPoints = 128
const MaxOperations = 256
const MaxValidInputLength = 898
const MaxParseableInputLength = 899
const MinCoordinate = -1_000'i64
const MaxCoordinate = 1_000'i64
const ChecksumOffset = 1_001'i64
const None = -1

type
  Point = object
    x, y: int64
  Node = object
    point: Point
    axis: int
    left, right: int

proc coordinate(point: Point, axis: int): int64 =
  if axis == 0: point.x else: point.y

proc build(points: var array[MaxInitialPoints, Point], start, length, depth: int,
           nodes: var array[MaxPoints, Node], nodeCount: var int): int =
  if length == 0: return None
  let axis = depth mod 2
  for index in start + 1 ..< start + length:
    let value = points[index]
    var position = index
    while position > start and coordinate(points[position - 1], axis) > coordinate(value, axis):
      points[position] = points[position - 1]
      dec position
    points[position] = value
  let median = length div 2
  let root = nodeCount
  inc nodeCount
  nodes[root] = Node(point: points[start + median], axis: axis, left: None, right: None)
  let left = build(points, start, median, depth + 1, nodes, nodeCount)
  let right = build(points, start + median + 1, length - median - 1, depth + 1, nodes, nodeCount)
  nodes[root].left = left
  nodes[root].right = right
  root

proc insert(nodes: var array[MaxPoints, Node], nodeCount: var int, root: int, point: Point, depth: int): int =
  if root == None:
    let index = nodeCount
    inc nodeCount
    nodes[index] = Node(point: point, axis: depth mod 2, left: None, right: None)
    return index
  let axis = nodes[root].axis
  if coordinate(point, axis) < coordinate(nodes[root].point, axis):
    nodes[root].left = insert(nodes, nodeCount, nodes[root].left, point, depth + 1)
  else:
    nodes[root].right = insert(nodes, nodeCount, nodes[root].right, point, depth + 1)
  root

proc search(nodes: var array[MaxPoints, Node], root: int, point: Point): bool =
  if root == None: return false
  if nodes[root].point.x == point.x and nodes[root].point.y == point.y: return true
  let axis = nodes[root].axis
  if coordinate(point, axis) < coordinate(nodes[root].point, axis):
    search(nodes, nodes[root].left, point)
  else:
    search(nodes, nodes[root].right, point)

proc distanceSquared(left, right: Point): int64 =
  let dx = left.x - right.x
  let dy = left.y - right.y
  dx * dx + dy * dy

proc nearest(nodes: var array[MaxPoints, Node], root: int, query: Point, bestArg: int): int =
  if root == None: return bestArg
  if nodes[root].point.x == query.x and nodes[root].point.y == query.y: return root
  let point = nodes[root].point
  let axis = nodes[root].axis
  let distance = distanceSquared(point, query)
  let dx = point.x - query.x
  let dy = point.y - query.y
  let distanceExceptAxis = if axis == 0: dy * dy else: dx * dx
  var best = bestArg
  if distance < distanceSquared(nodes[best].point, query): best = root
  let queryLeft = coordinate(query, axis) < coordinate(point, axis)
  let near = if queryLeft: nodes[root].left else: nodes[root].right
  let far = if queryLeft: nodes[root].right else: nodes[root].left
  best = nearest(nodes, near, query, best)
  if distanceExceptAxis < distanceSquared(nodes[best].point, query): best = nearest(nodes, far, query, best)
  best

proc kdtree_benchmark*(input: ptr UncheckedArray[int64], length: csize_t): int64
    {.cdecl, exportc: "kdtree_benchmark".} =
  if input.isNil or length < csize_t(2) or length > csize_t(MaxParseableInputLength): return -1
  if input[0] < 0 or input[0] > MaxInitialPoints: return -1
  let initialCount = int(input[0])
  let operationCountIndex = 1 + 2 * initialCount
  if operationCountIndex >= int(length): return -1
  let operationCountValue = input[operationCountIndex]
  if operationCountValue < 0 or operationCountValue > MaxOperations: return -1
  let operationCount = int(operationCountValue)
  if length != csize_t(operationCountIndex + 1 + 3 * operationCount) or length > csize_t(MaxValidInputLength): return -1

  var points: array[MaxInitialPoints, Point]
  for index in 0 ..< initialCount:
    let point = Point(x: input[1 + 2 * index], y: input[2 + 2 * index])
    if point.x < MinCoordinate or point.x > MaxCoordinate or point.y < MinCoordinate or point.y > MaxCoordinate: return -1
    for previous in 0 ..< index:
      if points[previous].x == point.x or points[previous].y == point.y: return -1
    points[index] = point

  var nodes: array[MaxPoints, Node]
  var pointCount = 0
  var root = None
  if initialCount > 0: root = build(points, 0, initialCount, 0, nodes, pointCount)
  var checksum = 0'i64
  let operationsStart = operationCountIndex + 1
  for operation in 0 ..< operationCount:
    let position = operationsStart + 3 * operation
    let opcode = input[position]
    let first = input[position + 1]
    let second = input[position + 2]
    var result = 0'i64
    if opcode == 0 or opcode == 1 or opcode == 4:
      if first < MinCoordinate or first > MaxCoordinate or second < MinCoordinate or second > MaxCoordinate: return -1
      let point = Point(x: first, y: second)
      if opcode == 0:
        if pointCount >= MaxPoints: return -1
        for index in 0 ..< pointCount:
          if nodes[index].point.x == first or nodes[index].point.y == second: return -1
        root = insert(nodes, pointCount, root, point, 0)
        continue
      elif opcode == 1:
        if search(nodes, root, point): result = 1
      else:
        if root == None: return -1
        let closest = nearest(nodes, root, point, root)
        result = distanceSquared(nodes[closest].point, point)
    elif opcode == 2 or opcode == 3:
      if first < 0 or first > 1 or second != 0 or root == None: return -1
      let axis = int(first)
      result = coordinate(nodes[0].point, axis)
      for index in 1 ..< pointCount:
        let value = coordinate(nodes[index].point, axis)
        if (opcode == 2 and value < result) or (opcode == 3 and value > result): result = value
    else:
      return -1
    checksum += int64(operation + 1) * (result + ChecksumOffset)
  checksum
