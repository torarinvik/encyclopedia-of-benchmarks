# Clean-room generalized vector First Fit bin-packing profile.
const MaxN=32;MaxD=4;MaxInput=130;MaxFields=161
proc put(out:ptr UncheckedArray[uint8],at:int,value:int64)=
  let bits=cast[uint64](value)
  for b in 0..<8:out[at+b]=uint8((bits shr (8*b)) and 255)
proc vector_bin_packing*(input:ptr UncheckedArray[int64],length:csize_t,output:ptr UncheckedArray[uint8],capacity:csize_t):int64 {.cdecl,exportc:"vector_bin_packing".}=
  if input.isNil or length<2 or length>csize_t(MaxInput):return -1
  let n64=input[0];let d64=input[1]
  if n64<1 or n64>32 or d64<1 or d64>4 or int(length)!=2+int(n64*d64):return -1
  let n=int(n64);let d=int(d64)
  for i in 0..<n*d:if input[2+i]<0 or input[2+i]>1000:return -1
  var loads:array[MaxN*MaxD,int64];var assignment:array[MaxN,int];var bins=0
  for item in 0..<n:
    var chosen=bins
    for b in 0..<bins:
      var fits=true
      for q in 0..<d:if loads[b*MaxD+q]+input[2+item*d+q]>1000:fits=false
      if fits:chosen=b;break
    if chosen==bins:inc bins
    assignment[item]=chosen
    for q in 0..<d:loads[chosen*MaxD+q]+=input[2+item*d+q]
  var staged:array[MaxFields,int64];var count=0
  staged[count]=int64(bins);inc count
  for i in 0..<n:staged[count]=int64(assignment[i]);inc count
  for b in 0..<bins:for q in 0..<d:staged[count]=loads[b*MaxD+q];inc count
  if output.isNil or capacity<csize_t(8*count):return -2
  for i in 0..<count:put(output,8*i,staged[i])
  int64(8*count)
