const MaxN = 32
const MaxQ = 64
const MaxInput = 3 * MaxN + 5 * MaxQ + 1
const MaxValue = 1000'i64

type LctNode = object
  left, right, parent: int
  reversed: bool
  value, virtualSum, sum: int64

proc isAuxRoot(nodes: var array[MaxN, LctNode], x: int): bool =
  let p = nodes[x].parent
  p < 0 or (nodes[p].left != x and nodes[p].right != x)

proc nodeSum(nodes: var array[MaxN, LctNode], x: int): int64 =
  if x < 0: return 0
  nodes[x].sum

proc pull(nodes: var array[MaxN, LctNode], x: int) =
  nodes[x].sum = nodes[x].value + nodes[x].virtualSum + nodeSum(nodes, nodes[x].left) + nodeSum(nodes, nodes[x].right)

proc toggleReverse(nodes: var array[MaxN, LctNode], x: int) =
  if x < 0: return
  swap(nodes[x].left, nodes[x].right)
  nodes[x].reversed = not nodes[x].reversed

proc push(nodes: var array[MaxN, LctNode], x: int) =
  if not nodes[x].reversed: return
  toggleReverse(nodes, nodes[x].left)
  toggleReverse(nodes, nodes[x].right)
  nodes[x].reversed = false

proc rotate(nodes: var array[MaxN, LctNode], x: int) =
  let p = nodes[x].parent
  let g = nodes[p].parent
  let rightChild = nodes[p].right == x
  let middle = if rightChild: nodes[x].left else: nodes[x].right
  if not isAuxRoot(nodes, p):
    if nodes[g].left == p: nodes[g].left = x else: nodes[g].right = x
  nodes[x].parent = g
  if rightChild:
    nodes[x].left = p
    nodes[p].right = middle
  else:
    nodes[x].right = p
    nodes[p].left = middle
  nodes[p].parent = x
  if middle >= 0: nodes[middle].parent = p
  pull(nodes, p)
  pull(nodes, x)

proc splay(nodes: var array[MaxN, LctNode], x: int) =
  var stack: array[MaxN, int]
  var count = 0
  var y = x
  stack[count] = y
  inc count
  while not isAuxRoot(nodes, y):
    y = nodes[y].parent
    stack[count] = y
    inc count
  while count > 0:
    dec count
    push(nodes, stack[count])
  while not isAuxRoot(nodes, x):
    let p = nodes[x].parent
    if not isAuxRoot(nodes, p):
      let g = nodes[p].parent
      let zigZig = (nodes[p].left == x) == (nodes[g].left == p)
      rotate(nodes, if zigZig: p else: x)
    rotate(nodes, x)

proc access(nodes: var array[MaxN, LctNode], x: int) =
  var last = -1
  var y = x
  while y >= 0:
    splay(nodes, y)
    let oldRight = nodes[y].right
    nodes[y].virtualSum += nodeSum(nodes, oldRight) - nodeSum(nodes, last)
    nodes[y].right = last
    if last >= 0: nodes[last].parent = y
    pull(nodes, y)
    last = y
    y = nodes[y].parent
  splay(nodes, x)

proc makeRoot(nodes: var array[MaxN, LctNode], x: int) =
  access(nodes, x)
  toggleReverse(nodes, x)

proc findRoot(nodes: var array[MaxN, LctNode], x: int): int =
  access(nodes, x)
  push(nodes, x)
  var root = x
  while nodes[root].left >= 0:
    root = nodes[root].left
    push(nodes, root)
  splay(nodes, root)
  root

proc linkNodes(nodes: var array[MaxN, LctNode], u, v: int): bool =
  if u == v: return false
  makeRoot(nodes, u)
  if findRoot(nodes, v) == u: return false
  access(nodes, v)
  nodes[u].parent = v
  nodes[v].virtualSum += nodes[u].sum
  pull(nodes, v)
  true

proc cutNodes(nodes: var array[MaxN, LctNode], u, v: int): bool =
  if u == v: return false
  makeRoot(nodes, u)
  access(nodes, v)
  if nodes[v].left != u or nodes[u].right >= 0: return false
  nodes[v].left = -1
  nodes[u].parent = -1
  pull(nodes, v)
  true

proc subtreeSideSum(nodes: var array[MaxN, LctNode], vertex, parent: int): int64 =
  makeRoot(nodes, parent)
  access(nodes, vertex)
  if nodes[vertex].left != parent or nodes[parent].right >= 0: return -1
  nodes[vertex].value + nodes[vertex].virtualSum

proc putI64(output: ptr UncheckedArray[uint8], offset: int, value: int64) =
  let bits = cast[uint64](value)
  for byte in 0..<8: output[offset + byte] = uint8((bits shr (8 * byte)) and 255)

proc dynamic_tree_vertex_add_subtree_sum*(input: ptr UncheckedArray[int64], inputLength: csize_t,
                    output: ptr UncheckedArray[uint8], outputCapacity: csize_t): int64
                    {.cdecl, exportc: "dynamic_tree_vertex_add_subtree_sum".} =
  if input == nil or inputLength < 3 or inputLength > MaxInput.csize_t: return -1
  let nValue = input[0]
  let qValue = input[1]
  if nValue < 1 or nValue > MaxN.int64 or qValue < 0 or qValue > MaxQ.int64: return -1
  let n = int(nValue)
  let q = int(qValue)
  if int(inputLength) != 3 * n + 5 * q: return -1
  for i in 0..<n:
    if input[2 + i] < 0 or input[2 + i] > MaxValue: return -1
  let edgeStart = 2 + n
  let operationStart = edgeStart + 2 * (n - 1)
  for i in 0 ..< (n - 1):
    let u = input[edgeStart + 2 * i]
    let v = input[edgeStart + 2 * i + 1]
    if u < 0 or u >= nValue or v < 0 or v >= nValue or u == v: return -1
  for i in 0..<q:
    let at = operationStart + 5 * i
    let kind = input[at]
    let a = input[at + 1]
    let b = input[at + 2]
    let c = input[at + 3]
    let d = input[at + 4]
    if kind == 0:
      if a < 0 or a >= nValue or b < 0 or b >= nValue or c < 0 or c >= nValue or d < 0 or d >= nValue or a == b or c == d: return -1
    elif kind == 1:
      if a < 0 or a >= nValue or b < 0 or b > MaxValue or c != 0 or d != 0: return -1
    elif kind == 2:
      if a < 0 or a >= nValue or b < 0 or b >= nValue or c != 0 or d != 0: return -1
    else: return -1

  var nodes: array[MaxN, LctNode]
  for i in 0..<n:
    nodes[i].left = -1
    nodes[i].right = -1
    nodes[i].parent = -1
    nodes[i].value = input[2 + i]
    nodes[i].sum = nodes[i].value
  for i in 0 ..< (n - 1):
    if not linkNodes(nodes, int(input[edgeStart + 2 * i]), int(input[edgeStart + 2 * i + 1])): return -1
  var answers: array[MaxQ, int64]
  var answerCount = 0
  for i in 0..<q:
    let at = operationStart + 5 * i
    let kind = int(input[at])
    let a = int(input[at + 1])
    let b = int(input[at + 2])
    if kind == 0:
      let c = int(input[at + 3])
      let d = int(input[at + 4])
      if not cutNodes(nodes, a, b) or not linkNodes(nodes, c, d): return -1
    elif kind == 1:
      access(nodes, a)
      nodes[a].value += int64(b)
      pull(nodes, a)
    else:
      let answer = subtreeSideSum(nodes, a, b)
      if answer < 0: return -1
      answers[answerCount] = answer
      inc answerCount
  let outputBytes = answerCount * 8
  if outputBytes > 0 and (output == nil or int(outputCapacity) < outputBytes): return -2
  for i in 0..<answerCount: putI64(output, 8 * i, answers[i])
  int64(outputBytes)
