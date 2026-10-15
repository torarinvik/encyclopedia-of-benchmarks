## Bounded circular doubly linked list using a circular sentinel ring.
proc circular_doubly_linked_list_benchmark*(values: ptr UncheckedArray[int64], length: csize_t): int64
    {.cdecl, exportc: "circular_doubly_linked_list_benchmark".} =
  if length > 1024 or length mod 2 != 0: return -1
  let operationCount = int(length div 2)
  const capacity = 256
  var nodeValue: array[capacity, int64]
  var nextNode, prevNode: array[capacity + 1, int]
  for i in 0 ..< capacity: nextNode[i] = i + 1
  var freeHead = 0
  var count = 0
  nextNode[capacity] = capacity
  prevNode[capacity] = capacity
  var checksum: int64 = 0
  for operation in 0 ..< operationCount:
    let opcode = values[2 * operation]
    let payload = values[2 * operation + 1]
    var observed: int64 = 0
    var returnsValue = true
    if opcode == 0 or opcode == 1:
      if payload < -1_000_000 or payload > 1_000_000 or count == capacity or freeHead == capacity: return -1
      let node = freeHead
      freeHead = nextNode[node]
      nodeValue[node] = payload
      let before = if opcode == 0: prevNode[capacity] else: capacity
      let after = if opcode == 0: capacity else: nextNode[capacity]
      nextNode[node] = after
      prevNode[node] = before
      nextNode[before] = node
      prevNode[after] = node
      inc count
      returnsValue = false
    elif opcode == 2 or opcode == 3:
      if payload != 0 or count == 0: return -1
      let node = if opcode == 2: nextNode[capacity] else: prevNode[capacity]
      observed = nodeValue[node]
      nextNode[prevNode[node]] = nextNode[node]
      prevNode[nextNode[node]] = prevNode[node]
      nextNode[node] = freeHead
      freeHead = node
      dec count
    elif opcode == 4 or opcode == 5:
      if payload < -1_000_000 or payload > 1_000_000: return -1
      var node = nextNode[capacity]
      while node != capacity and nodeValue[node] != payload: node = nextNode[node]
      observed = int64(node != capacity)
      if opcode == 4 and node != capacity:
        nextNode[prevNode[node]] = nextNode[node]
        prevNode[nextNode[node]] = prevNode[node]
        nextNode[node] = freeHead
        freeHead = node
        dec count
    elif opcode == 6:
      if payload != 0: return -1
      observed = int64(count)
    elif opcode == 7 or opcode == 8:
      if payload < 0 or payload > 1_000_000 or count == 0: return -1
      if opcode == 8 and payload >= int64(count): return -1
      let index = if opcode == 7: int(payload mod int64(count)) else: int(payload)
      var node: int
      if index <= count div 2:
        node = nextNode[capacity]
        for i in 0 ..< index: node = nextNode[node]
      else:
        node = prevNode[capacity]
        var i = count - 1
        while i > index:
          node = prevNode[node]
          dec i
      observed = nodeValue[node]
      if opcode == 8:
        nextNode[prevNode[node]] = nextNode[node]
        prevNode[nextNode[node]] = prevNode[node]
        nextNode[node] = freeHead
        freeHead = node
        dec count
    else: return -1
    if returnsValue: checksum += int64(operation + 1) * (observed + 1_000_000)
  var node = nextNode[capacity]
  var index = 0
  while node != capacity:
    checksum += int64(operationCount + index + 1) * (nodeValue[node] + 1_000_000)
    node = nextNode[node]
    inc index
  node = prevNode[capacity]
  index = 0
  while node != capacity:
    checksum += int64(operationCount + count + index + 1) * (nodeValue[node] + 1_000_000)
    node = prevNode[node]
    inc index
  checksum
