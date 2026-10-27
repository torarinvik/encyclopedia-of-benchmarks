const MaxN = 6
const MaxNodes = 10
const MaxEdges = 9
const MaxOutputBytes = 152

proc storeI64Le(output: ptr UncheckedArray[uint8], offset: int, value: int64) =
  let bits = cast[uint64](value)
  for byte in 0 ..< 8: output[offset + byte] = uint8((bits shr (8 * byte)) and 255)

proc treeDistance(nodeCount, edgeCount: int, edgeU, edgeV: array[MaxEdges, int],
                  edgeW: array[MaxEdges, int64], start, target: int,
                  distance: var array[MaxNodes, int64]): bool =
  var parent: array[MaxNodes, int]
  var queue: array[MaxNodes, int]
  for i in 0 ..< nodeCount: parent[i] = -1
  var head = 0
  var tail = 0
  parent[start] = start
  distance[start] = 0
  queue[tail] = start
  inc tail
  while head < tail:
    let node = queue[head]
    inc head
    if node == target: return true
    for e in 0 ..< edgeCount:
      var neighbor = -1
      if edgeU[e] == node: neighbor = edgeV[e]
      elif edgeV[e] == node: neighbor = edgeU[e]
      if neighbor < 0 or parent[neighbor] != -1: continue
      parent[neighbor] = node
      distance[neighbor] = distance[node] + edgeW[e]
      queue[tail] = neighbor
      inc tail
  false

proc phylogenetic_tree_from_distance_matrix*(input: ptr UncheckedArray[int64], length: csize_t,
    output: ptr UncheckedArray[uint8], capacity: csize_t): int64
    {.cdecl, exportc: "phylogenetic_tree_from_distance_matrix".} =
  if input.isNil or length < csize_t(1) or length > csize_t(MaxN * MaxN + 2): return -1
  let rawN = input[0]
  if rawN < 2 or rawN > MaxN or length != csize_t(1 + rawN * rawN): return -1
  let n = int(rawN)
  var d: array[MaxN * MaxN, int64]
  for i in 0 ..< n:
    for j in 0 ..< n:
      let value = input[1 + i * n + j]
      if (i == j and value != 0) or (i != j and (value < 1 or value > 32)): return -1
      d[i * MaxN + j] = value
  for i in 0 ..< n:
    for j in i + 1 ..< n:
      if d[i * MaxN + j] != d[j * MaxN + i]: return -1

  var edgeU, edgeV: array[MaxEdges, int]
  var edgeW: array[MaxEdges, int64]
  var edgeCount = 1
  edgeU[0] = 0; edgeV[0] = 1; edgeW[0] = 2 * d[1]
  var labelNode: array[MaxN, int]
  labelNode[0] = 0; labelNode[1] = 1
  var labelMask: array[MaxNodes, uint32]
  labelMask[0] = 1; labelMask[1] = 2
  var nodeCount = 2
  var additive = true

  for leaf in 2 ..< n:
    if not additive: break
    var limb2 = high(int64)
    for i in 0 ..< leaf:
      for j in i + 1 ..< leaf:
        limb2 = min(limb2, d[i * MaxN + leaf] + d[j * MaxN + leaf] - d[i * MaxN + j])
    if limb2 < 0: additive = false; break
    var witnessI = -1
    var witnessJ = -1
    var attachDistance = 0'i64
    for i in 0 ..< leaf:
      for j in i + 1 ..< leaf:
        let fromI = 2 * d[i * MaxN + leaf] - limb2
        let fromJ = 2 * d[j * MaxN + leaf] - limb2
        if fromI >= 0 and fromJ >= 0 and 2 * d[i * MaxN + j] == fromI + fromJ:
          witnessI = i; witnessJ = j; attachDistance = fromI
          break
      if witnessI >= 0: break
    if witnessI < 0: additive = false; break

    let start = labelNode[witnessI]
    let target = labelNode[witnessJ]
    var parentNode: array[MaxNodes, int]
    var parentEdge: array[MaxNodes, int]
    for i in 0 ..< nodeCount: parentNode[i] = -1; parentEdge[i] = -1
    var queue: array[MaxNodes, int]
    var head = 0; var tail = 0
    parentNode[start] = start; queue[tail] = start; inc tail
    while head < tail and parentNode[target] < 0:
      let node = queue[head]; inc head
      for e in 0 ..< edgeCount:
        var neighbor = -1
        if edgeU[e] == node: neighbor = edgeV[e]
        elif edgeV[e] == node: neighbor = edgeU[e]
        if neighbor < 0 or parentNode[neighbor] >= 0: continue
        parentNode[neighbor] = node; parentEdge[neighbor] = e
        queue[tail] = neighbor; inc tail
    if parentNode[target] < 0: additive = false; break
    var reverseNodes: array[MaxNodes, int]
    var reverseEdges: array[MaxNodes, int]
    var pathNodeCount = 1; var pathEdgeCount = 0; var current = target
    reverseNodes[0] = target
    while current != start:
      reverseEdges[pathEdgeCount] = parentEdge[current]; inc pathEdgeCount
      current = parentNode[current]
      reverseNodes[pathNodeCount] = current; inc pathNodeCount
    var pathNodes, pathEdges: array[MaxNodes, int]
    for i in 0 ..< pathNodeCount: pathNodes[i] = reverseNodes[pathNodeCount - 1 - i]
    for i in 0 ..< pathEdgeCount: pathEdges[i] = reverseEdges[pathEdgeCount - 1 - i]
    var elapsed = 0'i64
    var attachNode = -1
    var splitEdge = -1; var splitLeft = -1; var splitRight = -1; var splitFromLeft = 0'i64
    for step in 0 ..< pathNodeCount:
      if attachDistance == elapsed: attachNode = pathNodes[step]; break
      if step == pathEdgeCount: break
      let e = pathEdges[step]
      let weight = edgeW[e]
      if elapsed < attachDistance and attachDistance < elapsed + weight:
        splitEdge = e; splitLeft = pathNodes[step]; splitRight = pathNodes[step + 1]
        splitFromLeft = attachDistance - elapsed
        break
      elapsed += weight
    if attachNode < 0 and splitEdge < 0: additive = false; break
    if splitEdge >= 0:
      if nodeCount >= MaxNodes or edgeCount >= MaxEdges: additive = false; break
      let internal = nodeCount; inc nodeCount
      let whole = edgeW[splitEdge]
      edgeU[splitEdge] = splitLeft; edgeV[splitEdge] = internal; edgeW[splitEdge] = splitFromLeft
      edgeU[edgeCount] = internal; edgeV[edgeCount] = splitRight
      edgeW[edgeCount] = whole - splitFromLeft; inc edgeCount
      attachNode = internal
    if limb2 == 0:
      if labelMask[attachNode] != 0: additive = false; break
      labelNode[leaf] = attachNode
      labelMask[attachNode] = labelMask[attachNode] or (1'u32 shl leaf)
    else:
      if nodeCount >= MaxNodes or edgeCount >= MaxEdges: additive = false; break
      let newLeaf = nodeCount; inc nodeCount
      labelNode[leaf] = newLeaf
      labelMask[newLeaf] = 1'u32 shl leaf
      edgeU[edgeCount] = attachNode; edgeV[edgeCount] = newLeaf; edgeW[edgeCount] = limb2; inc edgeCount

  if not additive: return 0
  var distances: array[MaxNodes, int64]
  for i in 0 ..< n:
    for j in i + 1 ..< n:
      if not treeDistance(nodeCount, edgeCount, edgeU, edgeV, edgeW, labelNode[i], labelNode[j], distances) or
          distances[labelNode[j]] != 2 * d[i * MaxN + j]: return 0
  let fullMask = (1'u32 shl n) - 1
  var masks: array[MaxEdges, int64]
  var weights: array[MaxEdges, int64]
  for e in 0 ..< edgeCount:
    var seen = 1'u32 shl edgeU[e]
    var queue: array[MaxNodes, int]
    var head = 0; var tail = 0; queue[tail] = edgeU[e]; inc tail
    var mask = 0'u32
    while head < tail:
      let node = queue[head]; inc head; mask = mask or labelMask[node]
      for other in 0 ..< edgeCount:
        if other == e: continue
        var neighbor = -1
        if edgeU[other] == node: neighbor = edgeV[other]
        elif edgeV[other] == node: neighbor = edgeU[other]
        if neighbor < 0 or (seen and (1'u32 shl neighbor)) != 0: continue
        seen = seen or (1'u32 shl neighbor); queue[tail] = neighbor; inc tail
    if (mask and 1) == 0: mask = fullMask xor mask
    masks[e] = int64(mask); weights[e] = edgeW[e]
  for i in 1 ..< edgeCount:
    let mask = masks[i]; let weight = weights[i]
    var j = i
    while j > 0 and (masks[j - 1] > mask or (masks[j - 1] == mask and weights[j - 1] > weight)):
      masks[j] = masks[j - 1]; weights[j] = weights[j - 1]; dec j
    masks[j] = mask; weights[j] = weight
  let outputBytes = 8 * (1 + 2 * edgeCount)
  if output.isNil or capacity < csize_t(outputBytes): return -2
  var staged: array[MaxOutputBytes, uint8]
  storeI64Le(addr staged[0], 0, int64(edgeCount))
  for i in 0 ..< edgeCount:
    storeI64Le(addr staged[0], 8 * (1 + 2 * i), masks[i])
    storeI64Le(addr staged[0], 8 * (2 + 2 * i), weights[i])
  for byte in 0 ..< outputBytes: output[byte] = staged[byte]
  int64(outputBytes)
