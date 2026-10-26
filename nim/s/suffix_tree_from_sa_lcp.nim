const
  MaxText = 8
  MaxInput = 10
  MaxSuffixes = 9
  MaxNodes = 17
  MaxOutputWords = 86

type TreeRecord = object
  parentRep, parentDepth, nodeRep, nodeDepth, leafStart: int64

proc storeI64Le(output: ptr UncheckedArray[uint8], offset: int, value: int64) =
  let bits = cast[uint64](value)
  for byte in 0 ..< 8: output[offset + byte] = uint8((bits shr (8 * byte)) and 255)

proc symbolAt(input: ptr UncheckedArray[int64], n, position: int): int =
  if position == n: 0 else: int(input[position + 1])

proc suffixLess(input: ptr UncheckedArray[int64], n, leftStart, rightStart: int): bool =
  var left = leftStart
  var right = rightStart
  let total = n + 1
  while left < total and right < total:
    let a = symbolAt(input, n, left)
    let b = symbolAt(input, n, right)
    if a != b: return a < b
    inc left
    inc right
  left == total and right != total

proc recordLess(left, right: TreeRecord): bool =
  if left.nodeDepth != right.nodeDepth: return left.nodeDepth < right.nodeDepth
  if left.nodeRep != right.nodeRep: return left.nodeRep < right.nodeRep
  left.leafStart < right.leafStart

proc suffix_tree_from_sa_lcp*(input: ptr UncheckedArray[int64], length: csize_t,
    output: ptr UncheckedArray[uint8], capacity: csize_t): int64
    {.cdecl, exportc: "suffix_tree_from_sa_lcp".} =
  if input.isNil or length < csize_t(1) or length > csize_t(MaxInput): return -1
  let nRaw = input[0]
  if nRaw < 0 or nRaw > MaxText or int(length) != int(nRaw) + 1: return -1
  let n = int(nRaw)
  for i in 0 ..< n:
    if input[i + 1] < 1 or input[i + 1] > 255: return -1
  let suffixCount = n + 1
  var suffixArray: array[MaxSuffixes, int]
  var lcp: array[MaxSuffixes, int]
  for i in 0 ..< suffixCount: suffixArray[i] = i
  for i in 1 ..< suffixCount:
    let value = suffixArray[i]
    var j = i
    while j > 0 and suffixLess(input, n, value, suffixArray[j - 1]):
      suffixArray[j] = suffixArray[j - 1]
      dec j
    suffixArray[j] = value
  for rank in 1 ..< suffixCount:
    var left = suffixArray[rank - 1]
    var right = suffixArray[rank]
    var common = 0
    while left + common < suffixCount and right + common < suffixCount
        and symbolAt(input, n, left + common) == symbolAt(input, n, right + common):
      inc common
    lcp[rank] = common

  var parent: array[MaxNodes, int]
  var depth: array[MaxNodes, int]
  var representative: array[MaxNodes, int]
  var leaf: array[MaxNodes, int]
  var lastChild: array[MaxNodes, int]
  var stack: array[MaxNodes, int]
  var nodeCount = 1
  var stackSize = 1
  parent[0] = -1; depth[0] = 0; representative[0] = -1; leaf[0] = -1; lastChild[0] = -1
  stack[0] = 0
  for rank in 0 ..< suffixCount:
    if rank > 0:
      let common = lcp[rank]
      while stackSize > 1 and depth[stack[stackSize - 1]] > common: dec stackSize
      let top = stack[stackSize - 1]
      if depth[top] < common:
        let oldChild = lastChild[top]
        if oldChild < 0: return -1
        let internal = nodeCount
        inc nodeCount
        parent[internal] = top; depth[internal] = common
        representative[internal] = representative[oldChild]; leaf[internal] = -1
        lastChild[internal] = oldChild
        parent[oldChild] = internal
        lastChild[top] = internal
        stack[stackSize] = internal
        inc stackSize
    let owner = stack[stackSize - 1]
    let suffixStart = suffixArray[rank]
    let newLeaf = nodeCount
    inc nodeCount
    parent[newLeaf] = owner; depth[newLeaf] = suffixCount - suffixStart
    representative[newLeaf] = suffixStart; leaf[newLeaf] = suffixStart
    lastChild[newLeaf] = -1; lastChild[owner] = newLeaf

  var records: array[MaxNodes, TreeRecord]
  for node in 0 ..< nodeCount:
    if node == 0:
      records[node] = TreeRecord(parentRep: -1, parentDepth: -1, nodeRep: -1, nodeDepth: 0, leafStart: -1)
    else:
      let p = parent[node]
      records[node] = TreeRecord(parentRep: int64(representative[p]), parentDepth: int64(depth[p]),
        nodeRep: int64(representative[node]), nodeDepth: int64(depth[node]), leafStart: int64(leaf[node]))
  for i in 1 ..< nodeCount:
    let value = records[i]
    var j = i
    while j > 0 and recordLess(value, records[j - 1]):
      records[j] = records[j - 1]
      dec j
    records[j] = value
  var staged: array[MaxOutputWords, int64]
  staged[0] = int64(nodeCount)
  var words = 1
  for node in 0 ..< nodeCount:
    staged[words] = records[node].parentRep; inc words
    staged[words] = records[node].parentDepth; inc words
    staged[words] = records[node].nodeRep; inc words
    staged[words] = records[node].nodeDepth; inc words
    staged[words] = records[node].leafStart; inc words
  let bytes = words * 8
  if output.isNil or capacity < csize_t(bytes): return -2
  for word in 0 ..< words: storeI64Le(output, word * 8, staged[word])
  int64(bytes)
