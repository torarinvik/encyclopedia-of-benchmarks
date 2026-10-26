const N=16
const K=4
const L=66
proc put64(output:ptr UncheckedArray[uint8],pos:int,value:int64)=
  let bits=cast[uint64](value)
  for j in 0..<8:output[pos+j]=uint8((bits shr (8*j)) and 255)
proc min_hash_k_mins*(input:ptr UncheckedArray[int64],length:csize_t,output:ptr UncheckedArray[uint8],capacity:csize_t):int64 {.cdecl,exportc:"min_hash_k_mins".}=
  if input.isNil or length<csize_t(3) or length>csize_t(L):return -1
  let nr=input[0];let kr=input[1]
  if nr<1 or nr>N or kr<1 or kr>K or int64(length)!=2+nr*kr:return -1
  let n=int(nr);let k=int(kr)
  for i in 0..<(n*k):if input[2+i]<0 or input[2+i]>1000:return -1
  let bytes=8*k;if output.isNil or capacity<csize_t(bytes):return -2
  for col in 0..<k:
    var best=0
    for row in 1..<n:if input[2+row*k+col]<input[2+best*k+col]:best=row
    put64(output,8*col,int64(best))
  int64(bytes)
