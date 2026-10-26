const MaxPoints = 8
const MaxNodes = 15
const LeafSize = 2
const MaxInputLength = 34

type
  Point = object
    x, y: int64
  Node = object
    left, right, start, count: int
    minX, minY, maxX, maxY: int64
  Tree = object
    points: array[MaxPoints, Point]
    order, scratch: array[MaxPoints, int]
    nodes: array[MaxNodes, Node]
    used: int

proc build(tree: var Tree, start, count: int): int =
  result = tree.used
  inc tree.used
  let first = tree.points[tree.order[start]]
  var node = Node(left: -1, right: -1, start: start, count: count,
                  minX: first.x, minY: first.y, maxX: first.x, maxY: first.y)
  for i in 1..<count:
    let p = tree.points[tree.order[start + i]]
    node.minX = min(node.minX, p.x); node.maxX = max(node.maxX, p.x)
    node.minY = min(node.minY, p.y); node.maxY = max(node.maxY, p.y)
  if count <= LeafSize:
    tree.nodes[result] = node
    return
  let axisX = (node.maxX - node.minX) > (node.maxY - node.minY)
  let midpointTwice = if axisX: node.minX + node.maxX else: node.minY + node.maxY
  var leftCount = 0
  for i in 0..<count:
    let p = tree.points[tree.order[start + i]]
    let coordinate = if axisX: p.x else: p.y
    if 2 * coordinate < midpointTwice: inc leftCount
  if leftCount == 0 or leftCount == count:
    leftCount = (count + 1) div 2
    for i in 0..<count: tree.scratch[i] = tree.order[start + i]
  else:
    var l = 0
    var r = leftCount
    for i in 0..<count:
      let index = tree.order[start + i]
      let p = tree.points[index]
      let coordinate = if axisX: p.x else: p.y
      if 2 * coordinate < midpointTwice:
        tree.scratch[l] = index; inc l
      else:
        tree.scratch[r] = index; inc r
  for i in 0..<count: tree.order[start + i] = tree.scratch[i]
  node.left = build(tree, start, leftCount)
  node.right = build(tree, start + leftCount, count - leftCount)
  node.count = 0
  tree.nodes[result] = node

proc boxDistance(a, b: Node): int64 =
  var dx = 0'i64
  var dy = 0'i64
  if a.maxX < b.minX: dx = b.minX - a.maxX
  elif b.maxX < a.minX: dx = a.minX - b.maxX
  if a.maxY < b.minY: dy = b.minY - a.maxY
  elif b.maxY < a.minY: dy = a.minY - b.maxY
  dx * dx + dy * dy

proc search(a, b: var Tree, ai, bi: int, best: var int64) =
  let na = a.nodes[ai]
  let nb = b.nodes[bi]
  if boxDistance(na, nb) > best: return
  let aLeaf = na.left < 0
  let bLeaf = nb.left < 0
  if aLeaf and bLeaf:
    for i in 0..<na.count:
      let p = a.points[a.order[na.start + i]]
      for j in 0..<nb.count:
        let q = b.points[b.order[nb.start + j]]
        let dx = p.x - q.x
        let dy = p.y - q.y
        let distance = dx * dx + dy * dy
        if distance < best: best = distance
  elif aLeaf:
    let left = nb.left
    let right = nb.right
    if boxDistance(na, b.nodes[left]) < boxDistance(na, b.nodes[right]):
      search(a, b, ai, left, best); search(a, b, ai, right, best)
    else:
      search(a, b, ai, right, best); search(a, b, ai, left, best)
  elif bLeaf:
    let left = na.left
    let right = na.right
    if boxDistance(nb, a.nodes[left]) < boxDistance(nb, a.nodes[right]):
      search(a, b, left, bi, best); search(a, b, right, bi, best)
    else:
      search(a, b, right, bi, best); search(a, b, left, bi, best)
  else:
    var pairs = [(na.left, nb.left), (na.left, nb.right), (na.right, nb.left), (na.right, nb.right)]
    var distances: array[4, int64]
    for i in 0..<4: distances[i] = boxDistance(a.nodes[pairs[i][0]], b.nodes[pairs[i][1]])
    for i in 1..<4:
      let pair = pairs[i]
      let distance = distances[i]
      var j = i
      while j > 0 and distance < distances[j - 1]:
        pairs[j] = pairs[j - 1]; distances[j] = distances[j - 1]; dec j
      pairs[j] = pair; distances[j] = distance
    for pair in pairs: search(a, b, pair[0], pair[1], best)

proc writeI64Le(output: ptr UncheckedArray[uint8], value: int64) =
  let bits = cast[uint64](value)
  for i in 0..<8: output[i] = uint8((bits shr (8 * i)) and 0xff'u64)

# Clean-room bounded ParGeo profile; see package LICENSE.txt for the complete MIT notice.
proc pargeo_bichromatic_closest_pair*(input: ptr UncheckedArray[int64], inputLength: csize_t,
    output: ptr UncheckedArray[uint8], outputCapacity: csize_t): int64
    {.cdecl, exportc: "pargeo_bichromatic_closest_pair".} =
  if input == nil or inputLength < 10 or inputLength > MaxInputLength: return -1
  if input[0] < 2 or input[0] > MaxPoints or input[1] < 2 or input[1] > MaxPoints: return -1
  let na = int(input[0]); let nb = int(input[1])
  if inputLength != csize_t(2 + 2 * (na + nb)): return -1
  for i in 2..<int(inputLength):
    if input[i] < -1_000_000 or input[i] > 1_000_000: return -1
  if output == nil or outputCapacity < 8: return -2
  var a: Tree
  var b: Tree
  for i in 0..<na:
    a.points[i] = Point(x: input[2 + 2 * i], y: input[3 + 2 * i]); a.order[i] = i
  let offset = 2 + 2 * na
  for i in 0..<nb:
    b.points[i] = Point(x: input[offset + 2 * i], y: input[offset + 2 * i + 1]); b.order[i] = i
  let rootA = build(a, 0, na)
  let rootB = build(b, 0, nb)
  var best = high(int64)
  search(a, b, rootA, rootB, best)
  writeI64Le(output, best)
  8
