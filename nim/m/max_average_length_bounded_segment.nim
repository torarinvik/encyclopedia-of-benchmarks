const MaxN=32
const MaxInput=35
proc put64(output:ptr UncheckedArray[uint8],pos:int,value:int64)=
  let bits=cast[uint64](value)
  for j in 0..<8:output[pos+j]=uint8((bits shr (8*j)) and 255)
proc max_average_length_bounded_segment*(input:ptr UncheckedArray[int64],length:csize_t,output:ptr UncheckedArray[uint8],capacity:csize_t):int64 {.cdecl,exportc:"max_average_length_bounded_segment".}=
  if input.isNil or length<csize_t(4) or length>csize_t(MaxInput):return -1
  let n64=input[0];let lower64=input[1];let upper64=input[2]
  if n64<1 or n64>MaxN or lower64<1 or upper64<lower64 or upper64>n64 or int64(length)!=3+n64:return -1
  let n=int(n64);let lower=int(lower64);let upper=int(upper64)
  for i in 0..<n:if input[3+i]< -10000 or input[3+i]>10000:return -1
  if output.isNil or capacity<csize_t(32):return -2
  var bestSum=0'i64;var bestLen=1;var bestStart=0;var bestEnd=0;var have=false
  for start in 0..<n:
    var total=0'i64
    let limit=min(n,start+upper)
    for end in (start+1)..limit:
      total+=input[3+end-1]
      let size=end-start
      if size<lower:continue
      let left=total*int64(bestLen);let right=bestSum*int64(size)
      let tie=size<bestLen or (size==bestLen and (start<bestStart or (start==bestStart and end<bestEnd)))
      if not have or left>right or (left==right and tie):
        bestSum=total;bestLen=size;bestStart=start;bestEnd=end;have=true
  put64(output,0,bestSum);put64(output,8,int64(bestLen));put64(output,16,int64(bestStart));put64(output,24,int64(bestEnd));32
