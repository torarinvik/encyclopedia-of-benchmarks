const MaxN = 64
const MaxQ = 64
const Modulus = 998244353'i64
const MaxInputValues = 4 * MaxN + 4 * MaxQ

type
  Affine = object
    a, b: int64
  Aggregate = object
    forward, backward: Affine

proc identity(): Affine = Affine(a: 1, b: 0)

proc compose(after, before: Affine): Affine =
  Affine(a: (after.a * before.a) mod Modulus,
    b: (after.a * before.b + after.b) mod Modulus)

proc identityAggregate(): Aggregate =
  let id = identity()
  Aggregate(forward: id, backward: id)

proc combine(left, right: Aggregate): Aggregate =
  Aggregate(forward: compose(right.forward, left.forward),
    backward: compose(left.backward, right.backward))

proc findRoot(parent: var array[MaxN, int], item: int): int =
  var node = item
  while parent[node] != node:
    parent[node] = parent[parent[node]]
    node = parent[node]
  node

proc updateLeaf(tree: var array[2 * MaxN, Aggregate], base, position: int, value: Affine) =
  var node = base + position
  tree[node] = Aggregate(forward: value, backward: value)
  while node > 1:
    node = node shr 1
    tree[node] = combine(tree[node shl 1], tree[(node shl 1) or 1])

proc rangeQuery(tree: openArray[Aggregate], base, leftValue, rightValue: int): Aggregate =
  var prefix = identityAggregate()
  var suffix = identityAggregate()
  var left = leftValue + base
  var right = rightValue + base
  while left < right:
    if (left and 1) != 0:
      prefix = combine(prefix, tree[left])
      inc left
    if (right and 1) != 0:
      dec right
      suffix = combine(tree[right], suffix)
    left = left shr 1
    right = right shr 1
  combine(prefix, suffix)

proc pathComposition(tree: openArray[Aggregate], base: int,
    parent, depth, head, position: array[MaxN, int], fromValue, toValue: int): Affine =
  var left = identity()
  var right = identity()
  var from = fromValue
  var to = toValue
  while head[from] != head[to]:
    if depth[head[from]] >= depth[head[to]]:
      let part = rangeQuery(tree, base, position[head[from]], position[from] + 1)
      left = compose(part.backward, left)
      from = parent[head[from]]
    else:
      let part = rangeQuery(tree, base, position[head[to]], position[to] + 1)
      right = compose(right, part.forward)
      to = parent[head[to]]
  if depth[from] >= depth[to]:
    let part = rangeQuery(tree, base, position[to], position[from] + 1)
    left = compose(part.backward, left)
  else:
    let part = rangeQuery(tree, base, position[from], position[to] + 1)
    right = compose(right, part.forward)
  compose(right, left)

proc storeI64Le(output: ptr UncheckedArray[uint8], offset: int, value: int64) =
  let bits = cast[uint64](value)
  for byte in 0 ..< 8:
    output[offset + byte] = uint8((bits shr (8 * byte)) and 255)

proc vertex_set_path_composite*(input: ptr UncheckedArray[int64], length: csize_t,
    output: ptr UncheckedArray[uint8], capacity: csize_t): int64
    {.cdecl, exportc: "vertex_set_path_composite".} =
  if input.isNil or length < 8 or length > csize_t(MaxInputValues): return -1
  let nValue = input[0]
  let qValue = input[1]
  if nValue < 1 or nValue > MaxN or qValue < 1 or qValue > MaxQ: return -1
  let n = int(nValue)
  let q = int(qValue)
  if length != csize_t(4 * n + 4 * q): return -1

  var values: array[MaxN, Affine]
  for vertex in 0 ..< n:
    let a = input[2 + 2 * vertex]
    let b = input[3 + 2 * vertex]
    if a < 1 or a >= Modulus or b < 0 or b >= Modulus: return -1
    values[vertex] = Affine(a: a, b: b)

  var adjacent: array[MaxN, array[MaxN, bool]]
  var dsuParent, dsuSize: array[MaxN, int]
  for vertex in 0 ..< n:
    dsuParent[vertex] = vertex
    dsuSize[vertex] = 1
  let edgeStart = 2 + 2 * n
  for edge in 0 ..< (n - 1):
    let offset = edgeStart + 2 * edge
    let leftValue = input[offset]
    let rightValue = input[offset + 1]
    if leftValue < 0 or leftValue >= nValue or rightValue < 0 or
       rightValue >= nValue or leftValue == rightValue: return -1
    let left = int(leftValue)
    let right = int(rightValue)
    var rootLeft = findRoot(dsuParent, left)
    var rootRight = findRoot(dsuParent, right)
    if rootLeft == rootRight: return -1
    if dsuSize[rootLeft] < dsuSize[rootRight]: swap(rootLeft, rootRight)
    dsuParent[rootRight] = rootLeft
    dsuSize[rootLeft] += dsuSize[rootRight]
    adjacent[left][right] = true
    adjacent[right][left] = true

  let operationStart = edgeStart + 2 * (n - 1)
  for query in 0 ..< q:
    let offset = operationStart + 4 * query
    let kind = input[offset]
    let first = input[offset + 1]
    let second = input[offset + 2]
    let third = input[offset + 3]
    if kind == 0:
      if first < 0 or first >= nValue or second < 1 or second >= Modulus or
         third < 0 or third >= Modulus: return -1
    elif kind == 1:
      if first < 0 or first >= nValue or second < 0 or second >= nValue or
         third < 0 or third >= Modulus: return -1
    else:
      return -1

  var parent, depth, subtree, heavy, order, stack: array[MaxN, int]
  var orderCount = 0
  var top = 1
  parent[0] = 0
  subtree[0] = 1
  heavy[0] = MaxN
  stack[0] = 0
  order[orderCount] = 0
  inc orderCount
  while top > 0:
    dec top
    let vertex = stack[top]
    for neighbor in 0 ..< n:
      if not adjacent[vertex][neighbor] or neighbor == parent[vertex]: continue
      parent[neighbor] = vertex
      depth[neighbor] = depth[vertex] + 1
      subtree[neighbor] = 1
      heavy[neighbor] = MaxN
      order[orderCount] = neighbor
      inc orderCount
      stack[top] = neighbor
      inc top
  var reverseIndex = orderCount
  while reverseIndex > 1:
    dec reverseIndex
    let vertex = order[reverseIndex]
    let p = parent[vertex]
    subtree[p] += subtree[vertex]
    if heavy[p] == MaxN or subtree[vertex] > subtree[heavy[p]] or
       (subtree[vertex] == subtree[heavy[p]] and vertex < heavy[p]):
      heavy[p] = vertex

  var head, position, chainVertex, chainHead: array[MaxN, int]
  var chainCount = 1
  var timer = 0
  chainVertex[0] = 0
  chainHead[0] = 0
  while chainCount > 0:
    dec chainCount
    var vertex = chainVertex[chainCount]
    let currentHead = chainHead[chainCount]
    while vertex != MaxN:
      head[vertex] = currentHead
      position[vertex] = timer
      inc timer
      for child in 0 ..< n:
        if adjacent[vertex][child] and parent[child] == vertex and child != heavy[vertex]:
          chainVertex[chainCount] = child
          chainHead[chainCount] = child
          inc chainCount
      vertex = heavy[vertex]

  var base = 1
  while base < n: base = base shl 1
  var tree: array[2 * MaxN, Aggregate]
  for node in 0 ..< 2 * base: tree[node] = identityAggregate()
  for vertex in 0 ..< n:
    updateLeaf(tree, base, position[vertex], values[vertex])

  var answers: array[MaxQ, int64]
  var answerCount = 0
  for query in 0 ..< q:
    let offset = operationStart + 4 * query
    let kind = input[offset]
    let first = int(input[offset + 1])
    let second = input[offset + 2]
    let third = input[offset + 3]
    if kind == 0:
      values[first] = Affine(a: second, b: third)
      updateLeaf(tree, base, position[first], values[first])
    else:
      let combined = pathComposition(tree, base, parent, depth, head, position, first, int(second))
      answers[answerCount] = (combined.a * third + combined.b) mod Modulus
      inc answerCount

  let required = 8 * answerCount
  if output.isNil or capacity < csize_t(required): return -2
  for index in 0 ..< answerCount:
    storeI64Le(output, 8 * index, answers[index])
  int64(required)
