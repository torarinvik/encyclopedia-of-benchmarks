## Bounded linked-node pool for an ascending priority queue.
proc ascending_priority_queue*(input: ptr UncheckedArray[int64], length: csize_t): int64
    {.cdecl, exportc: "ascending_priority_queue".} =
  if input.isNil or length < 1: return -1
  let operationCount = input[0]
  if operationCount < 0 or operationCount > 512 or length != csize_t(1 + 2 * operationCount): return -1

  var nodeValues: array[64, int64]
  var nodeNext: array[64, int64]
  for index in 0 ..< 63: nodeNext[index] = int64(index + 1)
  nodeNext[63] = -1
  var freeHead = 0'i64
  var front = -1'i64
  var rear = -1'i64
  var checksum = 0'i64

  for operation in 0 ..< int(operationCount):
    let opcode = input[1 + 2 * operation]
    let payload = input[2 + 2 * operation]
    if opcode == 0:
      if payload < -1_000_000 or payload > 1_000_000 or freeHead < 0: return -1
      let node = int(freeHead)
      freeHead = nodeNext[node]
      nodeValues[node] = payload
      nodeNext[node] = -1
      if front < 0:
        front = int64(node)
        rear = int64(node)
      else:
        nodeNext[int(rear)] = int64(node)
        rear = int64(node)
    elif opcode == 1:
      if payload != 0 or front < 0: return -1
      var previous = -1'i64
      var current = front
      var minimum = front
      var minimumPrevious = -1'i64
      while current >= 0:
        if nodeValues[int(current)] < nodeValues[int(minimum)]:
          minimum = current
          minimumPrevious = previous
        previous = current
        current = nodeNext[int(current)]
      checksum += int64(operation + 1) * (nodeValues[int(minimum)] + 1_000_001)
      if minimumPrevious < 0: front = nodeNext[int(minimum)]
      else: nodeNext[int(minimumPrevious)] = nodeNext[int(minimum)]
      if rear == minimum: rear = minimumPrevious
      nodeNext[int(minimum)] = freeHead
      freeHead = minimum
    else:
      return -1

  var position = 1'i64
  var current = front
  while current >= 0:
    checksum += position * (nodeValues[int(current)] + 1_000_001)
    current = nodeNext[int(current)]
    inc position
  checksum
