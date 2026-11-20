const
  MaxVertices = 8
  MaxEdges = 16
  MaxNodes = MaxVertices + MaxEdges
  LogLevels = 5
  MaxInputLength = 67

type Edge = object
  fromVertex: int
  toVertex: int
  weight: int64
  originalIndex: int

proc findRoot(parent: var array[MaxVertices, int], start: int): int =
  var root = start
  while parent[root] != root: root = parent[root]
  var vertex = start
  while parent[vertex] != vertex:
    let next = parent[vertex]
    parent[vertex] = root
    vertex = next
  root

proc edgeGreater(left, right: Edge): bool =
  left.weight > right.weight or (left.weight == right.weight and left.originalIndex > right.originalIndex)

proc kruskal_reconstruction_tree_bottleneck*(input: ptr UncheckedArray[int64], length: csize_t): int64
    {.cdecl, exportc: "kruskal_reconstruction_tree_bottleneck".} =
  if input.isNil or length < 3 or length > csize_t(MaxInputLength): return -1
  let nValue = input[0]
  let mValue = input[1]
  let qValue = input[2]
  if nValue < 1 or nValue > int64(MaxVertices) or mValue < 0 or mValue > int64(MaxEdges)
      or qValue < 1 or qValue > 8: return -1
  let n = int(nValue)
  let m = int(mValue)
  let q = int(qValue)
  let queryOffset = 3 + 3 * m
  if length != csize_t(queryOffset + 2 * q): return -1

  var edges: array[MaxEdges, Edge]
  for edgeIndex in 0 ..< m:
    let fromValue = input[3 + 3 * edgeIndex]
    let toValue = input[4 + 3 * edgeIndex]
    let weight = input[5 + 3 * edgeIndex]
    if fromValue < 0 or fromValue >= nValue or toValue < 0 or toValue >= nValue
        or weight < 0 or weight > 1_000_000: return -1
    edges[edgeIndex] = Edge(fromVertex: int(fromValue), toVertex: int(toValue),
      weight: weight, originalIndex: edgeIndex)
  for query in 0 ..< q:
    for side in 0 ..< 2:
      let vertex = input[queryOffset + 2 * query + side]
      if vertex < 0 or vertex >= nValue: return -1

  for index in 1 ..< m:
    let edge = edges[index]
    var position = index
    while position > 0 and edgeGreater(edges[position - 1], edge):
      edges[position] = edges[position - 1]
      dec position
    edges[position] = edge

  var dsuParent: array[MaxVertices, int]
  var dsuSize: array[MaxVertices, int]
  var treeRoot: array[MaxVertices, int]
  for vertex in 0 ..< n:
    dsuParent[vertex] = vertex
    dsuSize[vertex] = 1
    treeRoot[vertex] = vertex

  var treeParent: array[MaxNodes, int]
  var children: array[MaxNodes, array[2, int]]
  var label: array[MaxNodes, int64]
  for node in 0 ..< MaxNodes:
    treeParent[node] = -1
    children[node] = [-1, -1]
  var nodeCount = n
  for edgeIndex in 0 ..< m:
    let edge = edges[edgeIndex]
    var leftRoot = findRoot(dsuParent, edge.fromVertex)
    var rightRoot = findRoot(dsuParent, edge.toVertex)
    if leftRoot == rightRoot: continue
    let mergedNode = nodeCount
    nodeCount += 1
    children[mergedNode] = [treeRoot[leftRoot], treeRoot[rightRoot]]
    label[mergedNode] = edge.weight
    treeParent[treeRoot[leftRoot]] = mergedNode
    treeParent[treeRoot[rightRoot]] = mergedNode
    if dsuSize[leftRoot] < dsuSize[rightRoot]: swap(leftRoot, rightRoot)
    dsuParent[rightRoot] = leftRoot
    dsuSize[leftRoot] += dsuSize[rightRoot]
    treeRoot[leftRoot] = mergedNode

  var depth: array[MaxNodes, int]
  var ancestors: array[LogLevels, array[MaxNodes, int]]
  for root in 0 ..< nodeCount:
    if treeParent[root] >= 0: continue
    ancestors[0][root] = root
    var stack: array[MaxNodes, int]
    var top = 1
    stack[0] = root
    while top > 0:
      dec top
      let node = stack[top]
      for side in 0 ..< 2:
        let child = children[node][side]
        if child < 0: continue
        depth[child] = depth[node] + 1
        ancestors[0][child] = node
        stack[top] = child
        inc top
  for level in 1 ..< LogLevels:
    for node in 0 ..< nodeCount:
      ancestors[level][node] = ancestors[level - 1][ancestors[level - 1][node]]

  var checksum = 0'i64
  for query in 0 ..< q:
    let source = int(input[queryOffset + 2 * query])
    let destination = int(input[queryOffset + 2 * query + 1])
    var answer: int64
    if source == destination:
      answer = 0
    elif findRoot(dsuParent, source) != findRoot(dsuParent, destination):
      answer = -1
    else:
      var left = source
      var right = destination
      if depth[left] < depth[right]: swap(left, right)
      let difference = depth[left] - depth[right]
      for level in 0 ..< LogLevels:
        if (difference and (1 shl level)) != 0: left = ancestors[level][left]
      if left != right:
        for level in countdown(LogLevels - 1, 0):
          if ancestors[level][left] != ancestors[level][right]:
            left = ancestors[level][left]
            right = ancestors[level][right]
        left = ancestors[0][left]
      answer = label[left]
    checksum += int64(query + 1) * (answer + 2)
  checksum
