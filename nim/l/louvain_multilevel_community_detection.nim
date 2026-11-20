const
  MaxVertices = 8
  MaxEdges = 28
  MaxParseableInputLength = 87

proc leastVertex(mask: int): int =
  for vertex in 0 ..< MaxVertices:
    if (mask and (1 shl vertex)) != 0:
      return vertex
  MaxVertices

proc modularityScore(adjacency: array[MaxVertices * MaxVertices, int64];
                      nodeCount: int; labels: array[MaxVertices, int]): int64 =
  var degrees: array[MaxVertices, int64]
  var communityDegrees: array[MaxVertices, int64]
  var totalDegree = 0'i64
  var internalDirectedWeight = 0'i64
  for vertex in 0 ..< nodeCount:
    for other in 0 ..< nodeCount:
      let weight = adjacency[vertex * MaxVertices + other]
      degrees[vertex] += weight
      if labels[vertex] == labels[other]:
        internalDirectedWeight += weight
    totalDegree += degrees[vertex]
    communityDegrees[labels[vertex]] += degrees[vertex]

  var squaredCommunityDegrees = 0'i64
  for community in 0 ..< MaxVertices:
    squaredCommunityDegrees += communityDegrees[community] * communityDegrees[community]
  totalDegree * internalDirectedWeight - squaredCommunityDegrees

proc communityKey(target, nodeCount: int; labels: array[MaxVertices, int];
                  masks: array[MaxVertices, int]): int =
  result = MaxVertices
  for node in 0 ..< nodeCount:
    if labels[node] == target:
      result = min(result, leastVertex(masks[node]))

proc louvain_multilevel_community_detection*(input: ptr UncheckedArray[int64], length: csize_t): int64
    {.cdecl, exportc: "louvain_multilevel_community_detection".} =
  if input == nil or length < csize_t(2) or length > csize_t(MaxParseableInputLength):
    return -1
  let vertexCountValue = input[0]
  let edgeCountValue = input[1]
  if vertexCountValue < 2 or vertexCountValue > int64(MaxVertices) or
      edgeCountValue < 1 or edgeCountValue > int64(MaxEdges):
    return -1
  let vertexCount = int(vertexCountValue)
  let edgeCount = int(edgeCountValue)
  if edgeCount > vertexCount * (vertexCount - 1) div 2 or
      length != csize_t(2 + 3 * edgeCount):
    return -1

  var adjacency: array[MaxVertices * MaxVertices, int64]
  var previousU = -1'i64
  var previousV = -1'i64
  for edge in 0 ..< edgeCount:
    let offset = 2 + 3 * edge
    let uValue = input[offset]
    let vValue = input[offset + 1]
    let weight = input[offset + 2]
    if uValue < 0 or uValue >= vertexCountValue or vValue < 0 or
        vValue >= vertexCountValue or uValue >= vValue or weight < 1 or weight > 7:
      return -1
    if edge > 0 and (uValue < previousU or (uValue == previousU and vValue <= previousV)):
      return -1
    previousU = uValue
    previousV = vValue
    let u = int(uValue)
    let v = int(vValue)
    adjacency[u * MaxVertices + v] = weight
    adjacency[v * MaxVertices + u] = weight

  var masks: array[MaxVertices, int]
  var nodeCount = vertexCount
  for node in 0 ..< nodeCount:
    masks[node] = 1 shl node

  var finalMasks: array[MaxVertices, int]
  var finalCommunityCount = 0
  while true:
    var labels: array[MaxVertices, int]
    for node in 0 ..< nodeCount:
      labels[node] = node

    var anyMoves = false
    while true:
      var sweepMoved = false
      for node in 0 ..< nodeCount:
        let currentScore = modularityScore(adjacency, nodeCount, labels)
        var bestScore = currentScore
        var bestTarget = -1
        var bestTargetKey = MaxVertices
        var seenTargets: array[MaxVertices, bool]
        for other in 0 ..< nodeCount:
          if other == node or adjacency[node * MaxVertices + other] <= 0:
            continue
          let target = labels[other]
          if target == labels[node] or seenTargets[target]:
            continue
          seenTargets[target] = true
          var candidateLabels = labels
          candidateLabels[node] = target
          let candidateScore = modularityScore(adjacency, nodeCount, candidateLabels)
          if candidateScore <= currentScore:
            continue
          let targetKey = communityKey(target, nodeCount, labels, masks)
          if bestTarget < 0 or candidateScore > bestScore or
              (candidateScore == bestScore and targetKey < bestTargetKey):
            bestScore = candidateScore
            bestTarget = target
            bestTargetKey = targetKey
        if bestTarget >= 0:
          labels[node] = bestTarget
          sweepMoved = true
          anyMoves = true
      if not sweepMoved:
        break

    if not anyMoves:
      for node in 0 ..< nodeCount:
        finalMasks[node] = masks[node]
      finalCommunityCount = nodeCount
      break

    var groupLabels: array[MaxVertices, int]
    var groupKeys: array[MaxVertices, int]
    var groupCount = 0
    for node in 0 ..< nodeCount:
      let label = labels[node]
      var found = false
      for group in 0 ..< groupCount:
        if groupLabels[group] == label:
          found = true
          break
      if not found:
        groupLabels[groupCount] = label
        groupKeys[groupCount] = communityKey(label, nodeCount, labels, masks)
        inc groupCount

    for position in 1 ..< groupCount:
      let label = groupLabels[position]
      let key = groupKeys[position]
      var insertion = position
      while insertion > 0 and key < groupKeys[insertion - 1]:
        groupLabels[insertion] = groupLabels[insertion - 1]
        groupKeys[insertion] = groupKeys[insertion - 1]
        dec insertion
      groupLabels[insertion] = label
      groupKeys[insertion] = key

    var labelToGroup: array[MaxVertices, int]
    for label in 0 ..< MaxVertices:
      labelToGroup[label] = -1
    for group in 0 ..< groupCount:
      labelToGroup[groupLabels[group]] = group

    var nextMasks: array[MaxVertices, int]
    var nextAdjacency: array[MaxVertices * MaxVertices, int64]
    for node in 0 ..< nodeCount:
      let group = labelToGroup[labels[node]]
      nextMasks[group] = nextMasks[group] or masks[node]
    for left in 0 ..< nodeCount:
      let leftGroup = labelToGroup[labels[left]]
      for right in 0 ..< nodeCount:
        let rightGroup = labelToGroup[labels[right]]
        nextAdjacency[leftGroup * MaxVertices + rightGroup] +=
          adjacency[left * MaxVertices + right]

    masks = nextMasks
    adjacency = nextAdjacency
    nodeCount = groupCount

  var originalLabels: array[MaxVertices, int]
  for community in 0 ..< finalCommunityCount:
    let label = leastVertex(finalMasks[community])
    for vertex in 0 ..< vertexCount:
      if (finalMasks[community] and (1 shl vertex)) != 0:
        originalLabels[vertex] = label

  var packedResult = int64(finalCommunityCount) shl 24
  for vertex in 0 ..< vertexCount:
    packedResult = packedResult or (int64(originalLabels[vertex]) shl (3 * vertex))
  packedResult
