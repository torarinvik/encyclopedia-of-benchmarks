# Clean-room TSVC s1213 profile; see package rights note.
proc tsvc_s1213_ordered_neighbor_array_map*(input:ptr UncheckedArray[int64],length:csize_t,out:ptr UncheckedArray[uint8],capacity:csize_t):int64 {.cdecl,exportc:"tsvc_s1213_ordered_neighbor_array_map".}=
 if input.isNil or length<13 or length>129:return -1
 let nr=input[0];if nr<3 or nr>32:return -1
 let n=int(nr);if length!=csize_t(1+4*n):return -1
 var a,b,c,d:array[32,int64]
 for i in 0..<n:let x=input[1+i];let y=input[1+n+i];let z=input[1+2*n+i];let w=input[1+3*n+i];if x< -1 or x>1 or y< -1 or y>1 or z< -1 or z>1 or w< -1 or w>1:return -1;a[i]=x;b[i]=y;c[i]=z;d[i]=w
 if out.isNil or capacity<csize_t(16*n):return -2
 for i in 1..<n-1:a[i]=b[i-1]+c[i];b[i]=a[i+1]*d[i]
 for i in 0..<n:
  var x=cast[uint64](a[i]);for k in 0..<8:out[8*i+k]=uint8(x and 255'u64);x=x shr 8
  x=cast[uint64](b[i]);for k in 0..<8:out[8*(n+i)+k]=uint8(x and 255'u64);x=x shr 8
 int64(2*n)
