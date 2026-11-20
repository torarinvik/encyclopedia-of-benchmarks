const MaxTextLength = 32
const MaxInputLength = 34
const MaxNodes = 64

type
  BlindTrie = object
    isLeaf: array[MaxNodes, bool]
    splitPos: array[MaxNodes, int32]
    leafStart: array[MaxNodes, int32]
    edgeSymbol: array[MaxNodes, int32]
    firstChild: array[MaxNodes, int32]
    nextSibling: array[MaxNodes, int32]
    count: int32
    root: int32

proc symbolAt(input: ptr UncheckedArray[int64], n, start, depth: int32): int32 =
  let position = start + depth
  if position >= n: return 0
  int32(input[int(position + 1)]) + 1

proc commonPrefix(input: ptr UncheckedArray[int64], n, left, right: int32): int32 =
  var depth = 0'i32
  while symbolAt(input, n, left, depth) == symbolAt(input, n, right, depth):
    inc depth
  depth

proc newNode(trie: var BlindTrie, isLeaf: bool, value: int32): int32 =
  result = trie.count
  inc trie.count
  trie.isLeaf[int(result)] = isLeaf
  trie.splitPos[int(result)] = if isLeaf: 0 else: value
  trie.leafStart[int(result)] = if isLeaf: value else: -1
  trie.firstChild[int(result)] = -1
  trie.nextSibling[int(result)] = -1

proc findChild(trie: var BlindTrie, parent, symbol: int32): int32 =
  var child = trie.firstChild[int(parent)]
  while child >= 0:
    if trie.edgeSymbol[int(child)] == symbol: return child
    if trie.edgeSymbol[int(child)] > symbol: return -1
    child = trie.nextSibling[int(child)]
  -1

proc linkChild(trie: var BlindTrie, parent, child: int32) =
  let symbol = trie.edgeSymbol[int(child)]
  var previous = -1'i32
  var cursor = trie.firstChild[int(parent)]
  while cursor >= 0 and trie.edgeSymbol[int(cursor)] < symbol:
    previous = cursor
    cursor = trie.nextSibling[int(cursor)]
  trie.nextSibling[int(child)] = cursor
  if previous < 0: trie.firstChild[int(parent)] = child
  else: trie.nextSibling[int(previous)] = child

proc replaceChild(trie: var BlindTrie, parent, oldChild, newChild: int32) =
  var previous = -1'i32
  var cursor = trie.firstChild[int(parent)]
  while cursor != oldChild:
    previous = cursor
    cursor = trie.nextSibling[int(cursor)]
  trie.edgeSymbol[int(newChild)] = trie.edgeSymbol[int(oldChild)]
  trie.nextSibling[int(newChild)] = trie.nextSibling[int(oldChild)]
  if previous < 0: trie.firstChild[int(parent)] = newChild
  else: trie.nextSibling[int(previous)] = newChild

proc insertSuffix(trie: var BlindTrie, input: ptr UncheckedArray[int64], n, start: int32) =
  let fresh = newNode(trie, true, start)
  if trie.isLeaf[int(trie.root)]:
    let old = trie.root
    let depth = commonPrefix(input, n, trie.leafStart[int(old)], start)
    let middle = newNode(trie, false, depth)
    trie.edgeSymbol[int(old)] = symbolAt(input, n, trie.leafStart[int(old)], depth)
    trie.edgeSymbol[int(fresh)] = symbolAt(input, n, start, depth)
    linkChild(trie, middle, old)
    linkChild(trie, middle, fresh)
    trie.root = middle
    return

  var leaf = trie.root
  while not trie.isLeaf[int(leaf)]:
    let symbol = symbolAt(input, n, start, trie.splitPos[int(leaf)])
    var child = findChild(trie, leaf, symbol)
    if child < 0: child = trie.firstChild[int(leaf)]
    leaf = child
  let oldStart = trie.leafStart[int(leaf)]
  let depth = commonPrefix(input, n, start, oldStart)
  var parent = -1'i32
  var current = trie.root
  while not trie.isLeaf[int(current)] and trie.splitPos[int(current)] < depth:
    let symbol = symbolAt(input, n, start, trie.splitPos[int(current)])
    var child = findChild(trie, current, symbol)
    if child < 0: child = trie.firstChild[int(current)]
    parent = current
    current = child
  if not trie.isLeaf[int(current)] and trie.splitPos[int(current)] == depth:
    trie.edgeSymbol[int(fresh)] = symbolAt(input, n, start, depth)
    linkChild(trie, current, fresh)
    return

  let middle = newNode(trie, false, depth)
  if parent < 0: trie.root = middle
  else: replaceChild(trie, parent, current, middle)
  trie.edgeSymbol[int(current)] = symbolAt(input, n, oldStart, depth)
  trie.edgeSymbol[int(fresh)] = symbolAt(input, n, start, depth)
  linkChild(trie, middle, current)
  linkChild(trie, middle, fresh)

proc orderedLeaves(trie: var BlindTrie, output: var array[MaxTextLength, int32]): int =
  var stack: array[MaxNodes, int32]
  var top = 1
  result = 0
  stack[0] = trie.root
  while top > 0:
    dec top
    let node = stack[top]
    if trie.isLeaf[int(node)]:
      output[result] = trie.leafStart[int(node)]
      inc result
      continue
    var children: array[MaxTextLength, int32]
    var childCount = 0
    var child = trie.firstChild[int(node)]
    while child >= 0:
      children[childCount] = child
      inc childCount
      child = trie.nextSibling[int(child)]
    while childCount > 0:
      dec childCount
      stack[top] = children[childCount]
      inc top

proc storeI64Le(output: ptr UncheckedArray[uint8], offset: int, value: int64) =
  let bits = uint64(value)
  for byte in 0 ..< 8:
    output[offset + byte] = uint8((bits shr (byte * 8)) and 255)

proc suffix_array_blind_trie*(values: ptr UncheckedArray[int64], length: csize_t,
    output: ptr UncheckedArray[uint8], capacity: csize_t): int64
    {.cdecl, exportc: "suffix_array_blind_trie".} =
  if values == nil or length < 1 or length > csize_t(MaxInputLength): return -1
  let countValue = values[0]
  if countValue < 0 or countValue > int64(MaxTextLength): return -1
  let count = int32(countValue)
  if length != csize_t(count + 1): return -1
  for index in 0 ..< int(count):
    if values[index + 1] < 0 or values[index + 1] > 255: return -1
  let outputBytes = int(count) * 8
  if output == nil or capacity < csize_t(outputBytes): return -2
  if count == 0: return 0

  var trie: BlindTrie
  for index in 0 ..< MaxNodes:
    trie.firstChild[index] = -1
    trie.nextSibling[index] = -1
  trie.root = newNode(trie, true, 0)
  for start in 1'i32 ..< count: insertSuffix(trie, values, count, start)
  var order: array[MaxTextLength, int32]
  let orderedCount = orderedLeaves(trie, order)
  for index in 0 ..< orderedCount:
    storeI64Le(output, index * 8, int64(order[index]))
  int64(outputBytes)
