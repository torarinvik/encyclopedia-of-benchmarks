const SocMaxVertices = 8
const SocMaxParseableInput = 117
const SocOutputBytes = 16

proc socShortestPath(adjacency: array[8, int64], n, source, target: int,
                     path: var array[8, int]): int =
  var distance: array[8, int]
  var predecessor: array[8, int]
  var queue: array[8, int]
  for vertex in 0..<n:
    distance[vertex] = -1
    predecessor[vertex] = -1
  var head = 0
  var tail = 0
  queue[tail] = source
  inc tail
  distance[source] = 0
  while head < tail:
    let vertex = queue[head]
    inc head
    for successor in 0..<n:
      let bit = 1'i64 shl successor
      if (adjacency[vertex] and bit) != 0 and distance[successor] == -1:
        distance[successor] = distance[vertex] + 1
        predecessor[successor] = vertex
        queue[tail] = successor
        inc tail
  if distance[target] == -1: return 0
  var reversed: array[8, int]
  var count = 0
  var vertex = target
  while vertex != -1:
    reversed[count] = vertex
    inc count
    if vertex == source: break
    vertex = predecessor[vertex]
  if reversed[count - 1] != source: return 0
  for index in 0..<count:
    path[index] = reversed[count - index - 1]
  return count

proc socGcd(leftValue, rightValue: int64): int64 =
  var left = leftValue
  var right = rightValue
  while right != 0:
    let remainder = left mod right
    left = right
    right = remainder
  return left

proc socWriteI64(output: ptr UncheckedArray[uint8], word: int, value: int64) =
  let bits = cast[uint64](value)
  for byte in 0..<8:
    output[word * 8 + byte] = uint8((bits shr (byte * 8)) and 255)

proc network_erosion_strength_of_connection*(input: ptr UncheckedArray[int64],
    length: csize_t, output: ptr UncheckedArray[uint8], capacity: csize_t): int64
    {.cdecl, exportc: "network_erosion_strength_of_connection".} =
  if input == nil or length < 4 or length > SocMaxParseableInput: return -1
  let vertexRaw = input[0]
  let edgeRaw = input[1]
  let sourceRaw = input[2]
  let targetRaw = input[3]
  if vertexRaw < 2 or vertexRaw > SocMaxVertices or edgeRaw < 0 or
      edgeRaw > vertexRaw * (vertexRaw - 1) or sourceRaw < 0 or sourceRaw >= vertexRaw or
      targetRaw < 0 or targetRaw >= vertexRaw or sourceRaw == targetRaw: return -1
  let n = int(vertexRaw)
  let edgeCount = int(edgeRaw)
  let source = int(sourceRaw)
  let target = int(targetRaw)
  if length != csize_t(4 + 2 * edgeCount): return -1

  var adjacency: array[8, int64]
  var cursor = 4
  for _ in 0..<edgeCount:
    let fromRaw = input[cursor]
    let toRaw = input[cursor + 1]
    cursor += 2
    if fromRaw < 0 or fromRaw >= vertexRaw or toRaw < 0 or toRaw >= vertexRaw or fromRaw == toRaw:
      return -1
    let from = int(fromRaw)
    let to = int(toRaw)
    let bit = 1'i64 shl to
    if (adjacency[from] and bit) != 0: return -1
    adjacency[from] = adjacency[from] or bit

  var distances: array[8, int]
  for vertex in 0..<n: distances[vertex] = -1
  var path: array[8, int]
  let firstCount = socShortestPath(adjacency, n, source, target, path)
  if firstCount != 0:
    let initialLength = firstCount - 1
    distances[source] = initialLength
    distances[target] = initialLength
    while true:
      let pathCount = socShortestPath(adjacency, n, source, target, path)
      if pathCount == 0: break
      let pathLength = pathCount - 1
      if pathLength == 1:
        adjacency[source] = adjacency[source] and not (1'i64 shl target)
        continue
      for index in 0..<pathCount:
        let vertex = path[index]
        if distances[vertex] == -1: distances[vertex] = pathLength
      for index in 1 ..< (pathCount - 1):
        let vertex = path[index]
        let bit = 1'i64 shl vertex
        adjacency[vertex] = 0
        for other in 0..<n:
          adjacency[other] = adjacency[other] and not bit

  var reciprocalSumScaled = 0'i64
  for vertex in 0..<n:
    if distances[vertex] >= 1: reciprocalSumScaled += 420 div distances[vertex]
  var numerator = 2 * reciprocalSumScaled
  var denominator = 420 * int64(n + 2)
  if numerator == 0:
    denominator = 1
  else:
    let divisor = socGcd(numerator, denominator)
    numerator = numerator div divisor
    denominator = denominator div divisor
  if output == nil or capacity < SocOutputBytes: return -2
  socWriteI64(output, 0, numerator)
  socWriteI64(output, 1, denominator)
  return SocOutputBytes
