const MaxNodes = 256
const MaxQueries = 1024
const MaxArcs = 510
const MaxEuler = 2 * MaxNodes - 1
const MaxBlocks = 128
const MaxLevels = 8
const MaxMicro = 4

proc shallower(depth: var array[MaxEuler, int], a, b: int): int =
  if depth[a] != depth[b]:
    return if depth[a] < depth[b]: a else: b
  min(a, b)

proc rangeMinimum(first, last, eulerCount, blockSize: int,
    depth: var array[MaxEuler, int], pattern: var array[MaxBlocks, int],
    micro: var array[8, array[MaxMicro, array[MaxMicro, int]]],
    macroTable: var array[MaxLevels, array[MaxBlocks, int]],
    logs: var array[MaxBlocks + 1, int]): int =
  let blockA = first div blockSize
  let blockB = last div blockSize
  let offsetA = first mod blockSize
  let offsetB = last mod blockSize
  if blockA == blockB:
    return blockA * blockSize + micro[pattern[blockA]][offsetA][offsetB]
  let baseA = blockA * blockSize
  let baseB = blockB * blockSize
  let lengthA = min(blockSize, eulerCount - baseA)
  var best = baseA + micro[pattern[blockA]][offsetA][lengthA - 1]
  let rightBest = baseB + micro[pattern[blockB]][0][offsetB]
  best = shallower(depth, best, rightBest)
  if blockB > blockA + 1:
    let lo = blockA + 1
    let hi = blockB - 1
    let count = hi - lo + 1
    let level = logs[count]
    let span = 1 shl level
    best = shallower(depth, best, macroTable[level][lo])
    best = shallower(depth, best, macroTable[level][hi - span + 1])
  best

proc lowest_common_ancestor_farach_colton_bender*(input: ptr UncheckedArray[int64], inputLength: csize_t,
    output: ptr UncheckedArray[uint8], outputCapacity: csize_t): int64
    {.cdecl, exportc: "lowest_common_ancestor_farach_colton_bender".} =
  if input.isNil or inputLength < 4: return -1
  if input[0] < 1'i64 or input[0] > MaxNodes: return -1
  let nodeCount = int(input[0])
  if input[1] < 0'i64 or input[1] >= int64(nodeCount) or input[2] != int64(nodeCount - 1) or
      input[3] < 0'i64 or input[3] > MaxQueries: return -1
  let edgeCount = int(input[2])
  let queryCount = int(input[3])
  let queryOffset = 4 + 2 * edgeCount
  if inputLength != csize_t(queryOffset + 2 * queryCount): return -1
  let root = int(input[1])

  var head: array[MaxNodes, int]
  var arcTo, arcNext: array[MaxArcs, int]
  var parent, treeDepth, first: array[MaxNodes, int]
  var euler, eulerDepth: array[MaxEuler, int]
  var stackNode, stackArc: array[MaxNodes, int]
  for node in 0 ..< nodeCount:
    head[node] = -1
    parent[node] = -2
  var arcs = 0
  for edge in 0 ..< edgeCount:
    let uValue = input[4 + 2 * edge]
    let vValue = input[5 + 2 * edge]
    if uValue < 0'i64 or uValue >= int64(nodeCount) or vValue < 0'i64 or vValue >= int64(nodeCount) or uValue == vValue:
      return -1
    let u = int(uValue)
    let v = int(vValue)
    arcTo[arcs] = v; arcNext[arcs] = head[u]; head[u] = arcs; inc arcs
    arcTo[arcs] = u; arcNext[arcs] = head[v]; head[v] = arcs; inc arcs
  for query in 0 ..< queryCount:
    for side in 0 .. 1:
      let node = input[queryOffset + 2 * query + side]
      if node < 0'i64 or node >= int64(nodeCount): return -1

  var eulerCount = 1
  var top = 1
  var reached = 1
  parent[root] = -1
  first[root] = 0
  euler[0] = root
  stackNode[0] = root
  stackArc[0] = head[root]
  while top > 0:
    let slot = top - 1
    let node = stackNode[slot]
    let arc = stackArc[slot]
    if arc < 0:
      dec top
      if top > 0:
        let up = stackNode[top - 1]
        euler[eulerCount] = up
        eulerDepth[eulerCount] = treeDepth[up]
        inc eulerCount
      continue
    stackArc[slot] = arcNext[arc]
    let neighbor = arcTo[arc]
    if neighbor == parent[node]: continue
    if parent[neighbor] != -2: return -1
    parent[neighbor] = node
    treeDepth[neighbor] = treeDepth[node] + 1
    first[neighbor] = eulerCount
    euler[eulerCount] = neighbor
    eulerDepth[eulerCount] = treeDepth[neighbor]
    inc eulerCount
    inc reached
    stackNode[top] = neighbor
    stackArc[top] = head[neighbor]
    inc top
  if reached != nodeCount: return -1
  if queryCount > int(outputCapacity) or (queryCount > 0 and output.isNil): return -2

  var logarithm = 0
  var value = eulerCount
  while value > 1:
    value = value div 2
    inc logarithm
  let blockSize = max(1, logarithm div 2)
  let blockCount = (eulerCount + blockSize - 1) div blockSize
  var micro: array[8, array[MaxMicro, array[MaxMicro, int]]]
  var pattern: array[MaxBlocks, int]
  var logs: array[MaxBlocks + 1, int]
  var macroTable: array[MaxLevels, array[MaxBlocks, int]]
  for shape in 0 ..< (1 shl (blockSize - 1)):
    var relative: array[MaxMicro, int]
    for step in 0 ..< blockSize - 1:
      relative[step + 1] = relative[step] + (if ((shape shr step) and 1) != 0: 1 else: -1)
    for left in 0 ..< blockSize:
      for right in left ..< blockSize:
        var best = left
        for at in left + 1 .. right:
          if relative[at] < relative[best]: best = at
        micro[shape][left][right] = best
  for block in 0 ..< blockCount:
    let base = block * blockSize
    let end = min(eulerCount, base + blockSize)
    var best = base
    for at in base ..< end - 1:
      if eulerDepth[at + 1] > eulerDepth[at]: pattern[block] = pattern[block] or (1 shl (at - base))
      best = shallower(eulerDepth, best, at + 1)
    macroTable[0][block] = best
  for count in 2 .. blockCount: logs[count] = logs[count div 2] + 1
  var macroLevels = 1
  while (1 shl macroLevels) <= blockCount and macroLevels < MaxLevels:
    let half = 1 shl (macroLevels - 1)
    let span = 2 * half
    for block in 0 .. blockCount - span:
      macroTable[macroLevels][block] = shallower(eulerDepth,
        macroTable[macroLevels - 1][block], macroTable[macroLevels - 1][block + half])
    inc macroLevels

  var answers: array[MaxQueries, uint8]
  for query in 0 ..< queryCount:
    let u = int(input[queryOffset + 2 * query])
    let v = int(input[queryOffset + 2 * query + 1])
    var left = first[u]
    var right = first[v]
    if left > right: swap(left, right)
    answers[query] = uint8(euler[rangeMinimum(left, right, eulerCount, blockSize,
      eulerDepth, pattern, micro, macroTable, logs)])
  for query in 0 ..< queryCount: output[query] = answers[query]
  int64(queryCount)
