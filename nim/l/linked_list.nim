## Bounded singly linked list with a portable index-based node pool.
proc linked_list_benchmark*(values: ptr UncheckedArray[int64], length: csize_t): int64
    {.cdecl, exportc: "linked_list_benchmark".} =
  if length > 1024 or length mod 2 != 0: return -1
  let operationCount = int(length div 2)
  const capacity = 256
  var nodeValue: array[capacity, int64]
  var nextNode: array[capacity + 1, int]
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
      if opcode == 0:
        if tail == capacity: head = node
        else: nextNode[tail] = node
        tail = node
        nextNode[node] = capacity
      else:
        nextNode[node] = head
        head = node
        if tail == capacity: tail = node
      inc count
      returnsValue = false
    elif opcode == 2:
      if payload != 0 or count == 0: return -1
      let node = head
      observed = nodeValue[node]
      head = nextNode[node]
      if head == capacity: tail = capacity
      nextNode[node] = freeHead
      freeHead = node
      dec count
    elif opcode == 3:
      if payload != 0 or count == 0: return -1
      let node = tail
      observed = nodeValue[node]
      if head == tail:
        head = capacity
        tail = capacity
      else:
        var before = head
        while nextNode[before] != tail: before = nextNode[before]
        tail = before
        nextNode[before] = capacity
      nextNode[node] = freeHead
      freeHead = node
      dec count
    elif opcode == 4 or opcode == 5:
      if payload < -1000000 or payload > 1000000: return -1
      var before = capacity
      var node = head
      while node != capacity and nodeValue[node] != payload:
        before = node
        node = nextNode[node]
      observed = int64(node != capacity)
      if opcode == 4 and node != capacity:
        if before == capacity: head = nextNode[node]
        else: nextNode[before] = nextNode[node]
        if tail == node: tail = before
        nextNode[node] = freeHead
        freeHead = node
        dec count
    elif opcode == 6:
      if payload != 0: return -1
      observed = int64(count)
    elif opcode == 7:
      if payload != 0: return -1
      var previous = capacity
      var node = head
      tail = head
      while node != capacity:
        let next = nextNode[node]
        nextNode[node] = previous
        previous = node
        node = next
      head = previous
      returnsValue = false
    else: return -1
    if returnsValue: checksum += int64(operation + 1) * (observed + 1000000)
  var node = head
  var index = 0
  while node != capacity:
    checksum += int64(operationCount + index + 1) * (nodeValue[node] + 1000000)
    node = nextNode[node]
    inc index
  checksum
