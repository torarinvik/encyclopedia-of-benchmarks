const MaxNodes = 128
const MaxQueries = 256
const MaxLevels = 7
const MaxValidInputLength = 770
const MaxParseableInputLength = 771

proc lowestCommonAncestor(leftArg, rightArg: int, depth: var array[MaxNodes, int],
                          up: var array[MaxNodes, array[MaxLevels, int]], levels: int): int =
  var left = leftArg
  var right = rightArg
  if depth[left] < depth[right]: swap(left, right)
  var difference = depth[left] - depth[right]
  var bit = 0
  while difference > 0:
    if (difference and 1) != 0: left = up[left][bit]
    difference = difference shr 1
    inc bit
  if left == right: return left
  var level = levels - 1
  while level >= 0:
    if up[left][level] != up[right][level]:
      left = up[left][level]
      right = up[right][level]
    dec level
  up[left][0]

proc lca_binary_lifting_benchmark*(input: ptr UncheckedArray[int64], length: csize_t): int64
    {.cdecl, exportc: "lca_binary_lifting_benchmark".} =
  if input.isNil or length < csize_t(4) or length > csize_t(MaxParseableInputLength): return -1
  if input[0] < 2 or input[0] > MaxNodes: return -1
  let nodeCount = int(input[0])
  if input[1] < 0 or input[1] >= int64(nodeCount) or input[2] != int64(nodeCount - 1): return -1
  let root = int(input[1])
  let edgeCount = nodeCount - 1
  let queryCountIndex = 3 + 2 * edgeCount
  if queryCountIndex >= int(length): return -1
  let queryCountValue = input[queryCountIndex]
  if queryCountValue < 0 or queryCountValue > MaxQueries: return -1
  let queryCount = int(queryCountValue)
  if length != csize_t(queryCountIndex + 1 + 2 * queryCount) or length > csize_t(MaxValidInputLength): return -1

  var adjacency: array[MaxNodes, array[MaxNodes, bool]]
  for edge in 0 ..< edgeCount:
    let leftValue = input[3 + 2 * edge]
    let rightValue = input[4 + 2 * edge]
    if leftValue < 0 or leftValue >= int64(nodeCount) or rightValue < 0 or rightValue >= int64(nodeCount) or leftValue == rightValue: return -1
    let left = int(leftValue)
    let right = int(rightValue)
    if adjacency[left][right]: return -1
    adjacency[left][right] = true
    adjacency[right][left] = true

  var parent: array[MaxNodes, int]
  var depth: array[MaxNodes, int]
  var visited: array[MaxNodes, bool]
  var queue: array[MaxNodes, int]
  var head = 0
  var tail = 1
  queue[0] = root
  visited[root] = true
  parent[root] = root
  while head < tail:
    let node = queue[head]
    inc head
    for child in 0 ..< nodeCount:
      if not adjacency[node][child]: continue
      if not visited[child]:
        visited[child] = true
        parent[child] = node
        depth[child] = depth[node] + 1
        queue[tail] = child
        inc tail
      elif child != parent[node]:
        return -1
  if tail != nodeCount: return -1

  var levels = 0
  var power = 1
  while power < nodeCount:
    power *= 2
    inc levels
  var up: array[MaxNodes, array[MaxLevels, int]]
  for node in 0 ..< nodeCount: up[node][0] = parent[node]
  for level in 1 ..< levels:
    for node in 0 ..< nodeCount: up[node][level] = up[up[node][level - 1]][level - 1]

  var checksum = 0'i64
  let queriesStart = queryCountIndex + 1
  for query in 0 ..< queryCount:
    let leftValue = input[queriesStart + 2 * query]
    let rightValue = input[queriesStart + 2 * query + 1]
    if leftValue < 0 or leftValue >= int64(nodeCount) or rightValue < 0 or rightValue >= int64(nodeCount): return -1
    let ancestor = lowestCommonAncestor(int(leftValue), int(rightValue), depth, up, levels)
    checksum += int64(query + 1) * int64(ancestor + 1)
  checksum
