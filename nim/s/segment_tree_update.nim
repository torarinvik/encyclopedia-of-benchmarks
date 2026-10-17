const
  MaxN = 64
  MaxOperations = 64
  MaxInputLength = 259
  MaxTreeLength = 128
  ValueMin = -1_000_000'i64
  ValueMax = 1_000_000'i64
  FnvOffset = 14695981039346656037'u64
  FnvPrime = 1099511628211'u64
  Mask63 = 0x7fffffffffffffff'u64

proc querySum(tree: var array[MaxTreeLength, int32], node, segmentLeft, segmentRight,
              queryLeft, queryRight: int): int32 =
  if queryLeft <= segmentLeft and segmentRight <= queryRight: return tree[node]
  if queryRight < segmentLeft or segmentRight < queryLeft: return 0
  let middle = segmentLeft + (segmentRight - segmentLeft) div 2
  querySum(tree, node * 2, segmentLeft, middle, queryLeft, queryRight) +
    querySum(tree, node * 2 + 1, middle + 1, segmentRight, queryLeft, queryRight)

proc hashI64Word(hashValue: uint64, word: int64): uint64 =
  var hash = hashValue
  let bits = cast[uint64](word)
  for shift in countup(0, 56, 8):
    hash = (hash xor ((bits shr shift) and 255'u64)) *% FnvPrime
  hash

proc segment_tree_update_benchmark*(input: ptr UncheckedArray[int64], length: csize_t): int64
    {.cdecl, exportc: "segment_tree_update_benchmark".} =
  if input == nil or length < 3 or length > csize_t(MaxInputLength): return -1
  if input[0] < 1 or input[0] > MaxN: return -1
  let n = int(input[0])
  if length < csize_t(n + 2): return -1
  if input[n + 1] < 1 or input[n + 1] > MaxOperations: return -1
  let operationCount = int(input[n + 1])
  if int(length) != n + 2 + 3 * operationCount: return -1

  for index in 0 ..< n:
    if input[index + 1] < ValueMin or input[index + 1] > ValueMax: return -1
  let operationsStart = n + 2
  var queryCount = 0
  for operation in 0 ..< operationCount:
    let offset = operationsStart + 3 * operation
    let kind = input[offset]
    let first = input[offset + 1]
    let second = input[offset + 2]
    if kind == 0:
      if first < 0 or first > second or second >= int64(n): return -1
      inc queryCount
    elif kind == 1:
      if first < 0 or first >= int64(n) or second < ValueMin or second > ValueMax: return -1
    else:
      return -1
  if queryCount == 0: return -1

  var power = 1
  while power < n: power *= 2
  var tree: array[MaxTreeLength, int32]
  for index in 0 ..< n: tree[power + index] = int32(input[index + 1])
  var node = power - 1
  while node > 0:
    tree[node] = tree[node * 2] + tree[node * 2 + 1]
    dec node

  var hash = hashI64Word(FnvOffset, int64(queryCount))
  for operation in 0 ..< operationCount:
    let offset = operationsStart + 3 * operation
    let kind = input[offset]
    let first = input[offset + 1]
    let second = input[offset + 2]
    if kind == 0:
      let sum = querySum(tree, 1, 1, power, int(first) + 1, int(second) + 1)
      hash = hashI64Word(hash, int64(sum))
    else:
      var node = power + int(first)
      tree[node] = int32(second)
      while node > 1:
        node = node div 2
        tree[node] = tree[node * 2] + tree[node * 2 + 1]
  int64(hash and Mask63)
