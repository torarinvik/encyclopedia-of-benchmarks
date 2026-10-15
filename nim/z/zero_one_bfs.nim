## 0-1 BFS over a bounded directed graph encoded as weighted edge triples.
proc zero_one_bfs*(values: ptr UncheckedArray[int64], length: csize_t,
    output: ptr UncheckedArray[uint8], outputCapacity: csize_t): int64
    {.cdecl, exportc: "zero_one_bfs".} =
  if values == nil or length < 3 or length > 3075:
    return -1
  if values[0] < 1 or values[0] > 64 or values[2] < 0 or values[2] > 1024:
    return -1
  let vertices = csize_t(values[0])
  let sourceValue = values[1]
  let edgeCount = csize_t(values[2])
  if sourceValue < 0 or uint64(sourceValue) >= uint64(vertices) or
      length != 3 + 3 * edgeCount:
    return -1
  let source = csize_t(sourceValue)

  var zeroEdges: array[64, uint64]
  var oneEdges: array[64, uint64]
  var distance: array[64, uint8]
  var deque: array[4097, uint8]
  for vertex in 0 ..< 64:
    distance[vertex] = 255'u8
  for edge in 0'u64 ..< uint64(edgeCount):
    let originValue = values[3 + 3 * csize_t(edge)]
    let destinationValue = values[4 + 3 * csize_t(edge)]
    let weight = values[5 + 3 * csize_t(edge)]
    if originValue < 0 or destinationValue < 0 or
        uint64(originValue) >= uint64(vertices) or uint64(destinationValue) >= uint64(vertices) or
        (weight != 0 and weight != 1):
      return -1
    let origin = csize_t(originValue)
    let destination = csize_t(destinationValue)
    let mask = 1'u64 shl int(destination)
    if weight == 0:
      zeroEdges[origin] = zeroEdges[origin] or mask
    else:
      oneEdges[origin] = oneEdges[origin] or mask
  if outputCapacity < vertices or (vertices != 0 and output == nil):
    return -2

  var head = csize_t(0)
  var tail = csize_t(1)
  var queued = csize_t(1)
  deque[0] = uint8(source)
  distance[source] = 0
  while queued != 0:
    let origin = csize_t(deque[head])
    head = (head + 1) mod 4097
    dec queued
    let base = distance[origin]
    for destination in 0'u64 ..< uint64(vertices):
      let index = csize_t(destination)
      let mask = 1'u64 shl int(index)
      if (zeroEdges[origin] and mask) != 0'u64 and base < distance[index]:
        distance[index] = base
        if head == 0:
          head = 4096
        else:
          dec head
        deque[head] = uint8(index)
        inc queued
      let candidate = base + 1'u8
      if (oneEdges[origin] and mask) != 0'u64 and candidate < distance[index]:
        distance[index] = candidate
        deque[tail] = uint8(index)
        tail = (tail + 1) mod 4097
        inc queued

  for vertex in 0 ..< int(vertices):
    output[csize_t(vertex)] = distance[vertex]
  int64(vertices)
