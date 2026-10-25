proc put64(out: ptr UncheckedArray[uint8], pos: int, value: int64) =
  let u = cast[uint64](value)
  for j in 0..<8: out[pos+j] = uint8((u shr (8*j)) and 255)
proc edn_lattice_synthesis*(values: ptr UncheckedArray[int64], length: csize_t,
    output: ptr UncheckedArray[uint8], capacity: csize_t): int64 {.cdecl,exportc:"edn_lattice_synthesis".} =
  if values.isNil or length<2 or length>34:return -1
  let orderValue=values[0];var f=values[1]
  if orderValue<1 or orderValue>16 or f< -65536 or f>65535 or length!=csize_t(2+2*orderValue):return -1
  let q=int(orderValue);var b:array[16,int64];var k:array[16,int64]
  for i in 0..<q:
    b[i]=values[2+i];k[i]=values[2+q+i]
    if b[i]< -1024 or b[i]>1023 or k[i]< -1024 or k[i]>1023:return -1
  let bytes=8*(q+1)
  if output.isNil or capacity<csize_t(bytes):return -2
  f-=b[q-1]*k[q-1]
  if q>1:
    for z in countdown(q-1,1):
      let i=z-1;f-=b[i]*k[i];b[i+1]=b[i]+((k[i]*(f shr 16)) shr 16)
  b[0]=f shr 16;put64(output,0,f)
  for i in 0..<q:put64(output,8*(i+1),b[i])
  int64(bytes)
