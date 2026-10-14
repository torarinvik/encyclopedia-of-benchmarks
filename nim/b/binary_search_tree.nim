## Bounded unbalanced binary search tree with an index-based node pool.
proc binary_search_tree_benchmark*(values: ptr UncheckedArray[int64], length: csize_t): int64
    {.cdecl, exportc: "binary_search_tree_benchmark".} =
  if length > 1024 or length mod 2 != 0: return -1
  const capacity = 256
  let operationCount = int(length div 2)
  var key: array[capacity, int64]
  var left, right, freeNext: array[capacity + 1, int]
  for i in 0 ..< capacity: freeNext[i] = i + 1
  var freeHead = 0
  var root = capacity
  var count = 0
  var checksum: int64 = 0
  for operation in 0 ..< operationCount:
    let opcode = values[2 * operation]
    let payload = values[2 * operation + 1]
    var observed: int64 = 0
    if opcode == 0:
      if payload < -1000000 or payload > 1000000: return -1
      var parent = capacity
      var node = root
      while node != capacity and key[node] != payload:
        parent = node
        if payload < key[node]: node = left[node] else: node = right[node]
      if node == capacity:
        if count == capacity or freeHead == capacity: return -1
        node = freeHead
        freeHead = freeNext[node]
        key[node] = payload
        left[node] = capacity
        right[node] = capacity
        if parent == capacity: root = node
        elif payload < key[parent]: left[parent] = node
        else: right[parent] = node
        inc count
        observed = 1
    elif opcode == 1:
      if payload < -1000000 or payload > 1000000: return -1
      var parent = capacity
      var node = root
      while node != capacity and key[node] != payload:
        parent = node
        if payload < key[node]: node = left[node] else: node = right[node]
      observed = int64(node != capacity)
      if node != capacity:
        if left[node] != capacity and right[node] != capacity:
          var predParent = node
          var pred = left[node]
          while right[pred] != capacity:
            predParent = pred
            pred = right[pred]
          key[node] = key[pred]
          parent = predParent
          node = pred
        var child = left[node]
        if child == capacity: child = right[node]
        if parent == capacity: root = child
        elif left[parent] == node: left[parent] = child
        else: right[parent] = child
        freeNext[node] = freeHead
        freeHead = node
        dec count
    elif opcode == 2:
      if payload < -1000000 or payload > 1000000: return -1
      var node = root
      while node != capacity and key[node] != payload:
        if payload < key[node]: node = left[node] else: node = right[node]
      observed = int64(node != capacity)
    elif opcode == 3 or opcode == 4:
      if payload != 0 or root == capacity: return -1
      var node = root
      if opcode == 3:
        while left[node] != capacity: node = left[node]
      else:
        while right[node] != capacity: node = right[node]
      observed = key[node]
    elif opcode == 5:
      if payload != 0: return -1
      observed = int64(count)
    else: return -1
    checksum += int64(operation + 1) * (observed + 1000000)
  var stack: array[capacity, int]
  var top = 0
  var node = root
  var index = 0
  while node != capacity or top != 0:
    while node != capacity:
      stack[top] = node
      inc top
      node = left[node]
    dec top
    node = stack[top]
    checksum += int64(operationCount + index + 1) * (key[node] + 1000000)
    inc index
    node = right[node]
  checksum
