## Stack-based DFS that marks vertices when they are pushed, matching the source order.
proc depth_first_search_with_stack*(values: ptr UncheckedArray[int64], length: csize_t,
    output: ptr UncheckedArray[uint8], outputCapacity: csize_t): int64
    {.cdecl, exportc: "depth_first_search_with_stack".} =
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

  var adjacency: array[2048, csize_t]
  var degree: array[64, csize_t]
  var state: array[64, uint8]
  let edgeCount = (length - 2) div 2
  for edge in 0'u64 ..< uint64(edgeCount):
    let originValue = values[2 + 2 * csize_t(edge)]
    let destinationValue = values[3 + 2 * csize_t(edge)]
    if originValue < 0 or destinationValue < 0 or
        uint64(originValue) >= uint64(vertices) or uint64(destinationValue) >= uint64(vertices):
      return -2
    let origin = csize_t(originValue)
    adjacency[origin * 32 + degree[origin]] = csize_t(destinationValue)
    inc degree[origin]

  var stack: array[33, csize_t]
  var order: array[64, csize_t]
  var stackLength = csize_t(1)
  var count = csize_t(0)
  let start = csize_t(startValue)
  state[start] = 1
  stack[0] = start
  while stackLength != 0:
    dec stackLength
    let vertex = stack[stackLength]
    if state[vertex] == 1:
      order[count] = vertex
      inc count
      for edge in 0'u64 ..< uint64(degree[vertex]):
        let neighbor = adjacency[vertex * 32 + csize_t(edge)]
        stack[stackLength] = neighbor
        inc stackLength
        if state[neighbor] != 2:
          state[neighbor] = 1
      state[vertex] = 2
  if outputCapacity < count or (count != 0 and output == nil):
    return -2
  for index in 0'u64 ..< uint64(count):
    output[csize_t(index)] = uint8(order[csize_t(index)])
  int64(count)
