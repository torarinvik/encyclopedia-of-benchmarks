const MinRuns = 1'i64
const MaxRuns = 100'i64
const ElementCount = 5000
const MaxOutputBytes = 700

type TreeNode = object
  value: int32
  left: int32
  right: int32

proc nextRandom(seed: var int64): int32 =
  seed = (seed * 1309 + 13849) mod 65536
  int32(seed)
proc validateTree(nodes: var array[ElementCount, TreeNode], root: int): bool =
  let node = nodes[root]
  if node.left != -1:
    let child = nodes[int(node.left)]
    if child.value <= node.value or not validateTree(nodes, int(node.left)): return false
  if node.right != -1:
    let child = nodes[int(node.right)]
    if child.value >= node.value or not validateTree(nodes, int(node.right)): return false
  true
proc buildAndCheckPass(selectedRun: int): tuple[value: int32, valid: bool] =
  var values: array[ElementCount, int32]
  var nodes: array[ElementCount, TreeNode]
  var seed = 74755'i64
  for index in 0 ..< ElementCount:
    let temp = nextRandom(seed)
    values[index] = temp - (temp div 100000) * 100000 - 50000
  nodes[0] = TreeNode(value: values[0], left: -1, right: -1)
  var used = 1
  for index in 1 ..< ElementCount:
    var current = 0
    while true:
      if values[index] > nodes[current].value:
        if nodes[current].left == -1:
          nodes[current].left = int32(used)
          nodes[used] = TreeNode(value: values[index], left: -1, right: -1)
          inc used
          break
        current = int(nodes[current].left)
      elif values[index] < nodes[current].value:
        if nodes[current].right == -1:
          nodes[current].right = int32(used)
          nodes[used] = TreeNode(value: values[index], left: -1, right: -1)
          inc used
          break
        current = int(nodes[current].right)
      else:
        break
  (values[selectedRun + 1], validateTree(nodes, 0))
proc appendText(buffer: var array[MaxOutputBytes, uint8], used: var int, text: string) =
  for ch in text: buffer[used] = uint8(ord(ch)); inc used
proc appendInteger(buffer: var array[MaxOutputBytes, uint8], used: var int, value: int32) =
  var remaining = value
  if remaining < 0: buffer[used] = uint8(ord('-')); inc used; remaining = -remaining
  var reverse: array[12, uint8]
  var count = 0
  while true:
    reverse[count] = uint8(48 + remaining mod 10); inc count
    remaining = remaining div 10
    if remaining == 0: break
  while count > 0: dec count; buffer[used] = reverse[count]; inc used

proc stanford_treesort*(runs: int64, output: ptr UncheckedArray[uint8], outputCapacity: csize_t): int64 {.cdecl, exportc: "stanford_treesort".} =
  if runs < MinRuns or runs > MaxRuns: return -1
  if output.isNil: return -2
  var staged: array[MaxOutputBytes, uint8]
  var used = 0
  for run in 0 ..< int(runs):
    let item = buildAndCheckPass(run)
    appendInteger(staged, used, item.value); appendText(staged, used, "\n")
    if not item.valid: appendText(staged, used, " Error in Tree.\n")
  if outputCapacity < csize_t(used): return -2
  for index in 0 ..< used: output[index] = staged[index]
  int64(used)
