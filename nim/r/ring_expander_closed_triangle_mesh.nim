const MaxN = 12
const MaxT = 20
const MaxC = 60
const MaxInput = 64

type I64Input = ptr UncheckedArray[int64]
type ByteOutput = ptr UncheckedArray[uint8]

proc nextCorner(c: int): int = 3 * (c div 3) + ((c mod 3 + 1) mod 3)
proc prevCorner(c: int): int = 3 * (c div 3) + ((c mod 3 + 2) mod 3)
proc cornerVertex(faces: array[MaxC, int64], c: int): int =
  int(faces[3 * (c div 3) + c mod 3])

proc putWord(output: ByteOutput, offset: int, value: int64) =
  let bits = cast[uint64](value)
  for byte in 0 ..< 8:
    output[offset + byte] = uint8((bits shr (8 * byte)) and 255'u64)

proc runRing(n, t, seed: int, faces: array[MaxC, int64], trace: var array[MaxC, int64],
             traceCount: var int, vertexMask, triangleMask: var uint64): bool =
  var opposite: array[MaxC, int]
  var link: array[MaxN, array[MaxN, array[MaxN, bool]]]
  var used: array[MaxN, bool]
  var edgeCount: array[MaxN, array[MaxN, uint8]]
  var edgeFirst: array[MaxN, array[MaxN, int32]]
  var edgeSecond: array[MaxN, array[MaxN, int32]]
  for a in 0 ..< MaxN:
    for b in 0 ..< MaxN:
      edgeFirst[a][b] = -1
      edgeSecond[a][b] = -1
  for ti in 0 ..< t:
    let a = int(faces[3 * ti])
    let b = int(faces[3 * ti + 1])
    let c = int(faces[3 * ti + 2])
    used[a] = true; used[b] = true; used[c] = true
    link[a][b][c] = true; link[a][c][b] = true
    link[b][c][a] = true; link[b][a][c] = true
    link[c][a][b] = true; link[c][b][a] = true
    for j in 0 ..< 3:
      let first = int(faces[3 * ti + (j + 1) mod 3])
      let second = int(faces[3 * ti + (j + 2) mod 3])
      let low = min(first, second)
      let high = max(first, second)
      if edgeCount[low][high] == 0'u8: edgeFirst[low][high] = int32(3 * ti + j)
      elif edgeCount[low][high] == 1'u8: edgeSecond[low][high] = int32(3 * ti + j)
      else: return false
      inc edgeCount[low][high]
  for v in 0 ..< n:
    if not used[v]: return false

  for low in 0 ..< n:
    for high in low + 1 ..< n:
      if edgeCount[low][high] == 0'u8: continue
      if edgeCount[low][high] != 2'u8: return false
      let a = int(edgeFirst[low][high])
      let b = int(edgeSecond[low][high])
      let at = a div 3; let aj = a mod 3
      let bt = b div 3; let bj = b mod 3
      let a0 = int(faces[3 * at + (aj + 1) mod 3])
      let a1 = int(faces[3 * at + (aj + 2) mod 3])
      let b0 = int(faces[3 * bt + (bj + 1) mod 3])
      let b1 = int(faces[3 * bt + (bj + 2) mod 3])
      if a0 != b1 or a1 != b0: return false
      opposite[a] = b
      opposite[b] = a

  for v in 0 ..< n:
    var start = -1
    for w in 0 ..< n:
      var degree = 0
      for x in 0 ..< n:
        if link[v][w][x]: inc degree
      if degree > 0 and start < 0: start = w
      if degree > 0 and degree != 2: return false
    if start < 0: return false
    var seen: array[MaxN, bool]
    var queue: array[MaxN, int]
    var head = 0; var tail = 0
    seen[start] = true; queue[tail] = start; inc tail
    while head < tail:
      let w = queue[head]; inc head
      for x in 0 ..< n:
        if link[v][w][x] and not seen[x]:
          seen[x] = true; queue[tail] = x; inc tail
    for w in 0 ..< n:
      var hasEdge = false
      for x in 0 ..< n: hasEdge = hasEdge or link[v][w][x]
      if hasEdge and not seen[w]: return false

  var reached: array[MaxT, bool]
  var triQueue: array[MaxT, int]
  var head = 0; var tail = 0
  reached[0] = true; triQueue[tail] = 0; inc tail
  while head < tail:
    let ti = triQueue[head]; inc head
    for j in 0 ..< 3:
      let other = opposite[3 * ti + j] div 3
      if not reached[other]: reached[other] = true; triQueue[tail] = other; inc tail
  for ti in 0 ..< t:
    if not reached[ti]: return false

  var seenCorners: array[MaxC, bool]
  vertexMask = 0; triangleMask = 0; traceCount = 0
  vertexMask = vertexMask or (1'u64 shl cornerVertex(faces, nextCorner(seed)))
  vertexMask = vertexMask or (1'u64 shl cornerVertex(faces, prevCorner(seed)))
  let stop = opposite[seed]
  var current = seed
  while current != stop:
    if current < 0 or current >= 3 * t or seenCorners[current] or traceCount >= 3 * t: return false
    seenCorners[current] = true
    trace[traceCount] = int64(current); inc traceCount
    let ti = current div 3
    let v = cornerVertex(faces, current)
    if ((vertexMask shr v) and 1'u64) == 0:
      vertexMask = vertexMask or (1'u64 shl v)
      triangleMask = triangleMask or (1'u64 shl ti)
    elif ((triangleMask shr ti) and 1'u64) == 0:
      current = opposite[current]
    current = opposite[prevCorner(current)]
  true

proc ring_expander_closed_triangle_mesh*(input: I64Input, length: csize_t,
    output: ByteOutput, capacity: csize_t): int64 {.cdecl, exportc: "ring_expander_closed_triangle_mesh".} =
  if input == nil or length < csize_t(15) or length > csize_t(MaxInput): return -1
  let n64 = input[0]; let t64 = input[1]; let seed64 = input[2]
  if n64 < 4 or n64 > MaxN or t64 < 4 or t64 > MaxT or
      int64(length) != 3 + 3 * t64 or seed64 < 0 or seed64 >= 3 * t64: return -1
  let n = int(n64); let t = int(t64); let seed = int(seed64)
  var faces: array[MaxC, int64]
  for i in 0 ..< 3 * t:
    let value = input[3 + i]
    if value < 0 or value >= n64: return -1
    faces[i] = value
  for ti in 0 ..< t:
    if faces[3 * ti] == faces[3 * ti + 1] or faces[3 * ti + 1] == faces[3 * ti + 2] or
        faces[3 * ti + 2] == faces[3 * ti]: return -1
  var trace: array[MaxC, int64]
  var traceCount = 0
  var vertices = 0'u64; var triangles = 0'u64
  if not runRing(n, t, seed, faces, trace, traceCount, vertices, triangles): return -1
  let words = 1 + traceCount + 2
  let bytes = 8 * words
  if output == nil or capacity < csize_t(bytes): return -2
  putWord(output, 0, int64(traceCount))
  for i in 0 ..< traceCount: putWord(output, 8 * (i + 1), trace[i])
  putWord(output, 8 * (traceCount + 1), int64(vertices))
  putWord(output, 8 * (traceCount + 2), int64(triangles))
  int64(bytes)
