const MaxN = 64
const MaxQ = 64
const MaxLevels = 7
const MaxInputValues = 2 + 2 * (MaxN - 1) + 3 * MaxQ

proc findRoot(parent: var array[MaxN, int], item: int): int =
  var node = item
  while parent[node] != node:
    parent[node] = parent[parent[node]]
    node = parent[node]
  node

proc lift(ancestors: array[MaxN, array[MaxLevels, int]], vertex, distance: int): int =
  result = vertex
  for bit in 0 ..< MaxLevels:
    if ((distance shr bit) and 1) != 0:
      result = ancestors[result][bit]

proc lowestCommonAncestor(ancestors: array[MaxN, array[MaxLevels, int]],
    depth: array[MaxN, int], leftValue, rightValue: int): int =
  var left = leftValue
  var right = rightValue
  if depth[left] < depth[right]: swap(left, right)
  left = lift(ancestors, left, depth[left] - depth[right])
  if left == right: return left
  for level in countdown(MaxLevels - 1, 0):
    if ancestors[left][level] != ancestors[right][level]:
      left = ancestors[left][level]
      right = ancestors[right][level]
  ancestors[left][0]

proc storeI64Le(output: ptr UncheckedArray[uint8], offset: int, value: int64) =
  let bits = cast[uint64](value)
  for byte in 0 ..< 8:
    output[offset + byte] = uint8((bits shr (8 * byte)) and 255)

proc jump_on_tree*(input: ptr UncheckedArray[int64], length: csize_t,
    output: ptr UncheckedArray[uint8], capacity: csize_t): int64
    {.cdecl, exportc: "jump_on_tree".} =
  if input.isNil or length < 2 or length > csize_t(MaxInputValues): return -1
  let nValue = input[0]
  let qValue = input[1]
  if nValue < 2 or nValue > MaxN or qValue < 1 or qValue > MaxQ: return -1
  let n = int(nValue)
  let q = int(qValue)
  let queryStart = 2 + 2 * (n - 1)
  if length != csize_t(queryStart + 3 * q): return -1

  var adjacent: array[MaxN, array[MaxN, bool]]
  var dsuParent, dsuSize: array[MaxN, int]
  for vertex in 0 ..< n:
    dsuParent[vertex] = vertex
    dsuSize[vertex] = 1
  for edge in 0 ..< (n - 1):
    let offset = 2 + 2 * edge
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

  var ancestors: array[MaxN, array[MaxLevels, int]]
  var depth, stack: array[MaxN, int]
  var visited: array[MaxN, bool]
  var top = 1
  stack[0] = 0
  visited[0] = true
  while top > 0:
    dec top
    let vertex = stack[top]
    for neighbor in 0 ..< n:
      if not adjacent[vertex][neighbor] or visited[neighbor]: continue
      visited[neighbor] = true
      ancestors[neighbor][0] = vertex
      depth[neighbor] = depth[vertex] + 1
      stack[top] = neighbor
      inc top
  for level in 1 ..< MaxLevels:
    for vertex in 0 ..< n:
      ancestors[vertex][level] = ancestors[ancestors[vertex][level - 1]][level - 1]

  var answers: array[MaxQ, int64]
  for query in 0 ..< q:
    let offset = queryStart + 3 * query
    let startValue = input[offset]
    let targetValue = input[offset + 1]
    let indexValue = input[offset + 2]
    if startValue < 0 or startValue >= nValue or targetValue < 0 or
       targetValue >= nValue or indexValue < 0 or indexValue >= nValue: return -1
    let start = int(startValue)
    let target = int(targetValue)
    let index = int(indexValue)
    let common = lowestCommonAncestor(ancestors, depth, start, target)
    let upward = depth[start] - depth[common]
    let pathLength = upward + depth[target] - depth[common]
    if index > pathLength: answers[query] = -1
    elif index <= upward: answers[query] = int64(lift(ancestors, start, index))
    else: answers[query] = int64(lift(ancestors, target, pathLength - index))

  let required = 8 * q
  if output.isNil or capacity < csize_t(required): return -2
  for query in 0 ..< q:
    storeI64Le(output, 8 * query, answers[query])
  int64(required)
