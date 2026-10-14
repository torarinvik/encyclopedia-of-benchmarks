## Bounded doubly linked list with a portable index-based node pool.
proc doubly_linked_list_benchmark*(values: ptr UncheckedArray[int64], length: csize_t): int64
    {.cdecl, exportc: "doubly_linked_list_benchmark".} =
  if length > 1024 or length mod 2 != 0: return -1
  let operationCount = int(length div 2)
  const capacity = 256
  var nodeValue: array[capacity, int64]
  var nextNode, prevNode: array[capacity + 1, int]
  for i in 0 ..< capacity: nextNode[i] = i + 1
  var freeHead = 0
  var head = capacity
  var tail = capacity
  var count = 0
  var checksum: int64 = 0
  for operation in 0 ..< operationCount:
    let opcode = values[2 * operation]
    let payload = values[2 * operation + 1]
    var observed: int64 = 0
    var returnsValue = true
    if opcode == 0 or opcode == 1:
      if payload < -1000000 or payload > 1000000 or count == capacity or freeHead == capacity: return -1
      let node = freeHead
      freeHead = nextNode[node]
      nodeValue[node] = payload
      nextNode[node] = capacity
      prevNode[node] = capacity
      if opcode == 0:
        if tail == capacity: head = node
        else:
          prevNode[node] = tail
          nextNode[tail] = node
        tail = node
      else:
        if head == capacity: tail = node
        else:
          nextNode[node] = head
          prevNode[head] = node
        head = node
      inc count
      returnsValue = false
    elif opcode == 2 or opcode == 3:
      if payload != 0 or count == 0: return -1
      let node = if opcode == 2: head else: tail
      observed = nodeValue[node]
      let before = prevNode[node]
      let after = nextNode[node]
      if before == capacity: head = after else: nextNode[before] = after
      if after == capacity: tail = before else: prevNode[after] = before
      nextNode[node] = freeHead
      freeHead = node
      dec count
    elif opcode == 4 or opcode == 5:
      if payload < -1000000 or payload > 1000000: return -1
      var node = head
      while node != capacity and nodeValue[node] != payload: node = nextNode[node]
      observed = int64(node != capacity)
      if opcode == 4 and node != capacity:
        let before = prevNode[node]
        let after = nextNode[node]
        if before == capacity: head = after else: nextNode[before] = after
        if after == capacity: tail = before else: prevNode[after] = before
        nextNode[node] = freeHead
        freeHead = node
        dec count
    elif opcode == 6:
      if payload != 0: return -1
      observed = int64(count)
    else: return -1
    if returnsValue: checksum += int64(operation + 1) * (observed + 1000000)
  var node = head
  var index = 0
  while node != capacity:
    checksum += int64(operationCount + index + 1) * (nodeValue[node] + 1000000)
    node = nextNode[node]
    inc index
  node = tail
  index = 0
  while node != capacity:
    checksum += int64(operationCount + count + index + 1) * (nodeValue[node] + 1000000)
    node = prevNode[node]
    inc index
  checksum
