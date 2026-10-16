proc interleavingstrings*(a:ptr UncheckedArray[int64],n:csize_t):int64 {.cdecl,exportc:"interleavingstrings".}=
 if a==nil or n<3:return -1
 let m=a[0];let k=a[1];let q=a[2]
 if m<0 or m>32 or k<0 or k>32 or q!=m+k or n!=csize_t(3+m+k+q):return -1
 for i in 3..<int(n):if a[i]<0 or a[i]>127:return -1
 let ml=int(m);let kl=int(k);let s2=3+ml;let s3=s2+kl
 var dp:array[33,array[33,bool]];dp[0][0]=true
 for i in 0..ml:
  for j in 0..kl:
   if i>0 and dp[i-1][j] and a[3+i-1]==a[s3+i+j-1]:dp[i][j]=true
   if j>0 and dp[i][j-1] and a[s2+j-1]==a[s3+i+j-1]:dp[i][j]=true
 if dp[ml][kl]:1 else:0
