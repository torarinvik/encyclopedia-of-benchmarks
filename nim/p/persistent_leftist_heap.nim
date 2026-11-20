const MaxOperations = 64
const MaxNodes = 1024
const MaxInputWords = 193
const MaxHeapSize = 128

type HeapNode = object
  key: int64
  left, right: int
  npl, size: int

proc meld(nodes: var array[MaxNodes, HeapNode], used: var int, firstRoot, secondRoot: int): int =
  if firstRoot == 0: return secondRoot
  if secondRoot == 0: return firstRoot
  var first = firstRoot
  var second = secondRoot
  if nodes[first].key > nodes[second].key: swap(first, second)
  if used >= MaxNodes: return -1
  let copy = used
  inc used
  nodes[copy] = nodes[first]
  let mergedRight = meld(nodes, used, nodes[copy].right, second)
  if mergedRight < 0: return -1
  nodes[copy].right = mergedRight
  if nodes[nodes[copy].left].npl < nodes[nodes[copy].right].npl:
    swap(nodes[copy].left, nodes[copy].right)
  nodes[copy].npl = nodes[nodes[copy].right].npl + 1
  nodes[copy].size = nodes[nodes[copy].left].size + nodes[nodes[copy].right].size + 1
  copy

proc persistent_leftist_heap*(input: ptr UncheckedArray[int64], length: csize_t): int64
    {.cdecl, exportc: "persistent_leftist_heap".} =
  if input.isNil or length < 1 or length > csize_t(MaxInputWords): return -1
  let operationCount64 = input[0]
  if operationCount64 < 0 or operationCount64 > MaxOperations: return -1
  let operationCount = int(operationCount64)
  let inputLength = int(length)

  var nodes: array[MaxNodes, HeapNode]
  nodes[0].npl = -1
  var used = 1
  var roots: array[MaxOperations + 1, int]
  var cursor = 1
  var rankSum = 0'i64
  var rankXor = 0'i64
  for operation in 0 ..< operationCount:
    if cursor >= inputLength: return -1
    let kind = input[cursor]
    inc cursor
    if kind == 0:
      if cursor + 2 > inputLength: return -1
      let base64 = input[cursor]
      let key = input[cursor + 1]
      cursor += 2
      if base64 < 0 or base64 > int64(operation) or key < -10000 or key > 10000: return -1
      let base = int(base64)
      if nodes[roots[base]].size >= MaxHeapSize or used >= MaxNodes: return -1
      let singleton = used
      inc used
      nodes[singleton] = HeapNode(key: key, npl: 0, size: 1)
      let resultRoot = meld(nodes, used, roots[base], singleton)
      if resultRoot < 0 or nodes[resultRoot].size > MaxHeapSize: return -1
      roots[operation + 1] = resultRoot
    elif kind == 1:
      if cursor + 2 > inputLength: return -1
      let left64 = input[cursor]
      let right64 = input[cursor + 1]
      cursor += 2
      if left64 < 0 or left64 > int64(operation) or right64 < 0 or right64 > int64(operation): return -1
      let leftVersion = int(left64)
      let rightVersion = int(right64)
      if nodes[roots[leftVersion]].size + nodes[roots[rightVersion]].size > MaxHeapSize: return -1
      let resultRoot = meld(nodes, used, roots[leftVersion], roots[rightVersion])
      if resultRoot < 0 or nodes[resultRoot].size > MaxHeapSize: return -1
      roots[operation + 1] = resultRoot
    elif kind == 2:
      if cursor + 1 > inputLength: return -1
      let version64 = input[cursor]
      inc cursor
      if version64 < 0 or version64 > int64(operation): return -1
      let root = roots[int(version64)]
      if root == 0:
        roots[operation + 1] = 0
        rankSum += 20001
        rankXor = rankXor xor 20001
      else:
        let rank = nodes[root].key + 10000
        rankSum += rank
        rankXor = rankXor xor rank
        let resultRoot = meld(nodes, used, nodes[root].left, nodes[root].right)
        if resultRoot < 0 or nodes[resultRoot].size > MaxHeapSize: return -1
        roots[operation + 1] = resultRoot
    elif kind == 3:
      if cursor + 1 > inputLength: return -1
      let version64 = input[cursor]
      inc cursor
      if version64 < 0 or version64 > int64(operation): return -1
      let root = roots[int(version64)]
      roots[operation + 1] = root
      let rank = if root == 0: 20001'i64 else: nodes[root].key + 10000
      rankSum += rank
      rankXor = rankXor xor rank
    else:
      return -1
  if cursor != inputLength: return -1
  (rankSum shl 15) or rankXor
