const
  MaxText = 32
  MaxInput = 33
  TagLimit = 1'u64 shl 62
type
  I64Input = ptr UncheckedArray[int64]
  U8Output = ptr UncheckedArray[uint8]
  SuffixTree = object
    text: array[MaxText, int64]
    left, right, size: array[MaxText, int]
    tag: array[MaxText, uint64]
    buffer, answer: array[MaxText, int]
    buffered: int

proc nodeSize(tree: var SuffixTree, node: int): int =
  if node < 0: 0 else: tree.size[node]

proc suffixLess(tree: var SuffixTree, x, y, n: int): bool =
  if tree.text[x] != tree.text[y]: return tree.text[x] < tree.text[y]
  let nextX = if x + 1 < n: tree.tag[x + 1] else: 0'u64
  let nextY = if y + 1 < n: tree.tag[y + 1] else: 0'u64
  nextX < nextY

proc flatten(tree: var SuffixTree, root: int) =
  if root < 0: return
  flatten(tree, tree.left[root])
  tree.buffer[tree.buffered] = root
  inc tree.buffered
  flatten(tree, tree.right[root])

proc buildBalanced(tree: var SuffixTree, lo, hi: int, low, high: uint64): int =
  if lo >= hi: return -1
  let mid = lo + (hi - lo) div 2
  let root = tree.buffer[mid]
  let tag = low + (high - low) div 2
  tree.tag[root] = tag
  let left = buildBalanced(tree, lo, mid, low, tag)
  let right = buildBalanced(tree, mid + 1, hi, tag, high)
  tree.left[root] = left
  tree.right[root] = right
  let leftSize = nodeSize(tree, left)
  let rightSize = nodeSize(tree, right)
  tree.size[root] = 1 + leftSize + rightSize
  root

proc rebuild(tree: var SuffixTree, root: int, low, high: uint64): int =
  tree.buffered = 0
  flatten(tree, root)
  buildBalanced(tree, 0, tree.buffered, low, high)

proc insertSuffix(tree: var SuffixTree, root, pos, n: int, low, high: uint64): int =
  if root < 0:
    tree.left[pos] = -1
    tree.right[pos] = -1
    tree.size[pos] = 1
    tree.tag[pos] = low + (high - low) div 2
    return pos
  let middle = tree.tag[root]
  if suffixLess(tree, pos, root, n):
    let child = tree.left[root]
    let inserted = insertSuffix(tree, child, pos, n, low, middle)
    tree.left[root] = inserted
  else:
    let child = tree.right[root]
    let inserted = insertSuffix(tree, child, pos, n, middle, high)
    tree.right[root] = inserted
  let leftChild = tree.left[root]
  let rightChild = tree.right[root]
  let leftSize = nodeSize(tree, leftChild)
  let rightSize = nodeSize(tree, rightChild)
  tree.size[root] = 1 + leftSize + rightSize
  if 4 * max(leftSize, rightSize) >= 3 * tree.size[root]: return rebuild(tree, root, low, high)
  root

proc inorder(tree: var SuffixTree, root: int, count: var int) =
  if root < 0: return
  inorder(tree, tree.left[root], count)
  tree.answer[count] = root
  inc count
  inorder(tree, tree.right[root], count)

proc storeLe(output: U8Output, offset: int, value: int64) =
  var bits = cast[uint64](value)
  for byte in 0 ..< 8:
    output[offset + byte] = uint8(bits and 255)
    bits = bits shr 8

proc suffix_balanced_tree*(input: I64Input, length: csize_t, output: U8Output,
    capacity: csize_t): int64 {.cdecl, exportc: "suffix_balanced_tree".} =
  if input == nil or length < 1 or length > MaxInput: return -1
  let nv = input[0]
  if nv < 0 or nv > MaxText or length != csize_t(1 + nv): return -1
  let n = int(nv)
  for i in 0 ..< n:
    if input[1 + i] < 0 or input[1 + i] > 255: return -1
  let required = 8 * n
  if output == nil or capacity < csize_t(required): return -2
  var tree: SuffixTree
  for i in 0 ..< n: tree.text[i] = input[1 + i]
  var root = -1
  if n > 0:
    for pos in countdown(n - 1, 0): root = insertSuffix(tree, root, pos, n, 0'u64, TagLimit)
  var count = 0
  inorder(tree, root, count)
  for i in 0 ..< count: storeLe(output, 8 * i, int64(tree.answer[i]))
  int64(required)
