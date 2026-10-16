proc peak(a:ptr UncheckedArray[int64],lo,hi,n:int64):int64=
 let mid=lo+(hi-lo) div 2
 if (mid==0 or a[mid-1]<=a[mid]) and (mid==n-1 or a[mid+1]<=a[mid]):return mid
 if mid>0 and a[mid-1]>a[mid]:return peak(a,lo,mid-1,n)
 peak(a,mid+1,hi,n)
proc peak_element*(v:ptr UncheckedArray[int64],n:csize_t):int64 {.cdecl,exportc:"peak_element".}=
 if v.isNil or n<2 or n>129 or v[0]<1 or v[0]>128 or n!=csize_t(v[0]+1):return -1
 let count=v[0]
 for i in 0..<int(count):
  if v[i+1]<low(int32).int64 or v[i+1]>high(int32).int64:return -1
 peak(cast[ptr UncheckedArray[int64]](addr v[1]),0,count-1,count)
