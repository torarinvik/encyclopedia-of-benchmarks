const MAX_INPUT=35
proc put64(output:ptr UncheckedArray[uint8],pos:int,value:int64)=
  let bits=cast[uint64](value)
  for j in 0..<8:output[pos+j]=uint8((bits shr (8*j)) and 255)
proc min_hash_bottom_k*(input:ptr UncheckedArray[int64],length:csize_t,output:ptr UncheckedArray[uint8],capacity:csize_t):int64 {.cdecl,exportc:"min_hash_bottom_k".}=
  if input.isNil or length<csize_t(4) or length>csize_t(MAX_INPUT):return -1
  let nr=input[0];let kr=input[1]
  if nr<1 or nr>16 or kr<1 or kr>8 or int64(length)!=2+2*nr:return -1
  let n=int(nr);let k=int(kr);var ids:array[16,int];var ranks:array[16,int64];var count=0
  for i in 0..<n:
    let id=input[2+2*i];let rank=input[3+2*i]
    if id<0 or id>=16 or rank<0 or rank>1000:return -1
    for j in 0..<i:if id==input[2+2*j]:return -1
    var pos=0
    while pos<count and (ranks[pos]<rank or (ranks[pos]==rank and ids[pos]<int(id))):pos+=1
    if pos<k:
      var next=if count<k:count else:k-1
      while next>pos:ids[next]=ids[next-1];ranks[next]=ranks[next-1];next-=1
      ids[pos]=int(id);ranks[pos]=rank
      if count<k:count+=1
  let bytes=8*(1+2*count)
  if output.isNil or capacity<csize_t(bytes):return -2
  put64(output,0,int64(count))
  for i in 0..<count:put64(output,8+16*i,int64(ids[i]));put64(output,16+16*i,ranks[i])
  int64(bytes)
