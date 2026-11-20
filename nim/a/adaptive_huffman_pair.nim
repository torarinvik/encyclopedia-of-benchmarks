const Alphabet = 16
const MaxNodes = 31
const MaxSymbols = 64
const MaxInput = 66
const MaxPacked = 152
const NytKind = 0
const LeafKind = 1
const InternalKind = 2

type
  Node = object
    parent, left, right, symbol, kind: int
    weight: int64
  Tree = object
    nodes: array[MaxNodes, Node]
    nodeCount, root, nyt: int
    leafOf: array[Alphabet, int]
    fgkOrder: array[MaxNodes, int]
    orderCount: int
    packed: array[MaxPacked, uint8]
    bitCount: int
  OrderedNode = object
    id, depth, path: int

proc emitBit(tree: var Tree, bit: int) =
  if bit != 0:
    tree.packed[tree.bitCount div 8] = tree.packed[tree.bitCount div 8] or
      uint8(1 shl (7 - tree.bitCount mod 8))
  inc tree.bitCount

proc emitValue(tree: var Tree, value, width: int) =
  for shift in countdown(width - 1, 0): tree.emitBit((value shr shift) and 1)

proc encodePath(tree: var Tree, node0: int) =
  var reversePath: array[MaxNodes, int]
  var depth = 0
  var node = node0
  while node != tree.root:
    let parent = tree.nodes[node].parent
    reversePath[depth] = ord(tree.nodes[parent].right == node)
    inc depth
    node = parent
  while depth > 0:
    dec depth
    tree.emitBit(reversePath[depth])

proc isAncestor(tree: Tree, ancestor, node: int): bool =
  var parent = tree.nodes[node].parent
  while parent >= 0:
    if parent == ancestor: return true
    parent = tree.nodes[parent].parent
  false

proc replaceChild(tree: var Tree, parent, oldChild, newChild: int) =
  if tree.nodes[parent].left == oldChild: tree.nodes[parent].left = newChild
  elif tree.nodes[parent].right == oldChild: tree.nodes[parent].right = newChild

proc swapPositions(tree: var Tree, a, b: int, updateOrder: bool) =
  if a == b or tree.nodes[a].parent == b or tree.nodes[b].parent == a or
      tree.isAncestor(a, b) or tree.isAncestor(b, a): return
  let parentA = tree.nodes[a].parent
  let parentB = tree.nodes[b].parent
  if parentA == parentB:
    if parentA >= 0: swap(tree.nodes[parentA].left, tree.nodes[parentA].right)
  else:
    if parentA >= 0: tree.replaceChild(parentA, a, b)
    if parentB >= 0: tree.replaceChild(parentB, b, a)
    tree.nodes[a].parent = parentB
    tree.nodes[b].parent = parentA
  if tree.root == a: tree.root = b
  elif tree.root == b: tree.root = a
  if updateOrder:
    var ra = -1
    var rb = -1
    for i in 0 ..< tree.orderCount:
      if tree.fgkOrder[i] == a: ra = i
      if tree.fgkOrder[i] == b: rb = i
    if ra >= 0 and rb >= 0: swap(tree.fgkOrder[ra], tree.fgkOrder[rb])

proc initialize(tree: var Tree) =
  tree = default(Tree)
  tree.nodeCount = 1
  tree.root = 0
  tree.nyt = 0
  tree.nodes[0] = Node(parent: -1, left: -1, right: -1, symbol: -1, kind: NytKind)
  tree.fgkOrder[0] = 0
  tree.orderCount = 1
  for i in 0 ..< Alphabet: tree.leafOf[i] = -1

proc addNode(tree: var Tree, parent, kind, symbol: int): int =
  result = tree.nodeCount
  inc tree.nodeCount
  tree.nodes[result] = Node(parent: parent, left: -1, right: -1, symbol: symbol, kind: kind)

proc splitNyt(tree: var Tree, symbol: int, remaining, forFgk: bool): int =
  let old = tree.nyt
  if not remaining:
    tree.nodes[old].kind = LeafKind
    tree.nodes[old].symbol = symbol
    tree.leafOf[symbol] = old
    tree.nyt = -1
    return old
  let left = tree.addNode(old, NytKind, -1)
  let right = tree.addNode(old, LeafKind, symbol)
  tree.nodes[old].kind = InternalKind
  tree.nodes[old].left = left
  tree.nodes[old].right = right
  tree.leafOf[symbol] = right
  tree.nyt = left
  if forFgk:
    var position = 0
    while tree.fgkOrder[position] != old: inc position
    for i in countdown(tree.orderCount + 1, position + 3):
      tree.fgkOrder[i] = tree.fgkOrder[i - 2]
    tree.fgkOrder[position] = left
    tree.fgkOrder[position + 1] = right
    tree.fgkOrder[position + 2] = old
    tree.orderCount += 2
  right

proc fgkLeader(tree: Tree, node: int, leavesOnly: bool): int =
  let weight = tree.nodes[node].weight
  let parent = tree.nodes[node].parent
  for i in countdown(tree.orderCount - 1, 0):
    let candidate = tree.fgkOrder[i]
    if candidate == parent or tree.nodes[candidate].weight != weight or
        (leavesOnly and tree.nodes[candidate].kind == InternalKind) or
        tree.isAncestor(candidate, node) or tree.isAncestor(node, candidate): continue
    return candidate
  node

proc updateFgk(tree: var Tree, node0: int) =
  var node = node0
  let parent = tree.nodes[node].parent
  if tree.nyt >= 0 and parent >= 0 and tree.nodes[tree.nyt].parent == parent:
    tree.swapPositions(node, tree.fgkLeader(node, true), true)
    inc tree.nodes[node].weight
    node = tree.nodes[node].parent
  while node != tree.root:
    tree.swapPositions(node, tree.fgkLeader(node, false), true)
    inc tree.nodes[node].weight
    node = tree.nodes[node].parent
  inc tree.nodes[tree.root].weight

proc implicitOrder(tree: Tree, order: var array[MaxNodes, OrderedNode]): int =
  for id in 0 ..< tree.nodeCount:
    var reversePath: array[MaxNodes, int]
    var depth = 0
    var at = id
    var path = 0
    while at != tree.root:
      let parent = tree.nodes[at].parent
      reversePath[depth] = ord(tree.nodes[parent].right == at)
      inc depth
      at = parent
    for i in countdown(depth - 1, 0): path = path * 2 + reversePath[i]
    order[id] = OrderedNode(id: id, depth: depth, path: path)
  for i in 1 ..< tree.nodeCount:
    let value = order[i]
    var j = i
    while j > 0 and (order[j - 1].depth < value.depth or
        (order[j - 1].depth == value.depth and order[j - 1].path > value.path)):
      order[j] = order[j - 1]
      dec j
    order[j] = value
  tree.nodeCount

proc vitterLeader(tree: Tree, node: int, order: var array[MaxNodes, OrderedNode]): int =
  let count = tree.implicitOrder(order)
  for i in countdown(count - 1, 0):
    let candidate = order[i].id
    if tree.nodes[candidate].weight == tree.nodes[node].weight and
        tree.nodes[candidate].kind == tree.nodes[node].kind: return candidate
  node

proc slideIncrement(tree: var Tree, node: int, order: var array[MaxNodes, OrderedNode]): int =
  let oldParent = tree.nodes[node].parent
  let targetKind = if tree.nodes[node].kind == LeafKind: InternalKind else: LeafKind
  let targetWeight = tree.nodes[node].weight + int64(if tree.nodes[node].kind == LeafKind: 0 else: 1)
  let count = tree.implicitOrder(order)
  var blockNodes: array[MaxNodes, int]
  var blockCount = 0
  for i in 0 ..< count:
    let candidate = order[i].id
    if tree.nodes[candidate].kind == targetKind and tree.nodes[candidate].weight == targetWeight:
      blockNodes[blockCount] = candidate
      inc blockCount
  for i in 0 ..< blockCount: tree.swapPositions(node, blockNodes[i], false)
  inc tree.nodes[node].weight
  if tree.nodes[node].kind == LeafKind: tree.nodes[node].parent else: oldParent

proc updateVitter(tree: var Tree, node0: int, justSplit: bool) =
  var node = node0
  var order: array[MaxNodes, OrderedNode]
  var leafToIncrement = -1
  if justSplit:
    leafToIncrement = node
    node = tree.nodes[node].parent
  else:
    tree.swapPositions(node, tree.vitterLeader(node, order), false)
    let parent = tree.nodes[node].parent
    if tree.nyt >= 0 and parent >= 0 and tree.nodes[tree.nyt].parent == parent:
      leafToIncrement = node
      node = parent
  while node != tree.root: node = tree.slideIncrement(node, order)
  if leafToIncrement >= 0: discard tree.slideIncrement(leafToIncrement, order)
  inc tree.nodes[tree.root].weight

proc run(input: ptr UncheckedArray[int64], length: csize_t, output: ptr UncheckedArray[uint8],
         capacity: csize_t, vitter: bool): int64 =
  if input == nil or length < 1 or length > csize_t(MaxInput): return -1
  let size = input[0]
  if size < 0 or size > MaxSymbols or int(length) != 1 + int(size): return -1
  for i in 0 ..< int(size):
    if input[i + 1] < 0 or input[i + 1] >= int64(Alphabet): return -1
  var tree: Tree
  tree.initialize()
  var seen = 0
  for i in 0 ..< int(size):
    let symbol = int(input[i + 1])
    let isNew = tree.leafOf[symbol] < 0
    var current = if isNew: tree.nyt else: tree.leafOf[symbol]
    if current < 0: return -1
    tree.encodePath(current)
    if isNew: tree.emitValue(symbol, 4)
    var justSplit = false
    if isNew:
      inc seen
      justSplit = seen < Alphabet
      current = tree.splitNyt(symbol, justSplit, not vitter)
    if vitter: tree.updateVitter(current, justSplit)
    else: tree.updateFgk(current)
  let packed = (tree.bitCount + 7) div 8
  let required = 8 + packed
  if output == nil or int(capacity) < required: return -2
  let count = uint64(tree.bitCount)
  for i in 0 ..< 8: output[i] = uint8((count shr (8 * i)) and 255)
  for i in 0 ..< packed: output[8 + i] = tree.packed[i]
  int64(required)

proc fgkAdaptiveHuffman*(input: ptr UncheckedArray[int64], length: csize_t,
                         output: ptr UncheckedArray[uint8], capacity: csize_t): int64
    {.cdecl, exportc: "fgk_adaptive_huffman".} = run(input, length, output, capacity, false)

proc vitterAdaptiveHuffman*(input: ptr UncheckedArray[int64], length: csize_t,
                            output: ptr UncheckedArray[uint8], capacity: csize_t): int64
    {.cdecl, exportc: "vitter_adaptive_huffman".} = run(input, length, output, capacity, true)
