proc longest_increasing_subsequence_iterative*(v:ptr UncheckedArray[int64],n:csize_t):int64 {.cdecl,exportc:"longest_increasing_subsequence_iterative".}=
 if v.isNil or n<1 or n>65:return -1
 let count=v[0]
 if count<0 or count>64 or n!=csize_t(count+1):return -1
 var a,dp:array[64,int64]
 for i in 0..<int(count):
  a[i]=v[i+1]
  if a[i]< -1000000 or a[i]>1000000:return -1
  dp[i]=1
 for i in 0..<int(count):
  for j in 0..<i:
   if a[j]<=a[i] and dp[j]+1>dp[i]:dp[i]=dp[j]+1
 var best=0'i64
 for i in 0..<int(count):best=max(best,dp[i])
 best
