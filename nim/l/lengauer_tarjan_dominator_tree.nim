const
  MaxV = 63
  MaxE = 2047
  MaxInput = 4097

proc ltEval(vertex: int, ancestor: var array[MaxV + 1, int],
    label: var array[MaxV + 1, int], semi: openArray[int],
    path: var array[MaxV + 1, int]): int =
  if ancestor[vertex] == 0: return vertex
  var used = 0
  var current = vertex
  while ancestor[ancestor[current]] != 0:
    path[used] = current
    inc used
    current = ancestor[current]
  while used > 0:
    dec used
    current = path[used]
    let p = ancestor[current]
    if semi[label[p]] < semi[label[current]]: label[current] = label[p]
    ancestor[current] = ancestor[p]
  label[vertex]

proc lengauer_tarjan_dominator_tree*(input: ptr UncheckedArray[int64], length: csize_t,
    output: ptr UncheckedArray[uint8], capacity: csize_t): int64
    {.cdecl, exportc: "lengauer_tarjan_dominator_tree".} =
  if input.isNil or length < 3 or length > csize_t(MaxInput): return -1
  let nv, rootValue, me = input[0], input[1], input[2]
  if nv < 1 or nv > MaxV or rootValue < 0 or rootValue >= nv or me < 0 or me > MaxE: return -1
  let n = int(nv)
  let root = int(rootValue)
  let m = int(me)
  if length != csize_t(3 + 2 * m): return -1

  var outmask: array[MaxV, uint64]
  var outHead: array[MaxV, int]
  var edgeSource, edgeTarget, outNext, predNext: array[MaxE, int]
  var predHead, vertexAt, parent, semi, ancestor, label, immediate, bucketHead, bucketNext: array[MaxV + 1, int]
  var dfsNumber, nodeStack, edgeStack: array[MaxV, int]
  var evalPath: array[MaxV + 1, int]
  var staged: array[MaxV, uint8]
  for vertex in 0 ..< n: outHead[vertex] = -1
  for vertex in 0 .. MaxV:
    predHead[vertex] = -1
    bucketHead[vertex] = -1

  var edgeCount = 0
  for i in 0 ..< m:
    let sv = input[3 + 2 * i]
    let tv = input[4 + 2 * i]
    if sv < 0 or sv >= nv or tv < 0 or tv >= nv: return -1
    let source = int(sv)
    let target = int(tv)
    let bit = 1'u64 shl target
    if (outmask[source] and bit) == 0:
      outmask[source] = outmask[source] or bit
      edgeSource[edgeCount] = source
      edgeTarget[edgeCount] = target
      outNext[edgeCount] = outHead[source]
      outHead[source] = edgeCount
      inc edgeCount

  var dfsCount = 1
  var top = 1
  dfsNumber[root] = 1
  vertexAt[1] = root
  nodeStack[0] = root
  edgeStack[0] = outHead[root]
  while top > 0:
    let frame = top - 1
    let current = nodeStack[frame]
    let edge = edgeStack[frame]
    if edge == -1:
      dec top
      continue
    edgeStack[frame] = outNext[edge]
    let target = edgeTarget[edge]
    if dfsNumber[target] == 0:
      inc dfsCount
      dfsNumber[target] = dfsCount
      vertexAt[dfsCount] = target
      parent[dfsCount] = dfsNumber[current]
      nodeStack[top] = target
      edgeStack[top] = outHead[target]
      inc top

  for edge in 0 ..< edgeCount:
    let sourceNumber = dfsNumber[edgeSource[edge]]
    let targetNumber = dfsNumber[edgeTarget[edge]]
    if sourceNumber != 0 and targetNumber != 0:
      predNext[edge] = predHead[targetNumber]
      predHead[targetNumber] = edge
  for vertex in 1 .. dfsCount:
    semi[vertex] = vertex
    label[vertex] = vertex

  for w in countdown(dfsCount, 2):
    var edge = predHead[w]
    while edge != -1:
      let predecessor = dfsNumber[edgeSource[edge]]
      let representative = ltEval(predecessor, ancestor, label, semi, evalPath)
      if semi[representative] < semi[w]: semi[w] = semi[representative]
      edge = predNext[edge]
    bucketNext[w] = bucketHead[semi[w]]
    bucketHead[semi[w]] = w
    ancestor[w] = parent[w]
    let owner = parent[w]
    var member = bucketHead[owner]
    bucketHead[owner] = -1
    while member != -1:
      let next = bucketNext[member]
      let representative = ltEval(member, ancestor, label, semi, evalPath)
      if semi[representative] < semi[member]: immediate[member] = representative
      else: immediate[member] = owner
      member = next

  for w in 2 .. dfsCount:
    if immediate[w] != semi[w]: immediate[w] = immediate[immediate[w]]
  immediate[1] = 1
  for vertex in 0 ..< n:
    let number = dfsNumber[vertex]
    if number == 0: staged[vertex] = 255
    else: staged[vertex] = uint8(vertexAt[immediate[number]])
  if output.isNil or capacity < csize_t(n): return -2
  for vertex in 0 ..< n: output[vertex] = staged[vertex]
  int64(n)
