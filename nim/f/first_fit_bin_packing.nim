proc putI64Le(output:ptr UncheckedArray[uint8],offset:int,value:int64)=
  let u=cast[uint64](value)
  for b in 0..<8:output[offset+b]=uint8((u shr (8*b)) and 255'u64)
proc first_fit_bin_packing*(input:ptr UncheckedArray[int64],length:csize_t,output:ptr UncheckedArray[uint8],capacity:csize_t):int64 {.cdecl,exportc:"first_fit_bin_packing".}=
  if input.isNil or length<1 or length>65:return -1
  let n64=input[0]
  if n64<0 or n64>64 or length!=csize_t(1+int(n64)):return -1
  let n=int(n64)
  for i in 0..<n:if input[i+1]<1 or input[i+1]>1_000_000:return -1
  var loads:array[64,int64];var ids:array[64,int64];var bins=0
  for i in 0..<n:
    let size=input[i+1];var b=0
    while b<bins and loads[b]+size>1_000_000:inc b
    if b==bins:loads[bins]=size;inc bins
    else:loads[b]+=size
    ids[i]=int64(b)
  let required=(n+1)*8
  if capacity<csize_t(required) or output.isNil:return -2
  putI64Le(output,0,int64(bins));for i in 0..<n:putI64Le(output,8*(i+1),ids[i])
  int64(required)
