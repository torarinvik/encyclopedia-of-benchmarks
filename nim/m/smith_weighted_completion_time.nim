const MaxN=12
const MaxInput=25
proc put64(output:ptr UncheckedArray[uint8],pos:int,value:int64)=
  let bits=cast[uint64](value)
  for j in 0..<8:output[pos+j]=uint8((bits shr (8*j)) and 255)
proc smith_weighted_completion_time*(input:ptr UncheckedArray[int64],length:csize_t,output:ptr UncheckedArray[uint8],capacity:csize_t):int64 {.cdecl,exportc:"smith_weighted_completion_time".}=
  if input.isNil or length<csize_t(3) or length>csize_t(MaxInput):return -1
  let n64=input[0]
  if n64<1 or n64>MaxN or int64(length)!=1+2*n64:return -1
  let n=int(n64);var p,w,order:array[MaxN,int64]
  for i in 0..<n:
    p[i]=input[1+2*i];w[i]=input[2+2*i]
    if p[i]<1 or p[i]>10000 or w[i]<1 or w[i]>10000:return -1
    order[i]=int64(i)
  let bytes=8*(n+1);if output.isNil or capacity<csize_t(bytes):return -2
  for i in 1..<n:
    let key=order[i];var j=i
    while j>0:
      let prev=int(order[j-1]);let k=int(key)
      let before=w[k]*p[prev]>w[prev]*p[k] or (w[k]*p[prev]==w[prev]*p[k] and k<prev)
      if not before:break
      order[j]=order[j-1];dec j
    order[j]=key
  var elapsed=0'i64;var total=0'i64
  for i in 0..<n:
    let job=int(order[i]);elapsed+=p[job];total+=w[job]*elapsed
  put64(output,0,total)
  for i in 0..<n:put64(output,8*(i+1),order[i])
  int64(bytes)
