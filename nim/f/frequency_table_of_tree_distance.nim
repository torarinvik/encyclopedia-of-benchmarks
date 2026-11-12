const MaxN = 64
const MaxInputValues = 1 + 2 * (MaxN - 1)

proc findRoot(parent: var array[MaxN, int], item: int): int =
  var node = item
  while parent[node] != node:
    parent[node] = parent[parent[node]]
    node = parent[node]
  node

proc solveComponent(n: int, adjacent: var array[MaxN, array[MaxN, bool]],
    removed: var array[MaxN, bool], answer: var array[MaxN, int64], start: int) =
  var order, parent, subtree, stack: array[MaxN, int]
  var orderCount = 0
  var top = 1
  stack[0] = start
  parent[start] = start
  subtree[start] = 1
  order[orderCount] = start
  inc orderCount
  while top > 0:
    dec top
    let vertex = stack[top]
    for neighbor in 0 ..< n:
      if not adjacent[vertex][neighbor] or removed[neighbor] or neighbor == parent[vertex]: continue
      parent[neighbor] = vertex
      subtree[neighbor] = 1
      order[orderCount] = neighbor
      inc orderCount
      stack[top] = neighbor
      inc top
  var position = orderCount
  while position > 1:
    dec position
    let vertex = order[position]
    subtree[parent[vertex]] += subtree[vertex]

  var centroid = MaxN
  for position in 0 ..< orderCount:
    let vertex = order[position]
    var largestPart = orderCount - subtree[vertex]
    for neighbor in 0 ..< n:
      if adjacent[vertex][neighbor] and not removed[neighbor] and parent[neighbor] == vertex and
          subtree[neighbor] > largestPart:
        largestPart = subtree[neighbor]
    if 2 * largestPart <= orderCount and (centroid == MaxN or vertex < centroid): centroid = vertex

  var frequency: array[MaxN, int64]
  var frequencyMax = 0
  frequency[0] = 1
  removed[centroid] = true
  for child in 0 ..< n:
    if not adjacent[centroid][child] or removed[child]: continue
    var localFrequency: array[MaxN, int]
    var walkVertex, walkParent, walkDepth: array[MaxN, int]
    var localMax = 0
    var walkTop = 1
    walkVertex[0] = child
    walkParent[0] = centroid
    walkDepth[0] = 1
    while walkTop > 0:
      dec walkTop
      let vertex = walkVertex[walkTop]
      let previous = walkParent[walkTop]
      let depth = walkDepth[walkTop]
      inc localFrequency[depth]
      if depth > localMax: localMax = depth
      for neighbor in 0 ..< n:
        if adjacent[vertex][neighbor] and not removed[neighbor] and neighbor != previous:
          walkVertex[walkTop] = neighbor
          walkParent[walkTop] = vertex
          walkDepth[walkTop] = depth + 1
          inc walkTop
    for depth in 1 .. localMax:
      for other in 0 .. frequencyMax:
        if depth + other < n:
          answer[depth + other] += int64(localFrequency[depth]) * frequency[other]
    for depth in 1 .. localMax:
      frequency[depth] += int64(localFrequency[depth])
    if localMax > frequencyMax: frequencyMax = localMax

  for child in 0 ..< n:
    if adjacent[centroid][child] and not removed[child]:
      solveComponent(n, adjacent, removed, answer, child)

proc storeI64Le(output: ptr UncheckedArray[uint8], offset: int, value: int64) =
  let bits = cast[uint64](value)
  for byte in 0 ..< 8:
    output[offset + byte] = uint8((bits shr (8 * byte)) and 255)

proc frequency_table_of_tree_distance*(input: ptr UncheckedArray[int64], length: csize_t,
    output: ptr UncheckedArray[uint8], capacity: csize_t): int64
    {.cdecl, exportc: "frequency_table_of_tree_distance".} =
  if input.isNil or length < 1 or length > csize_t(MaxInputValues): return -1
  let nValue = input[0]
  if nValue < 1 or nValue > MaxN: return -1
  let n = int(nValue)
  if length != csize_t(1 + 2 * (n - 1)): return -1

  var adjacent: array[MaxN, array[MaxN, bool]]
  var dsuParent, dsuSize: array[MaxN, int]
  for vertex in 0 ..< n:
    dsuParent[vertex] = vertex
    dsuSize[vertex] = 1
  for edge in 0 ..< (n - 1):
    let offset = 1 + 2 * edge
    let leftValue = input[offset]
    let rightValue = input[offset + 1]
    if leftValue < 0 or leftValue >= nValue or rightValue < 0 or
       rightValue >= nValue or leftValue == rightValue: return -1
    let left = int(leftValue)
    let right = int(rightValue)
    var rootLeft = findRoot(dsuParent, left)
    var rootRight = findRoot(dsuParent, right)
    if rootLeft == rootRight: return -1
    if dsuSize[rootLeft] < dsuSize[rootRight]: swap(rootLeft, rootRight)
    dsuParent[rootRight] = rootLeft
    dsuSize[rootLeft] += dsuSize[rootRight]
    adjacent[left][right] = true
    adjacent[right][left] = true

  var removed: array[MaxN, bool]
  var answer: array[MaxN, int64]
  solveComponent(n, adjacent, removed, answer, 0)
  let required = 8 * (n - 1)
  if output.isNil or capacity < csize_t(required): return -2
  for distance in 1 ..< n:
    storeI64Le(output, 8 * (distance - 1), answer[distance])
  int64(required)
