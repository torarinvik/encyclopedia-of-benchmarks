const MaxN = 16
const MaxM = 20

proc secretFind(parent: var array[MaxN, int], nodeInput: int): int =
  var node = nodeInput
  while parent[node] != node:
    parent[node] = parent[parent[node]]
    node = parent[node]
  node

proc secretJoin(parent: var array[MaxN, int], sizes: var array[MaxN, int], left, right: int) =
  var a = secretFind(parent, left)
  var b = secretFind(parent, right)
  if a == b: return
  if sizes[a] < sizes[b]: swap(a, b)
  parent[b] = a
  sizes[a] += sizes[b]

proc secret_sharing_time_batched_dsu*(input: ptr UncheckedArray[int64], length: csize_t): int64
    {.cdecl, exportc: "secret_sharing_time_batched_dsu".} =
  if input == nil or length < csize_t(3) or length > csize_t(64): return -1
  let nValue = input[0]
  let firstValue = input[1]
  let mValue = input[2]
  if nValue < 2'i64 or nValue > int64(MaxN) or firstValue < 1 or firstValue >= nValue
      or mValue < 0 or mValue > int64(MaxM): return -1
  let n = int(nValue)
  let first = int(firstValue)
  let m = int(mValue)
  if int(length) != 3 + 3 * m: return -1
  for i in 0 ..< m:
    let u = input[3 + 3*i]
    let v = input[4 + 3*i]
    let time = input[5 + 3*i]
    if u < 0'i64 or u >= nValue or v < 0'i64 or v >= nValue or u == v
        or time < 1'i64 or time > 20'i64: return -1

  var parent, sizes: array[MaxN, int]
  for node in 0 ..< n:
    parent[node] = node
    sizes[node] = 1
  secretJoin(parent, sizes, 0, first)
  for time in 1 .. 20:
    var touched: array[MaxN, bool]
    for i in 0 ..< m:
      let u = int(input[3 + 3*i])
      let v = int(input[4 + 3*i])
      if input[5 + 3*i] == int64(time):
        secretJoin(parent, sizes, u, v)
        touched[u] = true
        touched[v] = true
    let knownRoot = secretFind(parent, 0)
    for node in 0 ..< n:
      if touched[node] and secretFind(parent, node) != knownRoot:
        parent[node] = node
        sizes[node] = 1
  let knownRoot = secretFind(parent, 0)
  var result = 0'i64
  for node in 0 ..< n:
    if secretFind(parent, node) == knownRoot: result = result or (1'i64 shl node)
  result
