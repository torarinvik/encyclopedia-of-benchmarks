proc majority_element_sort*(v:ptr UncheckedArray[int64],n:csize_t):int64 {.cdecl,exportc:"majority_element_sort".}=
 if v.isNil or n<2 or n>128:return -1
 var a:array[128,int32]
 for i in 0..<int(n):
  if v[i]<low(int32).int64 or v[i]>high(int32).int64:return -1
  a[i]=int32(v[i])
 for i in 1..<int(n):
  let x=a[i];var j=i
  while j>0 and a[j-1]>x:a[j]=a[j-1];dec j
  a[j]=x
 var run=1
 for i in 1..<int(n):
  if a[i]==a[i-1]:inc run else:run=1
  if run>int(n) div 2:return int64(a[i])
 -1
