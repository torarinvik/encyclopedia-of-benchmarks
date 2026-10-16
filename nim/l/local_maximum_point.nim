proc local_maximum_point*(v:ptr UncheckedArray[int64],n:csize_t):int64 {.cdecl,exportc:"local_maximum_point".}=
 if v.isNil or n<1 or n>64:return -1
 for i in 0..<n:if v[i]< -1000000 or v[i]>1000000:return -1
 var s=0;var e=int(n)-1
 while true:
  let m=s+(e-s) div 2
  if (m==0 or v[m-1]<=v[m]) and (m==int(n)-1 or v[m+1]<=v[m]):return int64(m)
  if m>0 and v[m-1]>v[m]:e=m-1 else:s=m+1
