const MaxNodes = 256
const MaxQueries = 1024
const MaxArcs = 2 * (MaxNodes - 1)
const MaxInput = 4 + 2 * (MaxNodes - 1) + 2 * MaxQueries

proc lowbit(value: uint32): uint32 = value and (0'u32 - value)

proc highbit(value: uint32): uint32 =
  var rest = value
  while rest != 0:
    result = rest
    rest = rest shr 1

proc schieber_vishkin_lca*(input: ptr UncheckedArray[int64], inputLength: csize_t,
    output: ptr UncheckedArray[uint8], outputCapacity: csize_t): int64
    {.cdecl, exportc: "schieber_vishkin_lca".} =
  if input.isNil or inputLength < 4 or inputLength > csize_t(MaxInput + 1): return -1
  if input[0] < 1'i64 or input[0] > int64(MaxNodes): return -1
  let n = int(input[0])
  if input[1] < 0'i64 or input[1] >= int64(n) or input[2] != int64(n - 1) or
      input[3] < 0'i64 or input[3] > int64(MaxQueries): return -1
  let m = int(input[2])
  let q = int(input[3])
  let queryOffset = 4 + 2 * m
  if inputLength != csize_t(queryOffset + 2 * q): return -1
  let root = int(input[1])

  var arcTo, arcNext: array[MaxArcs, int]
  var nodeHead: array[MaxNodes, int]
  var parent, order, stackNode, stackArc: array[MaxNodes, int]
  var preorder: array[MaxNodes, int]
  var inlabel, ascendant: array[MaxNodes, uint32]
  var pathHead: array[MaxNodes, int]
  var answers: array[MaxQueries, uint8]
  for node in 0 ..< n:
    nodeHead[node] = -1
    parent[node] = -2

  var arcs = 0
  for edge in 0 ..< m:
    let aValue = input[4 + 2 * edge]
    let bValue = input[5 + 2 * edge]
    if aValue < 0'i64 or aValue >= int64(n) or bValue < 0'i64 or bValue >= int64(n) or aValue == bValue:
      return -1
    let a = int(aValue)
    let b = int(bValue)
    arcTo[arcs] = b; arcNext[arcs] = nodeHead[a]; nodeHead[a] = arcs; inc arcs
    arcTo[arcs] = a; arcNext[arcs] = nodeHead[b]; nodeHead[b] = arcs; inc arcs
  for query in 0 ..< q:
    for side in 0 .. 1:
      let node = input[queryOffset + 2 * query + side]
      if node < 0'i64 or node >= int64(n): return -1

  var reached = 1
  var top = 1
  parent[root] = -1
  preorder[root] = 1
  order[0] = root
  stackNode[0] = root
  stackArc[0] = nodeHead[root]
  while top > 0:
    let slot = top - 1
    let node = stackNode[slot]
    let arc = stackArc[slot]
    if arc < 0:
      dec top
      continue
    stackArc[slot] = arcNext[arc]
    let neighbor = arcTo[arc]
    if neighbor == parent[node]: continue
    if parent[neighbor] != -2: return -1
    parent[neighbor] = node
    preorder[neighbor] = reached + 1
    order[reached] = neighbor
    inc reached
    stackNode[top] = neighbor
    stackArc[top] = nodeHead[neighbor]
    inc top
  if reached != n: return -1
  if q > int(outputCapacity) or (q > 0 and output.isNil): return -2

  for node in 0 ..< n: inlabel[node] = uint32(preorder[node])
  for i in countdown(n - 1, 1):
    let node = order[i]
    let p = parent[node]
    if lowbit(inlabel[p]) < lowbit(inlabel[node]): inlabel[p] = inlabel[node]
  for position in 0 ..< n:
    let node = order[position]
    if parent[node] < 0:
      ascendant[node] = lowbit(inlabel[node])
      pathHead[preorder[node] - 1] = node
    else:
      let p = parent[node]
      ascendant[node] = ascendant[p] or lowbit(inlabel[node])
      if inlabel[node] != inlabel[p]: pathHead[preorder[node] - 1] = p
      else: pathHead[preorder[node] - 1] = pathHead[preorder[p] - 1]

  for query in 0 ..< q:
    let u = int(input[queryOffset + 2 * query])
    let v = int(input[queryOffset + 2 * query + 1])
    let lu = lowbit(inlabel[u])
    let lv = lowbit(inlabel[v])
    var mask = highbit((inlabel[u] xor inlabel[v]) or lu or lv) - 1'u32
    let j = lowbit(ascendant[u] and ascendant[v] and (not mask))
    if j == 0: return -1
    var x = u
    var y = v
    if j != lu:
      mask = highbit(ascendant[u] and (j - 1'u32)) - 1'u32
      let index = ((preorder[u] and not int(mask)) or (int(mask) + 1)) - 1
      x = pathHead[index]
    if j != lv:
      mask = highbit(ascendant[v] and (j - 1'u32)) - 1'u32
      let index = ((preorder[v] and not int(mask)) or (int(mask) + 1)) - 1
      y = pathHead[index]
    answers[query] = uint8(if preorder[x] < preorder[y]: x else: y)
  for query in 0 ..< q: output[query] = answers[query]
  int64(q)
