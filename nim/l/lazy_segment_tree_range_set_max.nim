const MaxN = 256
const MaxQ = 512
const MaxInput = 2306
const ChecksumOffset = 1_000_001'i64

proc build(node, left, right: int, values: openArray[int64], tree: var array[1024, int64]) =
  if left == right:
    tree[node] = values[left]
    return
  let mid = left + (right - left) div 2
  build(node * 2, left, mid, values, tree)
  build(node * 2 + 1, mid + 1, right, values, tree)
  tree[node] = max(tree[node * 2], tree[node * 2 + 1])

proc push(node, left, right: int, tree, lazy: var array[1024, int64], pending: var array[1024, bool]) =
  if not pending[node]: return
  tree[node] = lazy[node]
  pending[node] = false
  if left != right:
    let child = node * 2
    lazy[child] = tree[node]
    lazy[child + 1] = tree[node]
    pending[child] = true
    pending[child + 1] = true

proc assignRange(node, left, right, ql, qr: int, value: int64,
                 tree, lazy: var array[1024, int64], pending: var array[1024, bool]) =
  push(node, left, right, tree, lazy, pending)
  if right < ql or left > qr: return
  if ql <= left and right <= qr:
    tree[node] = value
    if left != right:
      let child = node * 2
      lazy[child] = value
      lazy[child + 1] = value
      pending[child] = true
      pending[child + 1] = true
    return
  let mid = left + (right - left) div 2
  assignRange(node * 2, left, mid, ql, qr, value, tree, lazy, pending)
  assignRange(node * 2 + 1, mid + 1, right, ql, qr, value, tree, lazy, pending)
  tree[node] = max(tree[node * 2], tree[node * 2 + 1])

proc rangeMax(node, left, right, ql, qr: int, tree, lazy: var array[1024, int64],
              pending: var array[1024, bool]): int64 =
  push(node, left, right, tree, lazy, pending)
  if right < ql or left > qr: return low(int64)
  if ql <= left and right <= qr: return tree[node]
  let mid = left + (right - left) div 2
  max(rangeMax(node * 2, left, mid, ql, qr, tree, lazy, pending),
      rangeMax(node * 2 + 1, mid + 1, right, ql, qr, tree, lazy, pending))

proc lazy_segment_tree_range_set_max*(packed: ptr UncheckedArray[int64], length: csize_t): int64
    {.cdecl, exportc: "lazy_segment_tree_range_set_max".} =
  if packed.isNil or length < 2 or length > MaxInput: return -1
  let inputLength = int(length)
  let nv = packed[0]
  let qv = packed[1]
  if nv < 1 or nv > MaxN or qv < 0 or qv > MaxQ: return -1
  let n = int(nv)
  let q = int(qv)
  if inputLength < 2 + n: return -1
  var initial: array[MaxN, int64]
  for i in 0 ..< n:
    initial[i] = packed[2 + i]
    if initial[i] < -1_000_000 or initial[i] > 1_000_000: return -1
  var offset = 2 + n
  var opcodes: array[MaxQ, int]
  var lefts, rights: array[MaxQ, int]
  var assigned: array[MaxQ, int64]
  for i in 0 ..< q:
    if offset >= inputLength: return -1
    let op = packed[offset]
    let width = if op == 0: 3 elif op == 1: 4 else: 0
    if width == 0 or offset + width > inputLength: return -1
    let l = packed[offset + 1]
    let r = packed[offset + 2]
    if l < 0 or l >= r or r > nv: return -1
    opcodes[i] = int(op)
    lefts[i] = int(l)
    rights[i] = int(r)
    if op == 1:
      assigned[i] = packed[offset + 3]
      if assigned[i] < -1_000_000 or assigned[i] > 1_000_000: return -1
    offset += width
  if offset != inputLength: return -1
  var tree, lazy: array[1024, int64]
  var pending: array[1024, bool]
  build(1, 0, n - 1, initial, tree)
  var checksum = 0'i64
  var ordinal = 0'i64
  for i in 0 ..< q:
    if opcodes[i] == 1:
      assignRange(1, 0, n - 1, lefts[i], rights[i] - 1, assigned[i], tree, lazy, pending)
    else:
      let answer = rangeMax(1, 0, n - 1, lefts[i], rights[i] - 1, tree, lazy, pending)
      inc ordinal
      checksum += ordinal * (answer + ChecksumOffset)
  checksum
