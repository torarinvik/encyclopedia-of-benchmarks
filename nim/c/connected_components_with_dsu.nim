const MaxNodeCount = 256
const MaxEdgeCount = 2047
const MaxInputLength = 2 + 2 * MaxEdgeCount

proc findRoot(parent: var array[MaxNodeCount + 1, int], node: int): int =
  var current = node
  while parent[current] != current:
    parent[current] = parent[parent[current]]
    current = parent[current]
  current

proc connected_components_with_dsu*(input: ptr UncheckedArray[int64], length: csize_t): int64
    {.cdecl, exportc: "connected_components_with_dsu".} =
  if input.isNil or length < 2 or length > MaxInputLength.csize_t: return -1
  if input[0] < 0'i64 or input[0] > MaxNodeCount or input[1] < 0'i64 or input[1] > MaxEdgeCount:
    return -1
  let nodeCount = int(input[0])
  let edgeCount = int(input[1])
  if int(length) != 2 + 2 * edgeCount: return -1

  var parent: array[MaxNodeCount + 1, int]
  var setSize: array[MaxNodeCount + 1, int]
  for node in 1 ..< nodeCount + 1:
    parent[node] = node
    setSize[node] = 1
  var componentCount = nodeCount
  for edge in 0 ..< edgeCount:
    let leftArg = input[2 + 2 * edge]
    let rightArg = input[3 + 2 * edge]
    if leftArg < 1'i64 or leftArg > int64(nodeCount) or
        rightArg < 1'i64 or rightArg > int64(nodeCount): return -1
    var left = findRoot(parent, int(leftArg))
    var right = findRoot(parent, int(rightArg))
    if left == right: continue
    if setSize[left] < setSize[right]: swap(left, right)
    parent[right] = left
    setSize[left] += setSize[right]
    dec componentCount
  int64(componentCount)
