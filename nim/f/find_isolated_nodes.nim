## Return vertices with no outgoing neighbors, in ascending vertex order.
proc find_isolated_nodes*(values: ptr UncheckedArray[int64], length: csize_t,
    output: ptr UncheckedArray[uint8], outputCapacity: csize_t): int64
    {.cdecl, exportc: "find_isolated_nodes".} =
  if values == nil or length < 1 or length > 65 or (length - 1) mod 2 != 0:
    return -2
  if values[0] < 0 or values[0] > 64:
    return -2
  let vertices = csize_t(values[0])
  var adjacency: array[64, uint64]
  let edgeCount = (length - 1) div 2
  for edge in 0'u64 ..< uint64(edgeCount):
    let originValue = values[1 + 2 * csize_t(edge)]
    let destinationValue = values[2 + 2 * csize_t(edge)]
    if originValue < 0 or destinationValue < 0 or
        uint64(originValue) >= uint64(vertices) or uint64(destinationValue) >= uint64(vertices):
      return -2
    adjacency[csize_t(originValue)] = adjacency[csize_t(originValue)] or
      (1'u64 shl int(destinationValue))
  var isolated: array[64, uint8]
  var count = csize_t(0)
  for vertex in 0'u64 ..< uint64(vertices):
    let index = csize_t(vertex)
    if adjacency[index] == 0'u64:
      isolated[count] = uint8(index)
      inc count
  if outputCapacity < count or (count != 0 and output == nil):
    return -2
  for index in 0'u64 ..< uint64(count):
    output[csize_t(index)] = isolated[csize_t(index)]
  int64(count)
