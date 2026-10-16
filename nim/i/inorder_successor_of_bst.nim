const MaxNodes = 64
const MaxInputLength = 67

proc inorder_successor_of_bst*(input: ptr UncheckedArray[int64], length: csize_t): int64
    {.cdecl, exportc: "inorder_successor_of_bst".} =
  if input.isNil or length < 2 or length > csize_t(MaxInputLength): return -1
  let countValue = input[0]
  let target = input[1]
  if countValue < 0 or countValue > int64(MaxNodes) or target < 1 or target > 2_147_483_647:
    return -1
  let count = int(countValue)
  if length != csize_t(count + 2): return -1

  var keys: array[MaxNodes, int64]
  var left, right: array[MaxNodes, int]
  for index in 0 ..< count:
    let key = input[index + 2]
    if key < 1 or key > 2_147_483_647: return -1
    for previous in 0 ..< index:
      if keys[previous] == key: return -1
    keys[index] = key
    left[index] = -1
    right[index] = -1

  var root = -1
  for index in 0 ..< count:
    if root < 0:
      root = index
      continue
    var current = root
    while true:
      if keys[index] <= keys[current]:
        if left[current] < 0:
          left[current] = index
          break
        current = left[current]
      else:
        if right[current] < 0:
          right[current] = index
          break
        current = right[current]

  var current = root
  while current >= 0 and keys[current] != target:
    if target > keys[current]: current = right[current]
    else: current = left[current]
  if current < 0: return 0

  if right[current] >= 0:
    var successor = right[current]
    while left[successor] >= 0: successor = left[successor]
    return keys[successor]

  var successor = -1
  var ancestor = root
  while ancestor >= 0 and ancestor != current:
    if keys[current] < keys[ancestor]:
      successor = ancestor
      ancestor = left[ancestor]
    else:
      ancestor = right[ancestor]
  if successor < 0: 0 else: keys[successor]
