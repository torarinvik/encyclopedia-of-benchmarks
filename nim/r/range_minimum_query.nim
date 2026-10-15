## Static range minimum queries using a sparse table.
const MaxN=64
proc putI64Le(output:ptr UncheckedArray[uint8],offset:int,value:int64)=
  let bits=cast[uint64](value)
  for b in 0..<8:output[offset+b]=uint8((bits shr (8*b)) and 0xFF'u64)
proc range_minimum_query*(input:ptr UncheckedArray[int64],length:csize_t,output:ptr UncheckedArray[uint8],capacity:csize_t):int64 {.cdecl,exportc:"range_minimum_query".}=
  if input.isNil or length<4:return -1
  if input[0]<1 or input[0]>MaxN:return -1
  let n=int(input[0]);let qp=1+n
  if length<=csize_t(qp) or input[qp]<1 or input[qp]>64:return -1
  let q=int(input[qp]);if length!=csize_t(qp+1+2*q):return -1
  var values:array[MaxN,int64]
  for i in 0..<n:values[i]=input[1+i];if values[i]< -1000 or values[i]>1000:return -1
  if capacity<csize_t(q*8) or output.isNil:return -2
  var table:array[7,array[MaxN,int]]
  for i in 0..<n:table[0][i]=i
  var k=1
  while (1 shl k)<=n:
    let width=1 shl k;let half=width shr 1
    for i in 0..n-width:
      let a=table[k-1][i];let b=table[k-1][i+half]
      table[k][i]=if values[a]<values[b]:a else:b
    inc k
  let invalid:int64=low(int64)
  for j in 0..<q:
    let left=input[qp+1+2*j];let right=input[qp+2+2*j];var answer=invalid
    if left>=0 and right>left and right<=int64(n):
      let l=int(left);let r=int(right);let size=r-l
      var level=0
      while (1 shl (level+1))<=size:inc level
      let width=1 shl level;let a=table[level][l];let b=table[level][r-width]
      answer=if values[a]<values[b]:values[a] else:values[b]
    putI64Le(output,j*8,answer)
  int64(q*8)
