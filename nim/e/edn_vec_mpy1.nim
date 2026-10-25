proc put64(out:ptr UncheckedArray[uint8],pos:int,value:int64)=
  let u=cast[uint64](value)
  for j in 0..<8:out[pos+j]=uint8((u shr (8*j)) and 255)
proc edn_vec_mpy1*(values:ptr UncheckedArray[int64],length:csize_t,output:ptr UncheckedArray[uint8],capacity:csize_t):int64 {.cdecl,exportc:"edn_vec_mpy1".}=
  if values.isNil or length<4 or length>130:return -1
  let count=values[0];if count<1 or count>64 or length!=csize_t(2+2*count):return -1
  let q=int(count);let scale=values[int(length)-1];if scale< -1024 or scale>1023:return -1
  var y:array[64,int64];var x:array[64,int64]
  for i in 0..<q:y[i]=values[1+i];x[i]=values[1+q+i];if y[i]< -1024 or y[i]>1023 or x[i]< -1024 or x[i]>1023:return -1
  let bytes=8*q;if output.isNil or capacity<csize_t(bytes):return -2
  for i in 0..<q:y[i]+=(scale*x[i]) shr 15
  for i in 0..<q:put64(output,8*i,y[i])
  int64(bytes)
