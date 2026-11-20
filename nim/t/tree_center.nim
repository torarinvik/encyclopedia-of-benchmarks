const MaxN = 64
const MaxInputLength = 1 + 2 * (MaxN - 1)
const MatrixCells = MaxN * MaxN

proc findRoot(parent: var array[MaxN, int], item: int): int =
  var node = item
  while parent[node] != node:
    parent[node] = parent[parent[node]]
    node = parent[node]
  node

proc storeI64Le(output: ptr UncheckedArray[uint8], offset: int, value: int64) =
  let bits = cast[uint64](value)
  for byte in 0 ..< 8:
    output[offset + byte] = uint8((bits shr (8 * byte)) and 255)

proc tree_center*(input: ptr UncheckedArray[int64], length: csize_t,
    output: ptr UncheckedArray[uint8], capacity: csize_t): int64
    {.cdecl, exportc: "tree_center".} =
  if input.isNil or length < 1 or length > csize_t(MaxInputLength): return -1
  let nValue = input[0]
  if nValue < 1 or nValue > MaxN: return -1
  let n = int(nValue)
  if length != csize_t(1 + 2 * (n - 1)): return -1

  var adjacency: array[MatrixCells, int]
  var adjacencyCount, degree: array[MaxN, int]
  var parent, componentSize: array[MaxN, int]
  for vertex in 0 ..< n:
    parent[vertex] = vertex
    componentSize[vertex] = 1
  for edge in 0 ..< (n - 1):
    let offset = 1 + 2 * edge
    let leftValue = input[offset]
    let rightValue = input[offset + 1]
    if leftValue < 0 or leftValue >= nValue or rightValue < 0 or
       rightValue >= nValue or leftValue == rightValue: return -1
    let left = int(leftValue)
    let right = int(rightValue)
    var rootLeft = findRoot(parent, left)
    var rootRight = findRoot(parent, right)
    if rootLeft == rootRight: return -1
    if componentSize[rootLeft] < componentSize[rootRight]: swap(rootLeft, rootRight)
    parent[rootRight] = rootLeft
    componentSize[rootLeft] += componentSize[rootRight]
    adjacency[left * MaxN + adjacencyCount[left]] = right
    inc adjacencyCount[left]
    adjacency[right * MaxN + adjacencyCount[right]] = left
    inc adjacencyCount[right]
    inc degree[left]
    inc degree[right]
  if n > 1 and componentSize[findRoot(parent, 0)] != n: return -1

  var active: array[MaxN, bool]
  var leaves: array[MaxN, int]
  var leafCount = 0
  for vertex in 0 ..< n:
    active[vertex] = true
    if degree[vertex] <= 1:
      leaves[leafCount] = vertex
      inc leafCount
  var remaining = n
  while remaining > 2:
    for index in 0 ..< leafCount: active[leaves[index]] = false
    remaining -= leafCount
    for index in 0 ..< leafCount:
      let leaf = leaves[index]
      for edge in 0 ..< adjacencyCount[leaf]:
        let neighbor = adjacency[leaf * MaxN + edge]
        if active[neighbor]: dec degree[neighbor]
    if remaining <= 2: break
    leafCount = 0
    for vertex in 0 ..< n:
      if active[vertex] and degree[vertex] == 1:
        leaves[leafCount] = vertex
        inc leafCount

  var centers: array[2, int64]
  var centerCount = 0
  for vertex in 0 ..< n:
    if active[vertex]:
      centers[centerCount] = int64(vertex)
      inc centerCount
  let required = 8 * centerCount
  if output.isNil or capacity < csize_t(required): return -2
  for index in 0 ..< centerCount:
    storeI64Le(output, 8 * index, centers[index])
  int64(required)
