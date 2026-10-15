## Compare two binary trees breadth first, including shape and values.
const MaxNodeCount = 1023

type TreeView = object
  count: int
  root: int64
  rowsOffset: int

proc parseTree(input: ptr UncheckedArray[int64], length: int, offset: var int,
    tree: var TreeView): bool =
  if offset > length or length - offset < 2: return false
  let countValue = input[offset]
  let root = input[offset + 1]
  if countValue < 0 or countValue > int64(MaxNodeCount): return false
  let count = int(countValue)
  let rowsOffset = offset + 2
  if count > (length - rowsOffset) div 3: return false
  tree = TreeView(count: count, root: root, rowsOffset: rowsOffset)
  offset = rowsOffset + 3 * count
  true

proc validTree(input: ptr UncheckedArray[int64], tree: TreeView): bool =
  if tree.count == 0: return tree.root == -1
  if tree.root < 0 or tree.root >= int64(tree.count): return false
  var parents: array[MaxNodeCount, int]
  for index in 0 ..< tree.count:
    let row = tree.rowsOffset + 3 * index
    let value = input[row]
    let left = input[row + 1]
    let right = input[row + 2]
    if value < int64(low(int32)) or value > int64(high(int32)) or left < -1 or right < -1 or
        left >= int64(tree.count) or right >= int64(tree.count): return false
    if left >= 0:
      inc parents[int(left)]
      if parents[int(left)] > 1: return false
    if right >= 0:
      inc parents[int(right)]
      if parents[int(right)] > 1: return false
  for index in 0 ..< tree.count:
    if parents[index] != (if index == int(tree.root): 0 else: 1): return false
  var queue: array[MaxNodeCount, int]
  var seen: array[MaxNodeCount, bool]
  var head = 0
  var tail = 1
  queue[0] = int(tree.root)
  while head < tail:
    let index = queue[head]
    inc head
    if seen[index]: return false
    seen[index] = true
    let row = tree.rowsOffset + 3 * index
    let left = input[row + 1]
    let right = input[row + 2]
    if left >= 0:
      queue[tail] = int(left)
      inc tail
    if right >= 0:
      queue[tail] = int(right)
      inc tail
  tail == tree.count

proc treesEqual(input: ptr UncheckedArray[int64], first: TreeView, second: TreeView): int64 =
  if first.root == -1 or second.root == -1:
    return if first.root == second.root: 1 else: 0
  var queue1, queue2: array[MaxNodeCount, int]
  var head = 0
  var tail = 1
  queue1[0] = int(first.root)
  queue2[0] = int(second.root)
  while head < tail:
    let index1 = queue1[head]
    let index2 = queue2[head]
    inc head
    let row1 = first.rowsOffset + 3 * index1
    let row2 = second.rowsOffset + 3 * index2
    let left1 = input[row1 + 1]
    let right1 = input[row1 + 2]
    let left2 = input[row2 + 1]
    let right2 = input[row2 + 2]
    if input[row1] != input[row2] or (left1 == -1) != (left2 == -1) or
        (right1 == -1) != (right2 == -1): return 0
    if left1 >= 0:
      queue1[tail] = int(left1)
      queue2[tail] = int(left2)
      inc tail
    if right1 >= 0:
      queue1[tail] = int(right1)
      queue2[tail] = int(right2)
      inc tail
  1

proc same_trees_check*(input: ptr UncheckedArray[int64], length: csize_t): int64
    {.cdecl, exportc: "same_trees_check".} =
  if input == nil or length < 4 or length > csize_t(4 + 3 * MaxNodeCount): return -1
  let inputLength = int(length)
  var offset = 0
  var first, second: TreeView
  if not parseTree(input, inputLength, offset, first) or
      not parseTree(input, inputLength, offset, second) or offset != inputLength or
      first.count + second.count > MaxNodeCount or not validTree(input, first) or
      not validTree(input, second): return -1
  treesEqual(input, first, second)
