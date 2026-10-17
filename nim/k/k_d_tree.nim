import std/math

type Node = object
  point, left, right: int

proc partitionFive(ids: var seq[int], points: seq[seq[float64]], fromIndex, toIndex, axis: int): int =
  let middle = (fromIndex + toIndex) div 2
  for i in fromIndex .. middle:
    var minimum = i
    for j in i + 1 .. toIndex:
      if points[ids[j]][axis] < points[ids[minimum]][axis]: minimum = j
    swap(ids[i], ids[minimum])
  middle

proc selectKth(ids: var seq[int], points: seq[seq[float64]], fromIndex, toIndex: int,
               rank, axis: int): int

proc chooseMedianOfMedians(ids: var seq[int], points: seq[seq[float64]],
                          fromIndex, toIndex, axis: int): int =
  if toIndex - fromIndex < 5:
    return partitionFive(ids, points, fromIndex, toIndex, axis)
  var mediansTo = fromIndex
  var start = fromIndex
  while start <= toIndex - 4:
    let median = partitionFive(ids, points, start, start + 4, axis)
    swap(ids[median], ids[mediansTo])
    inc mediansTo
    start += 5
  let remainder = (toIndex - fromIndex + 1) mod 5
  if remainder == 0:
    dec mediansTo
  else:
    let median = partitionFive(ids, points, toIndex - remainder + 1, toIndex, axis)
    swap(ids[median], ids[mediansTo])
  let mediansCount = mediansTo - fromIndex + 1
  selectKth(ids, points, fromIndex, mediansTo, (mediansCount + 1) div 2, axis)

proc partitionThreeWay(ids: var seq[int], points: seq[seq[float64]], fromIndex, toIndex,
                       pivotIndex, axis: int): tuple[smallerTo: int, largerFrom: int] =
  let pivot = points[ids[pivotIndex]][axis]
  var i = fromIndex
  var j = fromIndex
  var k = toIndex
  while j <= k:
    let value = points[ids[j]][axis]
    if value < pivot:
      swap(ids[i], ids[j])
      inc i
      inc j
    elif pivot < value:
      swap(ids[j], ids[k])
      if k == 0: break
      dec k
    else:
      inc j
  (i - 1, k + 1)

proc selectKth(ids: var seq[int], points: seq[seq[float64]], fromIndex, toIndex: int,
               rank, axis: int): int =
  var first = fromIndex
  var last = toIndex
  var targetRank = rank
  while first < last:
    let pivot = chooseMedianOfMedians(ids, points, first, last, axis)
    let (smallerTo, largerFrom) = partitionThreeWay(ids, points, first, last, pivot, axis)
    let absoluteIndex = first + targetRank - 1
    if absoluteIndex <= smallerTo:
      last = smallerTo
    elif absoluteIndex < largerFrom:
      return absoluteIndex
    else:
      targetRank -= largerFrom - first
      first = largerFrom
  first

proc buildTree(points: seq[seq[float64]], indices: seq[int], dimension, depth: int,
               nodes: var seq[Node]): int =
  if indices.len == 0: return -1
  let axis = depth mod dimension
  var ordered = indices
  let middle = selectKth(ordered, points, 0, ordered.len - 1, (ordered.len + 1) div 2, axis)
  var leftIndices = newSeq[int](middle)
  for i in 0 ..< middle: leftIndices[i] = ordered[i]
  var rightIndices = newSeq[int]()
  for i in middle + 1 ..< ordered.len: rightIndices.add(ordered[i])
  let current = nodes.len
  nodes.add(Node(point: ordered[middle], left: -1, right: -1))
  nodes[current].left = buildTree(points, leftIndices, dimension, depth + 1, nodes)
  nodes[current].right = buildTree(points, rightIndices, dimension, depth + 1, nodes)
  current

proc searchTree(points: seq[seq[float64]], nodes: seq[Node], current, axis: int,
                query: seq[float64], dimension: int, best: var float64,
                bestPoint: var int) =
  if current < 0: return
  let node = nodes[current]
  let point = points[node.point]
  var squared = 0.0
  for a in 0 ..< dimension:
    let delta = query[a] - point[a]
    squared += delta * delta
  let distance = sqrt(squared)
  if distance < best:
    best = distance
    bestPoint = node.point
  let goLeft = query[axis] <= point[axis]
  let near = if goLeft: node.left else: node.right
  let far = if goLeft: node.right else: node.left
  let nextAxis = (axis + 1) mod dimension
  searchTree(points, nodes, near, nextAxis, query, dimension, best, bestPoint)
  if best >= abs(point[axis] - query[axis]):
    searchTree(points, nodes, far, nextAxis, query, dimension, best, bestPoint)

proc finiteIntegerInRange(value: float64, low, high: float64): bool =
  classify(value) notin {fcNan, fcInf, fcNegInf} and value == floor(value) and
    value >= low and value <= high

proc k_d_tree*(input: ptr UncheckedArray[float64], length: csize_t,
    output: ptr UncheckedArray[float64], outputCapacity: csize_t): int64
    {.cdecl, exportc: "k_d_tree".} =
  if input == nil or length < 2 or length > 51: return -1
  if not finiteIntegerInRange(input[0], 2.0, 3.0) or (input[0] != 2.0 and input[0] != 3.0): return -1
  let dimension = int(input[0])
  if not finiteIntegerInRange(input[1], 1.0, 15.0): return -1
  let count = int(input[1])
  if length != csize_t(2 + dimension * (count + 1)): return -1
  var query = newSeq[float64](dimension)
  for axis in 0 ..< dimension:
    let value = input[2 + axis]
    if not finiteIntegerInRange(value, -1000.0, 1000.0): return -1
    query[axis] = value
  var points = newSeq[seq[float64]](count)
  let offset = 2 + dimension
  for i in 0 ..< count:
    points[i] = newSeq[float64](dimension)
    for axis in 0 ..< dimension:
      let value = input[offset + i * dimension + axis]
      if not finiteIntegerInRange(value, -1000.0, 1000.0): return -1
      points[i][axis] = value
  for axis in 0 ..< dimension:
    for i in 0 ..< count:
      for j in i + 1 ..< count:
        if points[i][axis] == points[j][axis]: return -1
  var smallest = Inf
  var nearestCount = 0
  for point in points:
    var squared = 0.0
    for axis in 0 ..< dimension:
      let delta = query[axis] - point[axis]
      squared += delta * delta
    if squared < smallest:
      smallest = squared
      nearestCount = 1
    elif squared == smallest:
      inc nearestCount
  if nearestCount != 1: return -1
  let outputLength = dimension + 1
  if output == nil or outputCapacity < csize_t(outputLength): return -2
  var indices = newSeq[int](count)
  for i in 0 ..< count: indices[i] = i
  var nodes = newSeq[Node]()
  let root = buildTree(points, indices, dimension, 0, nodes)
  var best = Inf
  var bestPoint = 0
  searchTree(points, nodes, root, 0, query, dimension, best, bestPoint)
  output[0] = best
  for axis in 0 ..< dimension: output[axis + 1] = points[bestPoint][axis]
  int64(outputLength)
