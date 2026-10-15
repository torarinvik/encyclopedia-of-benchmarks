const MaxNodes = 63
const MaxOutput = 6 * MaxNodes + 1

proc create_binary_tree_from_inorder_preorder*(values: ptr UncheckedArray[int64], length: csize_t,
    output: ptr UncheckedArray[uint8], outputCapacity: csize_t): int64
    {.cdecl, exportc: "create_binary_tree_from_inorder_preorder".} =
  if values.isNil or length < 1 or values[0] < 0 or values[0] > MaxNodes: return -1
  let count = int(values[0])
  if int(length) != 1 + 2 * count: return -1
  for i in 0 ..< count:
    let preorderValue = values[1 + i]
    let inorderValue = values[1 + count + i]
    if preorderValue < int64(low(int32)) or preorderValue > int64(high(int32)) or
        inorderValue < int64(low(int32)) or inorderValue > int64(high(int32)): return -1
    for j in 0 ..< i:
      if preorderValue == values[1 + j] or inorderValue == values[1 + count + j]: return -1
    var matches = 0
    for j in 0 ..< count:
      if preorderValue == values[1 + count + j]: inc matches
    if matches != 1: return -1
  var leftChild, rightChild: array[MaxNodes, int]
  for i in 0 ..< MaxNodes:
    leftChild[i] = -1; rightChild[i] = -1
  var taskPre, taskIn, taskSize: array[MaxNodes, int]
  var taskCount = 0
  if count > 0:
    taskPre[0] = 0; taskIn[0] = 0; taskSize[0] = count; inc taskCount
  while taskCount > 0:
    dec taskCount
    let preStart = taskPre[taskCount]
    let inStart = taskIn[taskCount]
    let size = taskSize[taskCount]
    if size <= 0 or preStart + size > count or inStart + size > count: return -1
    var rootPosition = -1
    for i in inStart ..< inStart + size:
      if values[1 + i] == values[1 + count + preStart]: rootPosition = i; break
    if rootPosition < 0: return -1
    let leftSize = rootPosition - inStart
    let rightSize = size - leftSize - 1
    if leftSize > 0: leftChild[preStart] = preStart + 1
    if rightSize > 0: rightChild[preStart] = preStart + leftSize + 1
    if rightSize > 0:
      taskPre[taskCount] = preStart + leftSize + 1
      taskIn[taskCount] = rootPosition + 1
      taskSize[taskCount] = rightSize
      inc taskCount
    if leftSize > 0:
      taskPre[taskCount] = preStart + 1
      taskIn[taskCount] = inStart
      taskSize[taskCount] = leftSize
      inc taskCount
  let required = 6 * count + 1
  if output.isNil or outputCapacity < required.csize_t: return -2
  var encoded: array[MaxOutput, uint8]
  var pending: array[2 * MaxNodes + 1, int]
  var top = 1
  pending[0] = if count == 0: -1 else: 0
  var written = 0
  while top > 0:
    dec top
    let node = pending[top]
    if node < 0:
      encoded[written] = 0; inc written
    else:
      let value = cast[uint32](int32(values[1 + node]))
      encoded[written] = 1; inc written
      for byte in 0 ..< 4:
        encoded[written] = uint8((value shr (8 * byte)) and 255); inc written
      pending[top] = rightChild[node]; inc top
      pending[top] = leftChild[node]; inc top
  for i in 0 ..< written: output[i] = encoded[i]
  int64(count)
