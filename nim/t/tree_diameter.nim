const MaxN = 64
const MaxInputValues = 1 + 3 * (MaxN - 1)
const MaxOutputValues = 2 + MaxN
const MaxEdgeWeight = 1_000_000_000'i64

proc findRoot(parent: var array[MaxN, int], item: int): int =
  var current = item
  while parent[current] != current:
    parent[current] = parent[parent[current]]
    current = parent[current]
  current

proc traverse(n, start: int, adjacent: var array[MaxN, array[MaxN, bool]],
    weight: var array[MaxN, array[MaxN, int64]], distance, pathParent: var array[MaxN, int64]) =
  var stack: array[MaxN, int]
  for vertex in 0 ..< n:
    distance[vertex] = -1
    pathParent[vertex] = -1
  var top = 1
  stack[0] = start
  distance[start] = 0
  while top > 0:
    dec top
    let vertex = stack[top]
    for neighbor in 0 ..< n:
      if not adjacent[vertex][neighbor] or distance[neighbor] >= 0: continue
      distance[neighbor] = distance[vertex] + weight[vertex][neighbor]
      pathParent[neighbor] = int64(vertex)
      stack[top] = neighbor
      inc top

proc farthest(n: int, distance: array[MaxN, int64]): int =
  for vertex in 1 ..< n:
    if distance[vertex] > distance[result] or
       (distance[vertex] == distance[result] and vertex < result): result = vertex

proc storeI64Le(output: ptr UncheckedArray[uint8], offset: int, value: int64) =
  let bits = cast[uint64](value)
  for byte in 0 ..< 8:
    output[offset + byte] = uint8((bits shr (8 * byte)) and 255)

proc tree_diameter*(input: ptr UncheckedArray[int64], length: csize_t,
    output: ptr UncheckedArray[uint8], capacity: csize_t): int64
    {.cdecl, exportc: "tree_diameter".} =
  if input.isNil or length < 1 or length > csize_t(MaxInputValues): return -1
  let nValue = input[0]
  if nValue < 1 or nValue > MaxN: return -1
  let n = int(nValue)
  if length != csize_t(1 + 3 * (n - 1)): return -1

  var adjacent: array[MaxN, array[MaxN, bool]]
  var weight: array[MaxN, array[MaxN, int64]]
  var dsuParent, dsuSize: array[MaxN, int]
  for vertex in 0 ..< n:
    dsuParent[vertex] = vertex
    dsuSize[vertex] = 1
  for edge in 0 ..< (n - 1):
    let offset = 1 + 3 * edge
    let leftValue = input[offset]
    let rightValue = input[offset + 1]
    let edgeWeight = input[offset + 2]
    if leftValue < 0 or leftValue >= nValue or rightValue < 0 or
       rightValue >= nValue or leftValue == rightValue or
       edgeWeight < 1 or edgeWeight > MaxEdgeWeight: return -1
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
    weight[left][right] = edgeWeight
    weight[right][left] = edgeWeight

  var distance: array[MaxN, int64]
  var pathParent: array[MaxN, int64]
  traverse(n, 0, adjacent, weight, distance, pathParent)
  let firstEndpoint = farthest(n, distance)
  traverse(n, firstEndpoint, adjacent, weight, distance, pathParent)
  let secondEndpoint = farthest(n, distance)
  var reversePath: array[MaxN, int]
  var pathLength = 0
  var current = int64(secondEndpoint)
  while current >= 0:
    reversePath[pathLength] = int(current)
    inc pathLength
    if int(current) == firstEndpoint: break
    current = pathParent[int(current)]

  var staged: array[MaxOutputValues, int64]
  var used = 0
  staged[used] = distance[secondEndpoint]
  inc used
  staged[used] = int64(pathLength)
  inc used
  for position in 0 ..< pathLength:
    staged[used] = int64(reversePath[pathLength - 1 - position])
    inc used
  let required = 8 * used
  if output.isNil or capacity < csize_t(required): return -2
  for index in 0 ..< used: storeI64Le(output, 8 * index, staged[index])
  int64(required)
