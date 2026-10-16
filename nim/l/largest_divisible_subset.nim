proc largest_divisible_subset*(v:ptr UncheckedArray[int64],n:csize_t):int64 {.cdecl,exportc:"largest_divisible_subset".}=
 if (v.isNil and n!=0) or n>64:return -1
 var a:array[64,int64];var d:array[64,int64]
 for i in 0..<n:
  if v[i]<1 or v[i]>50000:return -1
  a[i]=v[i]
 for i in 1..<n:
  let x=a[i];var j=i
  while j>0 and a[j-1]>x:a[j]=a[j-1];dec j
  a[j]=x
 var best=0'i64
 for i in 0..<n:
  d[i]=1
  for j in 0..<i:
   if a[i] mod a[j]==0 and d[j]+1>d[i]:d[i]=d[j]+1
  if d[i]>best:best=d[i]
 best
