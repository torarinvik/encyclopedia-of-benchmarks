const MaxLength = 64
const MaxOperations = 20
const MaxTreeNodes = 128
const MaxValidInputLength = 146
const MaxParseableInputLength = 147
const ChecksumOffset = 67108865'i64

type SegmentTreeStorage = array[MaxTreeNodes, int64]

proc applyUpdate(tree: var SegmentTreeStorage, operand: var SegmentTreeStorage,
                 queryLeft, queryRight, node, left, right: int, factor: int64) =
  if queryLeft <= left and right <= queryRight:
    operand[node] *= factor
    tree[node] *= factor
    return
  if queryRight <= left or right <= queryLeft: return
  let middle = left + (right - left) div 2
  applyUpdate(tree, operand, queryLeft, queryRight, node * 2, left, middle, factor)
  applyUpdate(tree, operand, queryLeft, queryRight, node * 2 + 1, middle, right, factor)
  tree[node] = operand[node] * (tree[node * 2] + tree[node * 2 + 1])

proc querySum(tree: SegmentTreeStorage, operand: SegmentTreeStorage,
              queryLeft, queryRight, node, left, right: int): int64 =
  if queryLeft <= left and right <= queryRight: return tree[node]
  if queryRight <= left or right <= queryLeft: return 0
  let middle = left + (right - left) div 2
  operand[node] * (querySum(tree, operand, queryLeft, queryRight, node * 2, left, middle) +
    querySum(tree, operand, queryLeft, queryRight, node * 2 + 1, middle, right))

proc segment_tree_apply_benchmark*(input: ptr UncheckedArray[int64], length: csize_t): int64
    {.cdecl, exportc: "segment_tree_apply_benchmark".} =
  if input.isNil or length < csize_t(2) or length > csize_t(MaxParseableInputLength): return -1
  if input[0] < 1 or input[0] > MaxLength: return -1
  let n = int(input[0])
  if length < csize_t(n + 2): return -1
  if input[n + 1] < 0 or input[n + 1] > MaxOperations: return -1
  let operationCount = int(input[n + 1])
  if length != csize_t(n + 2 + 4 * operationCount) or length > csize_t(MaxValidInputLength): return -1

  var base = 1
  while base < n: base = base shl 1
  var tree: SegmentTreeStorage
  var operand: SegmentTreeStorage
  for index in 0 ..< MaxTreeNodes: operand[index] = 1
  for index in 0 ..< n:
    let value = input[index + 1]
    if value < -1 or value > 1: return -1
    tree[base + index] = value
  var node = base
  while node > 1:
    dec node
    tree[node] = tree[node * 2] + tree[node * 2 + 1]

  var checksum = 0'i64
  for operation in 0 ..< operationCount:
    let offset = n + 2 + 4 * operation
    let opcode = input[offset]
    let left = input[offset + 1]
    let right = input[offset + 2]
    let argument = input[offset + 3]
    if left < 0 or left > right or right >= int64(n): return -1
    let queryLeft = int(left)
    let queryRight = int(right) + 1
    if opcode == 0:
      if argument < -2 or argument > 2: return -1
      applyUpdate(tree, operand, queryLeft, queryRight, 1, 0, base, argument)
    elif opcode == 1:
      if argument != 0: return -1
      let value = querySum(tree, operand, queryLeft, queryRight, 1, 0, base)
      checksum += int64(operation + 1) * (value + ChecksumOffset)
    else:
      return -1
  checksum
