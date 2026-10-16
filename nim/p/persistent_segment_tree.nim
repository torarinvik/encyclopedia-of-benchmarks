const MaxN = 64
const MaxQ = 64
const MaxInput = 322
const NodeCap = 640
const FnvOffset = 14695981039346656037'u64
const FnvPrime = 1099511628211'u64

type Node = object
  sum: int64
  left: int32
  right: int32

proc makeNode(nodes: var array[NodeCap, Node], used: var int, sum: int64, left, right: int32): int32 =
  if used >= NodeCap: return -1
  result = int32(used)
  nodes[used] = Node(sum: sum, left: left, right: right)
  inc used

proc build(nodes: var array[NodeCap, Node], used: var int, values: ptr UncheckedArray[int64], left, right: int): int32 =
  if left == right: return makeNode(nodes, used, values[2 + left], -1, -1)
  let mid = left + (right - left) div 2
  let a = build(nodes, used, values, left, mid)
  let b = build(nodes, used, values, mid + 1, right)
  if a < 0 or b < 0: return -1
  makeNode(nodes, used, nodes[a].sum + nodes[b].sum, a, b)

proc pointSet(nodes: var array[NodeCap, Node], used: var int, root: int32, left, right, index: int, value: int64): int32 =
  if left == right: return makeNode(nodes, used, value, -1, -1)
  let mid = left + (right - left) div 2
  var a = nodes[root].left
  var b = nodes[root].right
  if index <= mid: a = pointSet(nodes, used, a, left, mid, index, value)
  else: b = pointSet(nodes, used, b, mid + 1, right, index, value)
  if a < 0 or b < 0: return -1
  makeNode(nodes, used, nodes[a].sum + nodes[b].sum, a, b)

proc rangeSum(nodes: array[NodeCap, Node], node: int32, left, right, ql, qr: int): int64 =
  if ql <= left and right <= qr: return nodes[node].sum
  let mid = left + (right - left) div 2
  if qr <= mid: return rangeSum(nodes, nodes[node].left, left, mid, ql, qr)
  if ql > mid: return rangeSum(nodes, nodes[node].right, mid + 1, right, ql, qr)
  rangeSum(nodes, nodes[node].left, left, mid, ql, qr) + rangeSum(nodes, nodes[node].right, mid + 1, right, ql, qr)

proc hashWord(hashValue: var uint64, value: int64) =
  let bits = cast[uint64](value)
  for shift in countup(0, 56, 8): hashValue = (hashValue xor ((bits shr shift) and 0xff'u64)) *% FnvPrime

proc persistent_segment_tree*(input: ptr UncheckedArray[int64], length: csize_t): int64 {.cdecl, exportc: "persistent_segment_tree".} =
  if input.isNil or length < 3 or length > csize_t(MaxInput): return -1
  let n64 = input[0]
  let q64 = input[1]
  if n64 < 1 or n64 > MaxN or q64 < 0 or q64 > MaxQ: return -1
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
      if a < 0 or a >= versionCount.int64 or b < 0 or b >= n64 or c < -1000 or c > 1000: return -1
      let next = pointSet(nodes, used, roots[int(a)], 0, n - 1, int(b), c)
      if next < 0: return -1
      roots[versionCount] = next
      inc versionCount
    elif op == 1:
      if a < 0 or a >= versionCount.int64 or b < 0 or c < b or c >= n64: return -1
      querySums[queryCount] = rangeSum(nodes, roots[int(a)], 0, n - 1, int(b), int(c))
      inc queryCount
    else:
      return -1

  var hashValue = FnvOffset
  hashWord(hashValue, int64(versionCount))
  hashWord(hashValue, int64(queryCount))
  for i in 0 ..< queryCount: hashWord(hashValue, querySums[i])
  int64(hashValue and 0x7fff_ffff_ffff_ffff'u64)
