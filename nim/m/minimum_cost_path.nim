const InvalidResult = low(int64)

proc minimum_cost_path*(values: ptr UncheckedArray[int64], length: csize_t): int64
    {.cdecl, exportc: "minimum_cost_path".} =
  if values == nil or length < 3: return InvalidResult
  let rv = values[0]
  let cv = values[1]
  if rv < 1 or rv > 16 or cv < 1 or cv > 16: return InvalidResult
  let rows = int(rv)
  let cols = int(cv)
  if length != csize_t(2 + rows * cols): return InvalidResult
  var dp: array[16, array[16, int64]]
  for r in 0 ..< rows:
    for c in 0 ..< cols:
      let x = values[2 + r * cols + c]
      if x < low(int32).int64 or x > high(int32).int64: return InvalidResult
      dp[r][c] = x
  for c in 1 ..< cols: dp[0][c] += dp[0][c - 1]
  for r in 1 ..< rows: dp[r][0] += dp[r - 1][0]
  for r in 1 ..< rows:
    for c in 1 ..< cols:
      dp[r][c] += min(dp[r - 1][c], dp[r][c - 1])
  dp[rows - 1][cols - 1]
