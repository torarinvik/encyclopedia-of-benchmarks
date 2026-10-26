const MaxM=8
const MaxN=32
const MaxInput=34
proc put64(output:ptr UncheckedArray[uint8],pos:int,value:int64)=
  let bits=cast[uint64](value)
  for j in 0..<8:output[pos+j]=uint8((bits shr (8*j)) and 255)
proc list_scheduling*(input:ptr UncheckedArray[int64],length:csize_t,output:ptr UncheckedArray[uint8],capacity:csize_t):int64 {.cdecl,exportc:"list_scheduling".}=
  if input.isNil or length<csize_t(3) or length>csize_t(MaxInput):return -1
  let m64=input[0];let n64=input[1]
  if m64<1 or m64>MaxM or n64<1 or n64>MaxN or int64(length)!=2+n64:return -1
  let m=int(m64);let n=int(n64)
  for i in 0..<n:if input[2+i]<1 or input[2+i]>10000:return -1
  let bytes=8*(1+n+m);if output.isNil or capacity<csize_t(bytes):return -2
  var load:array[MaxM,int64];var assign:array[MaxN,int64]
  for i in 0..<n:
    var best=0
    for j in 1..<m:if load[j]<load[best]:best=j
    assign[i]=int64(best);load[best]+=input[2+i]
  var span=load[0];for j in 1..<m:if load[j]>span:span=load[j]
  put64(output,0,span)
  for i in 0..<n:put64(output,8*(1+i),assign[i])
  for j in 0..<m:put64(output,8*(1+n+j),load[j])
  int64(bytes)
