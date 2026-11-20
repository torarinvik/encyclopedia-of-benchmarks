type
  RbstNode = object
    key: int64
    left, right, size: int
  RbstState = object
    nodes: array[64, RbstNode]
    used: int
    randomState: uint32

proc treeSize(state: var RbstState, root: int): int =
  if root < 0: 0 else: state.nodes[root].size

proc refresh(state: var RbstState, root: int) =
  state.nodes[root].size = 1 + treeSize(state, state.nodes[root].left) + treeSize(state, state.nodes[root].right)

proc randbelow(state: var RbstState, bound: uint32): uint32 =
  let threshold = uint32((1'u64 shl 32) mod uint64(bound))
  while true:
    state.randomState = state.randomState *% 1_664_525'u32 +% 1_013_904_223'u32
    let raw = state.randomState
    if raw >= threshold: return raw mod bound

proc makeNode(state: var RbstState, key: int64, left, right: int): int =
  result = state.used
  inc state.used
  state.nodes[result] = RbstNode(key: key, left: left, right: right, size: 1)
  refresh(state, result)

proc splitTree(state: var RbstState, root: int, pivot: int64): tuple[low, high: int] =
  if root < 0: return (-1, -1)
  if state.nodes[root].key < pivot:
    let parts = splitTree(state, state.nodes[root].right, pivot)
    state.nodes[root].right = parts.low
    refresh(state, root)
    return (root, parts.high)
  let parts = splitTree(state, state.nodes[root].left, pivot)
  state.nodes[root].left = parts.high
  refresh(state, root)
  (parts.low, root)

proc joinTrees(state: var RbstState, left, right: int): int =
  if left < 0: return right
  if right < 0: return left
  let leftSize = uint32(treeSize(state, left))
  let total = leftSize + uint32(treeSize(state, right))
  if randbelow(state, total) < leftSize:
    let child = state.nodes[left].right
    state.nodes[left].right = joinTrees(state, child, right)
    refresh(state, left)
    return left
  let child = state.nodes[right].left
  state.nodes[right].left = joinTrees(state, left, child)
  refresh(state, right)
  right

proc contains(state: var RbstState, rootStart: int, key: int64): bool =
  var root = rootStart
  while root >= 0:
    if key == state.nodes[root].key: return true
    if key < state.nodes[root].key: root = state.nodes[root].left
    else: root = state.nodes[root].right
  false

proc insertAbsent(state: var RbstState, root: int, key: int64): int =
  if root < 0: return makeNode(state, key, -1, -1)
  if randbelow(state, uint32(treeSize(state, root) + 1)) == 0:
    let parts = splitTree(state, root, key)
    return makeNode(state, key, parts.low, parts.high)
  if key < state.nodes[root].key:
    let child = state.nodes[root].left
    state.nodes[root].left = insertAbsent(state, child, key)
  else:
    let child = state.nodes[root].right
    state.nodes[root].right = insertAbsent(state, child, key)
  refresh(state, root)
  root

proc eraseKey(state: var RbstState, root: int, key: int64): int =
  if root < 0: return -1
  if key == state.nodes[root].key:
    return joinTrees(state, state.nodes[root].left, state.nodes[root].right)
  if key < state.nodes[root].key:
    let child = state.nodes[root].left
    state.nodes[root].left = eraseKey(state, child, key)
  else:
    let child = state.nodes[root].right
    state.nodes[root].right = eraseKey(state, child, key)
  refresh(state, root)
  root

proc kth(state: var RbstState, rootStart, rankStart: int): int64 =
  if rankStart > treeSize(state, rootStart): return -1
  var root = rootStart
  var rank = rankStart
  while root >= 0:
    let leftSize = treeSize(state, state.nodes[root].left)
    if rank == leftSize + 1: return state.nodes[root].key
    if rank <= leftSize: root = state.nodes[root].left
    else:
      rank -= leftSize + 1
      root = state.nodes[root].right
  -1

proc minimum(state: var RbstState, rootStart: int): int64 =
  if rootStart < 0: return -1
  var root = rootStart
  while state.nodes[root].left >= 0: root = state.nodes[root].left
  state.nodes[root].key

proc maximum(state: var RbstState, rootStart: int): int64 =
  if rootStart < 0: return -1
  var root = rootStart
  while state.nodes[root].right >= 0: root = state.nodes[root].right
  state.nodes[root].key

proc validOperation(v: ptr UncheckedArray[int64], at: int): bool =
  let op = v[at]
  let a = v[at + 1]
  let b = v[at + 2]
  let c = v[at + 3]
  if op == 0 or op == 1: return a in 0'i64..1 and b in 0'i64..1000 and c == 0
  if op == 2: return a in 0'i64..1 and b in 1'i64..65 and c == 0
  if op == 3: return a in 0'i64..1 and b in 0'i64..1 and a != b and c in 0'i64..1001
  if op == 4: return a in 0'i64..1 and b in 0'i64..1 and a != b and c == 0
  false

proc randomized_binary_search_tree_order_statistics_split_join*(input: ptr UncheckedArray[int64], length: csize_t): int64
    {.cdecl, exportc: "randomized_binary_search_tree_order_statistics_split_join".} =
  if input.isNil or length < 3 or length > 164: return -1
  let nValue = input[0]
  let qValue = input[1]
  let seed = input[2]
  if nValue < 0 or nValue > 32 or qValue < 0 or qValue > 32 or seed < 0 or seed > 4_294_967_295'i64: return -1
  let n = int(nValue)
  let q = int(qValue)
  if int(length) != 3 + n + 4 * q: return -1
  for i in 0 ..< n:
    if input[3 + i] < 0 or input[3 + i] > 1000 or (i > 0 and input[2 + i] >= input[3 + i]): return -1
  let start = 3 + n
  for op in 0 ..< q:
    if not validOperation(input, start + 4 * op): return -1

  var state = RbstState(randomState: uint32(seed))
  var roots = [-1, -1]
  for i in 0 ..< n: roots[0] = insertAbsent(state, roots[0], input[3 + i])
  var checksum = 0'i64
  var queryNumber = 0'i64
  for op in 0 ..< q:
    let at = start + 4 * op
    let code = input[at]
    let tree = int(input[at + 1])
    let argument = input[at + 2]
    let extra = input[at + 3]
    if code == 0:
      if not contains(state, roots[tree], argument): roots[tree] = insertAbsent(state, roots[tree], argument)
    elif code == 1: roots[tree] = eraseKey(state, roots[tree], argument)
    elif code == 2:
      inc queryNumber
      checksum += queryNumber * (kth(state, roots[tree], int(argument)) + 1)
    elif code == 3:
      let destination = int(argument)
      if roots[destination] >= 0: return -1
      let parts = splitTree(state, roots[tree], extra)
      roots[tree] = parts.low
      roots[destination] = parts.high
    else:
      let right = int(argument)
      let leftMax = maximum(state, roots[tree])
      let rightMin = minimum(state, roots[right])
      if leftMax >= 0 and rightMin >= 0 and leftMax >= rightMin: return -1
      roots[tree] = joinTrees(state, roots[tree], roots[right])
      roots[right] = -1
  checksum
