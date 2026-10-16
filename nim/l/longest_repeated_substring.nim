proc longest_repeated_substring*(p:ptr UncheckedArray[int64],n:csize_t):int64 {.cdecl,exportc:"longest_repeated_substring".}=
 if p.isNil or n<1 or n>128:return -1
 let z=p[0]
 if z<0 or z>127 or n!=csize_t(z+1):return -1
 for k in 0..<int(z):if p[k+1]<0 or p[k+1]>127:return -1
 var dp:array[128,array[128,int64]]
 var best=0'i64
 for ii in 0..<int(z):
  let i=int(z)-1-ii
  for jj in 0..<int(z)-i-1:
   let j=int(z)-1-jj
   if p[i+1]==p[j+1]:
    dp[i][j]=1+dp[i+1][j+1]
    if dp[i][j]>best:best=dp[i][j]
 best
