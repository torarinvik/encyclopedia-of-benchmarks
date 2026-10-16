proc optimal_binary_search_tree*(values: ptr UncheckedArray[int64], length: csize_t): int64 {.cdecl, exportc: "optimal_binary_search_tree".} =
  if values == nil or length < 2 or length > 33: return -1
  let count = values[0]
  if count < 1 or count > 32 or int(length) != int(count)+1: return -1
  var prefix: array[33, int64]
  var dp: array[32, array[32, int64]]
  for i in 0 ..< int(count):
    let f = values[i+1]
    if f < 0 or f > 1000: return -1
    prefix[i+1] = prefix[i] + f; dp[i][i] = f
  for width in 2 .. int(count):
    for start in 0 .. int(count)-width:
      let finish = start+width-1; let total = prefix[finish+1]-prefix[start]
      var best = high(int64)
      for root in start .. finish:
        let left = if root > start: dp[start][root-1] else: 0'i64
        let right = if root < finish: dp[root+1][finish] else: 0'i64
        best = min(best, total+left+right)
      dp[start][finish] = best
  dp[0][int(count)-1]
