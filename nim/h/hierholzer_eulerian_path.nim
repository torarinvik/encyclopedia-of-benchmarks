const MaxVertices = 16
const MaxEdges = 48
const MaxInputLength = 2 + 2 * MaxEdges
const MaxRoute = MaxEdges + 1

proc writeI64Le(output: ptr UncheckedArray[uint8], offset: int, value: int64) =
  var bits = cast[uint64](value)
  for byte in 0 ..< 8:
    output[offset + byte] = uint8(bits and 255'u64)
    bits = bits shr 8

proc hierholzer_eulerian_path*(input: ptr UncheckedArray[int64], length: csize_t,
    output: ptr UncheckedArray[uint8], capacity: csize_t): int64
    {.cdecl, exportc: "hierholzer_eulerian_path".} =
  if input.isNil or length < 2 or length > csize_t(MaxInputLength): return -1
  let vertexCountValue = input[0]
  let edgeCountValue = input[1]
  if vertexCountValue < 0 or vertexCountValue > MaxVertices or
      edgeCountValue < 0 or edgeCountValue > MaxEdges: return -1
  let vertexCount = int(vertexCountValue)
  let edgeCount = int(edgeCountValue)
  if length != csize_t(2 + 2 * edgeCount): return -1

  var adjacency: array[MaxVertices, array[MaxEdges, int]]
  var inDegree: array[MaxVertices, int]
  var outDegree: array[MaxVertices, int]
  for edge in 0 ..< edgeCount:
    let sourceValue = input[2 + 2 * edge]
    let destinationValue = input[3 + 2 * edge]
    if sourceValue < 0 or sourceValue >= vertexCountValue or
        destinationValue < 0 or destinationValue >= vertexCountValue: return -1
    let source = int(sourceValue)
    let destination = int(destinationValue)
    adjacency[source][outDegree[source]] = destination
    inc outDegree[source]
    inc inDegree[destination]

  var path: array[MaxRoute, int]
  var pathLength = 0
  if vertexCount == 0:
    pathLength = 0
  elif edgeCount == 0:
    path[0] = 0
    pathLength = 1
  else:
    var start = -1
    var startCount = 0
    var endCount = 0
    var degreesValid = true
    for vertex in 0 ..< vertexCount:
      let difference = outDegree[vertex] - inDegree[vertex]
      if difference == 1:
        start = vertex
        inc startCount
      elif difference == -1:
        inc endCount
      elif difference < -1 or difference > 1:
        degreesValid = false
    if not ((startCount == 1 and endCount == 1) or
            (startCount == 0 and endCount == 0)):
      degreesValid = false
    if degreesValid and start < 0:
      for vertex in 0 ..< vertexCount:
        if outDegree[vertex] > 0:
          start = vertex
          break

    var connected = degreesValid
    if connected:
      var visited: array[MaxVertices, bool]
      var pending: array[MaxVertices, int]
      var pendingHead = 0
      var pendingTail = 1
      pending[0] = start
      visited[start] = true
      while pendingHead < pendingTail:
        let current = pending[pendingHead]
        inc pendingHead
        for edge in 0 ..< outDegree[current]:
          let next = adjacency[current][edge]
          if not visited[next]:
            visited[next] = true
            pending[pendingTail] = next
            inc pendingTail
        for source in 0 ..< vertexCount:
          if visited[source]: continue
          for edge in 0 ..< outDegree[source]:
            if adjacency[source][edge] == current:
              visited[source] = true
              pending[pendingTail] = source
              inc pendingTail
              break
      for vertex in 0 ..< vertexCount:
        if inDegree[vertex] + outDegree[vertex] > 0 and not visited[vertex]:
          connected = false

    if connected:
      var nextPosition: array[MaxVertices, int]
      var stack: array[MaxRoute, int]
      var reversePath: array[MaxRoute, int]
      var stackSize = 1
      var reverseLength = 0
      stack[0] = start
      while stackSize > 0:
        let current = stack[stackSize - 1]
        if nextPosition[current] < outDegree[current]:
          let next = adjacency[current][nextPosition[current]]
          inc nextPosition[current]
          stack[stackSize] = next
          inc stackSize
        else:
          dec stackSize
          reversePath[reverseLength] = stack[stackSize]
          inc reverseLength
      if reverseLength == edgeCount + 1:
        pathLength = reverseLength
        for index in 0 ..< pathLength:
          path[index] = reversePath[pathLength - 1 - index]

  let outputBytes = 8 * (pathLength + 1)
  if output.isNil or capacity < csize_t(outputBytes): return -2
  writeI64Le(output, 0, int64(pathLength))
  for index in 0 ..< pathLength:
    writeI64Le(output, 8 * (index + 1), int64(path[index]))
  int64(outputBytes)
