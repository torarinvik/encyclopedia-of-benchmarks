const MaxNodes = 64
const MaxEdges = 94
const MaxInputLength = 4 + MaxNodes + 2 * MaxEdges
const MaxOutputBytes = 128

proc depth_first_search_target_route*(values: ptr UncheckedArray[int64], length: csize_t,
    output: ptr UncheckedArray[uint8], outputCapacity: csize_t): int64
    {.cdecl, exportc: "depth_first_search_target_route".} =
  if values == nil or length < 5 or length > csize_t(MaxInputLength): return -2
  let nodeCountValue = values[0]
  let startLabel = values[1]
  let targetLabel = values[2]
  if nodeCountValue < 1 or nodeCountValue > MaxNodes or startLabel < 0 or startLabel > 255
      or targetLabel < 0 or targetLabel > 255: return -2
  let nodeCount = int(nodeCountValue)
  let edgeCountPosition = 3 + nodeCount
  if edgeCountPosition >= int(length): return -2

  var labels: array[MaxNodes, int64]
  var startIndex = nodeCount
  for index in 0 ..< nodeCount:
    let label = values[3 + index]
    if label < 0 or label > 255: return -2
    for prior in 0 ..< index:
      if labels[prior] == label: return -2
    labels[index] = label
    if label == startLabel: startIndex = index
  if startIndex == nodeCount: return -2

  let edgeCountValue = values[edgeCountPosition]
  if edgeCountValue < 0 or edgeCountValue > MaxEdges: return -2
  let edgeCount = int(edgeCountValue)
  if int(length) != edgeCountPosition + 1 + 2 * edgeCount: return -2

  var adjacency: array[MaxNodes, uint64]
  for edge in 0 ..< edgeCount:
    let leftLabel = values[edgeCountPosition + 1 + 2 * edge]
    let rightLabel = values[edgeCountPosition + 2 + 2 * edge]
    var left = nodeCount
    var right = nodeCount
    for index in 0 ..< nodeCount:
      if labels[index] == leftLabel: left = index
      if labels[index] == rightLabel: right = index
    if left == nodeCount or right == nodeCount: return -2
    adjacency[left] = adjacency[left] or (1'u64 shl right)
    adjacency[right] = adjacency[right] or (1'u64 shl left)

  var stack: array[MaxNodes, int]
  var stackLength = 1
  stack[0] = startIndex
  var route: array[MaxOutputBytes, uint8]
  var routeLength = 0
  while stackLength != 0:
    dec stackLength
    let current = stack[stackLength]
    if routeLength == MaxOutputBytes: return -2
    route[routeLength] = uint8(labels[current])
    inc routeLength
    for neighbor in 0 ..< nodeCount:
      let bit = 1'u64 shl neighbor
      if (adjacency[current] and bit) != 0:
        var pending = 0
        while pending < stackLength and stack[pending] != neighbor: inc pending
        if pending == stackLength:
          stack[stackLength] = neighbor
          inc stackLength
      adjacency[current] = adjacency[current] and not bit
      adjacency[neighbor] = adjacency[neighbor] and not (1'u64 shl current)
    if labels[current] == targetLabel:
      if csize_t(routeLength) > outputCapacity or (routeLength != 0 and output == nil): return -2
      for index in 0 ..< routeLength: output[index] = route[index]
      return int64(routeLength)
  0
