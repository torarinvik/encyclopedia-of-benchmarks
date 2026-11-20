const MaxN = 8
const MaxM = 20
const MaxInput = 63

type Edge = object
  u, v, weight: int32

proc graphConnected(n: int, edges: array[MaxM, Edge], m: int, active: uint32): bool =
  var seen: array[MaxN, bool]
  var queue: array[MaxN, int]
  var head = 0
  var tail = 1
  seen[0] = true
  queue[0] = 0
  while head < tail:
    let vertex = queue[head]
    inc head
    for id in 0 ..< m:
      if ((active shr id) and 1'u32) == 0: continue
      var neighbor = -1
      if int(edges[id].u) == vertex: neighbor = int(edges[id].v)
      elif int(edges[id].v) == vertex: neighbor = int(edges[id].u)
      if neighbor >= 0 and not seen[neighbor]:
        seen[neighbor] = true
        queue[tail] = neighbor
        inc tail
  for vertex in 0 ..< n:
    if not seen[vertex]: return false
  true

proc storeI64Le(output: ptr UncheckedArray[uint8], offset: int, value: int64) =
  let bits = cast[uint64](value)
  for byte in 0 ..< 8:
    output[offset + byte] = uint8((bits shr (8 * byte)) and 255'u64)

proc reverse_delete_mst*(input: ptr UncheckedArray[int64], length: csize_t,
    output: ptr UncheckedArray[uint8], capacity: csize_t): int64
    {.cdecl, exportc: "reverse_delete_mst".} =
  if input.isNil or length < 2 or length > csize_t(MaxInput): return -1
  let nWord = input[0]
  let mWord = input[1]
  if nWord < 2 or nWord > MaxN.int64 or mWord < nWord - 1 or mWord > MaxM.int64: return -1
  let n = int(nWord)
  let m = int(mWord)
  if int(length) != 2 + 3 * m: return -1
  var edges: array[MaxM, Edge]
  var order: array[MaxM, int]
  for id in 0 ..< m:
    let u = input[2 + 3 * id]
    let v = input[3 + 3 * id]
    let weight = input[4 + 3 * id]
    if u < 0 or u >= nWord or v < 0 or v >= nWord or u == v or weight < 0 or weight > 1000: return -1
    edges[id] = Edge(u: int32(u), v: int32(v), weight: int32(weight))
    order[id] = id
    let low = min(u, v)
    let high = max(u, v)
    for prior in 0 ..< id:
      if low == min(edges[prior].u.int64, edges[prior].v.int64) and
          high == max(edges[prior].u.int64, edges[prior].v.int64): return -1
  for i in 1 ..< m:
    let item = order[i]
    var j = i
    while j > 0 and (edges[order[j - 1]].weight < edges[item].weight or
        (edges[order[j - 1]].weight == edges[item].weight and order[j - 1] < item)):
      order[j] = order[j - 1]
      dec j
    order[j] = item
  var active = (1'u32 shl m) - 1'u32
  if not graphConnected(n, edges, m, active): return -1
  for position in 0 ..< m:
    let candidate = active and not (1'u32 shl order[position])
    if graphConnected(n, edges, m, candidate): active = candidate
  var totalWeight: int64 = 0
  for id in 0 ..< m:
    if ((active shr id) and 1'u32) != 0: totalWeight += edges[id].weight.int64
  if output.isNil or capacity < 16: return -2
  storeI64Le(output, 0, active.int64)
  storeI64Le(output, 8, totalWeight)
  16
