const MaxN = 20
const MaxM = 32
const MaxInput = 35
const MaxNodes = 128
const MaxOutput = 648
const Leaf = 0'u8
const PNode = 1'u8
const QNode = 2'u8
const White = 0'u8
const Black = 1'u8
const Mixed = 2'u8

type
  PqNode = object
    kind, arg: uint8
    count: int
    child: array[MaxN, uint8]
  PqTree = object
    nodes: array[MaxNodes, PqNode]
    color, freeId: array[MaxNodes, uint8]
    nextId, freeCount, root: int

proc newNode(t: var PqTree, kind: uint8): int =
  var id: int
  if t.freeCount > 0:
    dec t.freeCount
    id = int(t.freeId[t.freeCount])
  else:
    if t.nextId >= MaxNodes: return -1
    id = t.nextId
    inc t.nextId
  t.nodes[id] = PqNode()
  t.nodes[id].kind = kind
  id

proc deleteNode(t: var PqTree, id: int) =
  t.nodes[id].count = 0
  t.freeId[t.freeCount] = uint8(id)
  inc t.freeCount

proc push(t: var PqTree, id, child: int) =
  t.nodes[id].child[t.nodes[id].count] = uint8(child)
  inc t.nodes[id].count

proc paint(t: var PqTree, id: int, mask: uint64): uint8 =
  let node = t.nodes[id]
  if node.kind == Leaf:
    t.color[id] = if ((mask shr node.arg) and 1) != 0: Black else: White
    return t.color[id]
  var sawWhite = false
  var sawBlack = false
  for i in 0 ..< node.count:
    let shade = paint(t, int(node.child[i]), mask)
    sawWhite = sawWhite or shade != Black
    sawBlack = sawBlack or shade != White
  t.color[id] = if sawWhite and sawBlack: Mixed elif sawBlack: Black else: White
  t.color[id]

proc qPattern(t: PqTree, children: array[MaxN, uint8], count: int): bool =
  var pivot = -1
  var mixed = 0
  for i in 0 ..< count:
    if t.color[int(children[i])] == Mixed:
      pivot = i
      inc mixed
      if mixed > 1: return false
  if mixed == 0:
    for i in 0 ..< count:
      if t.color[int(children[i])] == Black:
        pivot = i
        break
  if pivot < 0: return false
  for i in 0 ..< pivot:
    if t.color[int(children[i])] != White: return false
  for i in pivot + 1 ..< count:
    if t.color[int(children[i])] != Black: return false
  true

proc split(t: var PqTree, id: int, output: var array[MaxN, uint8]): int =
  let node = t.nodes[id]
  if t.color[id] != Mixed:
    output[0] = uint8(id)
    return 1
  var old = node.child
  var white, black, mixed: array[MaxN, uint8]
  var nw = 0
  var nb = 0
  var nm = 0
  var used = 0
  for i in 0 ..< node.count:
    let child = old[i]
    case t.color[int(child)]
    of White: white[nw] = child; inc nw
    of Black: black[nb] = child; inc nb
    else: mixed[nm] = child; inc nm
  if node.kind == QNode:
    if not qPattern(t, old, node.count):
      for left in 0 ..< node.count div 2:
        swap old[left], old[node.count - 1 - left]
      if not qPattern(t, old, node.count): return -1
    for i in 0 ..< node.count:
      let child = int(old[i])
      if t.color[child] == Mixed:
        var part: array[MaxN, uint8]
        let partCount = split(t, child, part)
        if partCount < 0: return -1
        for j in 0 ..< partCount: output[used] = part[j]; inc used
      else:
        output[used] = old[i]
        inc used
  else:
    if nm > 1: return -1
    if nw > 0:
      let group = newNode(t, PNode)
      if group < 0: return -1
      for i in 0 ..< nw: push(t, group, int(white[i]))
      output[used] = uint8(group)
      inc used
    if nm > 0:
      var part: array[MaxN, uint8]
      let partCount = split(t, int(mixed[0]), part)
      if partCount < 0: return -1
      for i in 0 ..< partCount: output[used] = part[i]; inc used
    if nb > 0:
      let group = newNode(t, PNode)
      if group < 0: return -1
      for i in 0 ..< nb: push(t, group, int(black[i]))
      output[used] = uint8(group)
      inc used
  deleteNode(t, id)
  used

proc work(t: var PqTree, id: int): bool =
  let node = t.nodes[id]
  if t.color[id] != Mixed: return true
  var old, white, black, mixed: array[MaxN, uint8]
  var nw = 0
  var nb = 0
  var nm = 0
  for i in 0 ..< node.count:
    old[i] = node.child[i]
    case t.color[int(old[i])]
    of White: white[nw] = old[i]; inc nw
    of Black: black[nb] = old[i]; inc nb
    else: mixed[nm] = old[i]; inc nm
  if node.kind == PNode:
    if nb == 0 and nm == 1: return work(t, int(mixed[0]))
    if nm > 2: return false
    let q = newNode(t, QNode)
    if q < 0: return false
    for i in 0 ..< nw: t.nodes[id].child[i] = white[i]
    t.nodes[id].child[nw] = uint8(q)
    t.nodes[id].count = nw + 1
    if nm > 0:
      var part: array[MaxN, uint8]
      let partCount = split(t, int(mixed[0]), part)
      if partCount < 0: return false
      for i in 0 ..< partCount: push(t, q, int(part[i]))
    if nb > 0:
      let group = newNode(t, PNode)
      if group < 0: return false
      for i in 0 ..< nb: push(t, group, int(black[i]))
      push(t, q, group)
    if nm == 2:
      var part: array[MaxN, uint8]
      let partCount = split(t, int(mixed[1]), part)
      if partCount < 0: return false
      for i in countdown(partCount - 1, 0): push(t, q, int(part[i]))
    return true
  var left = -1
  var right = -1
  for i in 0 ..< node.count:
    if t.color[int(old[i])] != White:
      if left < 0: left = i
      right = i
  if left < 0: return false
  for i in left + 1 ..< right:
    if t.color[int(old[i])] != Black: return false
  if left == right and t.color[int(old[left])] == Mixed: return work(t, int(old[left]))
  var result: array[MaxN, uint8]
  var used = 0
  for i in 0 ..< left: result[used] = old[i]; inc used
  var part: array[MaxN, uint8]
  var partCount = split(t, int(old[left]), part)
  if partCount < 0: return false
  for i in 0 ..< partCount: result[used] = part[i]; inc used
  for i in left + 1 ..< right: result[used] = old[i]; inc used
  if right != left:
    partCount = split(t, int(old[right]), part)
    if partCount < 0: return false
    for i in countdown(partCount - 1, 0): result[used] = part[i]; inc used
  for i in right + 1 ..< node.count: result[used] = old[i]; inc used
  t.nodes[id].count = used
  for i in 0 ..< used: t.nodes[id].child[i] = result[i]
  true

proc normalize(t: var PqTree, id: int): int =
  let node = t.nodes[id]
  if node.kind == Leaf: return id
  for i in 0 ..< node.count: t.nodes[id].child[i] = uint8(normalize(t, int(node.child[i])))
  if t.nodes[id].count == 1:
    let child = int(t.nodes[id].child[0])
    deleteNode(t, id)
    return child
  if t.nodes[id].kind == QNode and t.nodes[id].count == 2: t.nodes[id].kind = PNode
  id

proc compareNodes(t: PqTree, a, b: int): int =
  let x = t.nodes[a]
  let y = t.nodes[b]
  let xa = if x.kind == Leaf: int(x.arg) else: x.count
  let ya = if y.kind == Leaf: int(y.arg) else: y.count
  if x.kind != y.kind: return if x.kind < y.kind: -1 else: 1
  if xa != ya: return if xa < ya: -1 else: 1
  if x.kind != Leaf:
    for i in 0 ..< x.count:
      let comparison = compareNodes(t, int(x.child[i]), int(y.child[i]))
      if comparison != 0: return comparison
  0

proc canonicalize(t: var PqTree, id: int) =
  let node = t.nodes[id]
  if node.kind == Leaf: return
  for i in 0 ..< node.count: canonicalize(t, int(node.child[i]))
  if node.kind == PNode:
    for i in 1 ..< node.count:
      let item = t.nodes[id].child[i]
      var j = i
      while j > 0 and compareNodes(t, int(item), int(t.nodes[id].child[j - 1])) < 0:
        t.nodes[id].child[j] = t.nodes[id].child[j - 1]
        dec j
      t.nodes[id].child[j] = item
  else:
    var order = 0
    for i in 0 ..< node.count:
      order = compareNodes(t, int(node.child[i]), int(node.child[node.count - 1 - i]))
      if order != 0: break
    if order > 0:
      for left in 0 ..< node.count div 2: swap t.nodes[id].child[left], t.nodes[id].child[node.count - 1 - left]

proc frontierCount(t: PqTree, id: int): int64 =
  let node = t.nodes[id]
  if node.kind == Leaf: return 1
  var result = 1'i64
  for i in 0 ..< node.count: result *= frontierCount(t, int(node.child[i]))
  if node.kind == PNode:
    for factor in 2 .. node.count: result *= int64(factor)
  else: result *= 2
  result

proc nodeCount(t: PqTree, id: int): int =
  let node = t.nodes[id]
  result = 1
  if node.kind != Leaf:
    for i in 0 ..< node.count: result += nodeCount(t, int(node.child[i]))

proc serialize(t: PqTree, id: int, words: var array[81, int64], used: var int) =
  let node = t.nodes[id]
  words[used] = int64(node.kind); inc used
  words[used] = if node.kind == Leaf: int64(node.arg) else: int64(node.count); inc used
  if node.kind != Leaf:
    for i in 0 ..< node.count: serialize(t, int(node.child[i]), words, used)

proc storeI64(output: ptr UncheckedArray[uint8], offset: int, value: int64) =
  let bits = cast[uint64](value)
  for i in 0 ..< 8: output[offset + i] = uint8((bits shr (8 * i)) and 255)

proc pq_tree_consecutive_ones*(input: ptr UncheckedArray[int64], length: csize_t,
    output: ptr UncheckedArray[uint8], capacity: csize_t): int64
    {.cdecl, exportc: "pq_tree_consecutive_ones".} =
  if input.isNil or length < csize_t(2) or length > csize_t(MaxInput): return -1
  let nRaw = input[0]
  let mRaw = input[1]
  if nRaw < 2 or nRaw > MaxN or mRaw < 0 or mRaw > MaxM or length != csize_t(2 + mRaw): return -1
  let n = int(nRaw)
  let m = int(mRaw)
  let validMask = (1'u64 shl n) - 1'u64
  for row in 0 ..< m:
    let raw = input[2 + row]
    if raw < 0 or (cast[uint64](raw) and not validMask) != 0: return -1
  var tree = PqTree()
  tree.nextId = n + 1
  tree.root = n
  for i in 0 ..< n:
    tree.nodes[i].kind = Leaf
    tree.nodes[i].arg = uint8(i)
    tree.nodes[n].child[i] = uint8(i)
  tree.nodes[n].kind = PNode
  tree.nodes[n].count = n
  for row in 0 ..< m:
    discard paint(tree, tree.root, cast[uint64](input[2 + row]))
    if not work(tree, tree.root):
      if output.isNil or capacity < csize_t(24): return -2
      for i in 0 ..< 24: output[i] = 0
      return 24
    tree.root = normalize(tree, tree.root)
  canonicalize(tree, tree.root)
  var words: array[81, int64]
  var used = 0
  words[used] = 1; inc used
  words[used] = frontierCount(tree, tree.root); inc used
  words[used] = int64(nodeCount(tree, tree.root)); inc used
  serialize(tree, tree.root, words, used)
  var staged: array[MaxOutput, uint8]
  for i in 0 ..< used: storeI64(addr staged[0], i * 8, words[i])
  let bytes = used * 8
  if output.isNil or capacity < csize_t(bytes): return -2
  for i in 0 ..< bytes: output[i] = staged[i]
  int64(bytes)
