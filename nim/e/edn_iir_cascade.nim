proc put64(out:ptr UncheckedArray[uint8],pos:int,value:int64)=
  let u=cast[uint64](value)
  for j in 0..<8:out[pos+j]=uint8((u shr (8*j)) and 255)
proc edn_iir_cascade*(values:ptr UncheckedArray[int64],length:csize_t,output:ptr UncheckedArray[uint8],capacity:csize_t):int64 {.cdecl,exportc:"edn_iir_cascade".}=
  if values.isNil or length<2 or length>50:return -1
  let count=values[0];var x=values[1]
  if count<1 or count>8 or x< -1024 or x>1023 or length!=csize_t(2+6*count):return -1
  let q=int(count);var c:array[32,int64];var s:array[16,int64]
  for i in 0..<4*q:c[i]=values[2+i];if c[i]< -1024 or c[i]>1023:return -1
  for i in 0..<2*q:s[i]=values[2+4*q+i];if s[i]< -1024 or s[i]>1023:return -1
  let bytes=8*(1+2*q);if output.isNil or capacity<csize_t(bytes):return -2
  for i in 0..<q:
    let t=x+((c[4*i+2]*s[2*i]+c[4*i+3]*s[2*i+1]) shr 15)
    x=t+((c[4*i]*s[2*i]+c[4*i+1]*s[2*i+1]) shr 15)
    s[2*i+1]=s[2*i];s[2*i]=t
  put64(output,0,x)
  for i in 0..<2*q:put64(output,8*(i+1),s[i])
  int64(bytes)
