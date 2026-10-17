const MaxN = 64
const MaxQ = 64
const MaxInputLength = 323
const NodeCap = 16384
const FnvOffset = 14695981039346656037'u64
const FnvPrime = 1099511628211'u64

type Node = object
  sum: int64
  prop: int64
  left: int32
  right: int32

proc makeNode(nodes: var array[NodeCap, Node], used: var int, sum, prop: int64, left, right: int32): int32 =
  if used >= NodeCap: return -1
  result = int32(used)
  nodes[used] = Node(sum: sum, prop: prop, left: left, right: right)
  inc used

proc cloneNode(nodes: var array[NodeCap, Node], used: var int, source: int32): int32 =
  if source < 0 or used >= NodeCap: return -1
  result = int32(used)
  nodes[used] = nodes[int(source)]
  inc used

proc pushLazy(nodes: var array[NodeCap, Node], used: var int, node: int32, left, right: int): bool =
  let prop = nodes[int(node)].prop
  if prop == 0: return true
  nodes[int(node)].sum += int64(right - left + 1) * prop
  if left != right:
    let newLeft = cloneNode(nodes, used, nodes[int(node)].left)
    let newRight = cloneNode(nodes, used, nodes[int(node)].right)
    if newLeft < 0 or newRight < 0: return false
    nodes[int(node)].left = newLeft
    nodes[int(node)].right = newRight
    nodes[int(newLeft)].prop += prop
    nodes[int(newRight)].prop += prop
  nodes[int(node)].prop = 0
  true

proc build(nodes: var array[NodeCap, Node], used: var int, values: ptr UncheckedArray[int64], left, right: int): int32 =
  if left == right: return makeNode(nodes, used, values[2 + left], 0, -1, -1)
  let mid = left + (right - left) div 2
  let a = build(nodes, used, values, left, mid)
  let b = build(nodes, used, values, mid + 1, right)
  if a < 0 or b < 0: return -1
  makeNode(nodes, used, nodes[int(a)].sum + nodes[int(b)].sum, 0, a, b)

proc rangeAdd(nodes: var array[NodeCap, Node], used: var int, current: int32,
              left, right, ql, qr: int, delta: int64): int32 =
  if not pushLazy(nodes, used, current, left, right): return -1
  if left >= ql and right <= qr:
    let copy = cloneNode(nodes, used, current)
    if copy < 0: return -1
    nodes[int(copy)].prop += delta
    if not pushLazy(nodes, used, copy, left, right): return -1
    return copy
  if left > qr or right < ql: return current
  let copy = makeNode(nodes, used, 0, 0, -1, -1)
  if copy < 0: return -1
  let mid = left + (right - left) div 2
  let a = rangeAdd(nodes, used, nodes[int(current)].left, left, mid, ql, qr, delta)
  let b = rangeAdd(nodes, used, nodes[int(current)].right, mid + 1, right, ql, qr, delta)
  if a < 0 or b < 0: return -1
  nodes[int(copy)].left = a
  nodes[int(copy)].right = b
  nodes[int(copy)].sum = nodes[int(a)].sum + nodes[int(b)].sum
  copy

proc rangeSum(nodes: var array[NodeCap, Node], used: var int, node: int32,
              left, right, ql, qr: int, ok: var bool): int64 =
  if not pushLazy(nodes, used, node, left, right):
    ok = false
    return 0
  if right < ql or qr < left: return 0
  if ql <= left and right <= qr: return nodes[int(node)].sum
  let mid = left + (right - left) div 2
  let a = rangeSum(nodes, used, nodes[int(node)].left, left, mid, ql, qr, ok)
  if not ok: return 0
  let b = rangeSum(nodes, used, nodes[int(node)].right, mid + 1, right, ql, qr, ok)
  a + b

proc hashWord(hashValue: var uint64, value: int64) =
  let bits = cast[uint64](value)
  for shift in countup(0, 56, 8):
    hashValue = (hashValue xor ((bits shr shift) and 0xff'u64)) *% FnvPrime

proc persistent_seg_tree_lazy_prop*(input: ptr UncheckedArray[int64], length: csize_t): int64
    {.cdecl, exportc: "persistent_seg_tree_lazy_prop".} =
  if input.isNil or length < csize_t(2) or length > csize_t(MaxInputLength): return -1
  let n64 = input[0]
  let q64 = input[1]
  if n64 < 1'i64 or n64 > int64(MaxN) or q64 < 0'i64 or q64 > int64(MaxQ): return -1
  let n = int(n64)
  let q = int(q64)
  if int(length) != 2 + n + 4 * q: return -1
  for i in 0 ..< n:
    if input[2 + i] < -1000 or input[2 + i] > 1000: return -1

  var nodes: array[NodeCap, Node]
  var used = 0
  var roots: array[MaxQ + 1, int32]
  roots[0] = build(nodes, used, input, 0, n - 1)
  if roots[0] < 0: return -1
  var versionCount = 1
  var queryCount = 0
  var querySums: array[MaxQ, int64]
  var offset = 2 + n
  for _ in 0 ..< q:
    let op = input[offset]
    let a = input[offset + 1]
    let b = input[offset + 2]
    let c = input[offset + 3]
    offset += 4
    if op == 0:
      if a < 0 or a > b or b >= n64 or c < -1000 or c > 1000: return -1
      let next = rangeAdd(nodes, used, roots[versionCount - 1], 0, n - 1, int(a), int(b), c)
      if next < 0: return -1
      roots[versionCount] = next
      inc versionCount
    elif op == 1:
      if a < 0 or a >= versionCount.int64 or b < 0 or c < b or c >= n64: return -1
      var ok = true
      querySums[queryCount] = rangeSum(nodes, used, roots[int(a)], 0, n - 1, int(b), int(c), ok)
      if not ok: return -1
      inc queryCount
    else:
      return -1

  var hashValue = FnvOffset
  hashWord(hashValue, int64(versionCount))
  hashWord(hashValue, int64(queryCount))
  for i in 0 ..< queryCount: hashWord(hashValue, querySums[i])
  int64(hashValue and 0x7fff_ffff_ffff_ffff'u64)
