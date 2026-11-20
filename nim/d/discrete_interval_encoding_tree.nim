const
  MaxQ = 32
  Arena = 64
  MinKey = -15'i64
  MaxKey = 15'i64

type DietNode = object
  lo: int64
  hi: int64
  left: int
  right: int

proc newNode(nodes: var array[Arena, DietNode], used: var int,
             lo, hi: int64, left = -1, right = -1): int =
  result = used
  nodes[result] = DietNode(lo: lo, hi: hi, left: left, right: right)
  inc used

proc popMax(nodes: var array[Arena, DietNode], root: int): tuple[root: int, lo, hi: int64] =
  if nodes[root].right < 0:
    return (nodes[root].left, nodes[root].lo, nodes[root].hi)
  let popped = popMax(nodes, nodes[root].right)
  nodes[root].right = popped.root
  (root, popped.lo, popped.hi)

proc popMin(nodes: var array[Arena, DietNode], root: int): tuple[root: int, lo, hi: int64] =
  if nodes[root].left < 0:
    return (nodes[root].right, nodes[root].lo, nodes[root].hi)
  let popped = popMin(nodes, nodes[root].left)
  nodes[root].left = popped.root
  (root, popped.lo, popped.hi)

proc maximumInterval(nodes: var array[Arena, DietNode], rootInput: int): tuple[lo, hi: int64] =
  var root = rootInput
  while nodes[root].right >= 0: root = nodes[root].right
  (nodes[root].lo, nodes[root].hi)

proc minimumInterval(nodes: var array[Arena, DietNode], rootInput: int): tuple[lo, hi: int64] =
  var root = rootInput
  while nodes[root].left >= 0: root = nodes[root].left
  (nodes[root].lo, nodes[root].hi)

proc insertNode(nodes: var array[Arena, DietNode], used: var int, root: int, key: int64,
                intervalCount: var int, changed: var bool): int =
  if root < 0:
    inc intervalCount
    changed = true
    return newNode(nodes, used, key, key)
  if key < nodes[root].lo:
    if key + 1 == nodes[root].lo:
      nodes[root].lo = key
      changed = true
      if nodes[root].left >= 0:
        let pred = maximumInterval(nodes, nodes[root].left)
        if pred.hi + 1 == key:
          let popped = popMax(nodes, nodes[root].left)
          nodes[root].left = popped.root
          nodes[root].lo = popped.lo
          dec intervalCount
    else:
      nodes[root].left = insertNode(nodes, used, nodes[root].left, key, intervalCount, changed)
    return root
  if key > nodes[root].hi:
    if key == nodes[root].hi + 1:
      nodes[root].hi = key
      changed = true
      if nodes[root].right >= 0:
        let succ = minimumInterval(nodes, nodes[root].right)
        if key + 1 == succ.lo:
          let popped = popMin(nodes, nodes[root].right)
          nodes[root].right = popped.root
          nodes[root].hi = popped.hi
          dec intervalCount
    else:
      nodes[root].right = insertNode(nodes, used, nodes[root].right, key, intervalCount, changed)
    return root
  changed = false
  root

proc eraseNode(nodes: var array[Arena, DietNode], used: var int, root: int, key: int64,
               intervalCount: var int, changed: var bool): int =
  if root < 0:
    changed = false
    return root
  if key < nodes[root].lo:
    nodes[root].left = eraseNode(nodes, used, nodes[root].left, key, intervalCount, changed)
    return root
  if key > nodes[root].hi:
    nodes[root].right = eraseNode(nodes, used, nodes[root].right, key, intervalCount, changed)
    return root
  changed = true
  if nodes[root].lo == nodes[root].hi:
    dec intervalCount
    if nodes[root].left < 0: return nodes[root].right
    if nodes[root].right < 0: return nodes[root].left
    let pred = popMax(nodes, nodes[root].left)
    nodes[root].left = pred.root
    nodes[root].lo = pred.lo
    nodes[root].hi = pred.hi
    return root
  if key == nodes[root].lo:
    inc nodes[root].lo
    return root
  if key == nodes[root].hi:
    dec nodes[root].hi
    return root
  let piece = newNode(nodes, used, key + 1, nodes[root].hi, -1, nodes[root].right)
  nodes[root].hi = key - 1
  nodes[root].right = piece
  inc intervalCount
  root

proc containsKey(nodes: var array[Arena, DietNode], rootInput: int, key: int64): bool =
  var root = rootInput
  while root >= 0:
    if key < nodes[root].lo: root = nodes[root].left
    elif key > nodes[root].hi: root = nodes[root].right
    else: return true
  false

proc validInput(input: ptr UncheckedArray[int64], length: int): int =
  if input.isNil or length < 1 or length > 2 + 2 * MaxQ: return -1
  let qValue = input[0]
  if qValue < 0 or qValue > MaxQ.int64: return -1
  let q = int(qValue)
  if length != 1 + 2 * q: return -1
  for op in 0 ..< q:
    let opcode = input[1 + 2 * op]
    let key = input[2 + 2 * op]
    if opcode < 0 or opcode > 2 or key < MinKey or key > MaxKey: return -1
  q

proc discrete_interval_encoding_tree*(input: ptr UncheckedArray[int64], length: csize_t,
    output: ptr UncheckedArray[uint8], capacity: csize_t): int64
    {.cdecl, exportc: "discrete_interval_encoding_tree".} =
  if input.isNil or length < 1 or length > csize_t(2 + 2 * MaxQ): return -1
  let q = validInput(input, int(length))
  if q < 0: return -1
  let required = q * 8
  if (required > 0 and output.isNil) or capacity < csize_t(required): return -2

  var nodes: array[Arena, DietNode]
  var used = 0
  var root = -1
  var cardinality = 0
  var intervalCount = 0
  var staged: array[MaxQ, int64]
  for op in 0 ..< q:
    let opcode = input[1 + 2 * op]
    let key = input[2 + 2 * op]
    var changed = false
    if opcode == 0:
      root = insertNode(nodes, used, root, key, intervalCount, changed)
      if changed: inc cardinality
    elif opcode == 1:
      root = eraseNode(nodes, used, root, key, intervalCount, changed)
      if changed: dec cardinality
    let present = if containsKey(nodes, root, key): 1 else: 0
    staged[op] = 64'i64 * int64(cardinality) + 2'i64 * int64(intervalCount) + int64(present)
  for op in 0 ..< q:
    let word = cast[uint64](staged[op])
    for byte in 0 ..< 8:
      output[8 * op + byte] = uint8((word shr (8 * byte)) and 0xff'u64)
  int64(required)
