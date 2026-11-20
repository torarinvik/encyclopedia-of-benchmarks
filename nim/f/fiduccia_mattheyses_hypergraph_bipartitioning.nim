const
  MaxVertices = 8
  MaxNets = 12
  MaxParseableInputLength = 112

proc countBits(valueInput: int): int =
  var value = valueInput
  while value != 0:
    result += (value and 1)
    value = value shr 1

proc cutSize(netMasks: array[MaxNets, int]; netSizes: array[MaxNets, int];
             netCount, partition: int): int =
  for edge in 0 ..< netCount:
    let inA = countBits(netMasks[edge] and partition)
    if inA > 0 and inA < netSizes[edge]:
      inc result

proc moveGain(vertex, partition, netCount: int;
              netMasks: array[MaxNets, int]; netSizes: array[MaxNets, int]): int =
  let vertexBit = 1 shl vertex
  let isInA = (partition and vertexBit) != 0
  for edge in 0 ..< netCount:
    if (netMasks[edge] and vertexBit) != 0:
      let beforeA = countBits(netMasks[edge] and partition)
      let afterA = if isInA: beforeA - 1 else: beforeA + 1
      let beforeCut = beforeA > 0 and beforeA < netSizes[edge]
      let afterCut = afterA > 0 and afterA < netSizes[edge]
      result += int(beforeCut) - int(afterCut)

proc fiduccia_mattheyses_hypergraph_bipartitioning*(input: ptr UncheckedArray[int64], length: csize_t): int64
    {.cdecl, exportc: "fiduccia_mattheyses_hypergraph_bipartitioning".} =
  if input == nil or length < csize_t(3) or length > csize_t(MaxParseableInputLength):
    return -1
  let vertexCountValue = input[0]
  let netCountValue = input[1]
  let partitionValue = input[2]
  if vertexCountValue < 4 or vertexCountValue > int64(MaxVertices) or
      vertexCountValue mod 2 != 0 or netCountValue < 0 or netCountValue > int64(MaxNets):
    return -1
  let vertexCount = int(vertexCountValue)
  let netCount = int(netCountValue)
  if partitionValue < 0 or partitionValue >= int64(1 shl vertexCount):
    return -1
  let initialPartition = int(partitionValue)
  if countBits(initialPartition) != vertexCount div 2:
    return -1

  var netMasks: array[MaxNets, int]
  var netSizes: array[MaxNets, int]
  var offset = 3
  for edge in 0 ..< netCount:
    if offset >= int(length):
      return -1
    let degreeValue = input[offset]
    if degreeValue < 2 or degreeValue > vertexCountValue:
      return -1
    let degree = int(degreeValue)
    if offset + 1 + degree > int(length):
      return -1
    var netMask = 0
    var previousVertex = -1
    for item in 0 ..< degree:
      let vertexValue = input[offset + 1 + item]
      if vertexValue < 0 or vertexValue >= vertexCountValue:
        return -1
      let vertex = int(vertexValue)
      if vertex <= previousVertex:
        return -1
      previousVertex = vertex
      netMask = netMask or (1 shl vertex)
    netMasks[edge] = netMask
    netSizes[edge] = degree
    offset += 1 + degree
  if offset != int(length):
    return -1

  var partition = initialPartition
  var currentCut = cutSize(netMasks, netSizes, netCount, partition)
  for pass in 0 .. netCount:
    let passStartCut = currentCut
    var workingPartition = partition
    var workingASize = countBits(workingPartition)
    var workingCut = currentCut
    var bestPartition = partition
    var bestCut = currentCut
    var locked: array[MaxVertices, bool]

    for _ in 0 ..< vertexCount:
      var bucketCounts: array[2 * MaxNets + 1, int]
      var buckets: array[2 * MaxNets + 1, array[MaxVertices, int]]
      for vertex in 0 ..< vertexCount:
        if locked[vertex]:
          continue
        let inA = (workingPartition and (1 shl vertex)) != 0
        let resultingASize = if inA: workingASize - 1 else: workingASize + 1
        if resultingASize < vertexCount div 2 - 1 or
            resultingASize > vertexCount div 2 + 1:
          continue
        let gain = moveGain(vertex, workingPartition, netCount, netMasks, netSizes)
        let bucket = gain + netCount
        buckets[bucket][bucketCounts[bucket]] = vertex
        inc bucketCounts[bucket]

      var selectedVertex = -1
      var selectedBalance = high(int)
      for bucket in countdown(2 * netCount, 0):
        if bucketCounts[bucket] == 0:
          continue
        for position in 0 ..< bucketCounts[bucket]:
          let vertex = buckets[bucket][position]
          let inA = (workingPartition and (1 shl vertex)) != 0
          let resultingASize = if inA: workingASize - 1 else: workingASize + 1
          let balance = abs(2 * resultingASize - vertexCount)
          if selectedVertex < 0 or balance < selectedBalance or
              (balance == selectedBalance and vertex < selectedVertex):
            selectedVertex = vertex
            selectedBalance = balance
        if selectedVertex >= 0:
          break
      if selectedVertex < 0:
        break

      locked[selectedVertex] = true
      workingPartition = workingPartition xor (1 shl selectedVertex)
      if (workingPartition and (1 shl selectedVertex)) != 0:
        inc workingASize
      else:
        dec workingASize
      workingCut = cutSize(netMasks, netSizes, netCount, workingPartition)
      if workingCut < bestCut:
        bestCut = workingCut
        bestPartition = workingPartition

    if bestCut < passStartCut:
      partition = bestPartition
      currentCut = bestCut
    else:
      break

  (int64(currentCut) shl 8) or int64(partition)
