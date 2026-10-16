proc maximal_square*(a: ptr UncheckedArray[int64], length: csize_t): int64 {.cdecl, exportc: "maximal_square".} =
  if a.isNil or length < 3 or length > 258 or a[0] < 1 or a[0] > 16 or a[1] < 1 or a[1] > 16 or length != csize_t(a[0] * a[1] + 2): return -1
  let rows=int(a[0]); let cols=int(a[1]); var dp: array[16,int]; var best=0
  for i in 0 ..< rows*cols: if a[i+2] != 0 and a[i+2] != 1: return -1
  for r in 0 ..< rows:
    var diagonal=0
    for c in 0 ..< cols:
      let above=dp[c]
      if a[r*cols+c+2] == 1:
        if r == 0 or c == 0: dp[c]=1
        else: dp[c]=min(diagonal,min(dp[c],dp[c-1]))+1
        best=max(best,dp[c])
      else: dp[c]=0
      diagonal=above
  int64(best*best)
