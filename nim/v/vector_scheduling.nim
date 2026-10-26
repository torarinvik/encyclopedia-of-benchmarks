# Clean-room explicit-choice profile of randomized vector scheduling.
const MaxN=16;MaxM=8;MaxD=4;MaxInput=83;MaxFields=35
proc put(out:ptr UncheckedArray[uint8],at:int,value:int64)=
  let bits=cast[uint64](value)
  for b in 0..<8:out[at+b]=uint8((bits shr (8*b)) and 255)
proc vector_scheduling*(input:ptr UncheckedArray[int64],length:csize_t,output:ptr UncheckedArray[uint8],capacity:csize_t):int64 {.cdecl,exportc:"vector_scheduling".}=
  if input.isNil or length<3 or length>csize_t(MaxInput):return -1
  let n64=input[0];let m64=input[1];let d64=input[2]
  if n64<1 or n64>16 or m64<1 or m64>8 or d64<1 or d64>4 or int(length)!=3+int(n64)+int(n64*d64):return -1
  let n=int(n64);let m=int(m64);let d=int(d64)
  for j in 0..<n:if input[3+j]<0 or input[3+j]>=m64:return -1
  for i in 0..<n*d:if input[3+n+i]<0 or input[3+n+i]>1000:return -1
  var loads:array[MaxM*MaxD,int64]
  for j in 0..<n:
    let machine=int(input[3+j])
    for q in 0..<d:loads[machine*MaxD+q]+=input[3+n+j*d+q]
  var span=0'i64
  for i in 0..<m:for q in 0..<d:span=max(span,loads[i*MaxD+q])
  var staged:array[MaxFields,int64];var count=0
  staged[count]=m64;inc count;staged[count]=d64;inc count;staged[count]=span;inc count
  for i in 0..<m:for q in 0..<d:staged[count]=loads[i*MaxD+q];inc count
  if output.isNil or capacity<csize_t(8*count):return -2
  for i in 0..<count:put(output,8*i,staged[i])
  int64(8*count)
