## Clean-room bounded GBBS MPX low-diameter decomposition profile.
const MaxN = 12
const MaxM = 24
const MaxInput = 2 + 2 * MaxM
const BatchSizes: array[13, int] = [1, 1, 1, 1, 2, 2, 3, 4, 4, 6, 7, 9, 11]

proc gbbs_low_diameter_decomposition*(input: ptr UncheckedArray[int64], length: csize_t,
    output: ptr UncheckedArray[uint8], capacity: csize_t): int64
    {.cdecl, exportc: "gbbs_low_diameter_decomposition".} =
  if input.isNil or length < csize_t(2) or length > csize_t(MaxInput): return -1
  let n64 = input[0]
  let m64 = input[1]
  if n64 < 1 or n64 > MaxN or m64 < 0 or m64 > MaxM or
      int64(length) != 2 + 2 * m64: return -1
  let n = int(n64)
  let m = int(m64)
  var adjacent: array[MaxN, array[MaxN, bool]]
  for edge in 0..<m:
    let u64 = input[2 + 2 * edge]
    let v64 = input[3 + 2 * edge]
    if u64 < 0 or u64 >= n64 or v64 <= u64 or v64 >= n64: return -1
    let u = int(u64)
    let v = int(v64)
    if adjacent[u][v]: return -1
    adjacent[u][v] = true
    adjacent[v][u] = true
  if output.isNil or capacity < csize_t(n): return -2

  var label: array[MaxN, int]
  for vertex in 0..<n: label[vertex] = -1
  var frontier: array[MaxN, int]
  var frontierCount = 0
  var cursor = 0
  var assigned = 0
  var round = 0
  while assigned < n:
    let finish = min(n, cursor + BatchSizes[round])
    for candidate in cursor..<finish:
      if label[candidate] < 0:
        label[candidate] = candidate
        frontier[frontierCount] = candidate
        inc frontierCount
        inc assigned
    cursor = finish
    if assigned == n: break

    var reached: array[MaxN, int]
    for vertex in 0..<n: reached[vertex] = -1
    for i in 0..<frontierCount:
      let vertex = frontier[i]
      for neighbor in 0..<n:
        if adjacent[vertex][neighbor] and label[neighbor] < 0 and
            (reached[neighbor] < 0 or label[vertex] < reached[neighbor]):
          reached[neighbor] = label[vertex]
    frontierCount = 0
    for vertex in 0..<n:
      if reached[vertex] >= 0:
        label[vertex] = reached[vertex]
        frontier[frontierCount] = vertex
        inc frontierCount
        inc assigned
    inc round
  for vertex in 0..<n: output[vertex] = uint8(label[vertex])
  return int64(n)
