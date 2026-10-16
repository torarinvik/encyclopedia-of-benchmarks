const MaxNodes = 64
const MaxInputLength = 3 + 3 * MaxNodes

proc walk(order: int64, values, left, right: array[MaxNodes, int64], node: int, output: var array[MaxNodes, int64], used: var int) =
  if order == 0:
    output[used] = values[node]
    inc used
  if left[node] >= 0: walk(order, values, left, right, int(left[node]), output, used)
  if order == 1:
    output[used] = values[node]
    inc used
  if right[node] >= 0: walk(order, values, left, right, int(right[node]), output, used)
  if order == 2:
    output[used] = values[node]
    inc used

proc breadthFirst(order: int64, values, left, right: array[MaxNodes, int64], root: int, output: var array[MaxNodes, int64], used: var int) =
  var queue: array[MaxNodes, int]
  var head = 0
  var tail = 1
  queue[0] = root
  while head < tail:
    let node = queue[head]
    inc head
    output[used] = values[node]
    inc used
    let first = if order == 3: left[node] else: right[node]
    let second = if order == 3: right[node] else: left[node]
    if first >= 0:
      queue[tail] = int(first)
      inc tail
    if second >= 0:
      queue[tail] = int(second)
      inc tail

proc breadthFirstZigzag(values, left, right: array[MaxNodes, int64], root: int, output: var array[MaxNodes, int64], used: var int) =
  var queue: array[MaxNodes, int]
  var head = 0
  var tail = 1
  var level = 0
  queue[0] = root
  while head < tail:
    let levelEnd = tail
    let levelStart = used
    while head < levelEnd:
      let node = queue[head]
      inc head
      output[used] = values[node]
      inc used
      if left[node] >= 0:
        queue[tail] = int(left[node])
        inc tail
      if right[node] >= 0:
        queue[tail] = int(right[node])
        inc tail
    if level mod 2 == 1:
      var lo = levelStart
      var hi = used - 1
      while lo < hi:
        swap(output[lo], output[hi])
        inc lo
        dec hi
    inc level

proc markReachable(left, right: array[MaxNodes, int64], root: int, seen: var array[MaxNodes, bool]): int =
  var stack: array[MaxNodes, int]
  var top = 1
  var count = 0
  stack[0] = root
  while top > 0:
    dec top
    let node = stack[top]
    if seen[node]: continue
    seen[node] = true
    inc count
    if right[node] >= 0:
      stack[top] = int(right[node])
      inc top
    if left[node] >= 0:
      stack[top] = int(left[node])
      inc top
  count

proc putI64(output: ptr UncheckedArray[uint8], index: int, value: int64) =
  let bits = cast[uint64](value)
  for byte in 0 ..< 8: output[index * 8 + byte] = uint8((bits shr (8 * byte)) and 255)

proc binary_tree_traversal*(input: ptr UncheckedArray[int64], length: csize_t, output: ptr UncheckedArray[uint8], capacity: csize_t): int64 {.cdecl, exportc: "binary_tree_traversal".} =
  if input.isNil or int(length) < 3 or int(length) > MaxInputLength: return -1
  let order = input[0]
  let countValue = input[1]
  let rootValue = input[2]
  if order < 0 or order > 6 or countValue < 0 or countValue > MaxNodes or int(length) != 3 + 3 * int(countValue): return -1
  let n = int(countValue)
  if (n == 0 and rootValue != -1) or (n > 0 and (rootValue < 0 or rootValue >= int64(n))): return -1
  var values, left, right: array[MaxNodes, int64]
  var parents: array[MaxNodes, uint8]
  for i in 0 ..< n:
    values[i] = input[3 + 3 * i]
    left[i] = input[4 + 3 * i]
    right[i] = input[5 + 3 * i]
    if left[i] < -1 or left[i] >= int64(n) or right[i] < -1 or right[i] >= int64(n) or left[i] == int64(i) or right[i] == int64(i): return -1
    if left[i] >= 0:
      inc parents[int(left[i])]
      if parents[int(left[i])] > 1: return -1
    if right[i] >= 0:
      inc parents[int(right[i])]
      if parents[int(right[i])] > 1: return -1
  var result: array[MaxNodes, int64]
  var used = 0
  if n > 0:
    let root = int(rootValue)
    for i in 0 ..< n:
      if parents[i] != (if i == root: 0'u8 else: 1'u8): return -1
    var seen: array[MaxNodes, bool]
    if markReachable(left, right, root, seen) != n: return -1
    if order <= 2:
      walk(order, values, left, right, root, result, used)
    elif order == 5:
      walk(1, values, right, left, root, result, used)
    elif order == 6:
      breadthFirstZigzag(values, left, right, root, result, used)
    else:
      breadthFirst(order, values, left, right, root, result, used)
  if output.isNil or capacity < csize_t(used * 8): return -2
  for i in 0 ..< used: putI64(output, i, result[i])
  int64(used * 8)
