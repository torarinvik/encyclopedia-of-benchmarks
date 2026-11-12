const MaxN = 64
const MaxInput = 65
const MaxFrequency = 1_000_000'i64

proc knuth_optimized_optimal_binary_search_tree*(values: ptr UncheckedArray[int64], length: csize_t): int64
    {.cdecl, exportc: "knuth_optimized_optimal_binary_search_tree".} =
  if values == nil or length < 2 or length > csize_t(MaxInput): return -1
  let nv = values[0]
  if nv < 1 or nv > MaxN or int(length) != int(nv) + 1: return -1
  let n = int(nv)
  var prefix: array[MaxN + 1, int64]
  var dp: array[MaxN, array[MaxN, int64]]
  var opt: array[MaxN, array[MaxN, int]]
  for i in 0 ..< n:
    let f = values[i + 1]
    if f < 0 or f > MaxFrequency: return -1
    prefix[i + 1] = prefix[i] + f
    dp[i][i] = f
    opt[i][i] = i
  for width in 2 .. n:
    for left in 0 .. n - width:
      let right = left + width - 1
      let first = opt[left][right - 1]
      let last = opt[left + 1][right]
      let total = prefix[right + 1] - prefix[left]
      var best = high(int64)
      var bestRoot = first
      for root in first .. last:
        var cost = total
        if root > left: cost += dp[left][root - 1]
        if root < right: cost += dp[root + 1][right]
        if cost < best: best = cost; bestRoot = root
      dp[left][right] = best
      opt[left][right] = bestRoot
  dp[0][n - 1]
