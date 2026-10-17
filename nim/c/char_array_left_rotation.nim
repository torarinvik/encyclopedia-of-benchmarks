const MaxArrayLength=256
proc reverseBytes(a:var array[MaxArrayLength,uint8],fromIndex,toIndex:int)=
  var left=fromIndex;var right=toIndex
  while left<right:
    swap(a[left],a[right]);inc left;dec right
proc char_array_left_rotation*(input:ptr UncheckedArray[int64],length:csize_t,output:ptr UncheckedArray[uint8],capacity:csize_t):int64 {.cdecl,exportc:"char_array_left_rotation".}=
  if input.isNil or length<2 or length>csize_t(MaxArrayLength+3):return -1
  if input[0]<0 or input[0]>MaxArrayLength:return -1
  let n=int(input[0])
  if input[1]<0 or input[1]>int64(n) or length!=csize_t(n+2):return -1
  for i in 0..<n:
    if input[i+2]<0 or input[i+2]>127:return -1
  if output.isNil or capacity<csize_t(n):return -2
  var a:array[MaxArrayLength,uint8]
  for i in 0..<n:a[i]=uint8(input[i+2])
  let k=int(input[1])
  if k>0:reverseBytes(a,0,k-1)
  if k<n:reverseBytes(a,k,n-1)
  if n>0:reverseBytes(a,0,n-1)
  for i in 0..<n:output[i]=a[i]
  int64(n)
