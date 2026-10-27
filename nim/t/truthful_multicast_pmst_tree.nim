const MaxN = 8
const MaxM = 28
const MaxInput = 95
const MaxOutput = 176

proc findRoot(parent: var array[MaxN, int], value: int): int =
  var x = value
  while parent[x] != x:
    parent[x] = parent[parent[x]]
    x = parent[x]
  x

proc putI64(output: ptr UncheckedArray[uint8], offset: int, value: int64) =
  let bits = cast[uint64](value)
  for b in 0 ..< 8: output[offset+b] = uint8((bits shr (8*b)) and 255)

proc truthful_multicast_pmst_tree*(values: ptr UncheckedArray[int64], length: csize_t,
    output: ptr UncheckedArray[uint8], capacity: csize_t): int64
    {.cdecl, exportc: "truthful_multicast_pmst_tree".} =
  if values == nil or length < 4 or length > csize_t(MaxInput): return -1
  if values[0] < 2 or values[0] > MaxN or values[1] < values[0]-1 or values[1] > MaxM or
      values[2] < 0 or values[2] >= values[0] or values[3] < 1 or values[3] >= values[0]: return -1
  let n = int(values[0]); let m = int(values[1]); let source = int(values[2]); let receiverCount = int(values[3])
  if int(length) != 4+3*m+receiverCount: return -1
  var eu, ev, ew, order: array[MaxM, int]
  var previousU = -1; var previousV = -1
  for i in 0 ..< m:
    let u = values[4+3*i]; let v = values[5+3*i]; let w = values[6+3*i]
    if u < 0 or v <= u or v >= int64(n) or w < 1 or w > 100: return -1
    if i > 0 and (u < int64(previousU) or (u == int64(previousU) and v <= int64(previousV))): return -1
    eu[i] = int(u); ev[i] = int(v); ew[i] = int(w); order[i] = i
    previousU = int(u); previousV = int(v)
  var receivers: array[MaxN, int]
  var previousReceiver = -1
  for i in 0 ..< receiverCount:
    let receiver = values[4+3*m+i]
    if receiver < 0 or receiver >= int64(n) or receiver == int64(source) or (i > 0 and receiver <= int64(previousReceiver)): return -1
    receivers[i] = int(receiver); previousReceiver = int(receiver)
  for i in 1 ..< m:
    let key = order[i]; var j = i
    while j > 0:
      let q = order[j-1]
      if ew[q] < ew[key] or (ew[q] == ew[key] and (eu[q] < eu[key] or (eu[q] == eu[key] and ev[q] < ev[key]))): break
      order[j] = q; dec j
    order[j] = key
  var dsu: array[MaxN, int]
  for i in 0 ..< n: dsu[i] = i
  var tu, tv, tw: array[MaxN, int]
  var treeCount = 0
  var z = 0
  while z < m and treeCount < n-1:
    let e = order[z]
    let a = findRoot(dsu, eu[e]); let b = findRoot(dsu, ev[e])
    if a != b:
      dsu[a] = b; tu[treeCount] = eu[e]; tv[treeCount] = ev[e]; tw[treeCount] = ew[e]; inc treeCount
    inc z
  if treeCount != n-1: return -1
  var edgeAt: array[MaxN*MaxN, int]
  for e in 0 ..< treeCount: edgeAt[tu[e]*MaxN+tv[e]] = e+1; edgeAt[tv[e]*MaxN+tu[e]] = e+1
  var parent, parentEdge: array[MaxN, int]
  for i in 0 ..< n: parent[i] = -1; parentEdge[i] = -1
  parent[source] = source
  var stack: array[MaxN, int]; var top = 1; stack[0] = source
  while top > 0:
    dec top
    let u = stack[top]
    for v in 0 ..< n:
      let edgePlus = edgeAt[u*MaxN+v]
      if edgePlus > 0 and parent[v] < 0:
        parent[v] = u; parentEdge[v] = edgePlus-1; stack[top] = v; inc top
  var keep: array[MaxN, bool]
  for i in 0 ..< receiverCount:
    var v = receivers[i]
    while v != source:
      if parent[v] < 0: return -1
      keep[parentEdge[v]] = true; v = parent[v]
  var selected: array[MaxN, int]; var count = 0
  for e in 0 ..< treeCount:
    if keep[e]: selected[count] = e; inc count
  for i in 1 ..< count:
    let key = selected[i]; var j = i
    while j > 0 and (tu[selected[j-1]] > tu[key] or (tu[selected[j-1]] == tu[key] and tv[selected[j-1]] > tv[key])):
      selected[j] = selected[j-1]; dec j
    selected[j] = key
  let byteCount = 8*(1+3*count)
  if output == nil or capacity < csize_t(byteCount): return -2
  var staged: array[MaxOutput, uint8]
  putI64(addr staged[0], 0, int64(count))
  for i in 0 ..< count:
    let e = selected[i]
    putI64(addr staged[0], 8*(1+3*i), int64(tu[e])); putI64(addr staged[0], 8*(2+3*i), int64(tv[e])); putI64(addr staged[0], 8*(3+3*i), int64(tw[e]))
  for i in 0 ..< byteCount: output[i] = staged[i]
  int64(byteCount)
