## Restricted Damerau-Levenshtein (optimal string alignment) distance.
proc optimal_string_alignment_distance*(values: ptr UncheckedArray[int64], length: csize_t): int64
    {.cdecl, exportc: "optimal_string_alignment_distance".} =
  if length < 2 or length > 66: return -1
  let leftNValue = values[0]
  let rightNValue = values[1]
  if leftNValue < 0 or leftNValue > 32 or rightNValue < 0 or rightNValue > 32: return -1
  let n = int(leftNValue)
  let m = int(rightNValue)
  if int(length) != 2 + n + m: return -1
  for k in 0 ..< n + m:
    if values[2 + k] < 0 or values[2 + k] > 127: return -1
  var dp: array[34, array[34, int64]]
  for i in 0 .. n: dp[i][0] = int64(i)
  for j in 0 .. m: dp[0][j] = int64(j)
  for i in 1 .. n:
    for j in 1 .. m:
      let cost = if values[2 + i - 1] == values[2 + n + j - 1]: 0'i64 else: 1'i64
      var best = min(dp[i - 1][j - 1] + cost, min(dp[i][j - 1] + 1, dp[i - 1][j] + 1))
      if i > 1 and j > 1 and values[2 + i - 1] == values[2 + n + j - 2] and values[2 + i - 2] == values[2 + n + j - 1]:
        best = min(best, dp[i - 2][j - 2] + cost)
      dp[i][j] = best
  dp[n][m]
