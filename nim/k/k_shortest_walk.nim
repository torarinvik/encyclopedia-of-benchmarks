const
  MaxVertices = 6
  MaxEdges = 12
  MaxK = 8
  MaxInputLength = 41
  MaxFrontier = 97

proc writeI64(output: ptr UncheckedArray[uint8], offset: int, value: int64) =
  let bits = cast[uint64](value)
  for byte in 0 ..< 8:
    output[offset + byte] = uint8((bits shr (8 * byte)) and 0xff'u64)

proc k_shortest_walk*(input: ptr UncheckedArray[int64], length: csize_t,
    output: ptr UncheckedArray[uint8], outputCapacity: csize_t): int64
    {.cdecl, exportc: "k_shortest_walk".} =
  if input == nil or length < 5 or length > csize_t(MaxInputLength):
    return -1
  let nValue = input[0]
  let mValue = input[1]
  let sourceValue = input[2]
  let targetValue = input[3]
  let kValue = input[4]
  if nValue < 1 or nValue > int64(MaxVertices) or mValue < 0 or mValue > int64(MaxEdges) or
      kValue < 1 or kValue > int64(MaxK) or sourceValue < 0 or sourceValue >= nValue or
      targetValue < 0 or targetValue >= nValue:
    return -1
  let n = int(nValue)
  let m = int(mValue)
  let source = int(sourceValue)
  let target = int(targetValue)
  let k = int(kValue)
  if length != csize_t(5 + 3 * m):
    return -1

  var head: array[MaxVertices, int64]
  var edgeTo, edgeWeight, edgeNext: array[MaxEdges, int64]
  for vertex in 0 ..< n:
    head[vertex] = -1
  for edge in 0 ..< m:
    let u = input[5 + 3 * edge]
    let v = input[6 + 3 * edge]
    let weight = input[7 + 3 * edge]
    if u < 0 or u >= nValue or v < 0 or v >= nValue or weight < 0 or weight > 1000:
      return -1
    edgeTo[edge] = v
    edgeWeight[edge] = weight
    edgeNext[edge] = head[int(u)]
    head[int(u)] = int64(edge)
  if output == nil or outputCapacity < csize_t(8 * k):
    return -2

  var queueDistance, queueVertex, queueOrder: array[MaxFrontier, int64]
  var expanded: array[MaxVertices, int64]
  var answers: array[MaxK, int64]
  var queueCount = 1
  var answerCount = 0
  var nextOrder = 1'i64
  queueDistance[0] = 0
  queueVertex[0] = int64(source)
  queueOrder[0] = 0

  while queueCount > 0 and answerCount < k:
    let distance = queueDistance[0]
    let vertex = int(queueVertex[0])
    for slot in 1 ..< queueCount:
      queueDistance[slot - 1] = queueDistance[slot]
      queueVertex[slot - 1] = queueVertex[slot]
      queueOrder[slot - 1] = queueOrder[slot]
    dec queueCount
    if expanded[vertex] >= int64(k):
      continue
    inc expanded[vertex]
    if vertex == target:
      answers[answerCount] = distance
      inc answerCount
      if answerCount == k:
        break
    var edge = head[vertex]
    while edge >= 0:
      let edgeIndex = int(edge)
      let candidateDistance = distance + edgeWeight[edgeIndex]
      let candidateVertex = edgeTo[edgeIndex]
      let candidateOrder = nextOrder
      inc nextOrder
      var position = queueCount
      while position > 0 and
          (queueDistance[position - 1] > candidateDistance or
           (queueDistance[position - 1] == candidateDistance and queueOrder[position - 1] > candidateOrder)):
        queueDistance[position] = queueDistance[position - 1]
        queueVertex[position] = queueVertex[position - 1]
        queueOrder[position] = queueOrder[position - 1]
        dec position
      queueDistance[position] = candidateDistance
      queueVertex[position] = candidateVertex
      queueOrder[position] = candidateOrder
      inc queueCount
      edge = edgeNext[edgeIndex]
  while answerCount < k:
    answers[answerCount] = -1
    inc answerCount
  for index in 0 ..< k:
    writeI64(output, 8 * index, answers[index])
  int64(8 * k)
