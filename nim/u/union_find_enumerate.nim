const
  MaxItems = 16
  MaxOperations = 32
  MaxInputLength = 99

proc findRoot(parent: var array[MaxItems, int64], item: int): int =
  var root = item
  while parent[root] >= 0: root = int(parent[root])
  var current = item
  while current != root:
    let nextItem = int(parent[current])
    parent[current] = int64(root)
    current = nextItem
  root

proc componentMask(successor: array[MaxItems, int64], start: int): int64 =
  var mask = 0'i64
  var item = start
  while true:
    mask = mask or (1'i64 shl item)
    item = int(successor[item])
    if item == start: break
  mask

proc union_find_enumerate*(input: ptr UncheckedArray[int64], length: csize_t): int64
    {.cdecl, exportc: "union_find_enumerate".} =
  if input == nil or length < 2 or length > csize_t(MaxInputLength): return -1
  let itemCountValue = input[0]
  let operationCountValue = input[1]
  if itemCountValue < 1 or itemCountValue > MaxItems or operationCountValue < 0 or operationCountValue > MaxOperations: return -1
  let itemCount = int(itemCountValue)
  let operationCount = int(operationCountValue)
  if length != csize_t(2 + 3 * operationCount): return -1

  for operation in 0 ..< operationCount:
    let position = 2 + 3 * operation
    let opcode = input[position]
    let first = input[position + 1]
    let second = input[position + 2]
    if opcode == 0:
      if first < 0 or first >= itemCountValue or second < 0 or second >= itemCountValue: return -1
    elif opcode == 1:
      if first < 0 or first >= itemCountValue or second != 0: return -1
    else:
      return -1

  var parent: array[MaxItems, int64]
  var successor: array[MaxItems, int64]
  for item in 0 ..< itemCount:
    parent[item] = -1
    successor[item] = int64(item)
  var checksum = 0'i64
  for operation in 0 ..< operationCount:
    let position = 2 + 3 * operation
    let opcode = input[position]
    let first = int(input[position + 1])
    var observed = 0'i64
    if opcode == 0:
      var left = findRoot(parent, first)
      var right = findRoot(parent, int(input[position + 2]))
      if left != right:
        if parent[left] > parent[right]: swap(left, right)
        parent[left] += parent[right]
        parent[right] = int64(left)
        swap(successor[left], successor[right])
        observed = 1
    else:
      observed = componentMask(successor, first)
    checksum += int64(operation + 1) * (observed + 1)
  checksum
