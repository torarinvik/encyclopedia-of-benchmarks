const MaxEdgeCount = 64
const MaxVertexId = 63'i64
const MaxNodeCount = 128
const MaxInputLength = 1 + 2 * MaxEdgeCount

proc findLastNode(label: int64, labels: ptr UncheckedArray[int64], nodeCount: int): int =
  result = MaxNodeCount
  for node in 0 ..< nodeCount:
    if labels[node] == label: result = node

proc visit(current, edgeCount: int, edgeStarts, edgeEnds: ptr UncheckedArray[int],
    visited: ptr UncheckedArray[bool]) =
  visited[current] = true
  for edge in 0 ..< edgeCount:
    let destination = edgeEnds[edge]
    if edgeStarts[edge] == current and not visited[destination]:
      visit(destination, edgeCount, edgeStarts, edgeEnds, visited)

proc directed_dfs_forest_count*(input: ptr UncheckedArray[int64], length: csize_t): int64
    {.cdecl, exportc: "directed_dfs_forest_count".} =
  if input == nil or length < 1 or length > csize_t(MaxInputLength + 1): return -1
  let edgeCountValue = input[0]
  if edgeCountValue < 0 or edgeCountValue > MaxEdgeCount: return -1
  let edgeCount = int(edgeCountValue)
  if length != csize_t(1 + 2 * edgeCount): return -1

  var labels: array[MaxNodeCount, int64]
  var edgeStarts, edgeEnds: array[MaxEdgeCount, int]
  var nodeCount = 0
  for edge in 0 ..< edgeCount:
    let startLabel = input[1 + 2 * edge]
    let endLabel = input[2 + 2 * edge]
    if startLabel < 0 or startLabel > MaxVertexId or endLabel < 0 or endLabel > MaxVertexId:
      return -1

    var start = findLastNode(startLabel, addr labels[0], nodeCount)
    var ending: int
    if startLabel == endLabel:
      if start == MaxNodeCount:
        start = nodeCount
        labels[nodeCount] = startLabel
        inc nodeCount
      ending = nodeCount
      labels[nodeCount] = endLabel
      inc nodeCount
    else:
      ending = findLastNode(endLabel, addr labels[0], nodeCount)
      if start == MaxNodeCount:
        start = nodeCount
        labels[nodeCount] = startLabel
        inc nodeCount
      if ending == MaxNodeCount:
        ending = nodeCount
        labels[nodeCount] = endLabel
        inc nodeCount
    edgeStarts[edge] = start
    edgeEnds[edge] = ending

  var marked: array[MaxNodeCount, bool]
  var roots = 0'i64
  for root in 0 ..< nodeCount:
    if marked[root]: continue
    var visited: array[MaxNodeCount, bool]
    visit(root, edgeCount, addr edgeStarts[0], addr edgeEnds[0], addr visited[0])
    for node in 0 ..< nodeCount:
      if visited[node]: marked[node] = true
    inc roots
  roots
