const Capacity = 256
const Sentinel = Capacity
const ValueOffset = 1_000_000'i64

proc circular_linked_list_benchmark*(values: ptr UncheckedArray[int64], length: csize_t): int64
    {.cdecl, exportc: "circular_linked_list_benchmark".} =
  if length > 1024 or length mod 2 != 0: return -1
  let operationCount = int(length div 2)
  var nodeValue: array[Capacity, int64]
  var nextNode: array[Capacity + 1, int]
  for index in 0 ..< Capacity: nextNode[index] = index + 1
  nextNode[Sentinel] = Sentinel
  var freeHead = 0
  var tail = Sentinel
  var count = 0
  var checksum = 0'i64
  for operation in 0 ..< operationCount:
    let opcode = values[2 * operation]
    let payload = values[2 * operation + 1]
    var observed = 0'i64
    var returnsValue = true
    if opcode == 0 or opcode == 1:
      if payload < -ValueOffset or payload > ValueOffset or count == Capacity or freeHead == Sentinel: return -1
      let node = freeHead
      freeHead = nextNode[node]
      nodeValue[node] = payload
      if opcode == 0:
        nextNode[node] = Sentinel
        nextNode[tail] = node
        tail = node
      else:
        nextNode[node] = nextNode[Sentinel]
        nextNode[Sentinel] = node
        if count == 0: tail = node
      inc count
      returnsValue = false
    elif opcode == 2 or opcode == 3:
      if payload != 0 or count == 0: return -1
      var previous = Sentinel
      if opcode == 3:
        while nextNode[previous] != tail: previous = nextNode[previous]
      let node = nextNode[previous]
      observed = nodeValue[node]
      nextNode[previous] = nextNode[node]
      if node == tail: tail = previous
      nextNode[node] = freeHead
      freeHead = node
      dec count
    elif opcode == 4 or opcode == 5:
      if payload < -ValueOffset or payload > ValueOffset: return -1
      var previous = Sentinel
      while nextNode[previous] != Sentinel and nodeValue[nextNode[previous]] != payload:
        previous = nextNode[previous]
      let node = nextNode[previous]
      observed = int64(node != Sentinel)
      if opcode == 4 and node != Sentinel:
        nextNode[previous] = nextNode[node]
        if node == tail: tail = previous
        nextNode[node] = freeHead
        freeHead = node
        dec count
    elif opcode == 6:
      if payload != 0: return -1
      observed = int64(count)
    elif opcode == 7 or opcode == 8:
      if payload < 0 or payload > 1_000_000 or count == 0 or payload >= int64(count): return -1
      var previous = Sentinel
      for _ in 0 ..< int(payload): previous = nextNode[previous]
      let node = nextNode[previous]
      observed = nodeValue[node]
      if opcode == 8:
        nextNode[previous] = nextNode[node]
        if node == tail: tail = previous
        nextNode[node] = freeHead
        freeHead = node
        dec count
    else:
      return -1
    if returnsValue: checksum += (int64(operation) + 1) * (observed + ValueOffset)
  var node = nextNode[Sentinel]
  var index = 0
  while node != Sentinel:
    checksum += (int64(operationCount + index) + 1) * (nodeValue[node] + ValueOffset)
    node = nextNode[node]
    inc index
  checksum
