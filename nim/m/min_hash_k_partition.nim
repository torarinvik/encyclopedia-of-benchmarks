const MaxK=8
const MaxN=32
const EmptyRank=1001
proc putI64(outp:ptr UncheckedArray[uint8],pos:int,value:int64)=
  let bits=cast[uint64](value)
  for b in 0..<8:outp[pos+b]=uint8((bits shr (8*b)) and 255)
proc minHashKPartition(input:ptr UncheckedArray[int64],length:csize_t,output:ptr UncheckedArray[uint8],capacity:csize_t):int64 {.cdecl,exportc:"min_hash_k_partition".}=
  if input.isNil or length<2 or length>66:return -1
  let k0=input[0];let n0=input[1]
  if k0<1 or k0>MaxK or n0<0 or n0>MaxN or length!=csize_t(2+2*n0):return -1
  let k=int(k0);let n=int(n0)
  var ids:array[MaxK,int64];var ranks:array[MaxK,int64]
  for b in 0..<k:ids[b]= -1;ranks[b]=EmptyRank
  for id in 0..<n:
    let bucket=input[2+2*id];let rank=input[3+2*id]
    if bucket<0 or bucket>=k0 or rank<0 or rank>1000:return -1
    let b=int(bucket)
    if ids[b]<0 or rank<ranks[b] or (rank==ranks[b] and int64(id)<ids[b]):ids[b]=int64(id);ranks[b]=rank
  var staged:array[2*MaxK,int64]
  for b in 0..<k:staged[2*b]=ids[b];staged[2*b+1]=ranks[b]
  let required=2*k*8
  if output.isNil or capacity<csize_t(required):return -2
  for i in 0..<2*k:putI64(output,i*8,staged[i])
  int64(required)
