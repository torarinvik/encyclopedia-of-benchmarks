## Historical maximum segment tree with ordered lazy add/assign summaries.
const MaxN = 32
const MaxQ = 32
const TreeSize = 4 * MaxN
const MaxInput = 2 + MaxN + 4 * MaxQ
const ValueLimit = 1000'i64

type ShNode = object
  maximum: int64
  historyMaximum: int64
  add: int64
  addPeak: int64
  setValue: int64
  setPeak: int64
  hasSet: bool

proc shApplyAddSummary(node: var ShNode, net, peak: int64) =
  node.historyMaximum = max(node.historyMaximum, node.maximum + peak)
  node.maximum += net
  if node.hasSet:
    node.setPeak = max(node.setPeak, node.setValue + peak)
    node.setValue += net
  else:
    node.addPeak = max(node.addPeak, node.add + peak)
    node.add += net

proc shApplyAdd(node: var ShNode, delta: int64) =
  if node.hasSet:
    node.setPeak = max(node.setPeak, node.setValue + delta)
    node.setValue += delta
  else:
    node.addPeak = max(node.addPeak, node.add + delta)
    node.add += delta
  node.historyMaximum = max(node.historyMaximum, node.maximum + delta)
  node.maximum += delta

proc shApplySetSummary(node: var ShNode, value, peak: int64) =
  node.historyMaximum = max(node.historyMaximum, peak)
  node.maximum = value
  if node.hasSet: node.setPeak = max(node.setPeak, peak)
  else:
    node.hasSet = true
    node.setPeak = peak
  node.setValue = value

proc shApplySet(node: var ShNode, value: int64) =
  node.historyMaximum = max(node.historyMaximum, value)
  node.maximum = value
  if node.hasSet: node.setPeak = max(node.setPeak, value)
  else:
    node.hasSet = true
    node.setPeak = value
  node.setValue = value

proc shPush(tree: var array[TreeSize, ShNode], node: int) =
  let parent = tree[node]
  if parent.add != 0 or parent.addPeak != 0:
    shApplyAddSummary(tree[2 * node], parent.add, parent.addPeak)
    shApplyAddSummary(tree[2 * node + 1], parent.add, parent.addPeak)
    tree[node].add = 0
    tree[node].addPeak = 0
  if parent.hasSet:
    shApplySetSummary(tree[2 * node], parent.setValue, parent.setPeak)
    shApplySetSummary(tree[2 * node + 1], parent.setValue, parent.setPeak)
    tree[node].hasSet = false
    tree[node].setValue = 0
    tree[node].setPeak = 0

proc shPull(tree: var array[TreeSize, ShNode], node: int) =
  tree[node].maximum = max(tree[2 * node].maximum, tree[2 * node + 1].maximum)
  tree[node].historyMaximum = max(tree[2 * node].historyMaximum, tree[2 * node + 1].historyMaximum)

proc shBuild(tree: var array[TreeSize, ShNode], values: ptr UncheckedArray[int64], node, left, right: int) =
  if right - left == 1:
    tree[node].maximum = values[left]
    tree[node].historyMaximum = values[left]
    return
  let middle = left + (right - left) div 2
  shBuild(tree, values, 2 * node, left, middle)
  shBuild(tree, values, 2 * node + 1, middle, right)
  shPull(tree, node)

proc shUpdate(tree: var array[TreeSize, ShNode], node, left, right, ql, qr: int,
              assignment: bool, value: int64) =
  if ql <= left and right <= qr:
    if assignment: shApplySet(tree[node], value)
    else: shApplyAdd(tree[node], value)
    return
  shPush(tree, node)
  let middle = left + (right - left) div 2
  if ql < middle: shUpdate(tree, 2 * node, left, middle, ql, qr, assignment, value)
  if middle < qr: shUpdate(tree, 2 * node + 1, middle, right, ql, qr, assignment, value)
  shPull(tree, node)

proc shQuery(tree: var array[TreeSize, ShNode], node, left, right, ql, qr: int, history: bool): int64 =
  if ql <= left and right <= qr:
    return if history: tree[node].historyMaximum else: tree[node].maximum
  shPush(tree, node)
  let middle = left + (right - left) div 2
  result = low(int64)
  if ql < middle: result = shQuery(tree, 2 * node, left, middle, ql, qr, history)
  if middle < qr: result = max(result, shQuery(tree, 2 * node + 1, middle, right, ql, qr, history))

proc shWriteI64(output: ptr UncheckedArray[uint8], offset: int, value: int64) =
  let bits = cast[uint64](value)
  for byte in 0..<8: output[offset + byte] = uint8((bits shr (8 * byte)) and 255)

proc segment_history_extreme*(input: ptr UncheckedArray[int64], inputLength: csize_t,
    output: ptr UncheckedArray[uint8], outputCapacity: csize_t): int64
    {.cdecl, exportc: "segment_history_extreme".} =
  if input == nil or inputLength < 2 or inputLength > MaxInput.csize_t: return -1
  let nValue = input[0]
  let qValue = input[1]
  if nValue < 1 or nValue > MaxN.int64 or qValue < 0 or qValue > MaxQ.int64: return -1
  let n = int(nValue)
  let q = int(qValue)
  if int(inputLength) != 2 + n + 4 * q: return -1
  for i in 0..<n:
    if input[2 + i] < -ValueLimit or input[2 + i] > ValueLimit: return -1
  let operationOffset = 2 + n
  for i in 0..<q:
    let offset = operationOffset + 4 * i
    let op = input[offset]
    let left = input[offset + 1]
    let right = input[offset + 2]
    let arg = input[offset + 3]
    if op < 0 or op > 3 or left < 0 or right <= left or right > nValue: return -1
    if op < 2:
      if arg < -ValueLimit or arg > ValueLimit: return -1
    elif arg != 0: return -1

  var tree: array[TreeSize, ShNode]
  var staged: array[MaxQ, int64]
  var answerCount = 0
  shBuild(tree, input, 1, 0, n)
  for i in 0..<q:
    let offset = operationOffset + 4 * i
    let op = int(input[offset])
    let left = int(input[offset + 1])
    let right = int(input[offset + 2])
    if op < 2: shUpdate(tree, 1, 0, n, left, right, op == 0, input[offset + 3])
    else:
      staged[answerCount] = shQuery(tree, 1, 0, n, left, right, op == 3)
      inc answerCount
  let outputBytes = 8 * answerCount
  if output == nil or outputCapacity < outputBytes.csize_t: return -2
  for i in 0..<answerCount: shWriteI64(output, 8 * i, staged[i])
  int64(outputBytes)
