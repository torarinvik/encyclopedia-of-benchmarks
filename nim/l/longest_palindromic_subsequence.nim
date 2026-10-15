const MaxValues = 128

proc longest_palindromic_subsequence*(values: ptr UncheckedArray[int64], length: csize_t): int64
    {.cdecl, exportc: "longest_palindromic_subsequence".} =
  if length > MaxValues: return -1
  if length == 0: return 0
  let n = int(length)
  var dp: array[MaxValues, int64]
  var start = n
  while start > 0:
    dec start
    dp[start] = 1
    var diagonal = 0'i64
    for finish in start + 1 ..< n:
      let previous = dp[finish]
      if values[start] == values[finish]:
        dp[finish] = diagonal + 2
      else:
        dp[finish] = max(dp[finish], dp[finish - 1])
      diagonal = previous
  dp[n - 1]
