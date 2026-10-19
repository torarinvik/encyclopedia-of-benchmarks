const
  MaxLevel = 12
  MaxNodes = (1 shl MaxLevel) - 1
  AdditionPasses = 100

type
  Node = object
    value: int32
    left: int32
    right: int32

proc allocateTree(nodes: var array[MaxNodes, Node], used: var int,
    level, lo, procCount: int32): int32 =
  if level == 0 or used >= MaxNodes: return -1
  let index = int32(used)
  inc used
  nodes[int(index)].value = 1
  let left = allocateTree(nodes, used, level - 1, lo + procCount div 2, procCount div 2)
  let right = allocateTree(nodes, used, level - 1, lo, procCount div 2)
  nodes[int(index)].left = left
  nodes[int(index)].right = right
  index

proc treeAdd(nodes: openArray[Node], index: int32): int64 =
  if index < 0: return 0
  let node = nodes[int(index)]
  int64(node.value) + treeAdd(nodes, node.left) + treeAdd(nodes, node.right)

proc treeadd*(level: int64): int64 {.cdecl, exportc: "treeadd".} =
  if level < 0 or level > int64(MaxLevel): return -1
  var nodes: array[MaxNodes, Node]
  var used = 0
  let root = allocateTree(nodes, used, int32(level), 0, 4)
  var result = 0'i64
  for _ in 0 ..< AdditionPasses:
    result = treeAdd(nodes, root)
  result
