## Traverse a directed graph from start with fixed-size adjacency bitsets.
proc depth_first_search*(values: ptr UncheckedArray[int64], length: csize_t,
    output: ptr UncheckedArray[uint8], outputCapacity: csize_t): int64
    {.cdecl, exportc: "depth_first_search".} =
  if values == nil or length < 2 or length > 66 or (length - 2) mod 2 != 0:
    return -2
  if values[0] < 0 or values[0] > 64:
    return -2
  let vertices = csize_t(values[0])
  let startValue = values[1]
  if vertices == 0:
    return (if startValue == -1 and length == 2: 0'i64 else: -2'i64)
  if startValue < 0 or uint64(startValue) >= uint64(vertices):
    return -2
  var adjacency: array[64, uint64]
  var visited: array[64, bool]
  var order: array[64, csize_t]
  let edgeCount = (length - 2) div 2
  for edge in 0'u64 ..< uint64(edgeCount):
    let originValue = values[2 + 2 * csize_t(edge)]
    let destinationValue = values[3 + 2 * csize_t(edge)]
    if originValue < 0 or destinationValue < 0 or
        uint64(originValue) >= uint64(vertices) or uint64(destinationValue) >= uint64(vertices):
      return -2
    let origin = csize_t(originValue)
    let destination = csize_t(destinationValue)
    adjacency[origin] = adjacency[origin] or (1'u64 shl int(destination))
  let start = csize_t(startValue)
  var count = csize_t(0)
  visited[start] = true
  var stackVertex: array[64, csize_t]
  var stackNext: array[64, csize_t]
  var depth = csize_t(1)
  stackVertex[0] = start
  order[count] = start
  inc count
  while depth != 0:
    let frame = depth - 1
    let origin = stackVertex[frame]
    if stackNext[frame] == vertices:
      dec depth
    else:
      let destination = stackNext[frame]
      inc stackNext[frame]
      if (adjacency[origin] and (1'u64 shl int(destination))) != 0'u64 and not visited[destination]:
        visited[destination] = true
        order[count] = destination
        inc count
        stackVertex[depth] = destination
        stackNext[depth] = 0
        inc depth
  if outputCapacity < count or (count != 0 and output == nil):
    return -2
  for index in 0'u64 ..< uint64(count):
    output[csize_t(index)] = uint8(order[csize_t(index)])
  int64(count)
