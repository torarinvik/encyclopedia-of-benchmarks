proc qs(a:openArray[int64],k:int64):int64=
 if a.len==1:return a[0]
 let p=a[0];var small:seq[int64]=@[];var big:seq[int64]=@[]
 for i in 1..<a.len:
  if a[i]<p:small.add(a[i])
  elif a[i]>p:big.add(a[i])
 if k==int64(small.len)+1:return p
 if k<=int64(small.len):return qs(small,k)
 qs(big,k-int64(small.len)-1)
proc kth_order_statistic*(v:ptr UncheckedArray[int64],n:csize_t):int64 {.cdecl,exportc:"kth_order_statistic".}=
 if v.isNil or n<2 or n>65:return -1
 let k=v[0];if k<1 or k>=int64(n-1):return -1
 var a:seq[int64]=@[]
 for i in 1..<n:
  if v[i]< -10000 or v[i]>10000:return -1
  for j in 1..<i:
   if v[i]==v[j]:return -1
  a.add(v[i])
 qs(a,k)
