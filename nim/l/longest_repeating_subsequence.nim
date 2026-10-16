proc longest_repeating_subsequence*(p: ptr UncheckedArray[int64], n: csize_t): int64 {.cdecl, exportc: "longest_repeating_subsequence".} =
 if p.isNil or n < 1 or n > 256: return -1
 let size=p[0]
 if size<0 or size>255 or n!=csize_t(size+1): return -1
 for k in 0..<int(size): if p[1+k]<0 or p[1+k]>127: return -1
 var dp: array[256,int64]
 for i in 1..int(size):
  var diag=0'i64
  for j in 1..int(size):
   let above=dp[j]
   if p[i]==p[j] and i!=j: dp[j]=diag+1
   elif dp[j-1]>dp[j]: dp[j]=dp[j-1]
   diag=above
 dp[int(size)]
