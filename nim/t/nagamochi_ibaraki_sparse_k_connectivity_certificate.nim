const MaxN = 8
const MaxM = 28
const MaxInput = 60

proc put(outp: ptr UncheckedArray[uint8], at: int, value: int64) =
  let bits = cast[uint64](value)
  for i in 0..<8: outp[at + i] = uint8((bits shr (8 * i)) and 255)

proc nagamochi_ibaraki_sparse_k_connectivity_certificate*(
    input: ptr UncheckedArray[int64], length: csize_t,
    output: ptr UncheckedArray[uint8], capacity: csize_t): int64 {.cdecl, exportc:"nagamochi_ibaraki_sparse_k_connectivity_certificate".} =
  if input.isNil or length < 3 or length > csize_t(MaxInput): return -1
  let n0 = input[0]
  let m0 = input[1]
  let k0 = input[2]
  if n0 < 3 or n0 > 8 or m0 < 0 or m0 > 28 or k0 < 1 or k0 > 3: return -1
  let n = int(n0)
  let m = int(m0)
  let k = int(k0)
  if int(length) != 3 + 2 * m: return -1

  var u, v: array[MaxM, int]
  var incident: array[MaxN * MaxN, int]
  var degree: array[MaxN, int]
  for e in 0..<m:
    let a = input[3 + 2 * e]
    let b = input[4 + 2 * e]
    if a < 0 or a >= b or b >= n0: return -1
    u[e] = int(a)
    v[e] = int(b)
    for prior in 0..<e:
      if u[prior] == u[e] and v[prior] == v[e]: return -1
    incident[u[e] * MaxN + degree[u[e]]] = e
    inc degree[u[e]]
    incident[v[e] * MaxN + degree[v[e]]] = e
    inc degree[v[e]]

  let bytes = 8 * (m + 1)
  if output.isNil or int(capacity) < bytes: return -2
  var rank: array[MaxN, int]
  var layer: array[MaxM, int]
  var scannedVertex: array[MaxN, bool]
  var scannedEdge: array[MaxM, bool]
  for _ in 0..<n:
    var x = n
    for vertex in 0..<n:
      if not scannedVertex[vertex] and (x == n or rank[vertex] > rank[x]): x = vertex
    for slot in 0..<degree[x]:
      let e = incident[x * MaxN + slot]
      if scannedEdge[e]: continue
      let y = if u[e] == x: v[e] else: u[e]
      layer[e] = rank[y] + 1
      if rank[x] == rank[y]: inc rank[x]
      inc rank[y]
      scannedEdge[e] = true
    scannedVertex[x] = true

  put(output, 0, int64(m))
  for e in 0..<m:
    let visible = if layer[e] <= k: layer[e] else: 0
    put(output, 8 * (e + 1), int64(visible))
  int64(bytes)
