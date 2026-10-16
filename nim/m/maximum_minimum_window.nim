proc storeI64Le(value:int64,out:ptr UncheckedArray[uint8],pos:int)=
  let bits=cast[uint64](value)
  for b in 0..<8:out[pos+b]=uint8((bits shr (8*b)) and 255)
proc maximum_minimum_window*(input:ptr UncheckedArray[int64],length:csize_t,output:ptr UncheckedArray[uint8],capacity:csize_t):int64 {.cdecl,exportc:"maximum_minimum_window".}=
  if input.isNil or length<2:return -2
  let n0=input[0];if n0<1 or n0>256 or int(length)!=int(n0)+1:return -2
  let n=int(n0);for i in 0..<n:if input[i+1]<0 or input[i+1]>1_000_000:return -2
  if output.isNil or capacity<csize_t(n*8):return -3
  var stack:array[256,int];var top=0;var left:array[256,int];var right:array[256,int];var ans:array[257,int64]
  for i in 0..<n:
    while top>0 and input[stack[top-1]+1]>=input[i+1]:dec top
    left[i]=if top>0:stack[top-1] else: -1;stack[top]=i;inc top
  top=0
  for ii in countdown(n-1,0):
    while top>0 and input[stack[top-1]+1]>=input[ii+1]:dec top
    right[ii]=if top>0:stack[top-1] else:n;stack[top]=ii;inc top
  for i in 0..<n:
    let size=right[i]-left[i]-1;ans[size]=max(ans[size],input[i+1])
  for k in countdown(n,2):ans[k-1]=max(ans[k-1],ans[k])
  for i in 1..n:storeI64Le(ans[i],output,(i-1)*8)
  int64(n)
