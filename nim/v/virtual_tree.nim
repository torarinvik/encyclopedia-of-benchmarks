const
  MaxN = 32
  MaxK = 32
  MaxInput = 66
  MaxVirtual = 32
  MaxCandidates = 64
  MaxWords = 1 + 3 * MaxVirtual

proc putWord(output: ptr UncheckedArray[uint8], offset: int, value: int64) =
  let bits = cast[uint64](value)
  for byte in 0 ..< 8:
    output[offset + byte] = uint8((bits shr (8 * byte)) and 255)

proc lca(a0, b0: int, parent, depth: openArray[int]): int =
  var a = a0
  var b = b0
  while depth[a] > depth[b]: a = parent[a]
  while depth[b] > depth[a]: b = parent[b]
  while a != b:
    a = parent[a]
    b = parent[b]
  a

proc isAncestor(a, b: int, tin, tout: openArray[int]): bool =
  tin[a] <= tin[b] and tin[b] < tout[a]

proc sortByTin(items: var array[MaxCandidates, int], count: int, tin: openArray[int]) =
  for i in 1 ..< count:
    let value = items[i]
    var j = i
    while j > 0 and tin[items[j - 1]] > tin[value]:
      items[j] = items[j - 1]
      dec j
    items[j] = value

proc virtual_tree*(input: ptr UncheckedArray[int64], length: csize_t,
    output: ptr UncheckedArray[uint8], capacity: csize_t): int64
    {.cdecl, exportc: "virtual_tree".} =
  if input.isNil or length < 2 or length > csize_t(MaxInput): return -1
  let nValue = input[0]
  let kValue = input[1]
  if nValue < 1 or nValue > MaxN or kValue < 0 or kValue > MaxK or kValue > nValue: return -1
  let n = int(nValue)
  let k = int(kValue)
  if length != csize_t(n + k + 1): return -1

  var parent: array[MaxN, int]
  var depth: array[MaxN, int]
  var children: array[MaxN, array[MaxN, int]]
  var childCount: array[MaxN, int]
  for vertex in 1 ..< n:
    let pValue = input[vertex + 1]
    if pValue < 0 or pValue >= nValue or pValue == int64(vertex): return -1
    let p = int(pValue)
    parent[vertex] = p
    children[p][childCount[p]] = vertex
    inc childCount[p]

  var marks: array[MaxK, int]
  for index in 0 ..< k:
    let markValue = input[n + 1 + index]
    if markValue < 0 or markValue >= nValue: return -1
    marks[index] = int(markValue)
    for previous in 0 ..< index:
      if marks[previous] == marks[index]: return -1

  var tin, tout: array[MaxN, int]
  var nodeStack, nextStack: array[MaxN, int]
  for vertex in 0 ..< MaxN:
    tin[vertex] = -1
    tout[vertex] = -1
  var timer = 0
  var top = 1
  var reached = 1
  nodeStack[0] = 0
  tin[0] = timer
  inc timer
  while top > 0:
    let frame = top - 1
    let current = nodeStack[frame]
    if nextStack[frame] == childCount[current]:
      tout[current] = timer
      dec top
      continue
    let child = children[current][nextStack[frame]]
    inc nextStack[frame]
    if tin[child] >= 0: return -1
    tin[child] = timer
    inc timer
    depth[child] = depth[current] + 1
    inc reached
    nodeStack[top] = child
    nextStack[top] = 0
    inc top
  if reached != n: return -1

  var words: array[MaxWords, int64]
  var wordCount = 1
  if k == 0:
    words[0] = 0
  else:
    for i in 1 ..< k:
      let value = marks[i]
      var j = i
      while j > 0 and tin[marks[j - 1]] > tin[value]:
        marks[j] = marks[j - 1]
        dec j
      marks[j] = value
    var nodes: array[MaxCandidates, int]
    var count = 0
    nodes[count] = 0
    inc count
    for index in 0 ..< k:
      nodes[count] = marks[index]
      inc count
    for index in 1 ..< k:
      nodes[count] = lca(marks[index - 1], marks[index], parent, depth)
      inc count
    sortByTin(nodes, count, tin)
    var unique: array[MaxVirtual, int]
    var uniqueCount = 0
    for index in 0 ..< count:
      if uniqueCount == 0 or unique[uniqueCount - 1] != nodes[index]:
        unique[uniqueCount] = nodes[index]
        inc uniqueCount
    words[0] = int64(uniqueCount)
    var stack: array[MaxVirtual, int]
    var stackSize = 0
    for index in 0 ..< uniqueCount:
      let vertex = unique[index]
      while stackSize > 0 and not isAncestor(stack[stackSize - 1], vertex, tin, tout):
        dec stackSize
      let virtualParent = if stackSize == 0: vertex else: stack[stackSize - 1]
      words[wordCount] = int64(vertex)
      words[wordCount + 1] = int64(virtualParent)
      words[wordCount + 2] = int64(depth[vertex] - depth[virtualParent])
      wordCount += 3
      stack[stackSize] = vertex
      inc stackSize

  let outputBytes = wordCount * 8
  if output.isNil or capacity < csize_t(outputBytes): return -2
  for index in 0 ..< wordCount: putWord(output, index * 8, words[index])
  int64(outputBytes)
