const MaxVertices = 8
const MaxEdges = 256
const MaxInputLength = 2 + 2 * MaxEdges
const MaxIncidences = 2 * MaxEdges
const FnvOffset = 14695981039346656037'u64
const FnvPrime = 1099511628211'u64

proc fnvWord(hash: uint64, value: int64): uint64 =
  let bits = cast[uint64](value)
  var resultHash = hash
  for byte in 0 ..< 8:
    resultHash = (resultHash xor ((bits shr (8 * byte)) and 255'u64)) * FnvPrime
  resultHash

proc hierholzer_algorithm*(input: ptr UncheckedArray[int64], length: csize_t): int64
    {.cdecl, exportc: "hierholzer_algorithm".} =
  if input.isNil or length < 2 or length > csize_t(MaxInputLength): return -1
  let n64 = input[0]
  let m64 = input[1]
  if n64 < 0 or n64 > MaxVertices or m64 < 0 or m64 > MaxEdges: return -1
  let n = int(n64)
  let m = int(m64)
  if (n == 0 and m != 0) or length != csize_t(2 + 2 * m): return -1

  var adjacency: array[MaxVertices, array[MaxIncidences, int]]
  var degree: array[MaxVertices, int]
  for edge in 0 ..< m:
    let u64 = input[2 + 2 * edge]
    let v64 = input[3 + 2 * edge]
    if u64 < 0 or u64 >= n64 or v64 < 0 or v64 >= n64: return -1
    let u = int(u64)
    let v = int(v64)
    adjacency[u][degree[u]] = v
    inc degree[u]
    adjacency[v][degree[v]] = u
    inc degree[v]

  var oddCount = 0
  var start = 0
  var firstNonempty = -1
  for vertex in 0 ..< n:
    if degree[vertex] > 0 and firstNonempty < 0: firstNonempty = vertex
    if degree[vertex] mod 2 != 0: inc oddCount
  if oddCount != 0: return int64(fnvWord(fnvWord(FnvOffset, 0), 0) and 0x7fff_ffff_ffff_ffff'u64)

  if n == 0:
    var hash = fnvWord(FnvOffset, 1)
    hash = fnvWord(hash, 0)
    return int64(hash and 0x7fff_ffff_ffff_ffff'u64)
  if firstNonempty < 0:
    var hash = fnvWord(FnvOffset, 1)
    hash = fnvWord(hash, 1)
    hash = fnvWord(hash, 0)
    return int64(hash and 0x7fff_ffff_ffff_ffff'u64)

  var reached: array[MaxVertices, bool]
  var queue: array[MaxVertices, int]
  var qHead = 0
  var qTail = 0
  queue[qTail] = firstNonempty
  inc qTail
  reached[firstNonempty] = true
  while qHead < qTail:
    let u = queue[qHead]
    inc qHead
    for i in 0 ..< degree[u]:
      let v = adjacency[u][i]
      if not reached[v]:
        reached[v] = true
        queue[qTail] = v
        inc qTail
  for vertex in 0 ..< n:
    if degree[vertex] > 0 and not reached[vertex]:
      var hash = fnvWord(FnvOffset, 0)
      hash = fnvWord(hash, 0)
      return int64(hash and 0x7fff_ffff_ffff_ffff'u64)

  # Consume the first edge in each adjacency list, removing its first reciprocal occurrence.
  var stack: array[MaxIncidences + 1, int]
  var routeReverse: array[MaxIncidences + 1, int]
  var top = 1
  stack[0] = firstNonempty
  var routeCount = 0
  while top > 0:
    let u = stack[top - 1]
    if degree[u] > 0:
      let v = adjacency[u][0]
      for i in 1 ..< degree[u]: adjacency[u][i - 1] = adjacency[u][i]
      dec degree[u]
      var reciprocal = -1
      for i in 0 ..< degree[v]:
        if adjacency[v][i] == u:
          reciprocal = i
          break
      if reciprocal < 0: return -1
      for i in reciprocal + 1 ..< degree[v]: adjacency[v][i - 1] = adjacency[v][i]
      dec degree[v]
      stack[top] = v
      inc top
    else:
      dec top
      routeReverse[routeCount] = u
      inc routeCount

  if routeCount != m + 1:
    var hash = fnvWord(FnvOffset, 0)
    hash = fnvWord(hash, 0)
    return int64(hash and 0x7fff_ffff_ffff_ffff'u64)
  var hash = fnvWord(FnvOffset, 1)
  hash = fnvWord(hash, int64(routeCount))
  for i in countdown(routeCount - 1, 0): hash = fnvWord(hash, int64(routeReverse[i]))
  int64(hash and 0x7fff_ffff_ffff_ffff'u64)
