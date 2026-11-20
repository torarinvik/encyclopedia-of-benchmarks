const MaxN = 16

proc repairFind(parent: var array[MaxN, int], nodeInput: int): int =
  var node = nodeInput
  while parent[node] != node:
    parent[node] = parent[parent[node]]
    node = parent[node]
  node

proc redundant_directed_connection_repair*(input: ptr UncheckedArray[int64], length: csize_t): int64
    {.cdecl, exportc: "redundant_directed_connection_repair".} =
  if input == nil or length < csize_t(1) or length > csize_t(34): return -1
  let nValue = input[0]
  if nValue < 3'i64 or nValue > int64(MaxN): return -1
  let n = int(nValue)
  if int(length) != 1 + 2 * n: return -1
  var from, to: array[MaxN, int]
  var incoming: array[MaxN, int]
  var parent: array[MaxN, int]
  var sizes: array[MaxN, int]
  for node in 0 ..< n:
    incoming[node] = -1
    parent[node] = node
    sizes[node] = 1
  for edge in 0 ..< n:
    let u = input[1 + 2*edge]
    let v = input[2 + 2*edge]
    if u < 0'i64 or u >= nValue or v < 0'i64 or v >= nValue or u == v: return -1
    from[edge] = int(u)
    to[edge] = int(v)
    for prior in 0 ..< edge:
      if from[prior] == from[edge] and to[prior] == to[edge]: return -1
  var firstParent = -1
  var secondParent = -1
  for edge in 0 ..< n:
    let child = to[edge]
    if incoming[child] < 0: incoming[child] = edge
    else:
      firstParent = incoming[child]
      secondParent = edge
      break
  var cycleEdge = -1
  for edge in 0 ..< n:
    if edge == secondParent: continue
    var a = repairFind(parent, from[edge])
    var b = repairFind(parent, to[edge])
    if a == b:
      cycleEdge = edge
      break
    if sizes[a] < sizes[b]: swap(a, b)
    parent[b] = a
    sizes[a] += sizes[b]
  if cycleEdge >= 0:
    if secondParent >= 0: return int64(firstParent)
    return int64(cycleEdge)
  int64(secondParent)
