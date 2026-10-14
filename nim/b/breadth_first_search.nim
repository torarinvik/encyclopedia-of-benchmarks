## Traverse a directed graph from start with fixed-size adjacency bitsets.
proc breadth_first_search*(values: ptr UncheckedArray[int64], length: csize_t,
    output: ptr UncheckedArray[uint8], outputCapacity: csize_t): int64
    {.cdecl, exportc: "breadth_first_search".} =
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
  var queue: array[64, csize_t]
  var head = csize_t(0)
  var tail = csize_t(1)
  queue[0] = start
  while head < tail:
    let origin = queue[head]
    inc head
    order[count] = origin
    inc count
    for destination in 0'u64 ..< uint64(vertices):
      let index = csize_t(destination)
      if (adjacency[origin] and (1'u64 shl int(index))) != 0'u64 and not visited[index]:
        visited[index] = true
        queue[tail] = index
        inc tail
  if outputCapacity < count or (count != 0 and output == nil):
    return -2
  for index in 0'u64 ..< uint64(count):
    output[csize_t(index)] = uint8(order[csize_t(index)])
  int64(count)
