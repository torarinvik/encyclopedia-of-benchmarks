const MaxNodeCount = 256
const MaxQueryCount = 1024
const MaxAdjacencyCount = 2 * (MaxNodeCount - 1)
const MaxQueryAdjacencyCount = 2 * MaxQueryCount

proc findRoot(parent: var array[MaxNodeCount, int], node: int): int =
  var root = node
  while parent[root] != root: root = parent[root]
  var current = node
  while parent[current] != current:
    let next = parent[current]
    parent[current] = root
    current = next
  root

proc unite(parent: var array[MaxNodeCount, int], rank: var array[MaxNodeCount, int],
           left, right: int) =
  let leftRoot = findRoot(parent, left)
  let rightRoot = findRoot(parent, right)
  if leftRoot == rightRoot: return
  if rank[leftRoot] < rank[rightRoot]: parent[leftRoot] = rightRoot
  elif rank[leftRoot] > rank[rightRoot]: parent[rightRoot] = leftRoot
  else:
    parent[rightRoot] = leftRoot
    inc rank[leftRoot]

proc lowest_common_ancestor_tarjan*(input: ptr UncheckedArray[int64], length: csize_t,
    output: ptr UncheckedArray[uint8], outputCapacity: csize_t): int64
    {.cdecl, exportc: "lowest_common_ancestor_tarjan".} =
  if input.isNil or length < 4 or input[0] < 1'i64 or input[0] > MaxNodeCount: return -1
  let nodeCount = int(input[0])
  if input[1] < 0'i64 or input[1] >= int64(nodeCount) or input[2] != int64(nodeCount - 1) or
      input[3] < 0'i64 or input[3] > MaxQueryCount: return -1
  let root = int(input[1])
  let edgeCount = int(input[2])
  let queryCount = int(input[3])
  if int(length) != 4 + 2 * edgeCount + 2 * queryCount: return -1

  var validationParent: array[MaxNodeCount, int]
  var dsuParent: array[MaxNodeCount, int]
  var ancestor: array[MaxNodeCount, int]
  var validationRank: array[MaxNodeCount, int]
  var dsuRank: array[MaxNodeCount, int]
  var edgeHead: array[MaxNodeCount, int]
  var edgeTo: array[MaxAdjacencyCount, int]
  var edgeNext: array[MaxAdjacencyCount, int]
  var queryHead: array[MaxNodeCount, int]
  var queryTo: array[MaxQueryAdjacencyCount, int]
  var queryNext: array[MaxQueryAdjacencyCount, int]
  var queryId: array[MaxQueryAdjacencyCount, int]
  var answers: array[MaxQueryCount, int]
  var treeParent: array[MaxNodeCount, int]
  var cursor: array[MaxNodeCount, int]
  var visited: array[MaxNodeCount, bool]
  var finished: array[MaxNodeCount, bool]
  var stack: array[MaxNodeCount, int]
  for node in 0 ..< nodeCount:
    validationParent[node] = node
    dsuParent[node] = node
    ancestor[node] = node
    edgeHead[node] = -1
    queryHead[node] = -1
    treeParent[node] = -1

  for edge in 0 ..< edgeCount:
    let leftArg = input[4 + 2 * edge]
    let rightArg = input[5 + 2 * edge]
    if leftArg < 0'i64 or rightArg < 0'i64 or leftArg >= int64(nodeCount) or
        rightArg >= int64(nodeCount) or leftArg == rightArg: return -1
    let left = int(leftArg)
    let right = int(rightArg)
    if findRoot(validationParent, left) == findRoot(validationParent, right): return -1
    unite(validationParent, validationRank, left, right)
    let forward = 2 * edge
    let reverse = forward + 1
    edgeTo[forward] = right
    edgeNext[forward] = edgeHead[left]
    edgeHead[left] = forward
    edgeTo[reverse] = left
    edgeNext[reverse] = edgeHead[right]
    edgeHead[right] = reverse
  let rootComponent = findRoot(validationParent, root)
  for node in 0 ..< nodeCount:
    if findRoot(validationParent, node) != rootComponent: return -1

  for query in 0 ..< queryCount:
    let leftArg = input[4 + 2 * edgeCount + 2 * query]
    let rightArg = input[5 + 2 * edgeCount + 2 * query]
    if leftArg < 0'i64 or rightArg < 0'i64 or leftArg >= int64(nodeCount) or
        rightArg >= int64(nodeCount): return -1
    let left = int(leftArg)
    let right = int(rightArg)
    let first = 2 * query
    let second = first + 1
    queryTo[first] = right
    queryId[first] = query
    queryNext[first] = queryHead[left]
    queryHead[left] = first
    queryTo[second] = left
    queryId[second] = query
    queryNext[second] = queryHead[right]
    queryHead[right] = second
  if queryCount > int(outputCapacity) or (queryCount != 0 and output.isNil): return -2

  var top = 1
  stack[0] = root
  visited[root] = true
  cursor[root] = edgeHead[root]
  while top > 0:
    let node = stack[top - 1]
    let edge = cursor[node]
    if edge >= 0:
      cursor[node] = edgeNext[edge]
      let child = edgeTo[edge]
      if child == treeParent[node]: continue
      if visited[child]: return -1
      visited[child] = true
      treeParent[child] = node
      cursor[child] = edgeHead[child]
      stack[top] = child
      inc top
      continue
    finished[node] = true
    var item = queryHead[node]
    while item >= 0:
      let other = queryTo[item]
      if finished[other]: answers[queryId[item]] = ancestor[findRoot(dsuParent, other)]
      item = queryNext[item]
    dec top
    if treeParent[node] >= 0:
      let parent = treeParent[node]
      unite(dsuParent, dsuRank, parent, node)
      let component = findRoot(dsuParent, parent)
      ancestor[component] = parent

  for query in 0 ..< queryCount: output[query] = uint8(answers[query])
  int64(queryCount)
