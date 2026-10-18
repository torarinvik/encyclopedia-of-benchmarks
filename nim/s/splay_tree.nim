const MaxOps = 64
const MaxKeys = 32
const MaxInput = 130
const MaxOutput = 784

type Node = object
  key: int32
  left: int32
  right: int32

proc rotateRight(nodes: var array[MaxOps, Node], root: int32): int32 =
  let child = nodes[int(root)].left
  nodes[int(root)].left = nodes[int(child)].right
  nodes[int(child)].right = root
  child

proc rotateLeft(nodes: var array[MaxOps, Node], root: int32): int32 =
  let child = nodes[int(root)].right
  nodes[int(root)].right = nodes[int(child)].left
  nodes[int(child)].left = root
  child

proc splay(nodes: var array[MaxOps, Node], root: int32, key: int32): int32 =
  if root < 0 or nodes[int(root)].key == key: return root
  if key < nodes[int(root)].key:
    let left = nodes[int(root)].left
    if left < 0: return root
    if key < nodes[int(left)].key:
      nodes[int(left)].left = splay(nodes, nodes[int(left)].left, key)
      result = rotateRight(nodes, root)
    elif key > nodes[int(left)].key:
      nodes[int(left)].right = splay(nodes, nodes[int(left)].right, key)
      if nodes[int(left)].right >= 0: nodes[int(root)].left = rotateLeft(nodes, left)
      result = root
    else:
      result = root
    if nodes[int(result)].left < 0: return result
    return rotateRight(nodes, result)
  let right = nodes[int(root)].right
  if right < 0: return root
  if key > nodes[int(right)].key:
    nodes[int(right)].right = splay(nodes, nodes[int(right)].right, key)
    result = rotateLeft(nodes, root)
  elif key < nodes[int(right)].key:
    nodes[int(right)].left = splay(nodes, nodes[int(right)].left, key)
    if nodes[int(right)].left >= 0: nodes[int(root)].right = rotateRight(nodes, right)
    result = root
  else:
    result = root
  if nodes[int(result)].right < 0: return result
  rotateLeft(nodes, result)

proc inorder(nodes: array[MaxOps, Node], root: int32, keys: var array[MaxKeys, int64], count: var int) =
  if root < 0: return
  inorder(nodes, nodes[int(root)].left, keys, count)
  keys[count] = int64(nodes[int(root)].key)
  inc count
  inorder(nodes, nodes[int(root)].right, keys, count)

proc writeWord(output: var array[MaxOutput, uint8], offset: var int, word: int64) =
  let bits = cast[uint64](word)
  for shift in countup(0, 56, 8):
    output[offset] = uint8((bits shr shift) and 0xff'u64)
    inc offset

proc splay_tree*(input: ptr UncheckedArray[int64], inputLength: csize_t,
    output: ptr UncheckedArray[uint8], capacity: csize_t): int64 {.cdecl, exportc: "splay_tree".} =
  if input == nil or inputLength == 0 or inputLength > csize_t(MaxInput): return -1
  if input[0] < 0 or input[0] > MaxOps: return -1
  let opCount = int(input[0])
  if inputLength != csize_t(1 + 2 * opCount): return -1
  var ops, keys, tags: array[MaxOps, int64]
  var live: array[MaxKeys, int64]
  var liveCount = 0
  var offset = 1
  for i in 0 ..< opCount:
    let op = input[offset]
    let key = input[offset + 1]
    offset += 2
    if (op != 0 and op != 1 and op != 2) or key < int64(low(int32)) or key > int64(high(int32)): return -1
    ops[i] = op; keys[i] = key
    var found = liveCount
    for j in 0 ..< liveCount:
      if live[j] == key: found = j; break
    if op == 0:
      if found < liveCount or liveCount == MaxKeys: return -1
      live[liveCount] = key; inc liveCount
    elif op == 2:
      if liveCount == 0: return -1
      if found < liveCount: dec liveCount; live[found] = live[liveCount]
  var nodes: array[MaxOps, Node]
  var nodeCount = 0
  var root = -1'i32
  for i in 0 ..< opCount:
    let key = int32(keys[i])
    if ops[i] == 0:
      if root < 0:
        nodes[nodeCount] = Node(key: key, left: -1, right: -1)
        root = int32(nodeCount); inc nodeCount
      else:
        root = splay(nodes, root, key)
        nodes[nodeCount] = Node(key: key, left: -1, right: -1)
        let fresh = int32(nodeCount); inc nodeCount
        if key < nodes[int(root)].key:
          nodes[int(fresh)].left = nodes[int(root)].left
          nodes[int(fresh)].right = root
          nodes[int(root)].left = -1
        else:
          nodes[int(fresh)].right = nodes[int(root)].right
          nodes[int(fresh)].left = root
          nodes[int(root)].right = -1
        root = fresh
      tags[i] = -2
    elif ops[i] == 1:
      root = splay(nodes, root, key)
      tags[i] = if root >= 0 and nodes[int(root)].key == key: 1 else: 0
    else:
      root = splay(nodes, root, key)
      tags[i] = -3
      if nodes[int(root)].key == key:
        let left = nodes[int(root)].left
        let right = nodes[int(root)].right
        if left < 0: root = right
        else: root = splay(nodes, left, key); nodes[int(root)].right = right
  var finalKeys: array[MaxKeys, int64]
  var finalCount = 0
  inorder(nodes, root, finalKeys, finalCount)
  var staged: array[MaxOutput, uint8]
  var written = 0
  writeWord(staged, written, int64(opCount))
  for i in 0 ..< opCount: writeWord(staged, written, tags[i])
  writeWord(staged, written, int64(finalCount))
  for i in 0 ..< finalCount: writeWord(staged, written, finalKeys[i])
  if output == nil or capacity < csize_t(written): return -2
  for i in 0 ..< written: output[i] = staged[i]
  int64(written)
