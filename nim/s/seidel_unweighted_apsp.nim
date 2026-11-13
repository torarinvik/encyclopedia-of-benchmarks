type Matrix = array[8, array[8, int64]]

proc distances(adjacency: Matrix, n: int): Matrix =
  var squared, expanded: Matrix
  var degree: array[8, int64]
  var complete = true
  for i in 0 ..< n:
    for j in 0 ..< n:
      degree[i] += adjacency[i][j]
      if i != j and adjacency[i][j] == 0: complete = false
      for k in 0 ..< n: squared[i][j] += adjacency[i][k] * adjacency[k][j]
  if complete:
    for i in 0 ..< n:
      for j in 0 ..< n:
        if i != j: result[i][j] = 1
    return
  for i in 0 ..< n:
    for j in 0 ..< n:
      if i != j and (adjacency[i][j] != 0 or squared[i][j] != 0): expanded[i][j] = 1
  let coarse = distances(expanded, n)
  for i in 0 ..< n:
    for j in 0 ..< n:
      if i == j: continue
      var neighborSum = 0'i64
      for k in 0 ..< n: neighborSum += coarse[i][k] * adjacency[k][j]
      result[i][j] = 2 * coarse[i][j]
      if neighborSum < coarse[i][j] * degree[j]: dec result[i][j]

proc seidel_unweighted_apsp*(input: ptr UncheckedArray[int64], length: csize_t,
    output: ptr UncheckedArray[uint8], capacity: csize_t): int64
    {.cdecl, exportc: "seidel_unweighted_apsp".} =
  if input == nil or length < 2 or length > 66: return -1
  if input[0] < 1 or input[0] > 8: return -1
  let n = int(input[0])
  if length != csize_t(1 + n * n): return -1
  var adjacency: Matrix
  for i in 0 ..< n:
    for j in 0 ..< n:
      let value = input[1 + i * n + j]
      if value < 0 or value > 1 or (i == j and value != 0): return -1
      adjacency[i][j] = value
  for i in 0 ..< n:
    for j in 0 ..< i:
      if adjacency[i][j] != adjacency[j][i]: return -1
  var seen: array[8, bool]
  var queue: array[8, int]
  seen[0] = true
  var head = 0
  var tail = 1
  while head < tail:
    let vertex = queue[head]
    inc head
    for other in 0 ..< n:
      if adjacency[vertex][other] != 0 and not seen[other]:
        seen[other] = true
        queue[tail] = other
        inc tail
  if tail != n: return -1
  let bytes = 8 * n * n
  if output == nil or capacity < csize_t(bytes): return -2
  let matrix = distances(adjacency, n)
  for i in 0 ..< n:
    for j in 0 ..< n:
      let bits = uint64(matrix[i][j])
      for byte in 0 ..< 8:
        output[8 * (i * n + j) + byte] = uint8((bits shr (8 * byte)) and 255'u64)
  int64(bytes)
