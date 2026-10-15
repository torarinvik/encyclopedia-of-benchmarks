## Source-faithful port of TheAlgorithms/Go graph.Topological.
proc topological*(values: ptr UncheckedArray[int64], length: csize_t,
    output: ptr UncheckedArray[uint8], outputCapacity: csize_t): int64
    {.cdecl, exportc: "topological".} =
  if values == nil or length < 1 or length > 66 or (length - 1) mod 2 != 0:
    return -2
  if values[0] < 0 or values[0] > 64:
    return -2
  let vertices = csize_t(values[0])
  let edgeCount = (length - 1) div 2
  var dependencies: array[64, uint8]
  var adjacency: array[64, uint64]
  var answer: array[96, uint8]

  for edge in 0'u64 ..< uint64(edgeCount):
    let originValue = values[1 + 2 * csize_t(edge)]
    let destinationValue = values[2 + 2 * csize_t(edge)]
    if originValue < 0 or destinationValue < 0 or
        uint64(originValue) >= uint64(vertices) or uint64(destinationValue) >= uint64(vertices):
      return -2
    let origin = csize_t(originValue)
    let destination = csize_t(destinationValue)
    inc dependencies[destination]
    adjacency[origin] = adjacency[origin] or (1'u64 shl int(destination))

  var answerCount = csize_t(0)
  for root in 0'u64 ..< uint64(vertices):
    let rootIndex = csize_t(root)
    if dependencies[rootIndex] != 0: continue
    var stack: array[64, csize_t]
    var top = csize_t(0)
    stack[top] = rootIndex
    inc top
    while top > 0:
      dec top
      let origin = stack[top]
      answer[answerCount] = uint8(origin)
      inc answerCount
      for destination in 0'u64 ..< uint64(vertices):
        let destinationIndex = csize_t(destination)
        let edgeMask = 1'u64 shl int(destination)
        if (adjacency[origin] and edgeMask) != 0:
          var inStack = false
          for stackIndex in 0'u64 ..< uint64(top):
            if stack[csize_t(stackIndex)] == destinationIndex:
              inStack = true
              break
          if not inStack:
            stack[top] = destinationIndex
            inc top
        adjacency[origin] = adjacency[origin] and not edgeMask
        adjacency[destinationIndex] = adjacency[destinationIndex] and not (1'u64 shl int(origin))

  if outputCapacity < answerCount or (answerCount != 0 and output == nil):
    return -2
  for index in 0'u64 ..< uint64(answerCount):
    output[csize_t(index)] = answer[csize_t(index)]
  int64(answerCount)
