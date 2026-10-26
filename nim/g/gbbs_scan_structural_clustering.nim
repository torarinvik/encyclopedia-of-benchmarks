## Clean-room bounded GBBS SCAN profile; see package LICENSE.txt.
const MaxN = 16
const MaxM = 64
const MaxInput = 130

proc storeI64LE(output: ptr UncheckedArray[uint8], offset: int, value: int64) =
  let bits = cast[uint64](value)
  for byte in 0..<8:
    output[offset + byte] = uint8((bits shr (8 * byte)) and 255)

proc similarityParts(u, v: int, adjacent: array[MaxN, array[MaxN, bool]],
    degree: array[MaxN, int]): tuple[numerator, denominatorSq: uint64] =
  var shared = 0'u64
  for w in 0..<MaxN:
    if adjacent[u][w] and adjacent[v][w]: inc shared
  result.numerator = shared + 2
  result.denominatorSq = uint64((degree[u] + 1) * (degree[v] + 1))

proc epsilonSimilar(numerator, denominatorSq: uint64): bool =
  4'u64 * numerator * numerator >= denominatorSq

proc gbbs_scan_structural_clustering*(input: ptr UncheckedArray[int64], length: csize_t,
    output: ptr UncheckedArray[uint8], capacity: csize_t): int64
    {.cdecl, exportc: "gbbs_scan_structural_clustering".} =
  if input.isNil or length < csize_t(2) or length > csize_t(MaxInput): return -1
  let n64 = input[0]
  let m64 = input[1]
  if n64 < 1 or n64 > int64(MaxN) or m64 < 0 or m64 > int64(MaxM): return -1
  let n = int(n64)
  let m = int(m64)
  if int(length) != 2 + 2 * m: return -1
  var adjacent: array[MaxN, array[MaxN, bool]]
  var degree: array[MaxN, int]
  for edge in 0..<m:
    let u64 = input[2 + 2 * edge]
    let v64 = input[3 + 2 * edge]
    if u64 < 0 or v64 <= u64 or v64 >= n64: return -1
    let u = int(u64)
    let v = int(v64)
    if adjacent[u][v]: return -1
    adjacent[u][v] = true
    adjacent[v][u] = true
    inc degree[u]
    inc degree[v]
  let outputBytes = 8 * n
  if output.isNil or capacity < csize_t(outputBytes): return -2

  var core: array[MaxN, bool]
  var labels: array[MaxN, int64]
  for u in 0..<n:
    var similarCount = 0
    for v in 0..<n:
      if adjacent[u][v]:
        let score = similarityParts(u, v, adjacent, degree)
        if epsilonSimilar(score.numerator, score.denominatorSq): inc similarCount
    core[u] = similarCount >= 2
    labels[u] = -1

  for root in 0..<n:
    if not core[root] or labels[root] != -1: continue
    var queue: array[MaxN, int]
    var head = 0
    var tail = 1
    labels[root] = int64(root)
    queue[0] = root
    while head < tail:
      let u = queue[head]
      inc head
      for v in 0..<n:
        if not core[v] or labels[v] != -1 or not adjacent[u][v]: continue
        let score = similarityParts(u, v, adjacent, degree)
        if epsilonSimilar(score.numerator, score.denominatorSq):
          labels[v] = int64(root)
          queue[tail] = v
          inc tail

  for u in 0..<n:
    if core[u]: continue
    var bestCore = MaxN
    var bestNum = 0'u64
    var bestDen = 1'u64
    for v in 0..<n:
      if not core[v] or not adjacent[u][v]: continue
      let score = similarityParts(u, v, adjacent, degree)
      if not epsilonSimilar(score.numerator, score.denominatorSq): continue
      let left = score.numerator * score.numerator * bestDen
      let right = bestNum * bestNum * score.denominatorSq
      if bestCore == MaxN or left > right or (left == right and v < bestCore):
        bestCore = v
        bestNum = score.numerator
        bestDen = score.denominatorSq
    if bestCore != MaxN: labels[u] = labels[bestCore]

  for v in 0..<n: storeI64LE(output, 8 * v, labels[v])
  int64(outputBytes)
