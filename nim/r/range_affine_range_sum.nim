const
  Modulus = 998244353'i64
  MaxLength = 64
  MaxOperations = 64
  TreeNodes = 256
  MaxParseableInputLength = 387

type AffineTree = object
  sums: array[TreeNodes, int64]
  lazyMul: array[TreeNodes, int64]
  lazyAdd: array[TreeNodes, int64]

proc apply(tree: var AffineTree, node, length: int, a, b: int64) =
  tree.sums[node] = (a * tree.sums[node] + b * int64(length)) mod Modulus
  tree.lazyMul[node] = (a * tree.lazyMul[node]) mod Modulus
  tree.lazyAdd[node] = (a * tree.lazyAdd[node] + b) mod Modulus

proc push(tree: var AffineTree, node, low, high: int) =
  if high - low <= 1 or (tree.lazyMul[node] == 1 and tree.lazyAdd[node] == 0): return
  let middle = low + (high - low) div 2
  let a = tree.lazyMul[node]
  let b = tree.lazyAdd[node]
  tree.apply(2 * node, middle - low, a, b)
  tree.apply(2 * node + 1, high - middle, a, b)
  tree.lazyMul[node] = 1
  tree.lazyAdd[node] = 0

proc build(tree: var AffineTree, values: openArray[int64], node, low, high: int) =
  if high - low == 1:
    tree.sums[node] = values[low]
    return
  let middle = low + (high - low) div 2
  tree.build(values, 2 * node, low, middle)
  tree.build(values, 2 * node + 1, middle, high)
  tree.sums[node] = (tree.sums[2 * node] + tree.sums[2 * node + 1]) mod Modulus

proc update(tree: var AffineTree, ql, qr, node, low, high: int, a, b: int64) =
  if ql <= low and high <= qr:
    tree.apply(node, high - low, a, b)
    return
  if qr <= low or high <= ql: return
  tree.push(node, low, high)
  let middle = low + (high - low) div 2
  tree.update(ql, qr, 2 * node, low, middle, a, b)
  tree.update(ql, qr, 2 * node + 1, middle, high, a, b)
  tree.sums[node] = (tree.sums[2 * node] + tree.sums[2 * node + 1]) mod Modulus

proc query(tree: var AffineTree, ql, qr, node, low, high: int): int64 =
  if ql <= low and high <= qr: return tree.sums[node]
  if qr <= low or high <= ql: return 0
  tree.push(node, low, high)
  let middle = low + (high - low) div 2
  (tree.query(ql, qr, 2 * node, low, middle) +
    tree.query(ql, qr, 2 * node + 1, middle, high)) mod Modulus

proc range_affine_range_sum_benchmark*(input: ptr UncheckedArray[int64], length: csize_t): int64
    {.cdecl, exportc: "range_affine_range_sum_benchmark".} =
  if input.isNil or length < csize_t(2) or length > csize_t(MaxParseableInputLength): return -1
  if input[0] < 1 or input[0] > MaxLength: return -1
  let n = int(input[0])
  if length < csize_t(n + 2): return -1
  var initial: array[MaxLength, int64]
  for i in 0 ..< n:
    if input[i + 1] < 0 or input[i + 1] >= Modulus: return -1
    initial[i] = input[i + 1]
  if input[n + 1] < 1 or input[n + 1] > MaxOperations: return -1
  let operationCount = int(input[n + 1])
  var tree: AffineTree
  for i in 0 ..< TreeNodes: tree.lazyMul[i] = 1
  tree.build(initial.toOpenArray(0, n - 1), 1, 0, n)
  var cursor = n + 2
  var checksum = 0'i64
  for operation in 0 ..< operationCount:
    if cursor >= int(length): return -1
    let opcode = input[cursor]
    inc cursor
    if opcode == 0:
      if cursor + 4 > int(length): return -1
      let (left, right, a, b) = (input[cursor], input[cursor + 1], input[cursor + 2], input[cursor + 3])
      cursor += 4
      if left < 0 or left >= right or right > int64(n) or a < 1 or a >= Modulus or b < 0 or b >= Modulus: return -1
      tree.update(int(left), int(right), 1, 0, n, a, b)
    elif opcode == 1:
      if cursor + 2 > int(length): return -1
      let left = input[cursor]
      let right = input[cursor + 1]
      cursor += 2
      if left < 0 or left >= right or right > int64(n): return -1
      let result = tree.query(int(left), int(right), 1, 0, n)
      checksum += int64(operation + 1) * (result + Modulus)
    else:
      return -1
  if cursor == int(length): checksum else: -1
