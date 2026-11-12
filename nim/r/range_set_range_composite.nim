const MaxN = 64
const MaxQ = 32
const TreeN = 4 * MaxN + 5
const Modulus = 998244353'i64
type
  Affine = object
    a, b: int64
  Node = object
    value, lazy: Affine
    hasLazy: bool
  Operation = object
    kind, left, right: int
    x, y: int64

proc compose(afterMap, beforeMap: Affine): Affine =
  Affine(a: afterMap.a * beforeMap.a mod Modulus,
    b: (afterMap.a * beforeMap.b + afterMap.b) mod Modulus)

proc powerMap(a, b: int64, exponentValue: int): Affine =
  var exponent = exponentValue
  var result = Affine(a: 1, b: 0)
  var base = Affine(a: a, b: b)
  while exponent > 0:
    if (exponent and 1) != 0: result = compose(base, result)
    base = compose(base, base)
    exponent = exponent shr 1
  result

proc build(tree: var array[TreeN, Node], node, left, right: int,
    initialA, initialB: array[MaxN, int64]) =
  if right - left == 1:
    tree[node].value = Affine(a: initialA[left], b: initialB[left])
    return
  let mid = left + (right - left) div 2
  build(tree, node * 2, left, mid, initialA, initialB)
  build(tree, node * 2 + 1, mid, right, initialA, initialB)
  tree[node].value = compose(tree[node * 2 + 1].value, tree[node * 2].value)

proc apply(tree: var array[TreeN, Node], node, left, right: int, a, b: int64) =
  tree[node].value = powerMap(a, b, right - left)
  tree[node].lazy = Affine(a: a, b: b)
  tree[node].hasLazy = true

proc push(tree: var array[TreeN, Node], node, left, right: int) =
  if not tree[node].hasLazy or right - left == 1: return
  let mid = left + (right - left) div 2
  let tag = tree[node].lazy
  apply(tree, node * 2, left, mid, tag.a, tag.b)
  apply(tree, node * 2 + 1, mid, right, tag.a, tag.b)
  tree[node].hasLazy = false

proc update(tree: var array[TreeN, Node], node, left, right, ql, qr: int, a, b: int64) =
  if ql <= left and right <= qr:
    apply(tree, node, left, right, a, b)
    return
  push(tree, node, left, right)
  let mid = left + (right - left) div 2
  if ql < mid: update(tree, node * 2, left, mid, ql, qr, a, b)
  if qr > mid: update(tree, node * 2 + 1, mid, right, ql, qr, a, b)
  tree[node].value = compose(tree[node * 2 + 1].value, tree[node * 2].value)

proc query(tree: var array[TreeN, Node], node, left, right, ql, qr: int): Affine =
  if ql <= left and right <= qr: return tree[node].value
  push(tree, node, left, right)
  let mid = left + (right - left) div 2
  if qr <= mid: return query(tree, node * 2, left, mid, ql, qr)
  if ql >= mid: return query(tree, node * 2 + 1, mid, right, ql, qr)
  compose(query(tree, node * 2 + 1, mid, right, ql, qr),
          query(tree, node * 2, left, mid, ql, qr))

proc put64(output: ptr UncheckedArray[uint8], offset: int, value: int64) =
  let bits = cast[uint64](value)
  for byte in 0 ..< 8: output[offset + byte] = uint8((bits shr (8 * byte)) and 255'u64)

proc range_set_range_composite*(input: ptr UncheckedArray[int64], length: csize_t,
    output: ptr UncheckedArray[uint8], capacity: csize_t): int64
    {.cdecl, exportc: "range_set_range_composite".} =
  if input.isNil or length < 2 or length > 291: return -1
  let n64 = input[0]
  let q64 = input[1]
  if n64 < 1 or n64 > MaxN or q64 < 1 or q64 > MaxQ: return -1
  let n = int(n64)
  let q = int(q64)
  if int(length) < 2 + 2 * n: return -1
  var initialA, initialB: array[MaxN, int64]
  var offset = 2
  for i in 0 ..< n:
    initialA[i] = input[offset]
    initialB[i] = input[offset + 1]
    offset += 2
    if initialA[i] < 1 or initialA[i] >= Modulus or initialB[i] < 0 or initialB[i] >= Modulus: return -1
  var operations: array[MaxQ, Operation]
  var queryCount = 0
  for k in 0 ..< q:
    if offset >= int(length): return -1
    let kind = input[offset]
    inc offset
    if kind == 0:
      if offset + 4 > int(length): return -1
      let left = input[offset]; let right = input[offset + 1]
      let a = input[offset + 2]; let b = input[offset + 3]
      offset += 4
      if left < 0 or left >= right or right > n64 or a < 1 or a >= Modulus or b < 0 or b >= Modulus: return -1
      operations[k] = Operation(kind: 0, left: int(left), right: int(right), x: a, y: b)
    elif kind == 1:
      if offset + 3 > int(length): return -1
      let left = input[offset]; let right = input[offset + 1]; let x = input[offset + 2]
      offset += 3
      if left < 0 or left >= right or right > n64 or x < 0 or x >= Modulus: return -1
      operations[k] = Operation(kind: 1, left: int(left), right: int(right), x: x)
      inc queryCount
    else: return -1
  if offset != int(length): return -1
  var tree: array[TreeN, Node]
  build(tree, 1, 0, n, initialA, initialB)
  var answers: array[MaxQ, int64]
  var answerIndex = 0
  for k in 0 ..< q:
    let op = operations[k]
    if op.kind == 0: update(tree, 1, 0, n, op.left, op.right, op.x, op.y)
    else:
      let z = query(tree, 1, 0, n, op.left, op.right)
      answers[answerIndex] = (z.a * op.x + z.b) mod Modulus
      inc answerIndex
  let bytes = 8 * queryCount
  if output.isNil or capacity < csize_t(bytes): return -2
  for i in 0 ..< queryCount: put64(output, 8 * i, answers[i])
  int64(bytes)
