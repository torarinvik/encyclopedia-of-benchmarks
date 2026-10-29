const
  MaxTrees = 16
  MaxTreeVertices = 32
  MaxTotalVertices = 128
  MaxInputLength = 1 + 2 * MaxTrees * MaxTreeVertices

type TreeSignature = object
  childCount: int
  childTypes: array[MaxTreeVertices, int]

proc internSignature(signatures: var array[MaxTotalVertices, TreeSignature],
                     signatureCount: var int, children: array[MaxTreeVertices, int],
                     childCount: int): int =
  for signature in 0 ..< signatureCount:
    if signatures[signature].childCount != childCount:
      continue
    var index = 0
    while index < childCount and signatures[signature].childTypes[index] == children[index]:
      inc index
    if index == childCount:
      return signature
  if signatureCount >= MaxTotalVertices:
    return MaxTotalVertices
  result = signatureCount
  signatures[result].childCount = childCount
  for index in 0 ..< childCount:
    signatures[result].childTypes[index] = children[index]
  inc signatureCount

proc canonicalRootType(adjacency: array[MaxTreeVertices, uint32], n, root: int,
                       signatures: var array[MaxTotalVertices, TreeSignature],
                       signatureCount: var int): int =
  var parent: array[MaxTreeVertices, int]
  var order: array[MaxTreeVertices, int]
  var stack: array[MaxTreeVertices, int]
  var nodeType: array[MaxTreeVertices, int]
  var visited: array[MaxTreeVertices, bool]
  for vertex in 0 ..< n:
    parent[vertex] = MaxTreeVertices
  parent[root] = root
  visited[root] = true
  var stackSize = 1
  var orderSize = 0
  stack[0] = root
  while stackSize > 0:
    dec stackSize
    let vertex = stack[stackSize]
    order[orderSize] = vertex
    inc orderSize
    for neighbor in 0 ..< n:
      let bit = 1'u32 shl neighbor
      if (adjacency[vertex] and bit) == 0 or neighbor == parent[vertex]:
        continue
      if visited[neighbor]:
        return -1
      visited[neighbor] = true
      parent[neighbor] = vertex
      stack[stackSize] = neighbor
      inc stackSize
  if orderSize != n:
    return -1

  var reverse = orderSize
  while reverse > 0:
    dec reverse
    let vertex = order[reverse]
    var children: array[MaxTreeVertices, int]
    var childCount = 0
    for candidate in 0 ..< n:
      if candidate != vertex and parent[candidate] == vertex:
        children[childCount] = nodeType[candidate]
        inc childCount
    for index in 1 ..< childCount:
      let value = children[index]
      var place = index
      while place > 0 and children[place - 1] > value:
        children[place] = children[place - 1]
        dec place
      children[place] = value
    nodeType[vertex] = internSignature(signatures, signatureCount, children, childCount)
    if nodeType[vertex] >= MaxTotalVertices:
      return -1
  nodeType[root]

proc rooted_tree_isomorphism_classification*(values: ptr UncheckedArray[int64], length: csize_t,
    output: ptr UncheckedArray[uint8], outputCapacity: csize_t): int64
    {.cdecl, exportc: "rooted_tree_isomorphism_classification".} =
  if values == nil or length < 1 or length > csize_t(MaxInputLength):
    return -1
  if values[0] < 1 or values[0] > int64(MaxTrees):
    return -1
  let treeCount = int(values[0])
  var signatures: array[MaxTotalVertices, TreeSignature]
  var signatureCount = 0
  var rootTypes: array[MaxTrees, int]
  var labels: array[MaxTrees, uint8]
  var position = 1
  var totalVertices = 0
  var classCount = 0

  for tree in 0 ..< treeCount:
    if position + 2 > int(length):
      return -1
    let nValue = values[position]
    let rootValue = values[position + 1]
    position += 2
    if nValue < 1 or nValue > int64(MaxTreeVertices) or rootValue < 0 or rootValue >= nValue:
      return -1
    let n = int(nValue)
    totalVertices += n
    if totalVertices > MaxTotalVertices:
      return -1
    let edgeCount = n - 1
    if 2 * edgeCount > int(length) - position:
      return -1

    var adjacency: array[MaxTreeVertices, uint32]
    for _ in 0 ..< edgeCount:
      let leftValue = values[position]
      let rightValue = values[position + 1]
      position += 2
      if leftValue < 0 or rightValue < 0 or leftValue >= nValue or rightValue >= nValue or leftValue == rightValue:
        return -1
      let left = int(leftValue)
      let right = int(rightValue)
      let leftBit = 1'u32 shl left
      let rightBit = 1'u32 shl right
      if (adjacency[left] and rightBit) != 0:
        return -1
      adjacency[left] = adjacency[left] or rightBit
      adjacency[right] = adjacency[right] or leftBit

    let rootType = canonicalRootType(adjacency, n, int(rootValue), signatures, signatureCount)
    if rootType < 0:
      return -1
    rootTypes[tree] = rootType
    var prior = 0
    while prior < tree and rootTypes[prior] != rootType:
      inc prior
    if prior < tree:
      labels[tree] = labels[prior]
    else:
      labels[tree] = uint8(classCount)
      inc classCount

  if position != int(length):
    return -1
  if output == nil or outputCapacity < csize_t(treeCount):
    return -2
  for tree in 0 ..< treeCount:
    output[tree] = labels[tree]
  int64(treeCount)
