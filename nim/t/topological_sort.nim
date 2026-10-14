## Kahn topological sort over a bounded directed graph encoded as edge pairs.
proc topological_sort*(values: ptr UncheckedArray[int64], length: csize_t,
    output: ptr UncheckedArray[uint8], outputCapacity: csize_t): int64
    {.cdecl, exportc: "topological_sort".} =
  if values == nil or length < 1 or length > 66 or (length - 1) mod 2 != 0:
    return -2
  if values[0] < 0 or values[0] > 64:
    return -2
  let vertices = csize_t(values[0])
  let edgeCount = (length - 1) div 2
  var adjacency: array[64, uint64]
  var indegree: array[64, csize_t]
  var queue: array[64, csize_t]
  var order: array[64, csize_t]

  for edge in 0'u64 ..< uint64(edgeCount):
    let originValue = values[1 + 2 * csize_t(edge)]
    let destinationValue = values[2 + 2 * csize_t(edge)]
    if originValue < 0 or destinationValue < 0 or
        uint64(originValue) >= uint64(vertices) or uint64(destinationValue) >= uint64(vertices):
      return -2
    let origin = csize_t(originValue)
    let destination = csize_t(destinationValue)
    let mask = 1'u64 shl int(destination)
    if (adjacency[origin] and mask) == 0'u64:
      adjacency[origin] = adjacency[origin] or mask
      inc indegree[destination]

  var head = csize_t(0)
  var tail = csize_t(0)
  for vertex in 0'u64 ..< uint64(vertices):
    if indegree[csize_t(vertex)] == 0:
      queue[tail] = csize_t(vertex)
      inc tail
  var count = csize_t(0)
  while head < tail:
    let origin = queue[head]
    inc head
    order[count] = origin
    inc count
    for destination in 0'u64 ..< uint64(vertices):
      let index = csize_t(destination)
      if (adjacency[origin] and (1'u64 shl int(index))) != 0'u64:
        dec indegree[index]
        if indegree[index] == 0:
          queue[tail] = index
          inc tail
  if count != vertices:
    return -1
  if outputCapacity < vertices or (vertices != 0 and output == nil):
    return -2
  for index in 0'u64 ..< uint64(count):
    output[csize_t(index)] = uint8(order[csize_t(index)])
  int64(count)
