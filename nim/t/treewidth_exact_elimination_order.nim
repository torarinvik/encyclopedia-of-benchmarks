const MaxN = 8
const MaxEdges = 28
const MaxInput = 58
const MaxOutput = 72

proc put(output: ptr UncheckedArray[uint8], offset: int, value: int64) =
  let bits = cast[uint64](value)
  for byte in 0..<8: output[offset + byte] = uint8((bits shr (8 * byte)) and 255)

proc treewidth_exact_elimination_order*(input: ptr UncheckedArray[int64], length: csize_t,
    output: ptr UncheckedArray[uint8], capacity: csize_t): int64 {.cdecl, exportc: "treewidth_exact_elimination_order".} =
  if input.isNil or length < 2 or length > csize_t(MaxInput): return -1
  let n64, m64 = input[0], input[1]
  if n64 < 1 or n64 > MaxN or m64 < 0 or m64 > MaxEdges: return -1
  let n, m = int(n64), int(m64)
  if m > n * (n - 1) div 2 or int(length) != 2 + 2 * m: return -1
  var base: array[MaxN, array[MaxN, bool]]
  for edge in 0..<m:
    let a64, b64 = input[2 + 2 * edge], input[3 + 2 * edge]
    if a64 < 0 or b64 < 0 or a64 >= n64 or b64 >= n64 or a64 >= b64: return -1
    let a, b = int(a64), int(b64)
    if base[a][b]: return -1
    base[a][b] = true; base[b][a] = true
  var permutation: array[MaxN, int]
  var bestOrder: array[MaxN, int]
  for i in 0..<n: permutation[i] = i
  var bestWidth = MaxN + 1
  while true:
    var adjacent = base
    var active: array[MaxN, bool]
    for i in 0..<n: active[i] = true
    var width = 0
    for step in 0..<n:
      let vertex = permutation[step]
      var neighbors: array[MaxN, int]
      var count = 0
      for other in 0..<n:
        if active[other] and adjacent[vertex][other]: neighbors[count] = other; inc count
      width = max(width, count)
      for i in 0..<count:
        for j in i + 1..<count:
          adjacent[neighbors[i]][neighbors[j]] = true
          adjacent[neighbors[j]][neighbors[i]] = true
      active[vertex] = false
    if width < bestWidth:
      bestWidth = width
      for i in 0..<n: bestOrder[i] = permutation[i]
    var pivot = n - 2
    while pivot >= 0 and permutation[pivot] >= permutation[pivot + 1]: dec pivot
    if pivot < 0: break
    var successor = n - 1
    while permutation[successor] <= permutation[pivot]: dec successor
    swap(permutation[pivot], permutation[successor])
    var left = pivot + 1
    var right = n - 1
    while left < right:
      swap(permutation[left], permutation[right])
      inc left; dec right
  let bytes = 8 * (n + 1)
  if output.isNil or capacity < csize_t(bytes): return -2
  var staged: array[MaxOutput, uint8]
  put(addr staged[0], 0, int64(bestWidth))
  for i in 0..<n: put(addr staged[0], 8 * (i + 1), int64(bestOrder[i]))
  for i in 0..<bytes: output[i] = staged[i]
  int64(bytes)
