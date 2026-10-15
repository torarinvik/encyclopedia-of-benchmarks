## Unrestricted Damerau-Levenshtein distance over ASCII byte strings.
proc damerau_levenshtein_distance*(values: ptr UncheckedArray[int64], length: csize_t): int64
    {.cdecl, exportc: "damerau_levenshtein_distance".} =
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
  var last: array[128, int]
  let maxDistance = int64(n + m)
  dp[0][0] = maxDistance
  for i in 0 .. n:
    dp[i + 1][0] = maxDistance
    dp[i + 1][1] = int64(i)
  for j in 0 .. m:
    dp[0][j + 1] = maxDistance
    dp[1][j + 1] = int64(j)
  for i in 1 .. n:
    var lastMatchColumn = 0
    for j in 1 .. m:
      let lastMatchRow = last[int(values[2 + n + j - 1])]
      let priorMatchColumn = lastMatchColumn
      let cost = if values[2 + i - 1] == values[2 + n + j - 1]: 0'i64 else: 1'i64
      if cost == 0: lastMatchColumn = j
      let transposition = dp[lastMatchRow][priorMatchColumn] + int64(i - lastMatchRow - 1) + 1 + int64(j - priorMatchColumn - 1)
      dp[i + 1][j + 1] = min(dp[i][j] + cost, min(dp[i + 1][j] + 1, min(dp[i][j + 1] + 1, transposition)))
    last[int(values[2 + i - 1])] = i
  dp[n + 1][m + 1]
