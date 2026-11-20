const MinN = 3
const MaxN = 10
const MaxLength = 37

proc convex_polygon_minimum_weight_triangulation*(input: ptr UncheckedArray[int64],
    length: csize_t): int64 {.cdecl, exportc: "convex_polygon_minimum_weight_triangulation".} =
  if input.isNil or length < csize_t(1) or length > csize_t(MaxLength): return -1
  if input[0] < MinN.int64 or input[0] > MaxN.int64: return -1
  let n = input[0].int
  var diagonalCount = 0
  for i in 0 ..< n:
    for j in i + 2 ..< n:
      if not (i == 0 and j == n - 1): inc diagonalCount
  if length != csize_t(1 + diagonalCount): return -1

  var weight: array[MaxN, array[MaxN, int64]]
  var at = 1
  for i in 0 ..< n:
    for j in i + 2 ..< n:
      if i == 0 and j == n - 1: continue
      let value = input[at]
      if value < 0 or value > 1000: return -1
      weight[i][j] = value
      inc at

  var dp: array[MaxN, array[MaxN, int64]]
  for span in 2 ..< n:
    for left in 0 ..< n - span:
      let right = left + span
      var best = 7001'i64
      for split in left + 1 ..< right:
        let leftEdge = if split - left == 1: 0'i64 else: weight[left][split]
        let rightEdge = if right - split == 1: 0'i64 else: weight[split][right]
        let candidate = dp[left][split] + dp[split][right] + leftEdge + rightEdge
        if candidate < best: best = candidate
      dp[left][right] = best
  dp[0][n - 1]
