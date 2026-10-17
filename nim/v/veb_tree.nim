const MaxCount = 256
const MaxInputValues = 771
const MaxOutputBytes = 1024
const MaxTreeNodes = 358
const MaxClusters = 16

type VebNode = object
  universe: int
  lowBits: int
  clusterCount: int
  minimum: int
  maximum: int
  summary: int
  clusters: array[MaxClusters, int]

proc initialize(nodes: var array[MaxTreeNodes, VebNode], next: var int, universe: int): int =
  result = next
  inc next
  nodes[result].universe = universe
  nodes[result].lowBits = 0
  nodes[result].clusterCount = 0
  nodes[result].minimum = -1
  nodes[result].maximum = 0
  nodes[result].summary = -1
  if universe > 2:
    var exponent = 0
    var remaining = universe
    while remaining > 1:
      remaining = remaining div 2
      inc exponent
    let lowBits = exponent div 2
    let lowSize = 1 shl lowBits
    let clusterCount = universe div lowSize
    nodes[result].lowBits = lowBits
    nodes[result].clusterCount = clusterCount
    nodes[result].summary = initialize(nodes, next, clusterCount)
    for index in 0 ..< clusterCount:
      nodes[result].clusters[index] = initialize(nodes, next, lowSize)

proc contains(nodes: var array[MaxTreeNodes, VebNode], id, value: int): bool =
  if nodes[id].minimum < 0: return false
  if nodes[id].minimum == value or nodes[id].maximum == value: return true
  if nodes[id].universe == 2: return false
  let lowSize = 1 shl nodes[id].lowBits
  let high = value shr nodes[id].lowBits
  let low = value and (lowSize - 1)
  contains(nodes, nodes[id].clusters[high], low)

proc insert(nodes: var array[MaxTreeNodes, VebNode], id, initialValue: int) =
  if contains(nodes, id, initialValue): return
  if nodes[id].minimum < 0:
    nodes[id].minimum = initialValue
    nodes[id].maximum = initialValue
    return
  var value = initialValue
  if value < nodes[id].minimum:
    swap(value, nodes[id].minimum)
  if nodes[id].universe > 2:
    let lowSize = 1 shl nodes[id].lowBits
    let high = value shr nodes[id].lowBits
    let low = value and (lowSize - 1)
    let cluster = nodes[id].clusters[high]
    if nodes[cluster].minimum < 0:
      insert(nodes, nodes[id].summary, high)
      nodes[cluster].minimum = low
      nodes[cluster].maximum = low
    else:
      insert(nodes, cluster, low)
  if value > nodes[id].maximum: nodes[id].maximum = value

proc successor(nodes: var array[MaxTreeNodes, VebNode], id, value: int): int =
  if nodes[id].minimum < 0: return -1
  if value < nodes[id].minimum: return nodes[id].minimum
  if nodes[id].universe == 2:
    return if value == 0 and nodes[id].maximum == 1: 1 else: -1
  let lowSize = 1 shl nodes[id].lowBits
  let high = value shr nodes[id].lowBits
  let low = value and (lowSize - 1)
  let cluster = nodes[id].clusters[high]
  if nodes[cluster].minimum >= 0 and low < nodes[cluster].maximum:
    let nextLow = successor(nodes, cluster, low)
    if nextLow < 0: return -1
    return high * lowSize + nextLow
  let nextCluster = successor(nodes, nodes[id].summary, high)
  if nextCluster < 0: return -1
  let nextMinimum = nodes[nodes[id].clusters[nextCluster]].minimum
  if nextMinimum < 0: return -1
  nextCluster * lowSize + nextMinimum

proc predecessor(nodes: var array[MaxTreeNodes, VebNode], id, value: int): int =
  if nodes[id].minimum < 0 or value <= nodes[id].minimum: return -1
  if value > nodes[id].maximum: return nodes[id].maximum
  if nodes[id].universe == 2:
    return if value == 1 and nodes[id].minimum == 0: 0 else: -1
  let lowSize = 1 shl nodes[id].lowBits
  let high = value shr nodes[id].lowBits
  let low = value and (lowSize - 1)
  let cluster = nodes[id].clusters[high]
  if nodes[cluster].minimum >= 0 and low > nodes[cluster].minimum:
    let previousLow = predecessor(nodes, cluster, low)
    if previousLow >= 0: return high * lowSize + previousLow
  let previousCluster = predecessor(nodes, nodes[id].summary, high)
  if previousCluster < 0: return nodes[id].minimum
  let previousMaximum = nodes[nodes[id].clusters[previousCluster]].maximum
  if previousMaximum < 0: return -1
  previousCluster * lowSize + previousMaximum

proc veb_tree*(input: ptr UncheckedArray[int64], length: csize_t,
    output: ptr UncheckedArray[uint8], capacity: csize_t): int64
    {.cdecl, exportc: "veb_tree".} =
  if input == nil or length < 3 or length > csize_t(MaxInputValues + 1): return -1
  if input[0] < 2 or input[0] > 256 or input[1] < 0 or input[1] > MaxCount or
      input[2] < 0 or input[2] > MaxCount: return -1
  let requested = int(input[0])
  let insertCount = int(input[1])
  let queryCount = int(input[2])
  if int(length) != 3 + insertCount + 2 * queryCount: return -1
  for index in 0 ..< insertCount:
    if input[3 + index] < 0 or input[3 + index] >= int64(requested): return -1
  for index in 0 ..< queryCount:
    let opcode = input[3 + insertCount + 2 * index]
    let key = input[4 + insertCount + 2 * index]
    if opcode < 0 or opcode > 4 or key < 0 or key >= int64(requested): return -1
  let needed = queryCount * 4
  if needed > MaxOutputBytes: return -1
  if output == nil or capacity < csize_t(needed): return -2

  var rounded = 1
  while rounded < requested: rounded *= 2
  var nodes: array[MaxTreeNodes, VebNode]
  var next = 0
  let root = initialize(nodes, next, rounded)
  for index in 0 ..< insertCount: insert(nodes, root, int(input[3 + index]))
  var resultBytes: array[MaxOutputBytes, uint8]
  for index in 0 ..< queryCount:
    let opcode = int(input[3 + insertCount + 2 * index])
    let key = int(input[4 + insertCount + 2 * index])
    var value = 0
    case opcode
    of 0: value = if contains(nodes, root, key): 1 else: 0
    of 1: value = successor(nodes, root, key)
    of 2: value = predecessor(nodes, root, key)
    of 3: value = nodes[root].minimum
    else: value = if nodes[root].minimum < 0: 0 else: nodes[root].maximum
    let bits = cast[uint32](int32(value))
    resultBytes[4 * index] = uint8(bits and 0xff)
    resultBytes[4 * index + 1] = uint8((bits shr 8) and 0xff)
    resultBytes[4 * index + 2] = uint8((bits shr 16) and 0xff)
    resultBytes[4 * index + 3] = uint8((bits shr 24) and 0xff)
  for index in 0 ..< needed: output[index] = resultBytes[index]
  int64(needed)
