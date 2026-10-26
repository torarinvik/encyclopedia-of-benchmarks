proc putI64Le(out:ptr UncheckedArray[uint8],x:int64)=
  let u=cast[uint64](x)
  for b in 0..<8:out[b]=uint8((u shr (8*b)) and 255'u64)
proc ams_sketch*(input:ptr UncheckedArray[int64],length:csize_t,output:ptr UncheckedArray[uint8],capacity:csize_t):int64 {.cdecl,exportc:"ams_sketch".}=
  if input.isNil or length<4 or length>116:return -1
  let d64=input[0];let w64=input[1];let k64=input[2];let u64=input[3]
  if (d64!=1 and d64!=3 and d64!=5) or w64<1 or w64>8 or k64<1 or k64>8 or u64<0 or u64>16:return -1
  let d=int(d64);let w=int(w64);let k=int(k64);let u=int(u64);let start=4+2*d*k
  if length!=csize_t(start+2*u):return -1
  for r in 0..<d:
    for key in 0..<k:
      let p=4+2*(r*k+key);if input[p]<0 or input[p]>=w64 or (input[p+1]!= -1 and input[p+1]!=1):return -1
  for i in 0..<u:
    let key=input[start+2*i];let weight=input[start+2*i+1];if key<0 or key>=k64 or weight< -1000 or weight>1000:return -1
  var counters:array[5,array[8,int64]];var estimates:array[5,int64]
  for i in 0..<u:
    let key=int(input[start+2*i]);let weight=input[start+2*i+1]
    for r in 0..<d:
      let p=4+2*(r*k+key);let bucket=int(input[p]);counters[r][bucket]+=weight*input[p+1]
  for r in 0..<d:
    for b in 0..<w:estimates[r]+=counters[r][b]*counters[r][b]
  for i in 1..<d:
    let x=estimates[i];var j=i
    while j>0 and estimates[j-1]>x:estimates[j]=estimates[j-1];dec j
    estimates[j]=x
  if capacity<8 or output.isNil:return -2
  putI64Le(output,estimates[d div 2]);8
