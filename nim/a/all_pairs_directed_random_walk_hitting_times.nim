const MaxN = 8
const MaxInputLength = 115
const Modulus = 1_000_000_007'i64
type Matrix = array[MaxN, array[2 * MaxN + 1, int64]]
type Graph = array[MaxN, array[MaxN, bool]]

proc norm(value: int64): int64 =
  let rem = value mod Modulus
  if rem < 0: rem + Modulus else: rem

proc power(baseInput, exponentInput: int64): int64 =
  var base = norm(baseInput)
  var exponent = exponentInput
  var result = 1'i64
  while exponent > 0:
    if (exponent and 1) != 0: result = result * base mod Modulus
    base = base * base mod Modulus
    exponent = exponent shr 1
  result

proc reachesAll(graph: Graph, n: int, reverse: bool): bool =
  var seen: array[MaxN, bool]
  var queue: array[MaxN, int]
  var head = 0
  var tail = 1
  seen[0] = true
  queue[0] = 0
  while head < tail:
    let current = queue[head]
    inc head
    for to in 0 ..< n:
      let hasEdge = if reverse: graph[to][current] else: graph[current][to]
      if hasEdge and not seen[to]:
        seen[to] = true
        queue[tail] = to
        inc tail
  tail == n

proc eliminate(matrix: var Matrix, size, rhsCount: int): bool =
  let width = size + rhsCount
  for column in 0 ..< size:
    var pivot = column
    while pivot < size and norm(matrix[pivot][column]) == 0: inc pivot
    if pivot == size: return false
    swap(matrix[pivot], matrix[column])
    let inverse = power(matrix[column][column], Modulus - 2)
    for j in 0 ..< width: matrix[column][j] = matrix[column][j] * inverse mod Modulus
    for row in 0 ..< size:
      if row == column: continue
      let factor = norm(matrix[row][column])
      if factor != 0:
        for j in 0 ..< width:
          matrix[row][j] = norm(matrix[row][j] - factor * matrix[column][j] mod Modulus)
  true

proc storeI64Le(output: ptr UncheckedArray[uint8], offset: int, value: int64) =
  let bits = cast[uint64](value)
  for byte in 0 ..< 8:
    output[offset + byte] = uint8((bits shr (8 * byte)) and 255)

proc all_pairs_directed_random_walk_hitting_times*(input: ptr UncheckedArray[int64],
    length: csize_t, output: ptr UncheckedArray[uint8], capacity: csize_t): int64
    {.cdecl, exportc: "all_pairs_directed_random_walk_hitting_times".} =
  if input.isNil or length < 2 or length > csize_t(MaxInputLength): return -1
  let nValue = input[0]
  let mValue = input[1]
  if nValue < 3 or nValue > MaxN: return -1
  if mValue < 0 or mValue > nValue * (nValue - 1): return -1
  let n = int(nValue)
  let m = int(mValue)
  if length != csize_t(2 + 2 * m): return -1
  var graph: Graph
  var degree: array[MaxN, int]
  for edge in 0 ..< m:
    let uValue = input[2 + 2 * edge]
    let vValue = input[3 + 2 * edge]
    if uValue < 0 or uValue >= nValue or vValue < 0 or vValue >= nValue or uValue == vValue: return -1
    let u = int(uValue)
    let v = int(vValue)
    if graph[u][v]: return -1
    graph[u][v] = true
    inc degree[u]
  for vertex in 0 ..< n:
    if degree[vertex] == 0: return -1
  if not reachesAll(graph, n, false) or not reachesAll(graph, n, true): return -1
  let outputBytes = 8 * n * n
  if output.isNil or capacity < csize_t(outputBytes): return -2

  var stationary: Matrix
  for destination in 0 ..< n - 1:
    for source in 0 ..< n:
      let transition = if graph[source][destination]: power(int64(degree[source]), Modulus - 2) else: 0
      stationary[destination][source] = norm(transition - (if source == destination: 1'i64 else: 0'i64))
  for source in 0 ..< n: stationary[n - 1][source] = 1
  stationary[n - 1][n] = 1
  if not eliminate(stationary, n, 1): return -1
  var reciprocal: array[MaxN, int64]
  for vertex in 0 ..< n:
    let pi = norm(stationary[vertex][n])
    if pi == 0: return -1
    reciprocal[vertex] = power(pi, Modulus - 2)

  var reduced: Matrix
  for row in 0 ..< n - 1:
    for column in 0 ..< n - 1:
      let transition = if graph[row][column]: power(int64(degree[row]), Modulus - 2) else: 0
      reduced[row][column] = norm((if row == column: 1'i64 else: 0'i64) - transition)
    for target in 0 ..< n:
      reduced[row][n - 1 + target] = norm(1 - (if row == target: reciprocal[target] else: 0))
  if not eliminate(reduced, n - 1, n): return -1
  var y: array[MaxN, array[MaxN, int64]]
  for row in 0 ..< n - 1:
    for target in 0 ..< n: y[row][target] = norm(reduced[row][n - 1 + target])
  for source in 0 ..< n:
    for target in 0 ..< n:
      storeI64Le(output, 8 * (source * n + target), norm(y[source][target] - y[target][target]))
  int64(outputBytes)
