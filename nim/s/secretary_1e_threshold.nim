const MaxN=16
const MaxInput=17
const SampleCounts=[0,0,0,1,1,1,2,2,2,3,3,4,4,4,5,5,5]

proc put64(outp:ptr UncheckedArray[uint8],value:int64)=
  let bits=cast[uint64](value)
  for j in 0..<8:outp[j]=uint8((bits shr (8*j)) and 255)

proc secretary_1e_threshold*(input:ptr UncheckedArray[int64],length:csize_t,
    output:ptr UncheckedArray[uint8],capacity:csize_t):int64 {.cdecl,exportc:"secretary_1e_threshold".}=
  if input.isNil or length<csize_t(4) or length>csize_t(MaxInput):return -1
  let n64=input[0]
  if n64<3 or n64>MaxN or int64(length)!=n64+1:return -1
  let n=int(n64)
  var seen:array[MaxN+1,bool]
  for i in 0..<n:
    let rank=input[i+1]
    if rank<1 or rank>n64 or seen[int(rank)]:return -1
    seen[int(rank)]=true
  let observed=SampleCounts[n]
  var threshold=input[1]
  for i in 1..<observed:
    if input[i+1]>threshold:threshold=input[i+1]
  var selected= -1'i64
  for i in observed..<n:
    if input[i+1]>threshold:selected=int64(i);break
  if output.isNil or capacity<csize_t(8):return -2
  var staged:array[8,uint8]
  put64(cast[ptr UncheckedArray[uint8]](addr staged[0]),selected)
  for i in 0..<8:output[i]=staged[i]
  8
