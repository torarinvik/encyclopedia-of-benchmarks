const MaxNodes = 10
const MaxEdges = 100
const MaxSignatureLength = 4
const MaxLabel = 7

proc searchLeg(values: ptr UncheckedArray[int64], edgeCount, labelsStart, signatureStart,
    signatureLength, node, signatureIndex: int, visited: var uint16): bool =
  let bit = 1'u16 shl node
  if (visited and bit) != 0: return false
  visited = visited or bit
  let targetLabel = values[signatureStart + signatureIndex]

  for edge in 0 ..< edgeCount:
    if int(values[3 + 2 * edge]) != node: continue
    let target = int(values[4 + 2 * edge])
    if values[labelsStart + target] != targetLabel: continue
    if signatureIndex + 1 == signatureLength: return true
    var nextVisited = 0'u16
    if searchLeg(values, edgeCount, labelsStart, signatureStart, signatureLength,
        target, signatureIndex + 1, nextVisited): return true

  for edge in 0 ..< edgeCount:
    if int(values[3 + 2 * edge]) != node: continue
    let target = int(values[4 + 2 * edge])
    if searchLeg(values, edgeCount, labelsStart, signatureStart, signatureLength,
        target, signatureIndex, visited): return true
  false

proc doe_pathfinder_signature_search*(values: ptr UncheckedArray[int64], length: csize_t): int64
    {.cdecl, exportc: "doe_pathfinder_signature_search".} =
  if values == nil or length < 3 or values[0] < 1 or values[0] > MaxNodes or
      values[1] < 0 or values[1] > MaxEdges or values[2] < 2 or
      values[2] > MaxSignatureLength: return -2
  let nodeCount = int(values[0])
  let edgeCount = int(values[1])
  let signatureLength = int(values[2])
  if edgeCount > nodeCount * nodeCount or
      length != csize_t(3 + 2 * edgeCount + nodeCount + signatureLength): return -2

  for edge in 0 ..< edgeCount:
    let fromNode = values[3 + 2 * edge]
    let toNode = values[4 + 2 * edge]
    if fromNode < 0 or fromNode >= int64(nodeCount) or toNode < 0 or toNode >= int64(nodeCount):
      return -2
    for previous in 0 ..< edge:
      if values[3 + 2 * previous] == fromNode and values[4 + 2 * previous] == toNode:
        return -2
  let labelsStart = 3 + 2 * edgeCount
  let signatureStart = labelsStart + nodeCount
  for node in 0 ..< nodeCount:
    if values[labelsStart + node] < -1 or values[labelsStart + node] > MaxLabel: return -2
  for index in 0 ..< signatureLength:
    if values[signatureStart + index] < 0 or values[signatureStart + index] > MaxLabel: return -2

  let firstLabel = values[signatureStart]
  for node in 0 ..< nodeCount:
    if values[labelsStart + node] == firstLabel:
      var visited = 0'u16
      if searchLeg(values, edgeCount, labelsStart, signatureStart, signatureLength,
          node, 1, visited): return 1
  0
